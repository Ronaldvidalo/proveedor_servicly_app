import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/order_model.dart';
import 'package:proveedor_servicly_app/core/services/order_service.dart';
// Ajusta esta importación si tu estructura de carpetas es diferente
import '../../manage_store/presentation/screens/order_detail_screen.dart';

/// Pantalla completa para que el proveedor gestione TODAS sus órdenes.
/// Muestra pestañas para "Pendientes", "Completadas" y "Canceladas".
class AllOrdersScreen extends StatefulWidget {
  /// El ID del proveedor (usuario actual)
  final String providerId;
  /// La pestaña que debe mostrarse al abrir (0 = Pendientes, 1 = Completadas, 2 = Canceladas)
  final int initialTabIndex;

  const AllOrdersScreen({
    super.key,
    required this.providerId,
    this.initialTabIndex = 0,
  });

  @override
  State<AllOrdersScreen> createState() => _AllOrdersScreenState();
}

class _AllOrdersScreenState extends State<AllOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3, 
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- TEMATIZACIÓN ---
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Fondo del tema
      appBar: AppBar(
        title: const Text('Gestión de Órdenes'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colors.primary, // Color de acento del tema
          indicatorWeight: 3,
          labelColor: colors.primary,
          unselectedLabelColor: colors.onSurface.withOpacity(0.7),
          tabs: const [
            Tab(text: 'PENDIENTES'),
            Tab(text: 'COMPLETADAS'),
            Tab(text: 'CANCELADAS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // --- Pestaña 1: Pendientes ---
          _OrderListTab(
            stream: context.read<OrderService>().getPendingOrders(widget.providerId),
            emptyMessage: 'No tienes órdenes pendientes de verificación.',
          ),
          
          // --- Pestaña 2: Completadas ---
          _OrderListTab(
            stream: context.read<OrderService>().getCompletedOrders(widget.providerId),
            emptyMessage: 'Aún no has completado ninguna orden.',
          ),
          
          // --- Pestaña 3: Canceladas ---
          _OrderListTab(
            stream: context.read<OrderService>().getCancelledOrders(widget.providerId),
            emptyMessage: 'No tienes órdenes canceladas.',
          ),
        ],
      ),
    );
  }
}

/// Un widget reutilizable que renderiza una lista de órdenes para una pestaña.
class _OrderListTab extends StatelessWidget {
  final Stream<List<OrderModel>> stream;
  final String emptyMessage;

  const _OrderListTab({
    required this.stream,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return StreamBuilder<List<OrderModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: colors.primary));
        }
        if (snapshot.hasError) {
          return _ErrorState(message: 'Error al cargar las órdenes: ${snapshot.error}');
        }
        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return _EmptyState(message: emptyMessage);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _CompactOrderItemCard(
              order: order, 
            );
          },
        );
      },
    );
  }
}

/// Una tarjeta compacta para mostrar en la lista de órdenes.
class _CompactOrderItemCard extends StatelessWidget {
  final OrderModel order;
  
  const _CompactOrderItemCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final item = order.items.isNotEmpty ? order.items.first : null;

    return Card(
      color: colors.surface, // Color de superficie del tema
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => OrderDetailScreen(order: order),
          ));
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: Nombre del item y Estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item != null ? '${item['quantity']}x ${item['name']}' : 'Orden Vacía',
                      style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _StatusBadge(status: order.status),
                ],
              ),
              if (order.items.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '+ ${order.items.length - 1} ${order.items.length - 1 == 1 ? 'item' : 'items'} más',
                    style: TextStyle(color: colors.onSurface.withOpacity(0.7), fontStyle: FontStyle.italic, fontSize: 12),
                  ),
                ),
              
              Divider(color: colors.onSurface.withOpacity(0.1), height: 24),

              // Fila inferior: Cliente y Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Cliente
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cliente',
                          style: TextStyle(color: colors.onSurface.withOpacity(0.7), fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.clientName,
                          style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Total
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(color: colors.onSurface.withOpacity(0.7), fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${order.total.toStringAsFixed(2)}',
                        style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGET PARA EL BADGE DE ESTADO ---
class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;
    IconData icon;

    switch (status) {
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
      default:
        text = 'Desconocido';
        color = Colors.grey;
        icon = Icons.question_mark_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 0.5)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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

// --- WIDGETS DE ESTADO (VACÍO Y ERROR) ---
class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 80, color: colors.onSurface.withOpacity(0.2)),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: colors.onSurface.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}