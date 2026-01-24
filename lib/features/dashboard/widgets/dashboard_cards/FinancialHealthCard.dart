import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proveedor_servicly_app/features/finance/presentation/providers/finance_providers.dart';
import 'universal_dashboard_card.dart';

class FinancialHealthCard extends ConsumerWidget {
  const FinancialHealthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(financialSummaryProvider);

    return summaryAsync.when(
      loading: () => const UniversalDashboardCard(title: "SALUD", icon: Icons.monitor_heart, primaryColor: Colors.grey, mainValue: "", isLoading: true),
      error: (_, __) => const SizedBox.shrink(),
      data: (summary) {
        final bool isHealthy = summary.ingresosNetos > 0;
        final Color statusColor = isHealthy ? const Color(0xFF00BFFF) : Colors.orangeAccent;
        
        return UniversalDashboardCard(
          title: "SALUD",
          icon: Icons.monitor_heart_outlined,
          primaryColor: statusColor,
          mainValue: isHealthy ? "Estable" : "Atención",
          subContent: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: isHealthy ? 0.85 : 0.4,
                  backgroundColor: statusColor.withValues(alpha: 0.2),
                  color: statusColor,
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 6),
              Text(isHealthy ? "Balance positivo" : "Revisar gastos"),
            ],
          ),
        );
      },
    );
  }
}