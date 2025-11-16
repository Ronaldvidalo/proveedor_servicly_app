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
    // Leer servicios del Provider
    // --- CORRECCIÓN 1 (Implícita): Asegurarse de usar el nombre correcto ---
    _paymentService = context.read<PaymentService>();
    _orderService = context.read<OrderService>();
    _authService = context.read<AuthService>();
    _storageService = context.read<StorageService>(); 

    // Obtener IDs
    _providerId = widget.cart.items.isNotEmpty 
        ? widget.cart.items.first.product.providerId 
        : null;
    _clientId = _authService.currentUser?.uid;
  }

  /// Lógica para seleccionar el comprobante
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

  /// Lógica para crear la orden
  Future<void> _placeOrder() async {
    // Validaciones
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
    
    // --- CORRECCIÓN LINT: '!' innecesario eliminado (Error 3) ---
    if (_clientId == null || _providerId == null || _providerId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se pudo identificar al cliente o proveedor.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    // --- CORRECCIÓN LINT (Error 6): Guardar BuildContext ---
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    // --- FIN CORRECCIÓN LINT ---

    try {
      final clientUser = _authService.currentUser;
      final clientName = clientUser?.displayName ?? clientUser?.email ?? 'Cliente Anónimo';
      final clientEmail = clientUser?.email ?? '';

      // 1. Subir el comprobante de pago
      // --- CORRECCIÓN LINT: '!' innecesario eliminado (Error 3) ---
      final String storagePath = 'orders/$_providerId/proof_${_clientId}_${Timestamp.now().millisecondsSinceEpoch}.jpg';
      final String paymentProofUrl = await _storageService.uploadFileWithProgress(
        File(_paymentProofFile!.path),
        storagePath,
        (progress) {},
      );

      // 2. Crear el modelo de la Orden
      final newOrder = OrderModel(
        id: '', // Firestore generará el ID
        clientId: _clientId!, // '!' es seguro aquí
        providerId: _providerId!, // '!' es seguro aquí
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

      // 3. Enviar a OrderService
      await _orderService.createOrder(newOrder);

      // 4. Limpiar carrito
      widget.cart.clearCart();

      // 5. Mostrar éxito y navegar
      // (Usamos las variables guardadas)
      if (mounted) { 
        await _showOrderSuccessDialog(navigator); // Pasamos el navigator
        navigator.popUntil((route) => route.isFirst);
      }

    } catch (e) {
      if (mounted) {
        // (Usamos la variable guardada)
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

  /// Devuelve los detalles del método de pago (Alias, CBU, etc.)
  String _getPaymentDetails(PaymentMethodModel method) {
    // Corrección para Null Safety
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
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);

    final bool canConfirm = _selectedMethod != null && _paymentProofFile != null && !_isLoading;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Confirmar Pedido'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- 1. Resumen de Compra ---
              _buildSectionTitle('Resumen de Compra'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
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
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            // --- CORRECCIÓN LINT: '!' innecesario eliminado (Error 4) ---
                            '\$${item.subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )),
                    const Divider(color: Colors.white24, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL',
                          style: TextStyle(color: accentColor, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\$${widget.cart.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(color: accentColor, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // --- 2. Métodos de Pago del Proveedor ---
              const SizedBox(height: 24),
              _buildSectionTitle('Seleccionar Método de Pago'),
              
              if (_providerId == null || _providerId!.isEmpty) 
                const Center(child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Error: No se pudo identificar al proveedor desde el carrito. Asegúrate de que los productos en la base de datos tengan un "providerId".', 
                    style: TextStyle(color: Colors.redAccent, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ))
              else
                // --- CORRECCIÓN 1 (Error 1): 'PaymentMethodService' -> 'PaymentService' ---
                StreamBuilder<List<PaymentMethodModel>>(
                  stream: _paymentService.getPaymentMethodsStream(_providerId!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: accentColor));
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('Error al cargar métodos de pago.', style: TextStyle(color: Colors.redAccent)));
                    }
                    final methods = snapshot.data ?? [];
                    if (methods.isEmpty) {
                      return const Center(child: Text('Este proveedor no ha configurado métodos de pago.', style: TextStyle(color: Colors.white70)));
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        // --- CORRECCIÓN 2 (Error 2): Argumentos corregidos ---
                        children: methods.map((method) {
                          return _buildPaymentMethodTile(method, accentColor);
                        }).toList(),
                      ),
                    );
                  },
                ),

              // --- 3. Widget para subir Comprobante ---
              if (_selectedMethod != null) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('Adjuntar Comprobante de Pago'),
                _buildPaymentProofUploader(surfaceColor, accentColor),
              ],

              const SizedBox(height: 100), // Espacio para el botón flotante
            ],
          ),
          // --- Overlay de Carga ---
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: accentColor),
              ),
            ),
        ],
      ),
      // --- 4. Botón de Confirmación Flotante (Actualizado) ---
      bottomNavigationBar: _buildConfirmButton(accentColor, canConfirm),
    );
  }

  /// Construye el título de una sección
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  /// Construye un RadioListTile para un método de pago
  @pragma("vm:prefer-inline")
  // --- CORRECCIÓN 2 (Error 2): Definición corregida a 2 argumentos ---
  Widget _buildPaymentMethodTile(PaymentMethodModel method, Color accentColor) {
    IconData icon;
    switch (method.type) {
      case PaymentMethodType.bank: icon = Icons.account_balance_outlined; break;
      case PaymentMethodType.wallet: icon = Icons.account_balance_wallet_outlined; break;
      case PaymentMethodType.crypto: icon = Icons.currency_bitcoin_outlined; break;
      case PaymentMethodType.other: icon = Icons.money_off; break;
    }
    
    // --- CORRECCIÓN LINT (Errores 7 y 8): Ignorar deprecaciones ---
    // ignore: deprecated_member_use
    return RadioListTile<PaymentMethodModel>(
      value: method,
      // ignore: deprecated_member_use
      groupValue: _selectedMethod,
      // ignore: deprecated_member_use
      onChanged: (value) {
        setState(() {
          _selectedMethod = value;
        });
      },
      activeColor: accentColor,
      title: Text(method.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(
        _getPaymentDetails(method), 
        style: const TextStyle(color: Colors.white70),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      secondary: Icon(icon, color: accentColor),
    );
  }

  // --- Widget para mostrar la imagen seleccionada ---
  Widget _buildPaymentProofUploader(Color surfaceColor, Color accentColor) {
    return GestureDetector(
      onTap: _pickPaymentProof,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _paymentProofFile == null ? Colors.white38 : accentColor,
            width: _paymentProofFile == null ? 1 : 2,
            style: _paymentProofFile == null ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child: _paymentProofFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file_outlined, color: accentColor, size: 40),
                  const SizedBox(height: 8),
                  const Text('Tocar para adjuntar imagen', style: TextStyle(color: Colors.white70)),
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
                      // --- CORRECCIÓN LINT: '!' innecesario eliminado (Error 5) ---
                      color: Colors.black.withOpacity(0.4),
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

  /// Construye el botón de confirmación en la barra inferior
  Widget _buildConfirmButton(Color accentColor, bool canConfirm) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      color: const Color(0xFF2D2D5A),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            // El botón se desactiva
            disabledBackgroundColor: Colors.grey.withAlpha(128),
            disabledForegroundColor: Colors.white.withAlpha(180),
          ),
          onPressed: canConfirm ? _placeOrder : null,
          child: _isLoading 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
              : const Text('Confirmar Pedido'),
        ),
      ),
    );
  }

  /// Muestra un diálogo de éxito
  // --- CORRECCIÓN LINT (Error 6): Aceptar el Navigator ---
  Future<void> _showOrderSuccessDialog(NavigatorState navigator) {
    return showDialog(
      context: navigator.context, // Usar el contexto del navigator
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D5A),
        title: const Text('¡Pedido Enviado!', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Tu pedido ha sido enviado al proveedor. Recibirás una notificación cuando sea aceptado.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('Genial', style: TextStyle(color: Color(0xFF00BFFF))),
            onPressed: () => navigator.pop(), // Usar el navigator para cerrar
          ),
        ],
      ),
    );
  }
}