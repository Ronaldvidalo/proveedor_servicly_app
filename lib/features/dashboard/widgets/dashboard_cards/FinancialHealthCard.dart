import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proveedor_servicly_app/features/finance/presentation/providers/finance_providers.dart';

class FinancialHealthCard extends ConsumerWidget {
  const FinancialHealthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(financialSummaryProvider);
    
    // QA FIX: Obtener tema del contexto
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return summaryAsync.when(
      loading: () => _buildLoadingState(theme),
      error: (_, __) => const SizedBox.shrink(),
      data: (summary) {
        final bool isHealthy = summary.ingresosNetos > 0;
        // Colores semánticos (Cyan para bien, Naranja para atención)
        // Estos colores funcionan bien tanto en fondo blanco como oscuro.
        final Color statusColor = isHealthy ? const Color(0xFF00BFFF) : Colors.orangeAccent;
        final String statusText = isHealthy ? "Estable" : "Atención";
        
        return Container(
          width: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // QA FIX: Fondo dinámico
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            // QA FIX: Borde y Sombra adaptativos
            border: Border.all(
              color: isDark 
                  ? statusColor.withValues(alpha: 0.3) // Borde neón en dark
                  : theme.dividerColor,                // Borde sutil en light
            ),
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? statusColor.withValues(alpha: 0.1) // Glow en dark
                    : Colors.black.withValues(alpha: 0.05), // Sombra suave en light
                blurRadius: 10, 
                offset: const Offset(0, 4)
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.monitor_heart_outlined, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "SALUD", 
                    style: TextStyle(
                      // Texto secundario adaptable
                      color: colorScheme.onSurface.withValues(alpha: 0.6), 
                      fontSize: 10, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                ],
              ),
              const Spacer(),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor, 
                  fontSize: 18, 
                  fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: isHealthy ? 0.8 : 0.3, 
                // Fondo de la barra adaptativo
                backgroundColor: isDark ? Colors.black26 : Colors.grey.shade200,
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

  Widget _buildLoadingState(ThemeData theme) {
    return Container(
      width: 160, 
      height: 120, 
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}