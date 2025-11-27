import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proveedor_servicly_app/features/inventory/providers/inventory_providers.dart';

class InventoryAlertCard extends ConsumerWidget {
  const InventoryAlertCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);
    
    // QA FIX: Obtener tema del contexto
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return productsAsync.when(
      loading: () => _buildLoadingState(theme),
      error: (_, __) => const SizedBox.shrink(),
      data: (products) {
        final lowStockItems = products.where((p) => p.isLowStock || p.isOutOfStock).toList();
        final int alertCount = lowStockItems.length;
        
        final bool isCritical = alertCount > 0;
        // Colores de estado (Naranja / Verde Neón)
        final Color statusColor = isCritical ? Colors.orangeAccent : const Color(0xFF00FF7F);
        final String statusTitle = isCritical ? "REVISAR" : "ÓPTIMO";

        return Container(
          width: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // QA FIX: Fondo dinámico
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            
            // QA FIX: Borde adaptativo (Neón en dark, Sutil en light)
            border: Border.all(
              color: isDark 
                  ? statusColor.withValues(alpha: 0.3) 
                  : theme.dividerColor,
            ),
            
            // QA FIX: Sombra adaptativa (Glow en dark, Sombra suave en light)
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? statusColor.withValues(alpha: 0.1) 
                    : Colors.black.withValues(alpha: 0.05),
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
                  Icon(Icons.inventory_2_outlined, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "STOCK", 
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
                alertCount > 0 ? "$alertCount Bajos" : "Todo Bien",
                style: TextStyle(
                  color: statusColor, 
                  fontSize: 18, 
                  fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 4),
              Text(
                statusTitle,
                style: TextStyle(
                  // Texto descriptivo adaptable
                  color: colorScheme.onSurface.withValues(alpha: 0.7), 
                  fontSize: 12
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
      height: 120, // Altura aproximada para evitar saltos de layout
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}