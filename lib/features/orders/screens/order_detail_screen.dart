import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:proveedor_servicly_app/core/models/order_model.dart';
import 'package:proveedor_servicly_app/features/orders/screens/rate_provider_screen.dart'; 

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isUpdating = false;
  late OrderModel _currentOrder; 

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  // Actualizar estado (Proveedor)
  Future<void> _updateStatus(OrderStatus newStatus) async {
  setState(() => _isUpdating = true);
  try {
    // 1. Actualizar en Firebase
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(_currentOrder.id)
        .update({
      'status': newStatus.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // --- CORRECCIÓN AQUÍ ---
    // En lugar de usar copyWith, recargamos los datos desde la BD
    await _refreshOrder(); 
    // -----------------------

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Orden actualizada a: ${newStatus.name}'),
          backgroundColor: Colors.green,
        ),
      );
      // Nota: No hacemos pop() para que veas el cambio en pantalla
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  } finally {
    if (mounted) setState(() => _isUpdating = false);
  }
}

  // Recargar orden tras calificar (Cliente)
  Future<void> _refreshOrder() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('orders').doc(_currentOrder.id).get();
      if (doc.exists) {
        setState(() {
          _currentOrder = OrderModel.fromFirestore(doc);
        });
      }
    } catch (e) {
      debugPrint("Error recargando orden: $e");
    }
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          child: Image.network(imageUrl, fit: BoxFit.contain),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUser = FirebaseAuth.instance.currentUser;
    
    final isPending = _currentOrder.status == OrderStatus.pending_verification;
    final isCompleted = _currentOrder.status == OrderStatus.completed;
    final isClient = currentUser?.uid == _currentOrder.clientId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Pedido'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: _StatusChip(status: _currentOrder.status),
            ),
          )
        ],
      ),
      body: _isUpdating 
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                
                // --- 1. DATOS ---
                _SectionTitle(title: isClient ? 'PROVEEDOR' : 'CLIENTE', icon: Icons.person_outline),
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primary.withValues(alpha: 0.1), // CORREGIDO
                      child: Text(
                        _currentOrder.clientName.isNotEmpty ? _currentOrder.clientName[0].toUpperCase() : '?',
                        style: TextStyle(color: colorScheme.primary),
                      ),
                    ),
                    title: Text(_currentOrder.clientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(_currentOrder.clientEmail),
                  ),
                ),
                const SizedBox(height: 20),

                // --- 2. LOGÍSTICA ---
                _SectionTitle(title: 'MÉTODO DE ENTREGA', icon: Icons.local_shipping_outlined),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _currentOrder.deliveryType == DeliveryType.delivery 
                        ? Colors.orange.withValues(alpha: 0.1) // CORREGIDO
                        : Colors.blue.withValues(alpha: 0.1),  // CORREGIDO
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _currentOrder.deliveryType == DeliveryType.delivery 
                          ? Colors.orange.withValues(alpha: 0.5) // CORREGIDO
                          : Colors.blue.withValues(alpha: 0.5),  // CORREGIDO
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _currentOrder.deliveryType == DeliveryType.delivery ? Icons.delivery_dining : Icons.storefront,
                            size: 28,
                            color: _currentOrder.deliveryType == DeliveryType.delivery ? Colors.orange : Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _currentOrder.deliveryType == DeliveryType.delivery ? "ENVÍO A DOMICILIO" : "RETIRO EN TIENDA",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _currentOrder.deliveryType == DeliveryType.delivery ? Colors.orange : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      if (_currentOrder.deliveryType == DeliveryType.delivery) ...[
                        const Divider(height: 24),
                        const Text("Dirección de entrega:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          _currentOrder.shippingAddress,
                          style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
                        ),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- 3. ITEMS ---
                _SectionTitle(title: 'PRODUCTOS', icon: Icons.shopping_bag_outlined),
                Card(
                  child: Column(
                    children: [
                      ..._currentOrder.items.map((item) => ListTile(
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            image: item['imageUrl'] != null 
                                ? DecorationImage(image: NetworkImage(item['imageUrl']), fit: BoxFit.cover)
                                : null,
                          ),
                        ),
                        title: Text(item['name']),
                        subtitle: Text('${item['quantity']} x \$${item['price']}'),
                        trailing: Text(
                          '\$${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )),
                      const Divider(),
                      ListTile(
                        title: const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Text(
                          '\$${_currentOrder.total.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- 4. COMPROBANTE ---
                _SectionTitle(title: 'COMPROBANTE DE PAGO', icon: Icons.receipt),
                if (_currentOrder.paymentProofUrl.isNotEmpty)
                  GestureDetector(
                    onTap: () => _showFullImage(_currentOrder.paymentProofUrl),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)), // CORREGIDO
                        image: DecorationImage(
                          image: NetworkImage(_currentOrder.paymentProofUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in, color: Colors.white, size: 18),
                              SizedBox(width: 4),
                              Text("Ver Comprobante", style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const Text("No hay comprobante disponible."),
                const SizedBox(height: 40),

                // --- 5. ACCIONES ---
                
                // PENDIENTE
                if (isPending) ...[
                  if (!isClient) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _updateStatus(OrderStatus.completed),
                        icon: const Icon(Icons.check_circle),
                        label: const Text("APROBAR Y FINALIZAR"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () => _updateStatus(OrderStatus.cancelled),
                        icon: const Icon(Icons.cancel),
                        label: const Text("RECHAZAR PEDIDO"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ] else ...[
                    const Center(child: Text("Esperando confirmación del proveedor...", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
                  ]
                ] 
                
                // COMPLETADO
                else if (isCompleted) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1), // CORREGIDO
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text("Orden Completada Exitosamente", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                  // BOTÓN DE CALIFICAR (Solo Cliente)
                  if (isClient && !_currentOrder.isRated) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => RateProviderScreen(order: _currentOrder)),
                          );
                          if (result == true) {
                             _refreshOrder();
                          }
                        },
                        icon: const Icon(Icons.star, color: Colors.white),
                        label: const Text("CALIFICAR EXPERIENCIA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ] else if (isClient && _currentOrder.isRated) ...[
                    const SizedBox(height: 20),
                    const Center(child: Text("⭐ ¡Gracias por tu calificación!", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))),
                  ],
                ],
                const SizedBox(height: 40),
              ],
            ),
    );
  }
}

// --- WIDGETS AUXILIARES ---

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    switch (status) {
      case OrderStatus.pending_verification:
      case OrderStatus.pending_payment:
        color = Colors.orange;
        text = "PENDIENTE";
        break;
      case OrderStatus.completed:
        color = Colors.green;
        text = "COMPLETADA";
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        text = "CANCELADA";
        break;
      default:
        color = Colors.grey;
        text = status.name.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2), // CORREGIDO
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}