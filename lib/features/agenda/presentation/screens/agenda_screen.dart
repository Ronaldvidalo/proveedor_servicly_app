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
    
    // QA FIX: Usar ThemeService
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // Fondo dinámico (Gris claro / Azul oscuro)
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mi Jornada'),
        backgroundColor: theme.scaffoldBackgroundColor, // Integrado con el fondo
        foregroundColor: colorScheme.onSurface, // Texto negro/blanco
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.today), 
            tooltip: "Ir a Hoy",
            color: colorScheme.primary, // Icono de acción con color de acento
            onPressed: () => setState(() {
              _focusedDay = DateTime.now();
              _selectedDay = _focusedDay;
            })
          ),
        ],
      ),
      body: Column(
        children: [
          // --- 1. CALENDARIO ADAPTATIVO ---
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
            
            // QA FIX: Estilos dinámicos para TableCalendar
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: TextStyle(
                color: colorScheme.onSurface, // Título del mes dinámico
                fontSize: 16, 
                fontWeight: FontWeight.bold
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: colorScheme.onSurface),
              rightChevronIcon: Icon(Icons.chevron_right, color: colorScheme.onSurface),
            ),
            calendarStyle: CalendarStyle(
              // Días normales
              defaultTextStyle: TextStyle(color: colorScheme.onSurface),
              // Fin de semana
              weekendTextStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
              // Días fuera del mes
              outsideTextStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3)),
              
              // Día Seleccionado (Círculo sólido color primario)
              selectedDecoration: BoxDecoration(
                color: colorScheme.primary, 
                shape: BoxShape.circle
              ),
              selectedTextStyle: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
              
              // Día de Hoy (Círculo transparente color primario)
              todayDecoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.3), 
                shape: BoxShape.circle
              ),
              todayTextStyle: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
              
              // Puntos de eventos (Markers)
              markerDecoration: BoxDecoration(
                color: colorScheme.secondary, // Fucsia/Verde según tema
                shape: BoxShape.circle
              ),
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
          Divider(color: theme.dividerColor, height: 1),

          // --- 3. LISTA DE EVENTOS ---
          Expanded(
            child: eventsAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: colorScheme.primary)),
              error: (e, _) => Center(child: Text("Error: $e", style: TextStyle(color: colorScheme.error))),
              data: (allEvents) {
                // Filtrado Local
                var dayEvents = allEvents.where((e) => isSameDay(e.startTime, _selectedDay)).toList();

                if (_filterType == 'visit') {
                  dayEvents = dayEvents.where((e) => e.eventType == EventType.visit || e.eventType == EventType.appointment).toList();
                } else if (_filterType == 'financial') {
                  dayEvents = dayEvents.where((e) => e.eventType == EventType.paymentReminder || e.eventType == EventType.collectionReminder).toList();
                }

                dayEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

                if (dayEvents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available, size: 48, color: colorScheme.onSurface.withValues(alpha: 0.2)),
                        const SizedBox(height: 12),
                        Text(
                          "Sin eventos para este día", 
                          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4))
                        ),
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
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => AddEditEventScreen(
                            selectedDay: _selectedDay ?? DateTime.now(),
                            user: widget.user,
                            eventToEdit: event,
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
        backgroundColor: colorScheme.primary,
        child: Icon(Icons.add, color: colorScheme.onPrimary),
        onPressed: () {
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
    // QA FIX: Colores dinámicos
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // Fondo: Primario si seleccionado, Surface (Tarjeta) si no
          color: isSelected ? colorScheme.primary : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : theme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            // Texto: OnPrimary (Negro/Blanco) si seleccionado, OnSurface si no
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface.withValues(alpha: 0.7), 
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
    // QA FIX: Obtener tema
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    // Mantenemos lógica de colores por tipo (Semántica de estado)
    // Usamos colores de Material que se ven bien en light/dark
    Color stripeColor = colorScheme.primary; 
    IconData icon = Icons.event;

    switch (event.eventType) {
      case EventType.visit:
        stripeColor = Colors.green; // Semántica OK
        icon = Icons.business_center;
        break;
      case EventType.appointment:
        stripeColor = colorScheme.primary; // Azul/Tema
        icon = Icons.video_call;
        break;
      case EventType.paymentReminder:
        stripeColor = Colors.redAccent; // Semántica OK
        icon = Icons.money_off;
        break;
      case EventType.collectionReminder:
        stripeColor = Colors.amber; // Semántica OK
        icon = Icons.attach_money;
        break;
      default: // personalReminder
        stripeColor = Colors.purpleAccent;
        icon = Icons.person;
    }

    if (event.eventStatus == EventStatus.cancelled) {
      stripeColor = Colors.grey;
      icon = Icons.cancel;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // QA FIX: Color de fondo de tarjeta del tema
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        // Sombra sutil
        boxShadow: [
           BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
        border: Border(left: BorderSide(color: stripeColor, width: 4)),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(DateFormat('HH:mm').format(event.startTime), 
                  style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
              Text(DateFormat('HH:mm').format(event.endTime), 
                  style: TextStyle(color: onSurface.withValues(alpha: 0.5), fontSize: 12)),
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
                    color: onSurface, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 16,
                    decoration: event.eventStatus == EventStatus.cancelled ? TextDecoration.lineThrough : null,
                  )
                ),
                if (event.description != null && event.description!.isNotEmpty)
                  Text(
                    event.description!, 
                    style: TextStyle(color: onSurface.withValues(alpha: 0.7), fontSize: 12), 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis
                  ),
              ],
            ),
          ),
          // QA FIX: Icono con color pero ajustado
          Icon(icon, color: stripeColor.withValues(alpha: 0.8)), 
        ],
      ),
    );
  }
}