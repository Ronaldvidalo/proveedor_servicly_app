import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:proveedor_servicly_app/core/services/availability_service.dart';
import 'package:proveedor_servicly_app/core/services/agenda_service.dart';
import 'package:proveedor_servicly_app/features/agenda/data/models/agenda_event_model.dart';
import 'package:proveedor_servicly_app/features/agenda/data/models/availability_model.dart';

class BookingScreen extends StatefulWidget {
  final String providerId;

  const BookingScreen({super.key, required this.providerId});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late Future<Map<String, DayAvailability>> _availabilityFuture;
  Map<String, DayAvailability> _availability = {};
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  final int _slotDuration = 60; // Duración de cada turno en minutos.

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _availabilityFuture = context.read<AvailabilityService>().getAvailability(widget.providerId);
  }
  
  void _onSlotPressed(DateTime slot) {
    _showBookingConfirmationDialog(context, slot);
  }
  
  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Seleccionar Turno'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, DayAvailability>>(
        future: _availabilityFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('No se pudo cargar la disponibilidad.', style: TextStyle(color: Colors.white70)));
          }
          
          _availability = snapshot.data!;
          
          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 60)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
                  leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                  rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
                ),
                 calendarStyle: const CalendarStyle(
                  defaultTextStyle: TextStyle(color: Colors.white70),
                  weekendTextStyle: TextStyle(color: accentColor),
                  todayDecoration: BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              Expanded(
                child: _buildAvailableSlots(),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Construye la lista de turnos disponibles para el día seleccionado.
  Widget _buildAvailableSlots() {
    if (_selectedDay == null) return const SizedBox.shrink();

    return StreamBuilder<List<AgendaEvent>>(
      stream: context.read<AgendaService>().getEventsForMonth(widget.providerId, _selectedDay!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final bookedEvents = snapshot.data!;
        final availableSlots = _calculateAvailableSlots(_selectedDay!, bookedEvents);
        
        if (availableSlots.isEmpty) {
          return const Center(child: Text('No hay turnos disponibles para este día.', style: TextStyle(color: Colors.white70)));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: availableSlots.length,
          itemBuilder: (context, index) {
            final slot = availableSlots[index];
            return OutlinedButton(
              onPressed: () => _onSlotPressed(slot),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF00BFFF)),
              child: Text(DateFormat.jm().format(slot)),
            );
          },
        );
      },
    );
  }

  /// La "magia" para calcular los turnos libres.
  List<DateTime> _calculateAvailableSlots(DateTime day, List<AgendaEvent> bookedEvents) {
    final List<DateTime> slots = [];
    final dayKey = DateFormat('EEEE').format(day).toLowerCase();
    final dayAvailability = _availability[dayKey];

    if (dayAvailability == null || !dayAvailability.isEnabled) {
      return slots; // El proveedor no trabaja este día
    }

    for (final workSlot in dayAvailability.workSlots) {
      DateTime slotTime = DateTime(day.year, day.month, day.day, workSlot.start.hour, workSlot.start.minute);
      final endTime = DateTime(day.year, day.month, day.day, workSlot.end.hour, workSlot.end.minute);

      while (slotTime.add(Duration(minutes: _slotDuration)).isBefore(endTime) || slotTime.add(Duration(minutes: _slotDuration)).isAtSameMomentAs(endTime)) {
        
        // Comprobar si el turno está en el futuro
        if (slotTime.isAfter(DateTime.now())) {
          // Comprobar si el turno se superpone con un evento ya agendado
          final isBooked = bookedEvents.any((event) => 
            slotTime.isBefore(event.endTime) && slotTime.add(Duration(minutes: _slotDuration)).isAfter(event.startTime)
          );

          if (!isBooked) {
            slots.add(slotTime);
          }
        }
        
        slotTime = slotTime.add(Duration(minutes: _slotDuration));
      }
    }
    return slots;
  }
}

// --- NUEVO MÉTODO ---
/// Muestra un diálogo de confirmación para que el cliente complete sus datos.
void _showBookingConfirmationDialog(BuildContext context, DateTime slot) {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  bool isBooking = false;

  showDialog(
    context: context,
    builder: (dialogContext) {
      final agendaService = dialogContext.read<AgendaService>();
      final providerId = (context.findAncestorWidgetOfExactType<BookingScreen>())!.providerId;
      
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2D2D5A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Confirmar Turno', style: TextStyle(color: Colors.white)),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estás a punto de reservar un turno para el:',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('EEEE d MMMM, HH:mm', 'es_ES').format(slot),
                      style: const TextStyle(color: Color(0xFF00BFFF), fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Tu Nombre'),
                      validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Tu Teléfono'),
                      keyboardType: TextInputType.phone,
                       validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: isBooking ? null : () async {
                  if (formKey.currentState!.validate()) {
                    setState(() => isBooking = true);
                    try {
                      await agendaService.createAppointmentByClient(
                        providerId: providerId,
                        startTime: slot,
                        durationInMinutes: 60, // Debería ser configurable
                        clientName: nameController.text,
                        clientPhone: phoneController.text,
                      );
                      Navigator.of(dialogContext).pop(); // Cierra el diálogo
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('¡Turno reservado con éxito!'), backgroundColor: Colors.green),
                      );
                    } catch (e) {
                      Navigator.of(dialogContext).pop();
                       ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al reservar: $e'), backgroundColor: Colors.redAccent),
                      );
                    }
                  }
                },
                child: isBooking ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Confirmar Turno'),
              ),
            ],
          );
        },
      );
    },
  );
}

