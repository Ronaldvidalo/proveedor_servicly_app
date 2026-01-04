import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Modelos y Providers
import 'package:proveedor_servicly_app/features/agenda/data/models/agenda_event_model.dart';
// Importamos el archivo de providers actualizado
import 'package:proveedor_servicly_app/features/agenda/providers/agenda_providers.dart'; 

class UnifiedNotificationScreen extends ConsumerWidget {
  const UnifiedNotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Resolvemos el error 'Undefined name agendaEventsProvider'
    // Este provider ahora existe en tu archivo agenda_providers.dart
    final eventsAsync = ref.watch(agendaEventsProvider);
    const accentColor = Color(0xFF00B2B2);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: const Text(
          "Notificaciones e Interacciones", 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        centerTitle: true,
      ),
      body: eventsAsync.when(
        data: (events) {
          // FILTRO TÉCNICO: Solo interacciones del catálogo
          final interactions = events.where((e) => 
            e.eventType == EventType.quoteNegotiation || 
            e.eventType == EventType.clientBooking
          ).toList();

          if (interactions.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: interactions.length,
            itemBuilder: (context, index) {
              final event = interactions[index];
              return _buildNotificationCard(context, event, accentColor);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: accentColor)),
        error: (err, stack) => Center(
          child: Text(
            "Error al cargar notificaciones: $err", 
            style: const TextStyle(color: Colors.redAccent)
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AgendaEvent event, Color accentColor) {
    // Identificamos el estado para resaltar visualmente
    final bool isNegotiation = event.eventType == EventType.quoteNegotiation;
    final bool needsApproval = event.eventStatus == EventStatus.pendingApproval;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          // CORRECCIÓN: Usamos .withValues(alpha: ...) en lugar de .withOpacity
          color: needsApproval 
              ? Colors.orangeAccent.withValues(alpha: 0.3) 
              : accentColor.withValues(alpha: 0.1),
          width: needsApproval ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          // CORRECCIÓN: .withValues para evitar pérdida de precisión cromática
          backgroundColor: needsApproval 
              ? Colors.orangeAccent.withValues(alpha: 0.1) 
              : accentColor.withValues(alpha: 0.1),
          child: Icon(
            isNegotiation ? Icons.request_quote_outlined : Icons.event_available,
            color: needsApproval ? Colors.orangeAccent : accentColor,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isNegotiation ? "SOLICITUD DE PRESUPUESTO" : "NUEVA CITA AGENDADA",
              style: TextStyle(
                color: needsApproval ? Colors.orangeAccent : accentColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              event.title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.white38),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEEE d MMMM, HH:mm', 'es_ES').format(event.startTime),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
            // Mostramos los servicios si existen en la metadata
            if (event.metadata != null && event.metadata!['services'] != null) ...[
              const SizedBox(height: 8),
              Text(
                "Servicios: ${(event.metadata!['services'] as List).map((s) => s['name']).join(', ')}",
                style: const TextStyle(color: Colors.white60, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
        onTap: () => _navigateToDetail(context, event),
      ),
    );
  }

  Widget _buildEmptyState() {
    // CORRECCIÓN: Eliminado 'const' innecesario para resolver warning
    return Center( 
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_off_outlined, size: 64, color: Colors.white10),
          const SizedBox(height: 16),
          const Text(
            "No hay interacciones recientes",
            style: TextStyle(color: Colors.white24, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context, AgendaEvent event) {
    // Aquí es donde implementarás la pantalla de contraoferta
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Ver detalles de: ${event.title}"),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
    );
  }
}