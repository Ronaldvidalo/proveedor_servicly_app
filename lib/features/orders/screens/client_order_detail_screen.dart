import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proveedor_servicly_app/core/models/order_model.dart';
import 'package:proveedor_servicly_app/core/models/payment_method_model.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/services/payment_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:proveedor_servicly_app/features/orders/screens/rate_provider_screen.dart';
// ✅ Importación para ir al perfil público
import 'package:proveedor_servicly_app/features/public_profile/screens/public_profile_screen.dart'; 

class ClientOrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const ClientOrderDetailScreen({super.key, required this.order});

  @override
  State<ClientOrderDetailScreen> createState() => _ClientOrderDetailScreenState();
}

class _ClientOrderDetailScreenState extends State<ClientOrderDetailScreen> {
  late OrderModel _currentOrder; 

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order; 
  }

  Future<void> _refreshOrder() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('orders').doc(_currentOrder.id).get();
      if (doc.exists && mounted) {
        setState(() {
          _currentOrder = OrderModel.fromFirestore(doc);
        });
      }
    } catch (e) {
      debugPrint("Error recargando orden: $e");
    }
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.of(ctx).pop(),
          child: InteractiveViewer(
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Definición de Tema Oscuro Local
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);
    
    final paymentService = context.read<PaymentService>();
    final isCompleted = _currentOrder.status == OrderStatus.completed;
    final isInProgress = _currentOrder.status == OrderStatus.inProgress; 

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Detalle de la Orden'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          
          // --- 0. HEADER DEL PROVEEDOR (DETALLADO) ---
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('brandProfiles').doc(_currentOrder.providerId).get(),
            builder: (context, snapshot) {
              
              // Datos por defecto
              String storeName = "Cargando...";
              String? storeLogoUrl;
              double rating = 0.0;
              String category = "General";
              String address = "Ubicación no disponible";

              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                
                // Extraemos todos los datos
                storeName = data['businessName'] ?? data['brandName'] ?? data['name'] ?? "Tienda";
                storeLogoUrl = data['logoUrl'] ?? data['profileImage'];
                rating = (data['ratingAvg'] ?? 0.0).toDouble();
                category = data['category'] ?? "Varios";
                address = data['address'] ?? data['location'] ?? "Dirección no especificada";
              
              } else if (snapshot.connectionState == ConnectionState.done) {
                storeName = "Proveedor Desconocido";
              }

              return GestureDetector(
                onTap: () {
                   // Navegación al perfil
                   Navigator.push(
                     context, 
                     MaterialPageRoute(builder: (_) => PublicProfileScreen(providerId: _currentOrder.providerId))
                   );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor, // Fondo oscuro de la tarjeta
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
                    ]
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LOGO
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12), // Cuadrado redondeado moderno
                          image: (storeLogoUrl != null && storeLogoUrl.isNotEmpty)
                              ? DecorationImage(image: NetworkImage(storeLogoUrl), fit: BoxFit.cover)
                              : null,
                        ),
                        child: (storeLogoUrl == null || storeLogoUrl.isEmpty)
                            ? const Icon(Icons.store, color: Colors.white70, size: 30)
                            : null,
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // INFORMACIÓN DETALLADA
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nombre del Negocio (Blanco y Grande)
                            Text(
                              storeName,
                              style: const TextStyle(
                                color: Colors.white, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 18
                              ),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            
                            // Fila: Estrellas | Categoría
                            Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  rating > 0 ? rating.toStringAsFixed(1) : "-",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)
                                ),
                                const SizedBox(width: 8),
                                Text("•", style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    category,
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 4),
                            
                            // Dirección (Más pequeña)
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 14, color: Colors.white.withValues(alpha: 0.5)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    address,
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Flecha indicando click
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Icon(Icons.chevron_right, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              );
            }
          ),

          // --- 1. CONFIRMACIÓN DE RECEPCIÓN (Estado: En Camino) ---
          if (isInProgress) 
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.local_shipping_outlined, color: Colors.orange, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "¡Tu pedido está en camino!", 
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 18)
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Mensaje del Proveedor:",
                    style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (_currentOrder.providerNote != null && _currentOrder.providerNote!.isNotEmpty) 
                          ? _currentOrder.providerNote! 
                          : "Revisa los detalles acordados. Pronto recibirás tu pedido.", 
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontStyle: FontStyle.italic),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await FirebaseFirestore.instance.collection('orders').doc(_currentOrder.id).update({
                            'status': 'completed', 
                            'completedAt': FieldValue.serverTimestamp(),
                          });
                          
                          await _refreshOrder(); 

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("¡Entregado! Ahora puedes calificar el servicio."), 
                                backgroundColor: Colors.green
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error al confirmar: $e"), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange, 
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text("CONFIRMAR QUE YA LO RECIBÍ", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),

          // --- 2. BLOQUE DE CALIFICACIÓN (Estado: Completado) ---
          if (isCompleted) 
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF00E5FF).withValues(alpha: 0.2), const Color(0xFF39FF14).withValues(alpha: 0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5), width: 1.5),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                    child: Icon(
                      _currentOrder.isRated ? Icons.star : Icons.star_border, 
                      color: _currentOrder.isRated ? Colors.amber : const Color(0xFF00E5FF), 
                      size: 32
                    ),
                  ),
                  title: Text(
                    _currentOrder.isRated ? "¡Gracias por tu opinión!" : "¡Trabajo Terminado!", 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      _currentOrder.isRated 
                        ? "Ya has calificado este servicio." 
                        : "¿Qué te pareció el servicio? Tu opinión ayuda a otros.", 
                      style: const TextStyle(color: Colors.white70, fontSize: 13)
                    ),
                  ),
                  trailing: _currentOrder.isRated 
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber)
                        ),
                        child: const Text("Enviado", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF), 
                          foregroundColor: Colors.black
                        ),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RateProviderScreen(order: _currentOrder),
                            ),
                          );

                          if (result == true) {
                             await _refreshOrder();
                          }
                        },
                        child: const Text("CALIFICAR", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                ),
              ),
            ),

          // --- 3. DATOS DE LA ORDEN ---
          _buildSectionCard(
            context: context,
            surfaceColor: surfaceColor,
            title: 'Estado de la Orden',
            children: [
              _StatusBadge(status: _currentOrder.status),
              const SizedBox(height: 12),
              Text(_getStatusDescription(_currentOrder.status), style: const TextStyle(color: Colors.white70, fontSize: 15)),
              const SizedBox(height: 16),
              if (_currentOrder.status == OrderStatus.pendingPayment)
                Text('Creado el: ${DateFormat('dd/MM/yyyy HH:mm').format(_currentOrder.createdAt.toDate())}', style: const TextStyle(color: Colors.white54, fontSize: 14)),
            ],
          ),

          const SizedBox(height: 24),

          // --- 4. MÉTODO DE ENTREGA ---
          _buildSectionCard(
            context: context,
            surfaceColor: surfaceColor,
            title: 'Método de Entrega',
            children: [
              Row(
                children: [
                  Icon(
                    _currentOrder.deliveryType == DeliveryType.delivery ? Icons.local_shipping : Icons.storefront,
                    color: accentColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _currentOrder.deliveryType == DeliveryType.delivery ? "Envío a Domicilio" : "Retiro en Tienda",
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              if (_currentOrder.deliveryType == DeliveryType.delivery && _currentOrder.shippingAddress.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                const Text("Dirección de Envío:", style: TextStyle(color: Colors.white54, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  _currentOrder.shippingAddress,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // --- 5. RESUMEN DE COMPRA ---
          _buildSectionCard(
            context: context,
            surfaceColor: surfaceColor,
            title: 'Resumen de la Compra',
            children: [
              _buildDetailRow('Orden ID:', _currentOrder.id, truncate: true),
              _buildDetailRow('Total:', '\$${_currentOrder.total.toStringAsFixed(2)}', isTotal: true),
              const Divider(color: Colors.white24, height: 24),
              ..._currentOrder.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${item['quantity']}x ${item['name']}', style: const TextStyle(color: Colors.white, fontSize: 16))),
                    Text('\$${(item['price'] as num).toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              )),
            ],
          ),

          const SizedBox(height: 24),

          // --- 6. COMPROBANTE ---
          if (_currentOrder.paymentProofUrl.isNotEmpty)
            _buildSectionCard(
              context: context,
              surfaceColor: surfaceColor,
              title: 'Comprobante Enviado',
              children: [
                GestureDetector(
                  onTap: () => _showFullImage(context, _currentOrder.paymentProofUrl),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _currentOrder.paymentProofUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (c, child, l) => l == null ? child : const Center(child: CircularProgressIndicator()),
                        errorBuilder: (c, e, s) => const Center(child: Icon(Icons.broken_image, color: Colors.white54)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
          const SizedBox(height: 24),

          // --- 7. MÉTODO DE PAGO ---
          _buildSectionCard(
            context: context,
            surfaceColor: surfaceColor,
            title: 'Pago',
            children: [
              FutureBuilder<DocumentSnapshot>(
                future: paymentService.getPaymentMethodDoc(_currentOrder.providerId, _currentOrder.paymentMethodId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  if (!snapshot.data!.exists) return const Text('Método no disponible', style: TextStyle(color: Colors.white54));
                  final method = PaymentMethodModel.fromFirestore(snapshot.data!);
                  return _buildDetailRow(method.name, _getPaymentDetails(method));
                },
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- Helpers ---
  String _getStatusDescription(OrderStatus status) {
    switch (status) {
      case OrderStatus.pendingPayment: return 'Esperando confirmación de pago.';
      case OrderStatus.pendingVerification: return 'El proveedor está verificando tu pago.';
      case OrderStatus.inProgress: return '¡Orden en camino! Revisa los detalles arriba.'; 
      case OrderStatus.completed: return '¡Orden completada y entregada!';
      case OrderStatus.cancelled: return 'Orden cancelada.';
      case OrderStatus.disputed: return 'Orden en disputa.';
    }
  }

  String _getPaymentDetails(PaymentMethodModel method) {
    if (method.alias != null && method.alias!.isNotEmpty) return "Alias: ${method.alias}";
    if (method.cbu != null && method.cbu!.isNotEmpty) return "CBU: ${method.cbu}";
    return "Ver detalles";
  }

  Widget _buildSectionCard({required BuildContext context, required Color surfaceColor, required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false, bool truncate = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              truncate && value.length > 15 ? '${value.substring(0, 15)}...' : value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isTotal ? const Color(0xFF00BFFF) : Colors.white,
                fontSize: isTotal ? 18 : 16,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    String text; 
    Color color; 
    IconData icon;
    
    switch (status) {
      case OrderStatus.pendingPayment: 
        text = 'Pago Pendiente'; color = Colors.blue; icon = Icons.payment; break;
      case OrderStatus.pendingVerification: 
        text = 'Verificando'; color = Colors.orange; icon = Icons.hourglass_top; break;
      case OrderStatus.inProgress: 
        text = 'En Camino'; color = Colors.indigoAccent; icon = Icons.local_shipping; break;
      case OrderStatus.completed: 
        text = 'Completado'; color = Colors.green; icon = Icons.check_circle; break;
      case OrderStatus.cancelled: 
        text = 'Cancelado'; color = Colors.red; icon = Icons.cancel; break;
      case OrderStatus.disputed:
        text = 'En Disputa'; color = Colors.purple; icon = Icons.gavel; break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: color)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, color: color, size: 14), const SizedBox(width: 6), Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold))],
      ),
    );
  }
}