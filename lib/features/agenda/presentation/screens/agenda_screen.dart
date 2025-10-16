import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:proveedor_servicly_app/core/services/agenda_service.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/features/agenda/viewmodels/agenda_view_model.dart';
import 'package:proveedor_servicly_app/features/agenda/data/models/agenda_event_model.dart';
import 'package:proveedor_servicly_app/features/agenda/presentation/screens/dd_edit_event_screen.dart';


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
      // Le pasamos el usuario a la vista interna.
      child: _AgendaView(user: user),
    );
  }
}

class _AgendaView extends StatelessWidget {
  // Recibimos el usuario para poder pasarlo en la navegación.
  final UserModel user;
  const _AgendaView({required this.user});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AgendaViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Jornada'),
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
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ValueListenableBuilder<List<AgendaEvent>>(
              valueListenable: viewModel.selectedEvents,
              builder: (context, value, _) {
                if (value.isEmpty) {
                  return const Center(child: Text('No hay eventos para este día.'));
                }
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    final event = value[index];
                    return ListTile(
                      leading: Icon(
                        event.eventType == EventType.visit 
                          ? Icons.business_center_outlined 
                          : Icons.person_outline,
                        color: Theme.of(context).primaryColor,
                      ),
                      title: Text(event.title),
                      subtitle: Text(event.description ?? ''),
                    );
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
                // --- MODIFICACIÓN CLAVE ---
                // Le pasamos el usuario a la pantalla del formulario.
                user: user,
              ),
            ),
          ));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

