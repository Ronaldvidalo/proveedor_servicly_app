import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart' as provider; // Alias para provider clásico

// --- Modelos ---
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/models/order_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';

// --- Providers ---
import 'package:proveedor_servicly_app/features/inventory/providers/inventory_providers.dart';
import 'package:proveedor_servicly_app/features/sales/providers/sales_providers.dart';

// --- Servicios ---
import 'package:proveedor_servicly_app/core/services/order_service.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isProcessing = false; // Evitar doble tap

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE VENTA INMEDIATA (SIN CARRITO) ---
  Future<void> _processInstantSale(ProductModel product, String providerId) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final messenger = ScaffoldMessenger.of(context);
    // Usamos los repositorios
    final inventoryRepo = ref.read(inventoryRepositoryProvider);
    // Usamos el servicio de órdenes existente (inyectado con Provider clásico)
    final orderService = provider.Provider.of<OrderService>(context, listen: false);

    try {
      // 1. Crear la Orden (Venta única)
      final newOrder = OrderModel(
        id: const Uuid().v4(),
        providerId: providerId,
        clientId: 'pos_instant',
        clientName: 'Venta Mostrador',
        clientEmail: '',
        items: [{
          'productId': product.id,
          'name': product.name,
          'price': product.price,
          'quantity': 1,
          'imageUrl': product.imageUrl,
          'unitCost': product.costoTotalReal, // Vital para la ganancia
        }],
        total: product.price,
        status: OrderStatus.completed,
        createdAt: Timestamp.now(),
        paymentMethodId: 'cash',
        paymentProofUrl: '',
        clientNotes: 'Venta Directa 1-Click',
      );

      // 2. Guardar Orden
      await orderService.createOrder(newOrder);

      // 3. Descontar Stock
      int newStock = (product.quantity ?? 0) - 1;
      if (newStock < 0) newStock = 0;
      await inventoryRepo.updateStock(product.id, newStock);

      // 4. Feedback (Vibración o Sonido sería ideal aquí)
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text("✅ Vendido: ${product.name}"),
          duration: const Duration(milliseconds: 800),
          backgroundColor: const Color(0xFF00FF7F).withAlpha(200), // ignore: deprecated_member_use
          behavior: SnackBarBehavior.floating,
          width: 250,
        )
      );

    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Datos de Productos (Inventario)
    final productsAsync = ref.watch(productsStreamProvider);
    // 2. Datos de Ventas (Historial en tiempo real)
    final salesAsync = ref.watch(salesStreamProvider);
    
    // Usuario actual (Provider clásico)
    final userModel = provider.Provider.of<UserModel?>(context);
    final String providerId = userModel?.uid ?? '';

    const backgroundColor = Color(0xFF1A1A2E);
    const surfaceColor = Color(0xFF2D2D5A);
    const accentColor = Color(0xFF00BFFF);

    return Scaffold(
      backgroundColor: backgroundColor,
      // AppBar simplificado
      appBar: AppBar(
        title: const Text("Caja Rápida"),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- SECCIÓN A: EL MARCADOR (Resumen de Hoy) ---
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [surfaceColor, const Color(0xFF252540)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: _DailyStatsWidget(salesAsync: salesAsync),
          ),

          // --- SECCIÓN B: BUSCADOR Y PRODUCTOS ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Buscar producto para vender...",
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: accentColor),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear, color: Colors.white38), onPressed: () { setState(() => _searchQuery = ''); _searchController.clear(); }) 
                  : null,
                filled: true,
                fillColor: surfaceColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          
          const SizedBox(height: 12),

          // --- LISTA DE PRODUCTOS (BOTONES DE VENTA) ---
          Expanded(
            flex: 3, // Ocupa más espacio que el historial
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: accentColor)),
              error: (e, _) => Center(child: Text("Error: $e")),
              data: (products) {
                final filtered = products.where((p) => 
                  p.name.toLowerCase().contains(_searchQuery.toLowerCase())
                ).toList();

                if (filtered.isEmpty) return const Center(child: Text("Sin resultados", style: TextStyle(color: Colors.white38)));

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // 3 columnas para densidad
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final product = filtered[i];
                    return _QuickSellCard(
                      product: product,
                      onTap: () => _processInstantSale(product, providerId),
                    );
                  },
                );
              },
            ),
          ),

          const Divider(height: 1, color: Colors.white10),

          // --- SECCIÓN C: LA CINTA DE VENTAS (Últimos movimientos) ---
          // Una vista rápida de lo que acabas de vender
          Container(
            height: 160, // Altura fija para el historial reciente
            color: const Color(0xFF202035),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text("Últimas Ventas (Hoy)", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: salesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_,__) => const SizedBox.shrink(),
                    data: (orders) {
                      // Filtramos solo hoy y tomamos las últimas 20
                      final now = DateTime.now();
                      final todayOrders = orders.where((o) {
                        final d = o.createdAt.toDate();
                        return d.year == now.year && d.month == now.month && d.day == now.day;
                      }).toList();

                      if (todayOrders.isEmpty) {
                        return const Center(child: Text("Esperando primera venta...", style: TextStyle(color: Colors.white24)));
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: todayOrders.length,
                        separatorBuilder: (_,__) => const Divider(height: 1, color: Colors.white10),
                        itemBuilder: (ctx, i) {
                          final order = todayOrders[i];
                          // Mostramos el primer producto como referencia
                          final firstName = order.items.isNotEmpty ? order.items.first['name'] : 'Venta';
                          final itemCount = order.items.length;
                          final time = DateFormat('HH:mm').format(order.createdAt.toDate());

                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            leading: Text(time, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                            title: Text(
                              itemCount > 1 ? "$firstName +${itemCount-1}" : firstName,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              "\$${order.total.toStringAsFixed(0)}",
                              style: const TextStyle(color: Color(0xFF00FF7F), fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// --- WIDGET: RESUMEN DIARIO (EL MARCADOR) ---
class _DailyStatsWidget extends StatelessWidget {
  final AsyncValue<List<OrderModel>> salesAsync;

  const _DailyStatsWidget({required this.salesAsync});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);

    return salesAsync.when(
      loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
      data: (orders) {
        // Cálculo rápido
        final now = DateTime.now();
        final todayOrders = orders.where((o) {
          final d = o.createdAt.toDate();
          return d.year == now.year && d.month == now.month && d.day == now.day;
        }).toList();

        double totalVentas = 0;
        double totalGanancia = 0;

        for (var order in todayOrders) {
          totalVentas += order.total;
          // Estimación de ganancia
          for (var item in order.items) {
             final price = (item['price'] as num?)?.toDouble() ?? 0.0;
             final cost = (item['unitCost'] as num?)?.toDouble() ?? 0.0; 
             final qty = (item['quantity'] as num?)?.toInt() ?? 1;
             totalGanancia += (price - cost) * qty;
          }
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Caja Total
            Column(
              children: [
                const Text("TOTAL VENDIDO", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(currencyFormat.format(totalVentas), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            Container(width: 1, height: 30, color: Colors.white24),
            // Caja Ganancia
            Column(
              children: [
                const Text("GANANCIA HOY", style: TextStyle(color: Color(0xFF00FF7F), fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(currencyFormat.format(totalGanancia), style: const TextStyle(color: Color(0xFF00FF7F), fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        );
      },
    );
  }
}

// --- WIDGET: TARJETA DE VENTA RÁPIDA (BOTÓN) ---
class _QuickSellCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _QuickSellCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.isOutOfStock;
    final format = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);

    return GestureDetector(
      onTap: isOutOfStock ? null : onTap,
      child: Opacity(
        opacity: isOutOfStock ? 0.5 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D5A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
            // ignore: deprecated_member_use
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))]
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Imagen pequeña
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(product.imageUrl, fit: BoxFit.contain)
                      : const Icon(Icons.inventory_2_outlined, color: Colors.white24),
                ),
              ),
              // Precio y Nombre
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFF252540),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: Column(
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      format.format(product.price),
                      style: const TextStyle(color: Color(0xFF00BFFF), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}