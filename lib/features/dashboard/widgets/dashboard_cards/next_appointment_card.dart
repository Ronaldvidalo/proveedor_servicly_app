import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// --- Imports de Agenda ---
import 'package:proveedor_servicly_app/features/agenda/providers/agenda_providers.dart';

class NextAppointmentCard extends ConsumerWidget {
  const NextAppointmentCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos la próxima cita real en tiempo real
    final nextEventAsync = ref.watch(nextAppointmentProvider);
    
    // QA FIX: Obtener tema del contexto
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    // Mantenemos el morado como color semántico de Agenda, pero lo adaptamos si es necesario
    const Color semanticColor = Color(0xFF6C63FF); 

    return nextEventAsync.when(
      loading: () => _buildPlaceholder(theme, isLoading: true),
      error: (_, __) => _buildPlaceholder(theme, errorText: "Error"),
      data: (event) {
        final bool hasAppointment = event != null;
        
        return Container(
          width: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // QA FIX: Fondo dinámico (Gradiente solo en dark)
            color: isDark ? null : theme.cardTheme.color,
            gradient: isDark ? LinearGradient(
              colors: [semanticColor.withValues(alpha: 0.2), semanticColor.withValues(alpha: 0.05)], 
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ) : null,
            borderRadius: BorderRadius.circular(20),
            // QA FIX: Borde adaptativo
            border: Border.all(
              color: isDark ? semanticColor.withValues(alpha: 0.5) : theme.dividerColor
            ),
            boxShadow: [
               BoxShadow(
                color: isDark 
                    ? semanticColor.withValues(alpha: 0.1) 
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
                  const Icon(Icons.calendar_today, color: semanticColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "PRÓXIMA", 
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
              if (hasAppointment) ...[
                Text(
                  DateFormat('HH:mm').format(event.startTime), 
                  style: TextStyle(
                    // Hora en grande (Texto principal)
                    color: colorScheme.onSurface, 
                    fontSize: 22, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: semanticColor, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  // Si es hoy, dice "Hoy", si no, la fecha
                  _formatDate(event.startTime),
                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 10),
                ),
              ] else ...[
                Text(
                  "Libre", 
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)
                ),
                Text(
                  "Sin citas pendientes", 
                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 10)
                ),
              ]
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return "Hoy";
    }
    if (date.year == now.year && date.month == now.month && date.day == now.day + 1) {
      return "Mañana";
    }
    return DateFormat('dd MMM').format(date);
  }

  Widget _buildPlaceholder(ThemeData theme, {bool isLoading = false, String? errorText}) {
    final colorScheme = theme.colorScheme;
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Center(
        child: isLoading 
            ? const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C63FF))
            : Text(errorText ?? "", style: TextStyle(color: colorScheme.error)),
      ),
    );
  }
}