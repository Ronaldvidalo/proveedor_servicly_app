import 'dart:io'; // Para File
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; // Para ImagePicker
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proveedor_servicly_app/core/models/order_model.dart';
import 'package:proveedor_servicly_app/core/models/payment_method_model.dart';
import 'package:proveedor_servicly_app/core/services/auth_service.dart';
import 'package:proveedor_servicly_app/core/services/order_service.dart';
import 'package:proveedor_servicly_app/core/services/payment_service.dart';
import 'package:proveedor_servicly_app/core/services/storage_service.dart'; // Para Storage
import 'package:proveedor_servicly_app/core/viewmodels/cart_provider.dart';

/// Pantalla donde el cliente selecciona el método de pago del proveedor
/// y confirma la orden.
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

  // IDs
  late final String? _providerId;
  late final String? _clientId;
  
  // Estado
  PaymentMethodModel? _selectedMethod;
  bool _isLoading = false;
  XFile? _paymentProofFile; 
  final ImagePicker _picker = ImagePicker(); 

  @override
  void initState() {
    super.initState();
    _paymentService = context.read<PaymentService>();
    _orderService = context.read<OrderService>();
    _authService = context.read<AuthService>();
    _storageService = context.read<StorageService>(); 

    _providerId = widget.cart.items.isNotEmpty 
        ? widget.cart.items.first.product.providerId 
        : null;
    _clientId = _authService.currentUser?.uid;
  }

  Future<void> _pickPaymentProof() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        setState(() {
          _paymentProofFile = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona un método de pago.'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    if (_paymentProofFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, adjunta el comprobante de pago.'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    
    if (_clientId == null || _providerId == null || _providerId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se pudo identificar al cliente o proveedor.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final clientUser = _authService.currentUser;
      final clientName = clientUser?.displayName ?? clientUser?.email ?? 'Cliente Anónimo';
      final clientEmail = clientUser?.email ?? '';

      final String storagePath = 'orders/$_providerId/proof_${_clientId}_${Timestamp.now().millisecondsSinceEpoch}.jpg';
      final String paymentProofUrl = await _storageService.uploadFileWithProgress(
        File(_paymentProofFile!.path),
        storagePath,
        (progress) {},
      );

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
      );

      await _orderService.createOrder(newOrder);
      widget.cart.clearCart();

      if (mounted) { 
        await _showOrderSuccessDialog(navigator); 
        navigator.popUntil((route) => route.isFirst);
      }

    } catch (e) {
      if (mounted) {
        messenger.showSnackBar( 
          SnackBar(content: Text('Error al crear la orden: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getPaymentDetails(PaymentMethodModel method) {
    final alias = method.alias;
    if (alias != null && alias.isNotEmpty) return "Alias: $alias";

    final cbu = method.cbu;
    if (cbu != null && cbu.isNotEmpty) return "CBU: $cbu";

    final cryptoAddress = method.cryptoAddress;
    if (cryptoAddress != null && cryptoAddress.isNotEmpty) return "Dirección: $cryptoAddress";

    final otherDetails = method.otherDetails;
    if (otherDetails != null && otherDetails.isNotEmpty) return otherDetails;
    
    return "Detalles no especificados";
  }

  @override
  Widget build(BuildContext context) {
    // QA FIX: Obtener tema del contexto
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = colorScheme.primary;

    final bool canConfirm = _selectedMethod != null && _paymentProofFile != null && !_isLoading;

    return Scaffold(
      // Fondo dinámico
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Confirmar Pedido'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- 1. Resumen de Compra ---
              _buildSectionTitle('Resumen de Compra', theme),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // Fondo tarjeta dinámico
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
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
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '\$${item.subtotal.toStringAsFixed(2)}',
                            style: TextStyle(color: colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )),
                    Divider(color: theme.dividerColor, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL',
                          style: TextStyle(color: accentColor, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\$${widget.cart.totalPrice.toStringAsFixed(2)}',
                          style: TextStyle(color: accentColor, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // --- 2. Métodos de Pago del Proveedor ---
              const SizedBox(height: 24),
              _buildSectionTitle('Seleccionar Método de Pago', theme),
              
              if (_providerId == null || _providerId!.isEmpty) 
                const Center(child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Error: No se pudo identificar al proveedor desde el carrito.', 
                    style: TextStyle(color: Colors.redAccent, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ))
              else
                StreamBuilder<List<PaymentMethodModel>>(
                  stream: _paymentService.getPaymentMethodsStream(_providerId!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: accentColor));
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('Error al cargar métodos de pago.', style: TextStyle(color: Colors.redAccent)));
                    }
                    final methods = snapshot.data ?? [];
                    if (methods.isEmpty) {
                      return Center(child: Text('Este proveedor no ha configurado métodos de pago.', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7))));
                    }

                    return Container(
                      decoration: BoxDecoration(
                        // QA FIX: Fondo tarjeta dinámico
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        children: methods.map((method) {
                          return _buildPaymentMethodTile(method, accentColor, theme);
                        }).toList(),
                      ),
                    );
                  },
                ),

              // --- 3. Widget para subir Comprobante ---
              if (_selectedMethod != null) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('Adjuntar Comprobante de Pago', theme),
                _buildPaymentProofUploader(theme.cardTheme.color!, accentColor, theme),
              ],

              const SizedBox(height: 100), 
            ],
          ),
          // --- Overlay de Carga ---
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(color: accentColor),
              ),
            ),
        ],
      ),
      // --- 4. Botón de Confirmación Flotante (Actualizado) ---
      bottomNavigationBar: _buildConfirmButton(accentColor, canConfirm, theme),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          // Texto secundario adaptable
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethodModel method, Color accentColor, ThemeData theme) {
    IconData icon;
    switch (method.type) {
      case PaymentMethodType.bank: icon = Icons.account_balance_outlined; break;
      case PaymentMethodType.wallet: icon = Icons.account_balance_wallet_outlined; break;
      case PaymentMethodType.crypto: icon = Icons.currency_bitcoin_outlined; break;
      case PaymentMethodType.other: icon = Icons.money_off; break;
    }
    
    return RadioListTile<PaymentMethodModel>(
      value: method,
      groupValue: _selectedMethod,
      onChanged: (value) {
        setState(() {
          _selectedMethod = value;
        });
      },
      activeColor: accentColor,
      title: Text(method.name, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
      subtitle: Text(
        _getPaymentDetails(method), 
        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      secondary: Icon(icon, color: accentColor),
    );
  }

  Widget _buildPaymentProofUploader(Color surfaceColor, Color accentColor, ThemeData theme) {
    return GestureDetector(
      onTap: _pickPaymentProof,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _paymentProofFile == null ? theme.dividerColor : accentColor,
            width: _paymentProofFile == null ? 1 : 2,
          ),
        ),
        child: _paymentProofFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file_outlined, color: accentColor, size: 40),
                  const SizedBox(height: 8),
                  Text('Tocar para adjuntar imagen', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.file(
                      File(_paymentProofFile!.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Velo oscuro para legibilidad
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 40),
                        SizedBox(height: 8),
                        Text('Imagen cargada', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Toca para cambiar', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildConfirmButton(Color accentColor, bool canConfirm, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      // QA FIX: Color de fondo de barra inferior
      color: theme.bottomNavigationBarTheme.backgroundColor,
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: accentColor,
            // QA FIX: Texto botón siempre legible
            foregroundColor: theme.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
          ),
          onPressed: canConfirm ? _placeOrder : null,
          child: _isLoading 
              ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: theme.colorScheme.onPrimary, strokeWidth: 3))
              : const Text('Confirmar Pedido'),
        ),
      ),
    );
  }

  Future<void> _showOrderSuccessDialog(NavigatorState navigator) {
    // QA FIX: Obtener tema desde el contexto del navigator
    final theme = Theme.of(navigator.context);
    
    return showDialog(
      context: navigator.context, 
      builder: (ctx) => AlertDialog(
        // QA FIX: Fondo alerta dinámico
        backgroundColor: theme.cardTheme.color,
        title: Text('¡Pedido Enviado!', style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text(
          'Tu pedido ha sido enviado al proveedor. Recibirás una notificación cuando sea aceptado.',
          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            child: Text('Genial', style: TextStyle(color: theme.primaryColor)),
            onPressed: () => navigator.pop(), 
          ),
        ],
      ),
    );
  }
}