import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proveedor_servicly_app/core/models/order_model.dart';
import 'package:proveedor_servicly_app/core/models/payment_method_model.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/services/payment_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:proveedor_servicly_app/features/orders/screens/rate_provider_screen.dart';

// Import del sistema de Reviews
import 'package:proveedor_servicly_app/features/reviews/index.dart';

class ClientOrderDetailScreen extends StatelessWidget {
  final OrderModel order;

  const ClientOrderDetailScreen({super.key, required this.order});

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.of(ctx).pop(),
          child: InteractiveViewer(
            child: Image.network(imageUrl, fit: BoxFit.contain),
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
    
    final paymentService = context.read<PaymentService>();
    final isCompleted = order.status == OrderStatus.completed;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Detalle de la Orden'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          
          // --- 1. BOTÓN DE CALIFICAR (Solo si completado) ---
          if (isCompleted) 
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF00E5FF).withOpacity(0.2), const Color(0xFF39FF14).withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.star_rate_rounded, color: Color(0xFF00E5FF), size: 32),
                  ),
                  title: const Text("¡Trabajo Terminado!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: const Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Text("¿Qué te pareció el servicio? Tu opinión ayuda a otros.", style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
                  trailing: ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF00E5FF), 
    foregroundColor: Colors.black
  ),
  
  // --- REEMPLAZA EL ONPRESSED POR ESTO: ---
  onPressed: () async {
    // Importante: Asegúrate de importar rate_provider_screen.dart arriba
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RateProviderScreen(order: order),
      ),
    );

    // Si calificó exitosamente (devuelve true), podemos mostrar confirmación
    if (result == true) {
      // Opcional: Aquí podrías forzar una recarga si fuera necesario, 
      // pero StreamBuilder suele encargarse de actualizar la UI automáticamente.
    }
  },
  
  child: const Text("CALIFICAR", style: TextStyle(fontWeight: FontWeight.bold)),
),
                ),
              ),
            ),

          // --- 2. Estado de la Orden ---
          _buildSectionCard(
            context: context,
            surfaceColor: surfaceColor,
            title: 'Estado de la Orden',
            children: [
              _StatusBadge(status: order.status),
              const SizedBox(height: 12),
              Text(_getStatusDescription(order.status), style: const TextStyle(color: Colors.white70, fontSize: 15)),
              const SizedBox(height: 16),
              if (order.status == OrderStatus.pending_payment)
                Text('Creado el: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt.toDate())}', style: const TextStyle(color: Colors.white54, fontSize: 14)),
            ],
          ),

          const SizedBox(height: 24),

          // ---------------------------------------------------------
          // 🚚 3. NUEVA SECCIÓN: DATOS DE ENTREGA (Logística)
          // ---------------------------------------------------------
          _buildSectionCard(
            context: context,
            surfaceColor: surfaceColor,
            title: 'Método de Entrega',
            children: [
              Row(
                children: [
                  Icon(
                    order.deliveryType == DeliveryType.delivery ? Icons.local_shipping : Icons.storefront,
                    color: accentColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    order.deliveryType == DeliveryType.delivery ? "Envío a Domicilio" : "Retiro en Tienda",
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              if (order.deliveryType == DeliveryType.delivery && order.shippingAddress.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                const Text("Dirección de Envío:", style: TextStyle(color: Colors.white54, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  order.shippingAddress,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          // ---------------------------------------------------------

          // --- 4. Resumen de Compra ---
          _buildSectionCard(
            context: context,
            surfaceColor: surfaceColor,
            title: 'Resumen de la Compra',
            children: [
              _buildDetailRow('Orden ID:', order.id, truncate: true),
              _buildDetailRow('Total:', '\$${order.total.toStringAsFixed(2)}', isTotal: true),
              const Divider(color: Colors.white24, height: 24),
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${item['quantity']}x ${item['name']}', style: const TextStyle(color: Colors.white, fontSize: 16))),
                    Text('\$${(item['price'] as num).toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              )),
            ],
          ),

          const SizedBox(height: 24),

          // --- 5. Comprobante ---
          if (order.paymentProofUrl.isNotEmpty)
            _buildSectionCard(
              context: context,
              surfaceColor: surfaceColor,
              title: 'Comprobante Enviado',
              children: [
                GestureDetector(
                  onTap: () => _showFullImage(context, order.paymentProofUrl),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        order.paymentProofUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (c, child, l) => l == null ? child : const Center(child: CircularProgressIndicator()),
                        errorBuilder: (c, e, s) => const Center(child: Icon(Icons.broken_image, color: Colors.white54)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
          const SizedBox(height: 24),

          // --- 6. Método de Pago ---
          _buildSectionCard(
            context: context,
            surfaceColor: surfaceColor,
            title: 'Pago',
            children: [
              FutureBuilder<DocumentSnapshot>(
                future: paymentService.getPaymentMethodDoc(order.providerId, order.paymentMethodId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  if (!snapshot.data!.exists) return const Text('Método no disponible', style: TextStyle(color: Colors.white54));
                  final method = PaymentMethodModel.fromFirestore(snapshot.data!);
                  return _buildDetailRow(method.name, _getPaymentDetails(method));
                },
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- Helpers ---
  String _getStatusDescription(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending_payment: return 'Esperando confirmación de pago.';
      case OrderStatus.pending_verification: return 'El proveedor está verificando tu pago.';
      case OrderStatus.completed: return '¡Orden completada y entregada!';
      case OrderStatus.cancelled: return 'Orden cancelada.';
      case OrderStatus.disputed: return 'Orden en disputa.';
      default: return '';
    }
  }

  String _getPaymentDetails(PaymentMethodModel method) {
    if (method.alias != null && method.alias!.isNotEmpty) return "Alias: ${method.alias}";
    if (method.cbu != null && method.cbu!.isNotEmpty) return "CBU: ${method.cbu}";
    return "Ver detalles";
  }

  Widget _buildSectionCard({required BuildContext context, required Color surfaceColor, required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
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
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              truncate && value.length > 15 ? '${value.substring(0, 15)}...' : value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isTotal ? const Color(0xFF00BFFF) : Colors.white,
                fontSize: isTotal ? 18 : 16,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    String text; Color color; IconData icon;
    switch (status) {
      case OrderStatus.pending_payment: text = 'Pago Pendiente'; color = Colors.blue; icon = Icons.payment; break;
      case OrderStatus.pending_verification: text = 'Verificando'; color = Colors.orange; icon = Icons.hourglass_top; break;
      case OrderStatus.completed: text = 'Completado'; color = Colors.green; icon = Icons.check_circle; break;
      case OrderStatus.cancelled: text = 'Cancelado'; color = Colors.red; icon = Icons.cancel; break;
      default: text = 'Desconocido'; color = Colors.grey; icon = Icons.help;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: color)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, color: color, size: 14), const SizedBox(width: 6), Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold))],
      ),
    );
  }
}