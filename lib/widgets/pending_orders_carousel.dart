import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/order_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/order_service.dart';
import 'package:proveedor_servicly_app/features/manage_store/presentation/screens/order_detail_screen.dart';

/// Un widget de carrusel horizontal reutilizable que muestra
/// las órdenes pendientes de verificación de un proveedor.
class PendingOrdersCarousel extends StatelessWidget {
  final UserModel user;
  const PendingOrdersCarousel({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final orderService = context.read<OrderService>();
    const accentColor = Color(0xFF00BFFF);

    return StreamBuilder<List<OrderModel>>(
      stream: orderService.getPendingOrders(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Muestra un loader que coincide con la altura del widget
          return const SizedBox(
            height: 100,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: CircularProgressIndicator(color: accentColor),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return SizedBox(
            height: 100,
            child: Center(
              child: Text('Error al cargar órdenes',
                  style: const TextStyle(color: Colors.redAccent)),
            ),
          );
        }
        
        final pendingOrders = snapshot.data ?? [];

        // --- ¡LÓGICA DE UX CORREGIDA! ---
        // Si no hay órdenes, mostramos la tarjeta de estado "cero".
        if (pendingOrders.isEmpty) {
          return const _EmptyOrdersCard();
        }
        // --- FIN DE LA CORRECCIÓN ---

        // Si hay órdenes, mostramos el carrusel
        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: pendingOrders.length,
            itemBuilder: (context, index) {
              final order = pendingOrders[index];
              // Usamos el widget de tarjeta de orden que estaba en la pantalla principal
              return _OrderCard(order: order);
            },
          ),
        );
      },
    );
  }
}

/// --- WIDGET AUXILIAR (Movido de manage_store_screen.dart) ---
/// Tarjeta individual para una orden pendiente.
class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 12.0),
      decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withAlpha(100))),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => OrderDetailScreen(order: order),
            ));
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        color: accentColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Venta Pendiente',
                      style: TextStyle(
                          color: accentColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  order.items.isNotEmpty
                      ? order.items.first['name']
                      : 'Orden Desconocida',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Cliente: ${order.clientName} - \$${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// --- ¡NUEVO WIDGET AUXILIAR PARA ESTADO "CERO"! ---
class _EmptyOrdersCard extends StatelessWidget {
  const _EmptyOrdersCard();

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Color(0xFF2D2D5A);
    
    return Container(
      height: 100,
      width: double.infinity, // Ocupa todo el ancho
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(0.5), // Más sutil
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12), // Borde tenue
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, color: Colors.greenAccent.shade100, size: 28),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Todo al día!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold
                ),
              ),
              Text(
                'No tienes ventas pendientes por verificar.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}