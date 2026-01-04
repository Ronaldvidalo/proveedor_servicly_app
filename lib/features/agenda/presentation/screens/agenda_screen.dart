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
import 'package:proveedor_servicly_app/features/agenda/presentation/screens/negotiation_detail_screen.dart';

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
    
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Colores técnicos de la infraestructura de reservas
    const accentColor = Color(0xFF00B2B2);
    const pendingColor = Colors.orangeAccent;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mi Jornada'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.today), 
            tooltip: "Ir a Hoy",
            color: accentColor, 
            onPressed: () => setState(() {
              _focusedDay = DateTime.now();
              _selectedDay = _focusedDay;
            })
          ),
        ],
      ),
      body: Column(
        children: [
          // --- 1. CALENDARIO CON MARCADORES INTELIGENTES ---
          TableCalendar<AgendaEvent>(
            locale: 'es_ES',
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

            eventLoader: (day) {
              return eventsAsync.maybeWhen(
                data: (events) => events.where((e) => isSameDay(e.startTime, day)).toList(),
                orElse: () => [],
              );
            },
            
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16, 
                fontWeight: FontWeight.bold
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: colorScheme.onSurface),
              rightChevronIcon: Icon(Icons.chevron_right, color: colorScheme.onSurface),
            ),
            
            // --- ✅ CONSTRUCCIÓN DE MARCADORES (Puntos de colores) ---
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, dayEvents) {
                if (dayEvents.isEmpty) return const SizedBox.shrink();

                // Detectamos si hay alguna negociación pendiente en el día
                final bool hasPending = dayEvents.any((e) => 
                  e.eventStatus == EventStatus.pendingApproval
                );

                return Positioned(
                  bottom: 1,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Naranja para urgencia, Turquesa para citas normales
                      color: hasPending ? pendingColor : accentColor,
                      boxShadow: [
                        BoxShadow(
                          color: (hasPending ? pendingColor : accentColor).withValues(alpha: 0.5),
                          blurRadius: 4,
                        )
                      ],
                    ),
                  ),
                );
              },
            ),

            calendarStyle: CalendarStyle(
              defaultTextStyle: TextStyle(color: colorScheme.onSurface),
              weekendTextStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
              outsideTextStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3)),
              
              selectedDecoration: const BoxDecoration(
                color: accentColor, 
                shape: BoxShape.circle
              ),
              selectedTextStyle: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
              
              todayDecoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.2), 
                shape: BoxShape.circle
              ),
              todayTextStyle: const TextStyle(color: accentColor, fontWeight: FontWeight.bold),
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
                _FilterChip(label: 'Negociaciones', isSelected: _filterType == 'negotiation', onTap: () => setState(() => _filterType = 'negotiation')),
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
              loading: () => const Center(child: CircularProgressIndicator(color: accentColor)),
              error: (e, _) => Center(child: Text("Error: $e", style: TextStyle(color: colorScheme.error))),
              data: (allEvents) {
                var dayEvents = allEvents.where((e) => isSameDay(e.startTime, _selectedDay)).toList();

                if (_filterType == 'visit') {
                  dayEvents = dayEvents.where((e) => e.eventType == EventType.visit || e.eventType == EventType.appointment || e.eventType == EventType.clientBooking).toList();
                } else if (_filterType == 'negotiation') {
                  dayEvents = dayEvents.where((e) => e.eventType == EventType.quoteNegotiation).toList();
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
                        // ✅ LÓGICA DE NAVEGACIÓN UNIFICADA
                        if (event.eventType == EventType.quoteNegotiation) {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => NegotiationDetailScreen(event: event),
                          ));
                        } else {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => AddEditEventScreen(
                              selectedDay: _selectedDay ?? DateTime.now(),
                              user: widget.user,
                              eventToEdit: event,
                            ),
                          ));
                        }
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
      
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentColor,
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const accentColor = Color(0xFF00B2B2);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : theme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.7), 
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;
    const accentColor = Color(0xFF00B2B2);

    Color stripeColor = accentColor; 
    IconData icon = Icons.event;

    // --- ACTUALIZACIÓN DE LÓGICA DE COLORES SEMÁNTICOS ---
    switch (event.eventType) {
      case EventType.visit:
      case EventType.clientBooking:
        stripeColor = Colors.green;
        icon = Icons.event_available;
        break;
      case EventType.quoteNegotiation:
        stripeColor = Colors.orangeAccent;
        icon = Icons.request_quote_outlined;
        break;
      case EventType.appointment:
        stripeColor = accentColor;
        icon = Icons.video_call;
        break;
      case EventType.paymentReminder:
        stripeColor = Colors.redAccent;
        icon = Icons.money_off;
        break;
      case EventType.collectionReminder:
        stripeColor = Colors.amber;
        icon = Icons.attach_money;
        break;
      default:
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
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
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
                Row(
                  children: [
                    if (event.eventStatus == EventStatus.pendingApproval)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.orangeAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                        child: const Text("PENDIENTE", style: TextStyle(color: Colors.orangeAccent, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    Expanded(
                      child: Text(
                        event.title, 
                        style: TextStyle(
                          color: onSurface, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 16,
                          decoration: event.eventStatus == EventStatus.cancelled ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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
          Icon(icon, color: stripeColor.withValues(alpha: 0.8)), 
        ],
      ),
    );
  }
}