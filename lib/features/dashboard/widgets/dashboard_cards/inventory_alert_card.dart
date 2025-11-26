import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proveedor_servicly_app/features/inventory/providers/inventory_providers.dart';

class InventoryAlertCard extends ConsumerWidget {
  const InventoryAlertCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);

    return productsAsync.when(
      loading: () => Container(width: 160, decoration: BoxDecoration(color: const Color(0xFF2D2D5A), borderRadius: BorderRadius.circular(20))),
      error: (_, __) => const SizedBox.shrink(),
      data: (products) {
        final lowStockItems = products.where((p) => p.isLowStock || p.isOutOfStock).toList();
        final int alertCount = lowStockItems.length;
        
        final bool isCritical = alertCount > 0;
        final Color statusColor = isCritical ? Colors.orangeAccent : const Color(0xFF00FF7F);
        final String statusTitle = isCritical ? "REVISAR" : "ÓPTIMO";

        return Container(
          width: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D5A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withAlpha(77)),
            boxShadow: [
              BoxShadow(color: statusColor.withAlpha(26), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.inventory_2_outlined, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  const Text("STOCK", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              const Spacer(),
              Text(
                alertCount > 0 ? "$alertCount Bajos" : "Todo Bien",
                style: TextStyle(color: statusColor, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                statusTitle,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}