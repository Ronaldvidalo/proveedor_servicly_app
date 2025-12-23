import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:proveedor_servicly_app/core/models/order_model.dart';
import 'package:proveedor_servicly_app/core/services/order_service.dart';
import 'package:proveedor_servicly_app/features/manage_store/presentation/screens/order_detail_screen.dart';

class ProviderOrdersScreen extends StatelessWidget {
  const ProviderOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const Scaffold(body: Center(child: Text("Error de sesión")));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Gestión de Pedidos"),
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "POR APROBAR", icon: Icon(Icons.notifications_active_outlined)),
              Tab(text: "HISTORIAL", icon: Icon(Icons.history)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Pestaña 1: Pendientes (Urgente)
            _OrdersStreamList(
              stream: context.read<OrderService>().getPendingOrders(user.uid),
              emptyMessage: "No tienes pedidos pendientes 🚀",
              isPendingTab: true,
            ),
            
            // Pestaña 2: Historial (Completados)
            _OrdersStreamList(
              stream: context.read<OrderService>().getCompletedOrders(user.uid),
              emptyMessage: "Aún no tienes ventas completadas.",
              isPendingTab: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersStreamList extends StatelessWidget {
  final Stream<List<OrderModel>> stream;
  final String emptyMessage;
  final bool isPendingTab;

  const _OrdersStreamList({
    required this.stream,
    required this.emptyMessage,
    required this.isPendingTab,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPendingTab ? Icons.inbox : Icons.shopping_bag_outlined, 
                  size: 80, 
                  color: Colors.grey.withValues(alpha: 0.3)
                ),
                const SizedBox(height: 16),
                Text(emptyMessage, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final orders = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: orders.length,
          itemBuilder: (ctx, i) => _ProviderOrderTile(order: orders[i]),
        );
      },
    );
  }
}

class _ProviderOrderTile extends StatelessWidget {
  final OrderModel order;
  const _ProviderOrderTile({required this.order});

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    // Formato simple DD/MM HH:MM
    return "${date.day}/${date.month} ${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = order.status == OrderStatus.pendingVerification;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // Borde resaltado si es pendiente
        side: isPending 
            ? BorderSide(color: Colors.orange.withValues(alpha: 0.5), width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera: Estado y Fecha
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPending ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isPending ? "ACCIÓN REQUERIDA" : "COMPLETADA",
                      style: TextStyle(
                        color: isPending ? Colors.orange[800] : Colors.green[700],
                        fontSize: 10,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(order.createdAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Cuerpo: Cliente y Monto
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      order.clientName.isNotEmpty ? order.clientName[0].toUpperCase() : '?',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.clientName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${order.items.length} items • \$${order.total.toStringAsFixed(2)}",
                          style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              
              // Pie: Logística
              if (order.deliveryType == DeliveryType.delivery) ...[
                const Divider(height: 20),
                Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Envío: ${order.shippingAddress}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}