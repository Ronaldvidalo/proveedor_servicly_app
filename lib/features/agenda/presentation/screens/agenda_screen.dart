import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

// --- Modelos ---
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/features/agenda/data/models/agenda_event_model.dart';

// --- Providers ---
import 'package:proveedor_servicly_app/features/agenda/providers/agenda_providers.dart';

// --- Pantallas ---
import 'package:proveedor_servicly_app/features/agenda/presentation/screens/add_edit_event_screen.dart';

class AgendaScreen extends ConsumerStatefulWidget {
  final UserModel user;
  const AgendaScreen({super.key, required this.user});

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  String _filterType = 'all'; 

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos los eventos del mes
    final eventsAsync = ref.watch(eventsForMonthProvider(_focusedDay));
    
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Mi Jornada'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.today), 
            tooltip: "Ir a Hoy",
            onPressed: () => setState(() {
              _focusedDay = DateTime.now();
              _selectedDay = _focusedDay;
            })
          ),
        ],
      ),
      body: Column(
        children: [
          // --- 1. CALENDARIO ---
          TableCalendar<AgendaEvent>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            startingDayOfWeek: StartingDayOfWeek.monday,
            
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
            onFormatChanged: (format) => setState(() => _calendarFormat = format),

            // Cargador de eventos (puntos)
            eventLoader: (day) {
              return eventsAsync.maybeWhen(
                data: (events) => events.where((e) => isSameDay(e.startTime, day)).toList(),
                orElse: () => [],
              );
            },
            
            // Estilos Cyber Glow
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
            ),
            calendarStyle: CalendarStyle(
              defaultTextStyle: const TextStyle(color: Colors.white70),
              weekendTextStyle: const TextStyle(color: Colors.white70),
              outsideTextStyle: const TextStyle(color: Colors.white24),
              selectedDecoration: const BoxDecoration(color: accentColor, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: accentColor.withAlpha(77), shape: BoxShape.circle), // 0.3 opacity
              markerDecoration: const BoxDecoration(color: Color(0xFF00FF7F), shape: BoxShape.circle),
            ),
          ),
          
          const SizedBox(height: 10),
          
          // --- 2. FILTROS ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(label: 'Todo', isSelected: _filterType == 'all', onTap: () => setState(() => _filterType = 'all')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Citas', isSelected: _filterType == 'visit', onTap: () => setState(() => _filterType = 'visit')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Finanzas', isSelected: _filterType == 'financial', onTap: () => setState(() => _filterType = 'financial')),
              ],
            ),
          ),
          
          const SizedBox(height: 10),
          const Divider(color: Colors.white10, height: 1),

          // --- 3. LISTA DE EVENTOS ---
          Expanded(
            child: eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: accentColor)),
              error: (e, _) => Center(child: Text("Error: $e", style: const TextStyle(color: Colors.red))),
              data: (allEvents) {
                // Filtrado Local
                var dayEvents = allEvents.where((e) => isSameDay(e.startTime, _selectedDay)).toList();

                if (_filterType == 'visit') {
                  dayEvents = dayEvents.where((e) => e.eventType == EventType.visit || e.eventType == EventType.appointment).toList();
                } else if (_filterType == 'financial') {
                  dayEvents = dayEvents.where((e) => e.eventType == EventType.payment_reminder || e.eventType == EventType.collection_reminder).toList();
                }

                dayEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

                if (dayEvents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available, size: 48, color: Colors.white.withAlpha(50)),
                        const SizedBox(height: 12),
                        const Text("Sin eventos para este día", style: TextStyle(color: Colors.white38)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: dayEvents.length,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  itemBuilder: (context, index) {
                    final event = dayEvents[index];
                    return GestureDetector(
                      onTap: () {
                        // Navegar a editar evento existente
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => AddEditEventScreen(
                            selectedDay: _selectedDay ?? DateTime.now(),
                            user: widget.user,
                            eventToEdit: event, // Pasamos el evento para editar
                          ),
                        ));
                      },
                      child: _AgendaEventCard(event: event),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      
      // --- 4. BOTÓN FLOTANTE (FAB) ---
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentColor,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () {
          // Navegar a crear NUEVO evento
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => AddEditEventScreen(
              selectedDay: _selectedDay ?? DateTime.now(),
              user: widget.user,
            ),
          ));
        },
      ),
    );
  }
}

// --- WIDGETS AUXILIARES ---
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00BFFF) : const Color(0xFF2D2D5A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.white10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70, 
            fontWeight: FontWeight.bold, 
            fontSize: 12
          ),
        ),
      ),
    );
  }
}

class _AgendaEventCard extends StatelessWidget {
  final AgendaEvent event;
  const _AgendaEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    Color stripeColor = const Color(0xFF00BFFF);
    IconData icon = Icons.event;

    // Lógica de Colores e Iconos según Tipo
    switch (event.eventType) {
      case EventType.visit:
        stripeColor = const Color(0xFF00FF7F); // Verde
        icon = Icons.business_center;
        break;
      case EventType.appointment:
        stripeColor = const Color(0xFF00BFFF); // Azul
        icon = Icons.video_call;
        break;
      case EventType.payment_reminder:
        stripeColor = Colors.redAccent; // Rojo
        icon = Icons.money_off;
        break;
      case EventType.collection_reminder:
        stripeColor = Colors.amber; // Amarillo
        icon = Icons.attach_money;
        break;
      default: // personal_reminder
        stripeColor = Colors.purpleAccent;
        icon = Icons.person;
    }

    // Estilo para cancelados
    if (event.eventStatus == EventStatus.cancelled) {
      stripeColor = Colors.grey;
      icon = Icons.cancel;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D5A),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: stripeColor, width: 4)),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(DateFormat('HH:mm').format(event.startTime), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(DateFormat('HH:mm').format(event.endTime), style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title, 
                  style: TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 16,
                    decoration: event.eventStatus == EventStatus.cancelled ? TextDecoration.lineThrough : null,
                  )
                ),
                if (event.description != null && event.description!.isNotEmpty)
                  Text(event.description!, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Icon(icon, color: stripeColor.withAlpha(180)), // 0.7 opacity aprox
        ],
      ),
    );
  }
}