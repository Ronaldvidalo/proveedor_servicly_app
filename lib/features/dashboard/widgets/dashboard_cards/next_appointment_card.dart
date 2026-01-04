import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// --- Imports de Agenda ---
import 'package:proveedor_servicly_app/features/agenda/providers/agenda_providers.dart';
import 'package:proveedor_servicly_app/features/agenda/data/models/agenda_event_model.dart';

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

    // Colores semánticos definidos en la infraestructura de ingeniería
    const Color standardColor = Color(0xFF6C63FF); // Morado Agenda
    const Color pendingColor = Colors.orangeAccent; // Naranja Negociación

    return nextEventAsync.when(
      loading: () => _buildPlaceholder(theme, isLoading: true),
      error: (_, __) => _buildPlaceholder(theme, errorText: "Error"),
      data: (event) {
        final bool hasAppointment = event != null;
        
        // --- LÓGICA DE PRIORIDAD TÉCNICA ---
        // Si el próximo evento requiere aprobación, cambiamos el color de la tarjeta
        final bool isPending = hasAppointment && event.eventStatus == EventStatus.pendingApproval;
        final Color activeColor = isPending ? pendingColor : standardColor;

        return Container(
          width: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? null : theme.cardTheme.color,
            gradient: isDark ? LinearGradient(
              colors: [
                activeColor.withValues(alpha: 0.2), 
                activeColor.withValues(alpha: 0.05)
              ], 
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ) : null,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark 
                  ? activeColor.withValues(alpha: 0.5) 
                  : (isPending ? pendingColor : theme.dividerColor)
            ),
            boxShadow: [
               BoxShadow(
                color: isDark 
                    ? activeColor.withValues(alpha: 0.1) 
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
                  Icon(
                    isPending ? Icons.notification_important : Icons.calendar_today, 
                    color: activeColor, 
                    size: 18
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isPending ? "PENDIENTE" : "PRÓXIMA", 
                    style: TextStyle(
                      color: isPending ? pendingColor : colorScheme.onSurface.withValues(alpha: 0.6), 
                      fontSize: 10, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5
                    )
                  ),
                ],
              ),
              const Spacer(),
              if (hasAppointment) ...[
                Text(
                  DateFormat('HH:mm').format(event.startTime), 
                  style: TextStyle(
                    color: isPending ? pendingColor : colorScheme.onSurface, 
                    fontSize: 22, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isPending ? Colors.white : activeColor, 
                    fontSize: 12, 
                    fontWeight: FontWeight.w600
                  ),
                ),
                Text(
                  _formatDate(event.startTime),
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.6), 
                    fontSize: 10
                  ),
                ),
              ] else ...[
                Text(
                  "Libre", 
                  style: TextStyle(
                    color: colorScheme.onSurface, 
                    fontSize: 18, 
                    fontWeight: FontWeight.bold
                  )
                ),
                Text(
                  "Sin citas pendientes", 
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.5), 
                    fontSize: 10
                  )
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
            ? const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00B2B2))
            : Text(errorText ?? "", style: TextStyle(color: colorScheme.error)),
      ),
    );
  }
}