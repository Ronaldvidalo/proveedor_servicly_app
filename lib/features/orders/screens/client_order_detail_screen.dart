import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proveedor_servicly_app/core/models/order_model.dart';
import 'package:proveedor_servicly_app/core/models/payment_method_model.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/services/payment_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Necesario para DocumentSnapshot

/// Pantalla de "solo lectura" donde el CLIENTE ve el detalle
/// completo de una orden que realizó.
class ClientOrderDetailScreen extends StatelessWidget {
  final OrderModel order;

  const ClientOrderDetailScreen({super.key, required this.order});

  /// Muestra la imagen en un diálogo de pantalla completa
  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.of(ctx).pop(),
          child: InteractiveViewer( // Permite hacer zoom y pan
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);
    // Nota: Es mejor usar Provider.of<PaymentService>(context, listen: false) 
    // o context.read<PaymentService>() si estás en el método build.
    final paymentService = context.read<PaymentService>();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Detalle de la Orden'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- 1. Tarjeta de Estado de la Orden ---
          _buildSectionCard(
            context: context,
            surfaceColor: surfaceColor,
            title: 'Estado de la Orden',
            children: [
              _StatusBadge(status: order.status), // El mismo badge de la lista
              const SizedBox(height: 12),
              Text(
                _getStatusDescription(order.status),
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 16),
              if (order.status == OrderStatus.pending_payment && order.clientNotes == null)
                Text(
                  // Mensaje de ayuda si falta el pago y el cliente está mirando
                  'Fecha de Creación: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt.toDate())}',
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              if (order.clientNotes != null && order.clientNotes!.isNotEmpty)
                _buildDetailRow('Notas del Cliente:', order.clientNotes!),
            ],
          ),

          const SizedBox(height: 24),

          // --- 2. Tarjeta de Resumen de la Orden ---
          _buildSectionCard(
            context: context,
            surfaceColor: surfaceColor,
            title: 'Resumen de la Compra',
            children: [
              _buildDetailRow('Proveedor ID:', order.providerId, truncate: true),
              _buildDetailRow('Orden ID:', order.id, truncate: true),
              _buildDetailRow('Total Pagado:', '\$${order.total.toStringAsFixed(2)}', isTotal: true),
              const Divider(color: Colors.white24, height: 24),
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item['quantity']}x ${item['name']}',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    Text(
                      '\$${(item['price'] as num).toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              )),
            ],
          ),

          const SizedBox(height: 24),

          // --- 3. Tarjeta del Comprobante de Pago Subido (Solo si hay URL) ---
          if (order.paymentProofUrl.isNotEmpty)
            _buildSectionCard(
              context: context,
              surfaceColor: surfaceColor,
              title: 'Comprobante Enviado',
              children: [
                GestureDetector(
                  onTap: () => _showFullImage(context, order.paymentProofUrl),
                  child: Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        order.paymentProofUrl,
                        fit: BoxFit.cover, // Cambiado a cover para mejor visualización
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator(color: accentColor));
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                                SizedBox(height: 8),
                                Text('No se pudo cargar el comprobante', style: TextStyle(color: Colors.redAccent)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Toca la imagen para verla en pantalla completa.', 
                  style: TextStyle(color: Colors.white60, fontStyle: FontStyle.italic, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          
          if (order.paymentProofUrl.isNotEmpty)
            const SizedBox(height: 24),
          
          // --- 4. Tarjeta de Método de Pago Usado ---
          _buildSectionCard(
            context: context,
            surfaceColor: surfaceColor,
            title: 'Método de Pago Utilizado',
            children: [
              // Usamos un FutureBuilder para obtener los detalles
              // del método de pago que el proveedor podría haber borrado.
              FutureBuilder<DocumentSnapshot>(
                future: paymentService.getPaymentMethodDoc(order.providerId, order.paymentMethodId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: accentColor));
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text(
                      'El proveedor ha eliminado este método de pago.',
                      style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                    );
                  }
                  
                  // Se asume que PaymentMethodModel.fromFirestore recibe DocumentSnapshot
                  final method = PaymentMethodModel.fromFirestore(snapshot.data!);
                  return _buildDetailRow(method.name, _getPaymentDetails(method));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Devuelve el texto de descripción para un estado
  String _getStatusDescription(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending_payment: // <-- CORREGIDO: Nuevo estado
        return 'Debes subir el comprobante de pago para que el proveedor pueda iniciar la verificación.';
      case OrderStatus.pending_verification:
        return 'El proveedor está revisando tu comprobante de pago. Recibirás una notificación cuando sea aprobado.';
      case OrderStatus.completed:
        return '¡Pago aprobado! Tu orden está completa.';
      case OrderStatus.cancelled:
        return 'Esta orden fue cancelada por el proveedor. Contacta al proveedor para más detalles.';
      case OrderStatus.disputed: // CORREGIDO: Manejo explícito del estado Dispute
        return 'Existe una disputa sobre esta orden. Por favor, contacta a soporte.';
      default:
        return 'El estado de esta orden es desconocido.';
    }
  }

  /// Devuelve los detalles del método de pago
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

  // --- Widgets Auxiliares (Copiados de OrderDetailScreen) ---
  Widget _buildSectionCard({
    required BuildContext context,
    required Color surfaceColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false, bool truncate = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              truncate && value.length > 10 ? '${value.substring(0, 6)}...' : value, // Mejor manejo de truncate
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isTotal ? const Color(0xFF00BFFF) : Colors.white,
                fontSize: isTotal ? 18 : 16,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET PARA EL BADGE DE ESTADO (Copiado de my_orders_screen.dart) ---
class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;
    IconData icon;

    switch (status) {
      case OrderStatus.pending_payment: // <-- CORREGIDO: Nuevo estado
        text = 'Falta Pago';
        color = const Color(0xFF00BFFF); // Azul para falta de pago
        icon = Icons.payment_rounded;
        break;
      case OrderStatus.pending_verification:
        text = 'Pendiente';
        color = Colors.orangeAccent;
        icon = Icons.hourglass_top_rounded;
        break;
      case OrderStatus.completed:
        text = 'Completado';
        color = Colors.greenAccent;
        icon = Icons.check_circle_rounded;
        break;
      case OrderStatus.cancelled:
        text = 'Cancelado';
        color = Colors.redAccent;
        icon = Icons.cancel_rounded;
        break;
      case OrderStatus.disputed: // CORREGIDO: Manejo explícito del estado Dispute
        text = 'Disputa';
        color = Colors.yellow;
        icon = Icons.warning_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 0.5)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Para que el Row ocupe solo el espacio necesario
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}