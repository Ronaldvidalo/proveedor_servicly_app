import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:proveedor_servicly_app/core/models/order_model.dart';
import 'package:proveedor_servicly_app/core/services/order_service.dart';
import 'package:proveedor_servicly_app/features/orders/screens/client_order_detail_screen.dart'; // Asegúrate de importar la pantalla de detalle CORRECTA

class ClientOrdersScreen extends StatelessWidget {
  const ClientOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const Scaffold(body: Center(child: Text("No autenticado")));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Mis Compras"),
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: "EN CURSO"),
              Tab(text: "HISTORIAL"),
            ],
          ),
        ),
        body: StreamBuilder<List<OrderModel>>(
          stream: context.read<OrderService>().getMyOrders(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState(theme);
            }

            final orders = snapshot.data!;

            // 1. FILTRADO: Agregamos 'inProgress' a las órdenes activas
            final activeOrders = orders.where((o) => 
              o.status == OrderStatus.pendingPayment || 
              o.status == OrderStatus.pendingVerification ||
              o.status == OrderStatus.inProgress // <--- ¡AQUÍ ESTABA EL PROBLEMA!
            ).toList();

            final historyOrders = orders.where((o) => 
              o.status == OrderStatus.completed || 
              o.status == OrderStatus.cancelled ||
              o.status == OrderStatus.disputed
            ).toList();

            return TabBarView(
              children: [
                _OrdersList(orders: activeOrders),
                _OrdersList(orders: historyOrders),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: theme.disabledColor),
          const SizedBox(height: 16),
          Text("Aún no tienes pedidos", style: theme.textTheme.titleLarge?.copyWith(color: theme.disabledColor)),
        ],
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final List<OrderModel> orders;
  const _OrdersList({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text("No hay órdenes en esta sección.", style: TextStyle(color: Colors.grey[500])),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (ctx, i) => _OrderTile(order: orders[i]),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final OrderModel order;
  const _OrderTile({required this.order});

  // 2. COLORES: Definimos color para el nuevo estado
  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pendingVerification: return Colors.orange;
      case OrderStatus.pendingPayment: return Colors.blue;
      case OrderStatus.inProgress: return Colors.indigoAccent; // <--- NUEVO COLOR
      case OrderStatus.completed: return Colors.green;
      case OrderStatus.cancelled: return Colors.red;
      case OrderStatus.disputed: return Colors.purple;
    }
  }

  // 3. TEXTO: Definimos etiqueta para el nuevo estado
  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pendingVerification: return "Verificando Pago";
      case OrderStatus.pendingPayment: return "Pago Pendiente";
      case OrderStatus.inProgress: return "En Camino"; // <--- NUEVA ETIQUETA
      case OrderStatus.completed: return "Completado";
      case OrderStatus.cancelled: return "Cancelado";
      case OrderStatus.disputed: return "En Disputa";
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getStatusColor(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navegar al detalle (asegúrate de usar ClientOrderDetailScreen)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ClientOrderDetailScreen(order: order)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: color.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      _getStatusText(order.status).toUpperCase(),
                      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    _formatDate(order.createdAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Imagen del primer producto (preview)
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      image: order.items.isNotEmpty && order.items[0]['imageUrl'] != null
                          ? DecorationImage(image: NetworkImage(order.items[0]['imageUrl']), fit: BoxFit.cover)
                          : null,
                    ),
                    child: order.items.isEmpty || order.items[0]['imageUrl'] == null 
                        ? const Icon(Icons.image_not_supported, size: 20, color: Colors.grey) 
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.items.isNotEmpty 
                              ? "${order.items[0]['name']} ${order.items.length > 1 ? '+ ${order.items.length - 1} más' : ''}"
                              : "Pedido sin items",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Total: \$${order.total.toStringAsFixed(2)}",
                          style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              
              // Indicador si falta calificar (Solo en Historial y Completado)
              if (order.status == OrderStatus.completed && !order.isRated) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(Icons.star_border, size: 16, color: Colors.amber[700]),
                    const SizedBox(width: 4),
                    Text(
                      "Pendiente de calificación",
                      style: TextStyle(color: Colors.amber[700], fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}