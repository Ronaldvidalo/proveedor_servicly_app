import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proveedor_servicly_app/features/finance/presentation/providers/finance_providers.dart';

class FinancialHealthCard extends ConsumerWidget {
  const FinancialHealthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(financialSummaryProvider);

    return summaryAsync.when(
      loading: () => Container(
        width: 160, 
        height: 120, 
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D5A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ), 
      error: (_, __) => const SizedBox.shrink(),
      data: (summary) {
        final bool isHealthy = summary.ingresosNetos > 0;
        final Color statusColor = isHealthy ? const Color(0xFF00BFFF) : Colors.orangeAccent;
        final String statusText = isHealthy ? "Estable" : "Atención";
        
        return Container(
          width: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D5A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withAlpha(77)), // 0.3 * 255
             boxShadow: [
              BoxShadow(color: statusColor.withAlpha(26), blurRadius: 10, offset: const Offset(0, 4)) // 0.1 * 255
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.monitor_heart_outlined, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  const Text("SALUD", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              const Spacer(),
              Text(
                statusText,
                style: TextStyle(color: statusColor, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: isHealthy ? 0.8 : 0.3, 
                backgroundColor: Colors.black26,
                color: statusColor,
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              )
            ],
          ),
        );
      },
    );
  }
}