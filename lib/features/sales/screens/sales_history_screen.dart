import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/sales_providers.dart';

class SalesHistoryScreen extends ConsumerWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesStreamProvider);
    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM HH:mm');

    const backgroundColor = Color(0xFF1A1A2E);
    const surfaceColor = Color(0xFF2D2D5A);
    const accentColor = Color(0xFF00BFFF);
    const profitColor = Color(0xFF00FF7F); // Verde para ganancias

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Historial de Ventas"),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: salesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: accentColor)),
        error: (e, _) => Center(child: Text("Error: $e", style: const TextStyle(color: Colors.red))),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text("Aún no has realizado ventas.", style: TextStyle(color: Colors.white54)),
                ],
              ),
            );
          }

          // --- CÁLCULOS FINANCIEROS DEL DÍA ---
          final now = DateTime.now();
          // Filtramos solo las ventas de HOY
          final todayOrders = orders.where((o) {
            final date = o.createdAt.toDate();
            return date.year == now.year && date.month == now.month && date.day == now.day;
          }).toList();

          double totalVentasHoy = 0;
          double totalGananciaHoy = 0;

          for (var order in todayOrders) {
            totalVentasHoy += order.total;
            
            // Calculamos ganancia iterando los items de la orden
            // Recordar: Guardamos 'unitCost' en el item cuando vendimos en el POS
            for (var item in order.items) {
                // item es un Map<String, dynamic> según tu OrderModel actual
                final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                final cost = (item['unitCost'] as num?)?.toDouble() ?? 0.0; 
                final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                
                // Ganancia = (Precio Venta - Costo Total Real) * Cantidad
                totalGananciaHoy += (price - cost) * qty;
            }
          }

          return Column(
            children: [
              // 1. TARJETA DE RESUMEN DIARIO (EL IMPACTO)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [surfaceColor, surfaceColor.withOpacity(0.8)], // ignore: deprecated_member_use
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)) // ignore: deprecated_member_use
                  ]
                ),
                child: Row(
                  children: [
                    // Columna Ventas (Izquierda)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("VENTAS DE HOY", style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text(
                            currencyFormat.format(totalVentasHoy), 
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.white24),
                    const SizedBox(width: 16),
                    // Columna Ganancia (Derecha)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("GANANCIA NETA", style: TextStyle(color: profitColor, fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            currencyFormat.format(totalGananciaHoy), 
                            style: const TextStyle(color: profitColor, fontSize: 24, fontWeight: FontWeight.bold)
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. TÍTULO DE LISTA
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Últimos Movimientos", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
              
              // 3. LISTA DE TRANSACCIONES
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final itemCount = order.items.length;
                    final isCash = order.paymentMethodId == 'cash';
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          // ignore: deprecated_member_use
                          backgroundColor: isCash ? accentColor.withOpacity(0.2) : Colors.purple.withOpacity(0.2),
                          child: Icon(
                            isCash ? Icons.attach_money : Icons.qr_code, 
                            color: isCash ? accentColor : Colors.purpleAccent, 
                            size: 20
                          ),
                        ),
                        title: Text(
                          order.clientName.isNotEmpty ? order.clientName : "Venta Mostrador",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "${dateFormat.format(order.createdAt.toDate())} • $itemCount items",
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormat.format(order.total),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            // Estado (Pequeño)
                            Text(
                              order.status.name.toUpperCase(),
                              style: TextStyle(
                                color: order.status.name == 'completed' ? profitColor : Colors.orange,
                                fontSize: 10
                              ),
                            )
                          ],
                        ),
                        onTap: () {
                          // TODO: Navegar al detalle de la orden (Factura)
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}