import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/order_model.dart';
import 'package:proveedor_servicly_app/core/services/order_service.dart';

/// Esta es la pantalla donde el proveedor verá los detalles de la orden,
/// verá el comprobante de pago subido por el cliente,
/// y aprobará o rechazará la orden.
class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isLoading = false;

  /// Función para manejar la actualización de estado (Aprobar o Rechazar)
  Future<void> _updateOrderStatus(OrderStatus newStatus) async {
    if (_isLoading) return; // Evitar doble-tap

    setState(() => _isLoading = true);

    final orderService = context.read<OrderService>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      // 1. Llama al servicio para actualizar Firestore
      await orderService.updateOrderStatus(widget.order.id, newStatus);

      // 2. Muestra un mensaje de éxito
      final successMessage = newStatus == OrderStatus.completed
          ? '¡Venta aprobada con éxito!'
          : 'La orden ha sido rechazada.';
      
      messenger.showSnackBar(SnackBar(
        content: Text(successMessage),
        backgroundColor: Colors.green,
      ));

      // 3. Regresa a la pantalla anterior
      navigator.pop();

    } catch (e) {
      // 4. Muestra un error si algo falla
      messenger.showSnackBar(SnackBar(
        content: Text('Error al actualizar la orden: $e'),
        backgroundColor: Colors.redAccent,
      ));
    } finally {
      // 5. Vuelve a habilitar los botones
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Verificar Orden #${widget.order.id.substring(0, 6)}...'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Tarjeta de Resumen de la Orden ---
          _buildSectionCard(
            context: context,
            surfaceColor: surfaceColor,
            title: 'Resumen de la Orden',
            children: [
              _buildDetailRow('Cliente:', widget.order.clientName),
              _buildDetailRow('Email:', widget.order.clientEmail),
              _buildDetailRow('Total Pagado:', '\$${widget.order.total.toStringAsFixed(2)}', isTotal: true),
              const Divider(color: Colors.white24, height: 24),
              // Lista de ítems comprados
              ...widget.order.items.map((item) => Padding(
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
              )).toList(),
            ],
          ),

          const SizedBox(height: 24),

          // --- Tarjeta del Comprobante de Pago ---
          _buildSectionCard(
            context: context,
            surfaceColor: surfaceColor,
            title: 'Comprobante de Pago',
            children: [
              Container(
                height: 400, // Altura fija para la imagen
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.order.paymentProofUrl,
                    fit: BoxFit.contain, // contain para verla completa
                    // Loader mientras carga la imagen
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: accentColor),
                      );
                    },
                    // Error si la imagen no carga
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
            ],
          ),

          const SizedBox(height: 32),

          // --- Botones de Acción ---
          Row(
            children: [
              // Botón de Rechazar
              Expanded(
                child: FilledButton(
                  onPressed: _isLoading ? null : () => _updateOrderStatus(OrderStatus.cancelled),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading 
                      ? const SizedBox.shrink() // Se oculta si está cargando
                      : const Text('Rechazar Pago'),
                ),
              ),
              const SizedBox(width: 16),
              // Botón de Aprobar
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _isLoading ? null : () => _updateOrderStatus(OrderStatus.completed),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green, // Verde para "Aprobar"
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                      : const Text('Aprobar Pago', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Widgets Auxiliares ---

  /// Un widget reutilizable para las tarjetas de sección
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

  /// Un widget reutilizable para las filas de detalle
  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? const Color(0xFF00BFFF) : Colors.white,
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}