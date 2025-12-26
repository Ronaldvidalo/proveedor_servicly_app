import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 

import 'package:proveedor_servicly_app/core/models/order_model.dart';
import 'package:proveedor_servicly_app/core/services/order_service.dart';
import 'package:proveedor_servicly_app/features/orders/screens/client_order_detail_screen.dart'; 

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

            final activeOrders = orders.where((o) => 
              o.status == OrderStatus.pendingPayment || 
              o.status == OrderStatus.pendingVerification ||
              o.status == OrderStatus.inProgress
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

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pendingVerification: return Colors.orange;
      case OrderStatus.pendingPayment: return Colors.blue;
      case OrderStatus.inProgress: return Colors.indigoAccent;
      case OrderStatus.completed: return Colors.green;
      case OrderStatus.cancelled: return Colors.red;
      case OrderStatus.disputed: return Colors.purple;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pendingVerification: return "Verificando Pago";
      case OrderStatus.pendingPayment: return "Pago Pendiente";
      case OrderStatus.inProgress: return "En Camino";
      case OrderStatus.completed: return "Completado";
      case OrderStatus.cancelled: return "Cancelado";
      case OrderStatus.disputed: return "En Disputa";
    }
  }

  String _formatDate(Timestamp timestamp) {
    return DateFormat('dd/MM/yyyy').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getStatusColor(order.status);
    
    // Lógica de Imagen
    final hasItems = order.items.isNotEmpty;
    final String? productImageUrl = (hasItems && order.items[0]['imageUrl'] is String && order.items[0]['imageUrl'].toString().isNotEmpty) 
        ? order.items[0]['imageUrl'] 
        : null;
    final bool hasProductImage = productImageUrl != null;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('brandProfiles').doc(order.providerId).get(),
      builder: (context, snapshot) {
        
        String storeName = "Cargando...";
        String? storeLogoUrl;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          storeName = data['businessName'] ?? data['brandName'] ?? data['name'] ?? "Tienda";
          storeLogoUrl = data['logoUrl'] ?? data['profileImage'];
        } else if (snapshot.connectionState == ConnectionState.done) {
           storeName = "Tienda";
        }

        ImageProvider? displayImage;
        if (hasProductImage) {
          displayImage = NetworkImage(productImageUrl!);
        } else if (storeLogoUrl != null && storeLogoUrl.isNotEmpty) {
          displayImage = NetworkImage(storeLogoUrl);
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ClientOrderDetailScreen(order: order)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  // CABECERA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          _getStatusText(order.status).toUpperCase(),
                          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        _formatDate(order.createdAt),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  
                  // CONTENIDO PRINCIPAL
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- FOTO / LOGO (Full Cover) ---
                      Container(
                        width: 75,
                        height: 75,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                          image: displayImage != null
                              ? DecorationImage(
                                  image: displayImage,
                                  fit: BoxFit.cover, // Llena todo el espacio
                                )
                              : null,
                        ),
                        child: displayImage == null
                            ? Center(
                                child: Icon(
                                  Icons.storefront_rounded,
                                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                                  size: 35,
                                ),
                              )
                            : null,
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // --- DETALLES ---
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. NOMBRE DE LA TIENDA (Destacado y Claro)
                            Row(
                              children: [
                                Icon(Icons.store_mall_directory_rounded, size: 18, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    storeName,
                                    style: TextStyle(
                                      // CAMBIO AQUÍ: Usamos onSurface para que sea Blanco en Dark Mode / Negro en Light
                                      color: theme.colorScheme.onSurface, 
                                      fontSize: 16, 
                                      fontWeight: FontWeight.bold 
                                    ),
                                    maxLines: 1, 
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // 2. Nombre del Producto
                            Text(
                              hasItems 
                                  ? "${order.items[0]['name']} ${order.items.length > 1 ? '+ ${order.items.length - 1} más' : ''}"
                                  : "Pedido sin items",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.normal, // Normal para que destaque el nombre de la tienda
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            const SizedBox(height: 4),
                            
                            // 3. Precio Total
                            Text(
                              "Total: \$${order.total.toStringAsFixed(2)}",
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 15
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 20.0),
                        child: Icon(Icons.chevron_right, color: Colors.grey),
                      ),
                    ],
                  ),
                  
                  // AVISO DE CALIFICACIÓN
                  if (order.status == OrderStatus.completed && !order.isRated) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star_rate_rounded, size: 18, color: Colors.amber[800]),
                          const SizedBox(width: 6),
                          Text(
                            "¡Esperando tu calificación!",
                            style: TextStyle(color: Colors.amber[900], fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  ]
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}