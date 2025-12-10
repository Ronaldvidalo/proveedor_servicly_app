// --- UX/UI Enhancement Comment ---
// Widget: QuoteCard
// Ubicación: lib/features/quotes/presentation/widgets/quote_card.dart
// Estilo: Cyber Dual (Tarjeta limpia con indicadores de estado)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Asegúrate de tener intl en pubspec.yaml
import 'package:proveedor_servicly_app/features/budget/models/quote_model.dart';


class QuoteCard extends StatelessWidget {
  final Quote quote;
  final VoidCallback onTap;
  final VoidCallback? onMoreOptions;

  const QuoteCard({
    super.key,
    required this.quote,
    required this.onTap,
    this.onMoreOptions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Formateadores
    final currencyFormat = NumberFormat.simpleCurrency(name: quote.currency);
    final dateFormat = DateFormat('dd MMM yyyy');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          // Sombra sutil según el modo
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
          border: isDark 
            ? Border.all(color: theme.dividerColor.withValues(alpha: 0.1)) 
            : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER: Folio y Estado ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    quote.number,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                _StatusBadge(status: quote.status),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // --- CLIENTE Y FECHA ---
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  child: Text(
                    quote.clientName.isNotEmpty ? quote.clientName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quote.clientName.isNotEmpty ? quote.clientName : 'Cliente sin nombre',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        dateFormat.format(quote.createdAt),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Botón de opciones (tres puntos)
                if (onMoreOptions != null)
                  IconButton(
                    icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    onPressed: onMoreOptions,
                  ),
              ],
            ),
            
            const Divider(height: 24),
            
            // --- FOOTER: Resumen y Total ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${quote.items.length} ítems",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
                Text(
                  currencyFormat.format(quote.total),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Widget auxiliar para el badge de estado
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'sent':
      case 'enviada':
        color = Colors.blue;
        label = 'ENVIADA';
        break;
      case 'accepted':
      case 'aceptada':
        color = Colors.green;
        label = 'ACEPTADA';
        break;
      case 'rejected':
      case 'rechazada':
        color = Colors.red;
        label = 'RECHAZADA';
        break;
      default:
        color = Colors.grey;
        label = 'BORRADOR';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}