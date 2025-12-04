import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:proveedor_servicly_app/core/models/order_model.dart';
import 'package:proveedor_servicly_app/core/services/order_service.dart';
// IMPORTANTE: Ajusta esta ruta a donde realmente guardaste AllOrdersScreen
import 'package:proveedor_servicly_app/features/orders/screens/all_orders_screen.dart';

/// Un widget reutilizable que muestra un resumen de las ventas pendientes
/// del proveedor y sirve como acceso directo a la pantalla de órdenes.
class PendingSalesSummary extends StatelessWidget {
  final String providerId;

  const PendingSalesSummary({
    super.key,
    required this.providerId,
  });

  @override
  Widget build(BuildContext context) {
    final orderService = context.read<OrderService>();
    // --- TEMATIZACIÓN ---
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return StreamBuilder<List<OrderModel>>(
      stream: orderService.getPendingOrders(providerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState(colors);
        }

        if (snapshot.hasError) {
          debugPrint('Error al cargar órdenes pendientes: ${snapshot.error}');
          return _buildErrorState(colors);
        }

        final pendingOrders = snapshot.data ?? [];
        final count = pendingOrders.length;

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AllOrdersScreen(
                providerId: providerId,
                initialTabIndex: 0, 
              ),
            ));
          },
          child: _buildSummaryCard(context, count, colors),
        );
      },
    );
  }

  // Widget para el estado de carga
  Widget _buildLoadingState(ColorScheme colors) {
    return Container(
      height: 86,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(child: LinearProgressIndicator(color: colors.primary)),
    );
  }

  // Widget para el estado de error
  Widget _buildErrorState(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.error, width: 1),
      ),
      child: Center(
          child: Text(
        'Error al cargar órdenes',
        style: TextStyle(color: colors.error, fontWeight: FontWeight.bold),
      )),
    );
  }

  // Widget principal de la tarjeta con el conteo de órdenes
  Widget _buildSummaryCard(BuildContext context, int count, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withAlpha(100), width: 1),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withAlpha(51),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surface, // Fondo del icono
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.pending_actions_rounded, color: colors.primary, size: 30),
          ),

          const SizedBox(width: 16),

          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == 0
                      ? 'No hay ventas pendientes'
                      : '¡Tienes $count ${count == 1 ? 'venta' : 'ventas'} nuevas!',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count == 0
                      ? 'Todo al día'
                      : 'Accede para confirmar o rechazar',
                  style: TextStyle(
                    color: colors.onSurface.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Icono de flecha
          Icon(Icons.arrow_forward_ios_rounded, color: colors.onSurface.withOpacity(0.5), size: 18),
        ],
      ),
    );
  }
}