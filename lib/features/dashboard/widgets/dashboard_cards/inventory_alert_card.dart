import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proveedor_servicly_app/features/inventory/providers/inventory_providers.dart';
import 'universal_dashboard_card.dart';

class InventoryAlertCard extends ConsumerWidget {
  const InventoryAlertCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);

    return productsAsync.when(
      loading: () => const UniversalDashboardCard(title: "STOCK", icon: Icons.inventory_2, primaryColor: Colors.grey, mainValue: "", isLoading: true),
      error: (_, __) => const SizedBox.shrink(),
      data: (products) {
        final int alertCount = products.where((p) => p.isLowStock || p.isOutOfStock).length;
        final bool isCritical = alertCount > 0;
        final Color statusColor = isCritical ? Colors.orangeAccent : const Color(0xFF00FF7F);

        return UniversalDashboardCard(
          title: "STOCK",
          icon: Icons.inventory_2_rounded,
          primaryColor: statusColor,
          mainValue: isCritical ? "$alertCount" : "OK",
          subContent: Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(isCritical ? "Productos bajos" : "Inventario óptimo"),
            ],
          ),
        );
      },
    );
  }
}