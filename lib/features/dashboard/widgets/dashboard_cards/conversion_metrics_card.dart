import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proveedor_servicly_app/features/agenda/providers/agenda_providers.dart';

class ConversionMetricsCard extends ConsumerWidget {
  const ConversionMetricsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(weeklyConversionMetricsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const accentColor = Color(0xFF00B2B2);

    return metricsAsync.maybeWhen(
      data: (metrics) {
        final double rate = metrics['conversionRate'];
        final int totalClosed = metrics['totalClosed'];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              // 📊 INDICADOR CIRCULAR DE RATIO
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 70, height: 70,
                    child: CircularProgressIndicator(
                      value: rate / 100,
                      strokeWidth: 8,
                      backgroundColor: accentColor.withValues(alpha: 0.1),
                      color: accentColor,
                    ),
                  ),
                  Text(
                    "${rate.toStringAsFixed(0)}%",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              // 📝 DATOS TÉCNICOS
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "CONVERSIÓN SEMANAL",
                      style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$totalClosed Citas Cerradas",
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${metrics['confirmedQuotes']} presupuestos ganados de ${metrics['totalQuotes']}",
                      style: TextStyle(color: accentColor.withValues(alpha: 0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.trending_up, color: Colors.greenAccent, size: 24),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}