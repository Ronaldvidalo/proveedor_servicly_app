import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:proveedor_servicly_app/core/services/agenda_service.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/features/agenda/viewmodels/agenda_view_model.dart';
import 'package:proveedor_servicly_app/features/agenda/data/models/agenda_event_model.dart';
import 'package:proveedor_servicly_app/features/agenda/presentation/screens/add_edit_event_screen.dart';

class AgendaScreen extends StatelessWidget {
  final UserModel user;

  const AgendaScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AgendaViewModel(
        agendaService: context.read<AgendaService>(),
        userId: user.uid,
      )..fetchEvents(),
      child: _AgendaView(user: user),
    );
  }
}

class _AgendaView extends StatelessWidget {
  final UserModel user;
  const _AgendaView({required this.user});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AgendaViewModel>();
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Mi Jornada'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          TableCalendar<AgendaEvent>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: viewModel.focusedDay,
            selectedDayPredicate: (day) => isSameDay(viewModel.selectedDay, day),
            calendarFormat: viewModel.calendarFormat,
            eventLoader: viewModel.getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            onDaySelected: viewModel.onDaySelected,
            onFormatChanged: viewModel.onFormatChanged,
            onPageChanged: viewModel.onPageChanged,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
            ),
            calendarStyle: CalendarStyle(
              defaultTextStyle: const TextStyle(color: Colors.white70),
              weekendTextStyle: const TextStyle(color: accentColor),
              todayDecoration: BoxDecoration(
                color: accentColor.withAlpha(100),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: accentColor.withAlpha(150),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: ValueListenableBuilder<List<AgendaEvent>>(
              valueListenable: viewModel.selectedEvents,
              builder: (context, value, _) {
                if (value.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay eventos para este día.',
                      style: TextStyle(color: Colors.white60, fontSize: 16),
                    ),
                  );
                }
                value.sort((a, b) => a.startTime.compareTo(b.startTime));
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    return _EventCard(event: value[index], user: user);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final agendaViewModel = context.read<AgendaViewModel>();
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: agendaViewModel,
              child: AddEditEventScreen(
                selectedDay: viewModel.selectedDay ?? DateTime.now(),
                user: user,
              ),
            ),
          ));
        },
        backgroundColor: accentColor,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final AgendaEvent event;
  final UserModel user;

  const _EventCard({required this.event, required this.user});

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).primaryColor;
    final isVisit = event.eventType == EventType.visit;
    final isCancelled = event.eventStatus == EventStatus.cancelled;

    final cardColor = isCancelled ? const Color(0xFF2d343a) : (isVisit ? const Color(0xFF2D2D5A) : const Color(0xFF2a3b4a));
    final iconData = isVisit ? Icons.business_center_outlined : Icons.person_outline;
    
    final timeFormat = DateFormat('HH:mm');
    final timeRange = '${timeFormat.format(event.startTime)} - ${timeFormat.format(event.endTime)}';
    
    final textColor = isCancelled ? Colors.white38 : Colors.white;

    return InkWell(
      // --- MODIFICACIÓN CLAVE ---
      // Al tocar, se abre un diálogo de opciones.
      onTap: () => _showEventOptionsDialog(context, event, user),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: isCancelled ? Colors.grey : accentColor, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  timeRange,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (event.description != null && event.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        event.description!,
                        style: TextStyle(color: textColor.withAlpha(180)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Icon(iconData, color: isCancelled ? Colors.grey : accentColor),
            ],
          ),
        ),
      ),
    );
  }
}

/// Muestra un diálogo con opciones para editar o cancelar un evento.
void _showEventOptionsDialog(BuildContext context, AgendaEvent event, UserModel user) {
  final viewModel = context.read<AgendaViewModel>();

  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: const Color(0xFF2D2D5A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(event.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('¿Qué deseas hacer con este evento?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
          if (event.eventStatus != EventStatus.cancelled) ...[
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.orange.shade300),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Cierra el menú de opciones
                try {
                  await viewModel.cancelEvent(event);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Evento cancelado.'), backgroundColor: Colors.orange),
                  );
                } catch (e) {
                   ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al cancelar: $e'), backgroundColor: Colors.redAccent),
                    );
                }
              },
              child: const Text('Cancelar Evento'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Cierra el menú de opciones
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: viewModel,
                    child: AddEditEventScreen(
                      selectedDay: event.startTime,
                      user: user,
                      eventToEdit: event, // Pasamos el evento para editar
                    ),
                  ),
                ));
              },
            ),
          ]
        ],
      );
    },
  );
}

