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

  // --- Lógica de filtrado ---
  List<AgendaEvent> _getFilteredEvents(List<AgendaEvent> allEvents) {
    var dayEvents = allEvents.where((e) => isSameDay(e.startTime, _selectedDay)).toList();

    if (_filterType == 'visit') {
      dayEvents = dayEvents.where((e) => e.eventType == EventType.visit || e.eventType == EventType.appointment || e.eventType == EventType.clientBooking).toList();
    } else if (_filterType == 'negotiation') {
      dayEvents = dayEvents.where((e) => e.eventType == EventType.quoteNegotiation).toList();
    } else if (_filterType == 'financial') {
      dayEvents = dayEvents.where((e) => e.eventType == EventType.paymentReminder || e.eventType == EventType.collectionReminder).toList();
    }

    dayEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
    return dayEvents;
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsForMonthProvider(_focusedDay));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
            }),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWebLayout = constraints.maxWidth > 900;

          // 1. WIDGET CALENDARIO
          final calendarWidget = TableCalendar<AgendaEvent>(
            locale: 'es_ES',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            startingDayOfWeek: StartingDayOfWeek.monday,
            
            // Altura de filas
            rowHeight: isWebLayout ? 70.0 : 52.0, 
            daysOfWeekHeight: isWebLayout ? 40.0 : 16.0,
            
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
              formatButtonVisible: !isWebLayout, 
              titleTextStyle: TextStyle(
                color: colorScheme.onSurface,
                fontSize: isWebLayout ? 24 : 16,
                fontWeight: FontWeight.bold
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: colorScheme.onSurface),
              rightChevronIcon: Icon(Icons.chevron_right, color: colorScheme.onSurface),
            ),

            // --- CORRECCIÓN AQUÍ: weekdayStyle y weekendStyle (sin 'Text') ---
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
              weekendStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.8), fontWeight: FontWeight.bold),
            ),

            // --- CalendarStyle SÍ usa 'TextStyle' en el nombre ---
            calendarStyle: CalendarStyle(
              // Texto base
              defaultTextStyle: TextStyle(color: colorScheme.onSurface, fontSize: isWebLayout ? 16 : 14),
              weekendTextStyle: TextStyle(color: colorScheme.onSurface, fontSize: isWebLayout ? 16 : 14), 
              outsideTextStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3)),
              
              // Selección
              selectedDecoration: const BoxDecoration(color: accentColor, shape: BoxShape.circle),
              selectedTextStyle: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              
              // Hoy
              todayDecoration: BoxDecoration(color: accentColor.withValues(alpha: 0.2), shape: BoxShape.circle),
              todayTextStyle: const TextStyle(color: accentColor, fontWeight: FontWeight.bold),
            ),

            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, dayEvents) {
                if (dayEvents.isEmpty) return const SizedBox.shrink();
                final bool hasPending = dayEvents.any((e) => e.eventStatus == EventStatus.pendingApproval);
                return Positioned(
                  bottom: 8,
                  child: Container(
                    width: isWebLayout ? 8 : 6,
                    height: isWebLayout ? 8 : 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
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
          );

          // 2. WIDGET FILTROS
          final filtersWidget = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: isWebLayout ? 0 : 16),
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
          );

          // 3. WIDGET LISTA DE EVENTOS
          final eventsListWidget = Expanded(
            child: eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: accentColor)),
              error: (e, _) => Center(child: Text("Error: $e", style: TextStyle(color: colorScheme.error))),
              data: (allEvents) {
                final dayEvents = _getFilteredEvents(allEvents);

                if (dayEvents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available, size: 64, color: colorScheme.onSurface.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text(
                          "Sin eventos para este día", 
                          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 16)
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: dayEvents.length,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: isWebLayout ? 0 : 16),
                  itemBuilder: (context, index) {
                    final event = dayEvents[index];
                    return _AgendaEventCard(
                      event: event, 
                      onTap: () {
                        if (event.eventType == EventType.quoteNegotiation) {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => NegotiationDetailScreen(event: event)));
                        } else {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEditEventScreen(
                            selectedDay: _selectedDay ?? DateTime.now(),
                            user: widget.user,
                            eventToEdit: event,
                          )));
                        }
                      },
                    );
                  },
                );
              },
            ),
          );

          // ========================
          // 🖥️ DISEÑO WEB
          // ========================
          if (isWebLayout) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- PANEL IZQUIERDO (30%): AGENDA (SÓLIDO) ---
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(24, 24, 0, 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color, // Sólido
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(2, 0))
                      ]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedDay != null 
                            ? DateFormat('EEEE, d MMMM', 'es_ES').format(_selectedDay!).toUpperCase() 
                            : 'HOY',
                          style: TextStyle(
                            fontSize: 20, 
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: colorScheme.onSurface
                          ),
                        ),
                        const SizedBox(height: 24),
                        filtersWidget,
                        const SizedBox(height: 24),
                        Divider(color: theme.dividerColor.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        eventsListWidget, 
                      ],
                    ),
                  ),
                ),

                // --- PANEL DERECHO (70%): CALENDARIO (CON BORDES) ---
                Expanded(
                  flex: 7,
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.transparent, // Transparente
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.3), // Borde visible
                        width: 1.5
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        calendarWidget,
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegendItem(accentColor, "Confirmado"),
                            const SizedBox(width: 24),
                            _buildLegendItem(pendingColor, "Pendiente de Aprobación"),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          // ========================
          // 📱 DISEÑO MÓVIL
          // ========================
          return Column(
            children: [
              calendarWidget,
              const SizedBox(height: 10),
              filtersWidget,
              const SizedBox(height: 10),
              Divider(color: theme.dividerColor, height: 1),
              eventsListWidget,
            ],
          );
        },
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

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 10, height: 10, 
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
      ],
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const accentColor = Color(0xFF00B2B2);

    return InkWell( 
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      hoverColor: accentColor.withValues(alpha: 0.1),
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
  final VoidCallback onTap;
  
  const _AgendaEventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;
    const accentColor = Color(0xFF00B2B2);

    Color stripeColor = accentColor;
    IconData icon = Icons.event;

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
      child: Material(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        elevation: 0, 
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: stripeColor.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: stripeColor, width: 4)),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
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
          ),
        ),
      ),
    );
  }
}