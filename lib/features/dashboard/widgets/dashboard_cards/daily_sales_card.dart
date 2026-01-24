import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:proveedor_servicly_app/features/sales/providers/sales_providers.dart';
import 'universal_dashboard_card.dart'; // Asegúrate de importar el widget base

class DailySalesCard extends ConsumerWidget {
  const DailySalesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesStreamProvider);
    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);

    return salesAsync.when(
      loading: () => const UniversalDashboardCard(
        title: "HOY", icon: Icons.point_of_sale, primaryColor: Colors.grey, mainValue: "", isLoading: true
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (orders) {
        final now = DateTime.now();
        final todayOrders = orders.where((o) {
          final d = o.createdAt.toDate();
          return d.year == now.year && d.month == now.month && d.day == now.day;
        }).toList();

        final double totalToday = todayOrders.fold(0, (sum, item) => sum + item.total);
        final int countToday = todayOrders.length;

        return UniversalDashboardCard(
          title: "HOY",
          icon: Icons.point_of_sale_rounded,
          primaryColor: const Color(0xFF00FF7F), // Verde Base
          mainValue: currencyFormat.format(totalToday),
          subContent: Row(
            children: [
              const Icon(Icons.trending_up_rounded, size: 16, color: Color(0xFF00FF7F)),
              const SizedBox(width: 4),
              Text("$countToday ventas"),
            ],
          ),
        );
      },
    );
  }
}