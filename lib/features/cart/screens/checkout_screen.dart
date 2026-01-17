import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Importante para detectar web

// --- Imports de Modelos ---
import 'package:proveedor_servicly_app/core/models/order_model.dart';
import 'package:proveedor_servicly_app/core/models/payment_method_model.dart';

// --- Imports de Servicios ---
import 'package:proveedor_servicly_app/core/services/auth_service.dart';
import 'package:proveedor_servicly_app/core/services/order_service.dart';
import 'package:proveedor_servicly_app/core/services/payment_service.dart';
import 'package:proveedor_servicly_app/core/services/storage_service.dart'; 

// --- ViewModels y Pantallas ---
import 'package:proveedor_servicly_app/core/viewmodels/cart_provider.dart';
import 'package:proveedor_servicly_app/features/auth/screens/verification_screen.dart';

// CONSTANTES DE DISEÑO
const double kMaxWebWidth = 1200.0;
const double kMobileBreakpoint = 900.0;

class CheckoutScreen extends StatefulWidget {
  final CartProvider cart;
  const CheckoutScreen({super.key, required this.cart});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Servicios
  late final PaymentService _paymentService;
  late final OrderService _orderService;
  late final AuthService _authService;
  late final StorageService _storageService; 

  // Datos de la Orden
  late final String? _providerId;
  late final String? _clientId;
  
  // Estado del Formulario
  PaymentMethodModel? _selectedMethod;
  bool _isLoading = false;
  XFile? _paymentProofFile; 
  final ImagePicker _picker = ImagePicker(); 

  // Logística y Dirección
  DeliveryType _deliveryType = DeliveryType.pickup;
  
  // Gestión de Direcciones
  bool _useSavedAddress = true; 
  String? _savedUserAddress;    
  final TextEditingController _altAddressController = TextEditingController(); 
  final TextEditingController _dniController = TextEditingController(); 
  
  // Seguridad
  bool _isVerifiedClient = false; 

  @override
  void initState() {
    super.initState();
    _paymentService = context.read<PaymentService>();
    _orderService = context.read<OrderService>();
    _authService = context.read<AuthService>();
    _storageService = context.read<StorageService>(); 

    _providerId = widget.cart.items.isNotEmpty ? widget.cart.items.first.product.providerId : null;
    final user = _authService.currentUser;
    _clientId = user?.uid;

    if (user != null) {
      _loadUserData(user.uid);
    }
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        final String status = data?['verificationStatus'] ?? '';
        final bool isLegacyVerified = data?['isVerified'] == true;
        final bool isVerified = (status == 'basic_verified') || isLegacyVerified;
        
        String? loadedAddress = data?['address'] ?? data?['shippingAddress'];
        String? savedDni = data?['dni'] ?? data?['phoneNumber']; 

        if (mounted) {
          setState(() {
            _isVerifiedClient = isVerified;
            _savedUserAddress = loadedAddress; 
            if (_savedUserAddress == null || _savedUserAddress!.isEmpty) {
              _useSavedAddress = false;
            }
            if (_dniController.text.isEmpty && savedDni != null) {
              if (data?['dni'] != null) _dniController.text = savedDni;
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error cargando datos de usuario: $e");
    }
  }

  @override
  void dispose() {
    _altAddressController.dispose();
    _dniController.dispose();
    super.dispose();
  }

  Future<void> _pickPaymentProof() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 70
      );
      if (image != null) {
        setState(() => _paymentProofFile = image);
      }
    } catch (e) { 
      if (mounted) _showErrorSnackBar("Error al seleccionar imagen: $e"); 
    }
  }

  Future<void> _placeOrder() async {
    if (!_isVerifiedClient) {
       _showVerificationDialog();
       return;
    }
    
    if (_selectedMethod == null) return _showErrorSnackBar('Selecciona un método de pago.');
    if (_paymentProofFile == null) return _showErrorSnackBar('Adjunta el comprobante de pago.');
    
    // Validación de dirección
    String finalAddressToUse = '';
    if (_deliveryType == DeliveryType.delivery) {
      if (_useSavedAddress) {
        if (_savedUserAddress == null || _savedUserAddress!.isEmpty) {
          return _showErrorSnackBar('Tu dirección guardada está vacía. Por favor ingresa una nueva.');
        }
        finalAddressToUse = _savedUserAddress!;
      } else {
        if (_altAddressController.text.trim().isEmpty) {
          return _showErrorSnackBar('Ingresa la dirección de envío.');
        }
        finalAddressToUse = _altAddressController.text.trim();
      }
      if (_dniController.text.trim().isEmpty) {
        return _showErrorSnackBar('Ingresa tu DNI para la etiqueta de envío.');
      }
    }

    setState(() => _isLoading = true);
    final navigator = Navigator.of(context);

    try {
      final clientUser = _authService.currentUser;
      final clientName = clientUser?.displayName ?? 'Cliente';
      final clientEmail = clientUser?.email ?? '';

      // Upload Proof (Manejo Web vs Móvil)
      // En Web, pickImage devuelve un XFile que puede leerse como bytes
      String paymentProofUrl = '';
      if (kIsWeb) {
         final bytes = await _paymentProofFile!.readAsBytes();
         final String storagePath = 'orders/$_providerId/proof_${_clientId}_${Timestamp.now().millisecondsSinceEpoch}.jpg';
         // ESTA FUNCIÓN DEBE EXISTIR EN TU STORAGE SERVICE
         paymentProofUrl = await _storageService.uploadBytesWithProgress(bytes, storagePath, (_) {});
      } else {
         final String storagePath = 'orders/$_providerId/proof_${_clientId}_${Timestamp.now().millisecondsSinceEpoch}.jpg';
         paymentProofUrl = await _storageService.uploadFileWithProgress(File(_paymentProofFile!.path), storagePath, (_) {});
      }

      String shippingAddressFormatted = '';
      if (_deliveryType == DeliveryType.delivery) {
        shippingAddressFormatted = "$finalAddressToUse (DNI: ${_dniController.text.trim()})";
      }

      final newOrder = OrderModel(
        id: '', 
        clientId: _clientId!, 
        providerId: _providerId!, 
        clientName: clientName,
        clientEmail: clientEmail,
        items: widget.cart.items.map((item) => {
          'productId': item.product.id,
          'name': item.product.name,
          'price': (item.subtotal / item.quantity),
          'quantity': item.quantity,
          'imageUrl': item.product.imageUrl,
        }).toList(),
        total: widget.cart.totalPrice,
        status: OrderStatus.pendingVerification,
        createdAt: Timestamp.now(),
        paymentMethodId: _selectedMethod!.id, 
        paymentProofUrl: paymentProofUrl,
        clientNotes: '', 
        deliveryType: _deliveryType,
        shippingAddress: shippingAddressFormatted, 
        shippingCost: 0.0, 
      );

      await _orderService.createOrder(newOrder);

      if (_deliveryType == DeliveryType.delivery) {
         final updateData = <String, dynamic>{'dni': _dniController.text.trim()};
         if (!_useSavedAddress) {
           updateData['address'] = finalAddressToUse; 
         }
         await FirebaseFirestore.instance.collection('users').doc(_clientId).update(updateData);
      }

      widget.cart.clearCart();

      if (mounted) { 
        await _showOrderSuccessDialog(navigator); 
        navigator.popUntil((route) => route.isFirst); 
      }

    } catch (e) {
      if (mounted) _showErrorSnackBar('Error al procesar el pedido: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showVerificationDialog() {
    showDialog(
         context: context,
         builder: (ctx) {
           final theme = Theme.of(ctx); 
           return AlertDialog(
             backgroundColor: theme.cardTheme.color,
             title: Text('Verificación Requerida', style: TextStyle(color: theme.colorScheme.onSurface)),
             content: Text('Para seguridad de todos, verifica tu identidad antes de comprar.', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
             actions: [
               TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.pop(ctx)),
               FilledButton(child: const Text('Ir a Verificar'), onPressed: () { 
                   Navigator.pop(ctx); 
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationScreen())).then((_) {
                     if (_clientId != null) _loadUserData(_clientId!);
                   }); 
                 }
               ),
             ],
           );
         },
       );
  }

  void _showErrorSnackBar(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
    }
  }

  String _getPaymentDetails(PaymentMethodModel method) {
    if (method.alias?.isNotEmpty == true) return "Alias: ${method.alias}";
    if (method.cbu?.isNotEmpty == true) return "CBU: ${method.cbu}";
    return "Ver detalles";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = colorScheme.primary;
    
    // Validación de botón
    bool isAddressValid = false;
    if (_deliveryType == DeliveryType.pickup) {
      isAddressValid = true;
    } else {
      if (_useSavedAddress) {
        isAddressValid = (_savedUserAddress != null && _savedUserAddress!.isNotEmpty) && _dniController.text.isNotEmpty;
      } else {
        isAddressValid = _altAddressController.text.isNotEmpty && _dniController.text.isNotEmpty;
      }
    }

    final bool canConfirm = _selectedMethod != null && _paymentProofFile != null && !_isLoading && isAddressValid;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Confirmar Pedido'), 
        backgroundColor: theme.scaffoldBackgroundColor, 
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: kIsWeb, // Centrado en web
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // --- MODO WEB (SPLIT VIEW) ---
          if (constraints.maxWidth > kMobileBreakpoint) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kMaxWebWidth),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // COLUMNA IZQUIERDA (Scrollable Forms)
                      Expanded(
                        flex: 6,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_providerId != null) _buildReputationBanner(_providerId!, theme),
                              _buildSectionTitle('Método de Entrega', theme),
                              _buildDeliveryOptions(theme, accentColor), 
                              const SizedBox(height: 32),
                              _buildSectionTitle('Método de Pago', theme),
                              if (_providerId != null) _buildPaymentMethodsList(theme, accentColor),
                              if (_selectedMethod != null) ...[
                                const SizedBox(height: 32),
                                _buildSectionTitle('Comprobante', theme),
                                _buildPaymentProofUploader(theme.cardTheme.color!, accentColor, theme),
                              ],
                              const SizedBox(height: 50),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 32),

                      // COLUMNA DERECHA (Sticky Summary)
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            _buildOrderSummaryCard(theme, accentColor, canConfirm),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } 
          
          // --- MODO MÓVIL (Original ListView) ---
          else {
            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    if (_providerId != null) _buildReputationBanner(_providerId!, theme),
                    _buildSectionTitle('Resumen de Compra', theme),
                    _buildCompactOrderSummary(theme, accentColor, theme.colorScheme),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Método de Entrega', theme),
                    _buildDeliveryOptions(theme, accentColor), 
                    const SizedBox(height: 24),
                    _buildSectionTitle('Método de Pago', theme),
                    if (_providerId != null) _buildPaymentMethodsList(theme, accentColor),
                    if (_selectedMethod != null) ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle('Comprobante', theme),
                      _buildPaymentProofUploader(theme.cardTheme.color!, accentColor, theme),
                    ],
                    const SizedBox(height: 100), 
                  ],
                ),
                if (_isLoading) Container(color: Colors.black54, child: Center(child: CircularProgressIndicator(color: accentColor))),
                // Botón flotante móvil
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _buildConfirmButton(accentColor, canConfirm, theme),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  // --- WIDGETS AUXILIARES REUTILIZABLES ---

  // Tarjeta de Resumen GRANDE para Web (Con botón incluido)
  Widget _buildOrderSummaryCard(ThemeData theme, Color accentColor, bool canConfirm) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Resumen del Pedido", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Lista de items compacta
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView(
              shrinkWrap: true,
              children: widget.cart.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${item.quantity}x ${item.product.name}', style: const TextStyle(fontSize: 14))),
                    Text('\$${item.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              )).toList(),
            ),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total a Pagar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('\$${widget.cart.totalPrice.toStringAsFixed(2)}', style: TextStyle(color: accentColor, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: accentColor, 
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ), 
              onPressed: canConfirm ? _placeOrder : null, 
              child: _isLoading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
                : const Text('CONFIRMAR PEDIDO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  // Resumen simple para móvil
  Widget _buildCompactOrderSummary(ThemeData theme, Color accentColor, ColorScheme colorScheme) {
      return Container(
        padding: const EdgeInsets.all(16), 
        decoration: BoxDecoration(
          color: theme.cardTheme.color, 
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5))
        ), 
        child: Column(
          children: [
            ...widget.cart.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0), 
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                children: [
                  Flexible(child: Text('${item.quantity}x ${item.product.name}', style: TextStyle(color: colorScheme.onSurface, fontSize: 16), overflow: TextOverflow.ellipsis)), 
                  Text('\$${item.subtotal.toStringAsFixed(2)}', style: TextStyle(color: colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w500))
                ]
              )
            )), 
            Divider(color: theme.dividerColor, height: 24), 
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [
                Text('TOTAL', style: TextStyle(color: accentColor, fontSize: 20, fontWeight: FontWeight.bold)), 
                Text('\$${widget.cart.totalPrice.toStringAsFixed(2)}', style: TextStyle(color: accentColor, fontSize: 20, fontWeight: FontWeight.bold))
              ]
            )
          ]
        )
      );
  }

  // Botón Confirmar Móvil
  Widget _buildConfirmButton(Color accentColor, bool canConfirm, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), 
      color: theme.bottomNavigationBarTheme.backgroundColor, 
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: accentColor, 
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
        ), 
        onPressed: canConfirm ? _placeOrder : null, 
        child: _isLoading 
          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
          : const Text('CONFIRMAR PEDIDO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))
      )
    );
  }

  Widget _buildDeliveryOptions(ThemeData theme, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5))),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: _buildRadioOption(DeliveryType.pickup, "Retiro en Tienda", Icons.storefront, accentColor, theme)),
            Expanded(child: _buildRadioOption(DeliveryType.delivery, "Envío a Domicilio", Icons.local_shipping, accentColor, theme)),
          ]),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _deliveryType == DeliveryType.delivery ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity), 
            secondChild: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  const Divider(), const SizedBox(height: 8),
                  if (_savedUserAddress != null && _savedUserAddress!.isNotEmpty) ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero, 
                      activeTrackColor: accentColor, // CORRECCIÓN: activeColor Deprecado -> activeTrackColor
                      title: const Text("Usar mi dirección principal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), 
                      subtitle: Text(_savedUserAddress!, maxLines: 2, overflow: TextOverflow.ellipsis), 
                      value: _useSavedAddress, 
                      onChanged: (val) => setState(() => _useSavedAddress = val)
                    ),
                  ],
                  if (!_useSavedAddress || _savedUserAddress == null) ...[
                    const SizedBox(height: 8),
                    TextField(controller: _altAddressController, style: TextStyle(color: theme.colorScheme.onSurface), decoration: InputDecoration(labelText: 'Ingresa la dirección de envío', hintText: 'Calle, Altura, Piso, Ciudad', prefixIcon: Icon(Icons.location_on_outlined, color: accentColor), filled: true, fillColor: theme.scaffoldBackgroundColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), onChanged: (_) => setState((){})),
                  ],
                  const SizedBox(height: 12),
                  TextField(controller: _dniController, keyboardType: TextInputType.number, style: TextStyle(color: theme.colorScheme.onSurface), decoration: InputDecoration(labelText: 'DNI / CUIT', hintText: 'Requerido para la etiqueta de envío', prefixIcon: Icon(Icons.badge_outlined, color: accentColor), filled: true, fillColor: theme.scaffoldBackgroundColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), onChanged: (_) => setState((){})),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(DeliveryType value, String label, IconData icon, Color accentColor, ThemeData theme) {
    final isSelected = _deliveryType == value;
    return GestureDetector(
      onTap: () => setState(() => _deliveryType = value),
      child: Container(margin: const EdgeInsets.all(4), padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: isSelected ? accentColor.withValues(alpha: 0.1) : Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? accentColor : theme.dividerColor.withValues(alpha: 0.3))), child: Column(children: [Icon(icon, color: isSelected ? accentColor : theme.colorScheme.onSurface.withValues(alpha: 0.5)), const SizedBox(height: 4), Text(label, style: TextStyle(color: isSelected ? accentColor : theme.colorScheme.onSurface, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12))])),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title.toUpperCase(), style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.bold, letterSpacing: 1.0)));
  
  Widget _buildPaymentMethodsList(ThemeData theme, Color accentColor) {
    return StreamBuilder<List<PaymentMethodModel>>(
      stream: _paymentService.getPaymentMethodsStream(_providerId!), 
      builder: (context, snapshot) { 
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator()); 
        if (snapshot.data!.isEmpty) return const Text("Este proveedor no tiene métodos de pago configurados.");
        
        return Column(
          children: snapshot.data!.map((m) {
            final bool isSelected = _selectedMethod?.id == m.id;
            return Card(margin: const EdgeInsets.only(bottom: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: isSelected ? BorderSide(color: accentColor, width: 2) : BorderSide.none), color: theme.cardTheme.color, child: ListTile(onTap: () => setState(() => _selectedMethod = m), leading: Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? accentColor : theme.colorScheme.onSurface.withValues(alpha: 0.5)), title: Text(m.name, style: TextStyle(color: theme.colorScheme.onSurface)), subtitle: Text(_getPaymentDetails(m), style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)))));
          }).toList()
        ); 
      }
    );
  }

  Widget _buildPaymentProofUploader(Color surfaceColor, Color accentColor, ThemeData theme) {
      return GestureDetector(
        onTap: _pickPaymentProof, 
        child: Container(
          height: 200, 
          decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: _paymentProofFile == null ? theme.dividerColor : accentColor, width: 2, style: BorderStyle.solid)), 
          child: _paymentProofFile == null 
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cloud_upload_outlined, color: accentColor, size: 48), const SizedBox(height: 12), Text('Arrastra o selecciona el comprobante', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold))]) 
            : ClipRRect(borderRadius: BorderRadius.circular(10), child: kIsWeb 
                ? Image.network(_paymentProofFile!.path, fit: BoxFit.contain, width: double.infinity) 
                : Image.file(File(_paymentProofFile!.path), fit: BoxFit.cover, width: double.infinity)
              )
        )
      );
  }

  Future<void> _showOrderSuccessDialog(NavigatorState navigator) {
    return showDialog(context: navigator.context, builder: (ctx) => AlertDialog(title: const Text('¡Pedido Enviado!'), content: const Text('Tu pedido ha sido enviado al proveedor. Te notificaremos cuando lo acepte.'), actions: [TextButton(child: const Text('Entendido'), onPressed: () => navigator.pop())]));
  }

  Widget _buildReputationBanner(String providerId, ThemeData theme) {
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(providerId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          double rating = 0.0; int count = 0;
          if (data != null) { rating = (data['ratingAvg'] ?? 0.0).toDouble(); count = (data['ratingCount'] ?? 0) as int; }
          if (count == 0) return const SizedBox();
          return Container(margin: const EdgeInsets.only(bottom: 24), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.withValues(alpha: 0.3))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.verified_user_outlined, color: Colors.amber, size: 20), const SizedBox(width: 8), Text("Proveedor Destacado: ", style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.9))), const Icon(Icons.star, color: Colors.amber, size: 16), Text(" $rating ($count)", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))]));
        },
      );
  }
}