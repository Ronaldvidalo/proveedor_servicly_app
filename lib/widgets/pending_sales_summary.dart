import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:proveedor_servicly_app/core/models/order_model.dart';
import 'package:proveedor_servicly_app/core/services/order_service.dart';
import 'package:proveedor_servicly_app/features/profile/screens/all_orders_screen.dart';

// Definición de colores para consistencia
const _accentColor = Color(0xFF00BFFF); // Cyber Glow Accent
const _surfaceColor = Color(0xFF2D2D5A);
const _backgroundColor = Color(0xFF1A1A2E);

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
    // Asumo que OrderService está disponible en el Provider
    final orderService = context.read<OrderService>();

    return StreamBuilder<List<OrderModel>>(
      // Usamos el método 'getPendingOrders'
      stream: orderService.getPendingOrders(providerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Muestra un skeleton simple mientras carga
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          debugPrint('Error al cargar órdenes pendientes: ${snapshot.error}');
          return _buildErrorState();
        }

        final pendingOrders = snapshot.data ?? [];
        final count = pendingOrders.length;

        // --- El Widget Principal (Tarjeta de Resumen) ---
        return GestureDetector(
          onTap: () {
            // Navega a la pantalla de detalle de órdenes, abriendo en la pestaña "Pendientes"
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AllOrdersScreen(
                providerId: providerId,
                initialTabIndex: 0, 
              ),
            ));
          },
          child: _buildSummaryCard(context, count),
        );
      },
    );
  }

  // Widget para el estado de carga
  Widget _buildLoadingState() {
    return Container(
      height: 86, // Altura fija
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: LinearProgressIndicator(color: _accentColor)),
    );
  }

  // Widget para el estado de error
  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent, width: 1),
      ),
      child: const Center(
          child: Text(
        'Error al cargar órdenes',
        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
      )),
    );
  }

  // Widget principal de la tarjeta con el conteo de órdenes
  Widget _buildSummaryCard(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentColor.withAlpha(100), width: 1),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withAlpha(51),
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
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.pending_actions_rounded, color: _accentColor, size: 30),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count == 0
                      ? 'Todo al día'
                      : 'Accede para confirmar o rechazar',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Icono de flecha
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 18),
        ],
      ),
    );
  }
}