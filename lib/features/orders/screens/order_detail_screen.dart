import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; 
// Asumiendo que esta es la ruta a la pantalla de detalle de la orden del cliente
import 'client_order_detail_screen.dart'; 

// --- MODELOS Y SERVICIOS ---
import 'package:proveedor_servicly_app/core/models/order_model.dart';
import 'package:proveedor_servicly_app/core/services/auth_service.dart';
import 'package:proveedor_servicly_app/core/services/order_service.dart';


/// Pantalla donde el CLIENTE ve su historial de compras.
class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  late final String? _clientId;
  late final OrderService _orderService;

  // --- CONSTANTES DE ESTILO ---
  static const Color backgroundColor = Color(0xFF1A1A2E);
  static const Color accentColor = Color(0xFF00BFFF);

  @override
  void initState() {
    super.initState();
    // Obtenemos los servicios y el ID del cliente
    _orderService = context.read<OrderService>();
    final authService = context.read<AuthService>();
    _clientId = authService.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Mis Compras'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _clientId == null
          ? const _ErrorState(message: 'Debes iniciar sesión para ver tus compras.')
          : StreamBuilder<List<OrderModel>>(
              stream: _orderService.getMyOrders(_clientId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    // Utilizamos la constante definida
                    child: CircularProgressIndicator(color: accentColor),
                  );
                }
                if (snapshot.hasError) {
                  return _ErrorState(message: 'Error al cargar tus órdenes: ${snapshot.error}');
                }
                final orders = snapshot.data ?? [];

                if (orders.isEmpty) {
                  return const _EmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    // Pasamos el color de acento al widget de la tarjeta
                    return _MyOrderItemCard(order: order, accentColor: accentColor);
                  },
                );
              },
            ),
    );
  }
}

// --- WIDGET PARA CADA ITEM DE ORDEN ---
class _MyOrderItemCard extends StatelessWidget {
  final OrderModel order;
  final Color accentColor;
  
  const _MyOrderItemCard({required this.order, required this.accentColor});

  // Constantes de estilo local
  static const Color surfaceColor = Color(0xFF2D2D5A);
  
  // Helper para formatear la fecha
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy \'a las\' hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    // Tomamos el primer ítem para el título de la tarjeta
    final item = order.items.isNotEmpty ? order.items.first : null;

    return Card(
      color: surfaceColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navegación al detalle de la orden
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ClientOrderDetailScreen(order: order),
          ));
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Título principal (primer item)
                  Expanded(
                    child: Text(
                      item != null ? '${item['quantity']}x ${item['name']}' : 'Orden Vacía',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _StatusBadge(status: order.status), // El badge de estado
                ],
              ),
              if (order.items.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '+ ${order.items.length - 1} ${order.items.length - 1 == 1 ? 'item' : 'items'} más',
                    style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 12),
                  ),
                ),
              
              const Divider(color: Colors.white24, height: 24),

              // Fila de Fecha y Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Fecha
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fecha',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(order.createdAt.toDate()),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  // Total
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${order.total.toStringAsFixed(2)}',
                        // Usamos la propiedad accentColor
                        style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 18),
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
      // Añadimos el nuevo estado introducido en el archivo anterior para evitar errores
      case OrderStatus.pending_payment:
        text = 'Pago Pendiente';
        color = Colors.yellow;
        icon = Icons.payment_outlined;
        break;
      default:
        text = 'Desconocido';
        color = Colors.grey;
        icon = Icons.question_mark_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        // Utilizamos withAlpha para hacer el color de fondo más sutil
        color: color.withAlpha(51), // Aproximadamente 20% de opacidad
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 0.5)
      ),
      child: Row(
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
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 80, color: Colors.white24),
            SizedBox(height: 24),
            Text(
              'Aún no has realizado compras',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Los pedidos que realices aparecerán aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white60),
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