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
    
    // QA FIX: Obtener tema
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Definimos el color de éxito (Verde)
    const successColor = Color(0xFF00FF7F); // SpringGreen

    return salesAsync.when(
      loading: () => _buildLoadingState(theme),
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
            // QA FIX: Gradiente solo en modo oscuro. En claro, color sólido.
            color: isDark ? null : theme.cardTheme.color,
            gradient: isDark ? const LinearGradient(
              colors: [Color(0xFF2D2D5A), Color(0xFF202035)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ) : null,
            borderRadius: BorderRadius.circular(20),
            // Borde sutil en modo claro, Neón en modo oscuro
            border: Border.all(
              color: isDark 
                  ? successColor.withValues(alpha: 0.3) 
                  : theme.dividerColor,
            ),
            boxShadow: [
              // Glow verde en oscuro, Sombra suave en claro
              BoxShadow(
                color: isDark 
                    ? successColor.withValues(alpha: 0.1) 
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4)
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icono siempre verde para consistencia semántica
                  const Icon(Icons.point_of_sale, color: successColor, size: 20),
                  Text(
                    "HOY", 
                    style: TextStyle(
                      // Texto secundario adaptable
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6), 
                      fontSize: 10, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                currencyFormat.format(totalToday),
                style: TextStyle(
                  // Texto principal (Monto) adaptable
                  color: theme.colorScheme.onSurface, 
                  fontSize: 22, 
                  fontWeight: FontWeight.bold
                ),
              ),
              Text(
                "$countToday ventas",
                style: TextStyle(
                  // En modo claro, oscurecemos un poco el verde para leerlo mejor
                  color: isDark ? successColor : Colors.green.shade700, 
                  fontSize: 12,
                  fontWeight: FontWeight.w600
                ),
              ),
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
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2, 
          color: theme.colorScheme.primary
        )
      ),
    );
  }
}