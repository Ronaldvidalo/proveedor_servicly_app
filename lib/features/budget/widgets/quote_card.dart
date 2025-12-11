// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 2025-05-20 (Final Polish)
// Style: Cyber Glow High Contrast
// Component: QuoteCard
// Cambios:
// 1. Botones de acción visibles (Editar/Enviar) en lugar de menú oculto.
// 2. Jerarquía de precios aumentada (Fuente grande y blanca/color).
// 3. Eliminación de ruido visual.
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proveedor_servicly_app/features/budget/models/quote_model.dart';
import 'package:proveedor_servicly_app/shared/theme/widgets/cyber_container.dart';  // IMPORTANTE

class QuoteCard extends StatelessWidget {
  final Quote quote;
  final VoidCallback onTap;
  final VoidCallback onPreviewSend; // Nueva acción directa
  final VoidCallback? onEdit;       // Nueva acción directa

  const QuoteCard({
    super.key,
    required this.quote,
    required this.onTap,
    required this.onPreviewSend,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final currencyFormat = NumberFormat.simpleCurrency(name: quote.currency);
    final dateFormat = DateFormat('dd MMM yyyy');
    final isAccepted = quote.status.toLowerCase() == 'accepted';
    final isDraft = quote.status.toLowerCase() == 'draft';

    return CyberContainer(
      onTap: onTap,
      borderGlow: isAccepted, 
      padding: const EdgeInsets.all(0), 
      child: Column(
        children: [
          // --- HEADER: Folio y Estado ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Folio
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    quote.number,
                    style: TextStyle(
                      fontFamily: 'Courier',
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                _StatusBadge(status: quote.status),
              ],
            ),
          ),

          Divider(height: 1, thickness: 1, color: Colors.white.withValues(alpha: 0.05)),

          // --- BODY: Info Cliente ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              children: [
                // Avatar Brillante
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.2),
                        colorScheme.tertiary.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  ),
                  child: Center(
                    child: Text(
                      quote.clientName.isNotEmpty ? quote.clientName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Textos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quote.clientName.isNotEmpty ? quote.clientName : 'Cliente sin nombre',
                        style: const TextStyle(
                          color: Colors.white, // Blanco Puro para alto contraste
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 14, color: Colors.white54),
                          const SizedBox(width: 6),
                          Text(
                            dateFormat.format(quote.createdAt),
                            style: const TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- FOOTER: Totales y Acciones ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                // Total Grande
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${quote.items.length} ítems",
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "TOTAL",
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currencyFormat.format(quote.total),
                          style: TextStyle(
                            color: isAccepted ? const Color(0xFF00FF7F) : Colors.white, // Verde o Blanco Puro
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // BARRA DE ACCIONES (Botones Reales)
                Row(
                  children: [
                    // Botón Editar (Solo si es borrador)
                    if (isDraft && onEdit != null)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: OutlinedButton.icon(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text("Editar"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ),
                    
                    // Botón Principal (Enviar / Ver PDF)
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: onPreviewSend,
                        icon: Icon(isAccepted ? Icons.print : Icons.send_rounded, size: 18),
                        label: Text(isAccepted ? "Ver Recibo" : "Finalizar / Enviar"),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary, // Azul Neón
                          foregroundColor: const Color(0xFF1A1A2E), // Texto oscuro sobre neón
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 8,
                          shadowColor: colorScheme.primary.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'sent':
      case 'enviada':
        color = const Color(0xFF2196F3);
        label = 'Enviada';
        icon = Icons.send_rounded;
        break;
      case 'accepted':
      case 'aceptada':
        color = const Color(0xFF00E676);
        label = 'Aceptada';
        icon = Icons.check_circle_rounded;
        break;
      case 'rejected':
      case 'rechazada':
        color = const Color(0xFFFF5252);
        label = 'Rechazada';
        icon = Icons.cancel_rounded;
        break;
      default:
        color = Colors.grey;
        label = 'Borrador';
        icon = Icons.edit_note_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}