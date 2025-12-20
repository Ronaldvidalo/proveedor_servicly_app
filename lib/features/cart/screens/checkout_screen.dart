import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final TextEditingController _addressController = TextEditingController();
  
  // --- NUEVO: Controlador para DNI ---
  final TextEditingController _dniController = TextEditingController(); 
  
  // Seguridad
  bool _isVerifiedClient = false; 

  @override
  void initState() {
    super.initState();
    // Inicializar servicios
    _paymentService = context.read<PaymentService>();
    _orderService = context.read<OrderService>();
    _authService = context.read<AuthService>();
    _storageService = context.read<StorageService>(); 

    // Obtener IDs clave
    _providerId = widget.cart.items.isNotEmpty ? widget.cart.items.first.product.providerId : null;
    final user = _authService.currentUser;
    _clientId = user?.uid;

    // Cargar datos del usuario si existe
    if (user != null) {
      _loadUserData(user.uid);
    }
  }

  /// 🧠 CEREBRO: Carga datos guardados del usuario (Memoria)
  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        
        // 1. Verificar Estado de Verificación
        final bool isVerified = data?['isVerified'] == true;
        
        // 2. Recuperar Datos de Envío Guardados
        String? savedAddress = data?['shippingAddress'];
        String? savedDni = data?['dni']; 

        if (mounted) {
          setState(() {
            _isVerifiedClient = isVerified;
            
            // Auto-completar dirección si está guardada
            if (_addressController.text.isEmpty && savedAddress != null) {
              _addressController.text = savedAddress;
            }
            // Auto-completar DNI si está guardado (NUEVO)
            if (_dniController.text.isEmpty && savedDni != null) {
              _dniController.text = savedDni;
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
    _addressController.dispose();
    _dniController.dispose();
    super.dispose();
  }

  // Selección de Comprobante
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

  // Proceso Principal de Compra
  Future<void> _placeOrder() async {
    // 1. Verificación de Seguridad (Bloqueo si no está verificado)
    if (!_isVerifiedClient) {
       showDialog(
         context: context,
         builder: (ctx) {
           final theme = Theme.of(ctx); 
           return AlertDialog(
             backgroundColor: theme.cardTheme.color,
             title: Text(
               'Verificación Requerida', 
               style: TextStyle(color: theme.colorScheme.onSurface)
             ),
             content: Text(
               'Para seguridad de todos, verifica tu identidad (Email/Teléfono) antes de comprar.', 
               style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))
             ),
             actions: [
               TextButton(
                 child: const Text('Cancelar'), 
                 onPressed: () => Navigator.pop(ctx)
               ),
               FilledButton(
                 child: const Text('Verificarme'), 
                 onPressed: () { 
                   Navigator.pop(ctx); 
                   Navigator.push(
                     context, 
                     MaterialPageRoute(builder: (_) => const VerificationScreen())
                   ).then((_) => _loadUserData(_clientId!)); // Recargar al volver
                 }
               ),
             ],
           );
         },
       );
       return;
    }
    
    // Validaciones básicas del formulario
    if (_selectedMethod == null) return _showErrorSnackBar('Selecciona un método de pago.');
    if (_paymentProofFile == null) return _showErrorSnackBar('Adjunta el comprobante de pago.');
    
    // 2. Validaciones de Envío y DNI
    if (_deliveryType == DeliveryType.delivery) {
      if (_addressController.text.trim().isEmpty) {
        return _showErrorSnackBar('Ingresa la dirección de envío.');
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

      // A. Subir Imagen del Comprobante
      final String storagePath = 'orders/$_providerId/proof_${_clientId}_${Timestamp.now().millisecondsSinceEpoch}.jpg';
      final String paymentProofUrl = await _storageService.uploadFileWithProgress(
        File(_paymentProofFile!.path), 
        storagePath, 
        (_) {}
      );

      // B. Construir dirección final (Dirección + DNI)
      String finalShippingAddress = '';
      if (_deliveryType == DeliveryType.delivery) {
        finalShippingAddress = "${_addressController.text.trim()} (DNI: ${_dniController.text.trim()})";
      }

      // C. Crear Objeto Orden
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
        status: OrderStatus.pending_verification,
        createdAt: Timestamp.now(),
        paymentMethodId: _selectedMethod!.id, 
        paymentProofUrl: paymentProofUrl,
        clientNotes: '', 
        deliveryType: _deliveryType,
        shippingAddress: finalShippingAddress, 
        shippingCost: 0.0, 
      );

      // D. Guardar Orden en Base de Datos
      await _orderService.createOrder(newOrder);

      // E. --- MEMORIA: GUARDAR DATOS DE ENVÍO PARA LA PRÓXIMA ---
      if (_deliveryType == DeliveryType.delivery) {
        await FirebaseFirestore.instance.collection('users').doc(_clientId).update({
          'shippingAddress': _addressController.text.trim(),
          'dni': _dniController.text.trim(), // Guardamos el DNI
        });
      }
      // ----------------------------------------------------------

      // F. Limpiar Carrito y Salir
      widget.cart.clearCart();

      if (mounted) { 
        await _showOrderSuccessDialog(navigator); 
        navigator.popUntil((route) => route.isFirst); // Volver al inicio
      }

    } catch (e) {
      if (mounted) _showErrorSnackBar('Error al procesar el pedido: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent)
      );
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
    final bool canConfirm = _selectedMethod != null && 
                            _paymentProofFile != null && 
                            !_isLoading &&
                            (_deliveryType == DeliveryType.pickup || 
                             (_addressController.text.trim().isNotEmpty && _dniController.text.trim().isNotEmpty));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Confirmar Pedido'), 
        backgroundColor: theme.scaffoldBackgroundColor, 
        foregroundColor: colorScheme.onSurface,
        elevation: 0
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Banner de reputación (Placeholder si lo tenías)
              if (_providerId != null) 
                _buildReputationBanner(_providerId!, theme),
              
              // 1. Resumen
              _buildSectionTitle('Resumen de Compra', theme),
              _buildOrderSummary(theme, accentColor, theme.colorScheme),
              const SizedBox(height: 24),
              
              // 2. Método de Entrega
              _buildSectionTitle('Método de Entrega', theme),
              _buildDeliveryOptions(theme, accentColor), 
              const SizedBox(height: 24),
              
              // 3. Método de Pago
              _buildSectionTitle('Método de Pago', theme),
              if (_providerId == null) 
                const Text("Error: Proveedor no encontrado") 
              else 
                _buildPaymentMethodsList(theme, accentColor),
              
              // 4. Comprobante (Visible solo si seleccionó pago)
              if (_selectedMethod != null) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('Comprobante de Transferencia', theme),
                _buildPaymentProofUploader(theme.cardTheme.color!, accentColor, theme),
              ],
              
              const SizedBox(height: 100), // Espacio para el botón flotante
            ],
          ),
          
          // Loader superpuesto
          if (_isLoading) 
            Container(
              color: Colors.black54, 
              child: Center(child: CircularProgressIndicator(color: accentColor))
            ),
        ],
      ),
      bottomNavigationBar: _buildConfirmButton(accentColor, canConfirm, theme),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildDeliveryOptions(ThemeData theme, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5))
      ),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: _buildRadioOption(DeliveryType.pickup, "Retiro en Tienda", Icons.storefront, accentColor, theme)),
            Expanded(child: _buildRadioOption(DeliveryType.delivery, "Envío a Domicilio", Icons.local_shipping, accentColor, theme)),
          ]),
          
          // Campos visibles solo en Delivery con animación
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _deliveryType == DeliveryType.delivery ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity), 
            secondChild: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _addressController,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Dirección completa',
                      hintText: 'Calle, Altura, Piso, Ciudad',
                      prefixIcon: Icon(Icons.location_on_outlined, color: accentColor),
                      filled: true, 
                      fillColor: theme.scaffoldBackgroundColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (_) => setState((){}), 
                  ),
                  const SizedBox(height: 12),
                  // --- CAMPO DNI NUEVO ---
                  TextField(
                    controller: _dniController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'DNI / CUIT',
                      hintText: 'Requerido para el envío y facturación',
                      prefixIcon: Icon(Icons.badge_outlined, color: accentColor),
                      filled: true, 
                      fillColor: theme.scaffoldBackgroundColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (_) => setState((){}), 
                  ),
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
      child: Container(
        margin: const EdgeInsets.all(4), 
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.1) : Colors.transparent, 
          borderRadius: BorderRadius.circular(8), 
          border: Border.all(color: isSelected ? accentColor : theme.dividerColor.withValues(alpha: 0.3))
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? accentColor : theme.colorScheme.onSurface.withValues(alpha: 0.5)), 
            const SizedBox(height: 4), 
            Text(
              label, 
              style: TextStyle(
                color: isSelected ? accentColor : theme.colorScheme.onSurface, 
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, 
                fontSize: 12
              )
            )
          ]
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) => Padding(
    padding: const EdgeInsets.only(bottom: 12), 
    child: Text(
      title.toUpperCase(), 
      style: TextStyle(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7), 
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0
      )
    )
  );
  
  Widget _buildOrderSummary(ThemeData theme, Color accentColor, ColorScheme colorScheme) {
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
                 Flexible(
                   child: Text(
                     '${item.quantity}x ${item.product.name}', 
                     style: TextStyle(color: colorScheme.onSurface, fontSize: 16), 
                     overflow: TextOverflow.ellipsis
                   )
                 ), 
                 Text(
                   '\$${item.subtotal.toStringAsFixed(2)}', 
                   style: TextStyle(color: colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w500)
                 )
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

  Widget _buildPaymentMethodsList(ThemeData theme, Color accentColor) {
    return StreamBuilder<List<PaymentMethodModel>>(
      stream: _paymentService.getPaymentMethodsStream(_providerId!), 
      builder: (context, snapshot) { 
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator()); 
        if (snapshot.data!.isEmpty) return const Text("Este proveedor no tiene métodos de pago configurados.");
        
        return Column(
          children: snapshot.data!.map((m) => RadioListTile<PaymentMethodModel>(
            value: m, 
            groupValue: _selectedMethod, 
            onChanged: (v) => setState(() => _selectedMethod = v), 
            activeColor: accentColor, 
            title: Text(m.name, style: TextStyle(color: theme.colorScheme.onSurface)), 
            subtitle: Text(_getPaymentDetails(m), style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)))
          )).toList()
        ); 
      }
    );
  }

  Widget _buildPaymentProofUploader(Color surfaceColor, Color accentColor, ThemeData theme) {
     return GestureDetector(
       onTap: _pickPaymentProof, 
       child: Container(
         height: 150, 
         decoration: BoxDecoration(
           color: surfaceColor, 
           borderRadius: BorderRadius.circular(12), 
           border: Border.all(color: _paymentProofFile == null ? theme.dividerColor : accentColor, width: 2)
         ), 
         child: _paymentProofFile == null 
           ? Column(
               mainAxisAlignment: MainAxisAlignment.center, 
               children: [
                 Icon(Icons.upload_file, color: accentColor, size: 40), 
                 const SizedBox(height: 8),
                 Text('Toca para adjuntar foto', style: TextStyle(color: theme.colorScheme.onSurface))
               ]
             ) 
           : ClipRRect(
               borderRadius: BorderRadius.circular(10),
               child: Image.file(File(_paymentProofFile!.path), fit: BoxFit.cover, width: double.infinity)
             )
       )
     );
  }

  Widget _buildConfirmButton(Color accentColor, bool canConfirm, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), 
      color: theme.bottomNavigationBarTheme.backgroundColor, 
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: accentColor, 
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          // SOLUCIÓN ERROR DEPRECATED
          disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
        ), 
        onPressed: canConfirm ? _placeOrder : null, 
        child: _isLoading 
          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
          : const Text('CONFIRMAR PEDIDO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))
      )
    );
  }

  Future<void> _showOrderSuccessDialog(NavigatorState navigator) {
    return showDialog(
      context: navigator.context, 
      builder: (ctx) => AlertDialog(
        title: const Text('¡Pedido Enviado!'), 
        content: const Text('Tu pedido ha sido enviado al proveedor. Te notificaremos cuando lo acepte.'), 
        actions: [
          TextButton(
            child: const Text('Entendido'), 
            onPressed: () => navigator.pop()
          )
        ]
      )
    );
  }

  // --- BANNER DE REPUTACIÓN (RESTORED) ---
  Widget _buildReputationBanner(String providerId, ThemeData theme) {
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(providerId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          double rating = 0.0;
          int count = 0;

          if (data != null) {
             rating = (data['ratingAvg'] ?? 0.0).toDouble();
             count = (data['ratingCount'] ?? 0) as int;
          }

          if (count == 0) return const SizedBox();

          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // SOLUCIÓN ERROR DEPRECATED
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_user_outlined, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text("Proveedor Destacado: ", style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.9))),
                const Icon(Icons.star, color: Colors.amber, size: 16),
                Text(" $rating ($count)", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      );
  }
}