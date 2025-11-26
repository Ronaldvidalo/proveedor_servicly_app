import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:proveedor_servicly_app/features/sales/providers/sales_providers.dart';

class DailySalesCard extends ConsumerWidget {
  const DailySalesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesStreamProvider);
    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);

    return salesAsync.when(
      loading: () => _buildLoadingState(),
      error: (_, __) => const SizedBox.shrink(),
      data: (orders) {
        final now = DateTime.now();
        final todayOrders = orders.where((o) {
          final d = o.createdAt.toDate();
          return d.year == now.year && d.month == now.month && d.day == now.day;
        }).toList();

        final double totalToday = todayOrders.fold(0, (sum, item) => sum + item.total);
        final int countToday = todayOrders.length;

        return Container(
          width: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2D2D5A), Color(0xFF202035)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF00FF7F).withAlpha(77)),
            boxShadow: [
              BoxShadow(color: const Color(0xFF00FF7F).withAlpha(26), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.point_of_sale, color: Color(0xFF00FF7F), size: 20),
                  Text("HOY", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                currencyFormat.format(totalToday),
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                "$countToday ventas",
                style: const TextStyle(color: Color(0xFF00FF7F), fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: 160,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D5A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}