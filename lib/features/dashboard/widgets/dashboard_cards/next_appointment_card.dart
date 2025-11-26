import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// --- Imports de Agenda ---
import 'package:proveedor_servicly_app/features/agenda/data/models/agenda_event_model.dart';
import 'package:proveedor_servicly_app/features/agenda/providers/agenda_providers.dart';

// --- Pantalla de Agenda (Para navegación) ---
import 'package:proveedor_servicly_app/features/agenda/presentation/screens/agenda_screen.dart';
// Necesitamos el UserModel para navegar a la AgendaScreen. 
// Usaremos un truco: obtenerlo del contexto o pasar un callback, 
// pero para mantenerlo simple en el dashboard, asumimos que el padre maneja la navegación 
// O podemos usar el provider de usuario si está disponible globalmente con Riverpod.
// Por ahora, lo haremos solo visual y la navegación la maneja el DashboardSummaryCards.

class NextAppointmentCard extends ConsumerWidget {
  const NextAppointmentCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos la próxima cita real en tiempo real
    final nextEventAsync = ref.watch(nextAppointmentProvider);
    const Color cardColor = Color(0xFF6C63FF); // Morado Agenda

    return nextEventAsync.when(
      loading: () => _buildPlaceholder(isLoading: true),
      error: (_, __) => _buildPlaceholder(errorText: "Error"),
      data: (event) {
        final bool hasAppointment = event != null;
        
        return Container(
          width: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cardColor.withAlpha(51), cardColor.withAlpha(13)], // 0.2 y 0.05 opacity
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            // ignore: deprecated_member_use
            border: Border.all(color: cardColor.withAlpha(128)),
            boxShadow: [
              // ignore: deprecated_member_use
              BoxShadow(color: cardColor.withAlpha(26), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: cardColor, size: 18),
                  const SizedBox(width: 8),
                  // ignore: deprecated_member_use
                  Text("PRÓXIMA", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              const Spacer(),
              if (hasAppointment) ...[
                Text(
                  DateFormat('HH:mm').format(event!.startTime), 
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: cardColor, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  // Si es hoy, dice "Hoy", si no, la fecha
                  _formatDate(event.startTime),
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ] else ...[
                const Text("Libre", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Text("Sin citas pendientes", style: TextStyle(color: Colors.white54, fontSize: 10)),
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

  Widget _buildPlaceholder({bool isLoading = false, String? errorText}) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D5A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: isLoading 
            ? const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C63FF))
            : Text(errorText ?? "", style: const TextStyle(color: Colors.white38)),
      ),
    );
  }
}