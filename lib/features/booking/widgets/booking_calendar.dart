import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Modelos y Servicios
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/services/availability_service.dart';

class BookingCalendar extends StatefulWidget {
  final String providerId;
  final ProviderProfileModel profile;
  final List<ProductModel> selectedServices;

  const BookingCalendar({
    super.key,
    required this.providerId,
    required this.profile,
    required this.selectedServices,
  });

  @override
  State<BookingCalendar> createState() => _BookingCalendarState();
}

class _BookingCalendarState extends State<BookingCalendar> {
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedTime;
  bool _isLoadingSlots = false;
  List<DateTime> _availableSlots = [];

  @override
  void initState() {
    super.initState();
    _loadSlotsForDate(_selectedDate);
  }

  /// Carga los huecos disponibles usando el motor de disponibilidad
  Future<void> _loadSlotsForDate(DateTime date) async {
    setState(() => _isLoadingSlots = true);
    
    final availabilityService = context.read<AvailabilityService>();
    final slots = await availabilityService.getAvailableSlots(
      profile: widget.profile,
      date: date,
    );

    setState(() {
      _availableSlots = slots;
      _isLoadingSlots = false;
      _selectedTime = null; // Resetear hora al cambiar de día
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. SELECTOR DE DÍAS (Horizontal)
        _buildDateSelector(),
        
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            "Seleccioná un horario",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),

        // 2. CUADRÍCULA DE TURNOS (Grid)
        Expanded(
          child: _isLoadingSlots 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF00B2B2)))
            : _buildSlotsGrid(),
        ),

        // 3. BOTÓN DE ACCIÓN FINAL
        _buildConfirmButton(),
      ],
    );
  }

  Widget _buildDateSelector() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 14, // Mostramos las próximas 2 semanas
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final bool isSelected = DateUtils.isSameDay(_selectedDate, date);
          
          // Verificamos si el proveedor trabaja ese día
          final bool worksThisDay = widget.profile.weeklySchedule?.containsKey(date.weekday) ?? false;

          return GestureDetector(
            onTap: worksThisDay ? () {
              setState(() => _selectedDate = date);
              _loadSlotsForDate(date);
            } : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 65,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF00B2B2) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: worksThisDay ? (isSelected ? Colors.transparent : Colors.green.withOpacity(0.3)) : Colors.transparent,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E', 'es_ES').format(date).toUpperCase(),
                    style: TextStyle(color: isSelected ? Colors.white : Colors.white38, fontSize: 10),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${date.day}",
                    style: TextStyle(
                      color: isSelected ? Colors.white : (worksThisDay ? Colors.white : Colors.white10),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlotsGrid() {
    if (_availableSlots.isEmpty) {
      return const Center(
        child: Text("No hay turnos disponibles para este día", style: TextStyle(color: Colors.white24)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 2.2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: _availableSlots.length,
      itemBuilder: (context, index) {
        final slot = _availableSlots[index];
        final bool isSelected = _selectedTime == slot;

        return GestureDetector(
          onTap: () => setState(() => _selectedTime = slot),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF00B2B2) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isSelected ? Colors.transparent : Colors.white10),
            ),
            child: Text(
              DateFormat('HH:mm').format(slot),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfirmButton() {
    final bool isAgenda = widget.profile.actionType == 'booking';
    final bool canConfirm = _selectedTime != null;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: canConfirm ? const Color(0xFF00B2B2) : Colors.white10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: canConfirm ? _processFinalBooking : null,
          child: Text(
            isAgenda ? "CONFIRMAR TURNO" : "ENVIAR PROPUESTA TENTATIVA",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _processFinalBooking() async {
    final availabilityService = context.read<AvailabilityService>();
    
    // Mostramos cargando
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF00B2B2))),
    );

    try {
      // 1. Ejecutar persistencia y notificación Push
      await availabilityService.createAppointment(
        providerId: widget.providerId,
        services: widget.selectedServices,
        selectedDate: _selectedTime!,
        actionType: widget.profile.actionType,
      );

      if (!mounted) return;
      Navigator.pop(context); // Quitar cargando
      
      // 2. Pantalla de Éxito
      _showSuccessSheet();
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      isDismissible: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: Color(0xFF00B2B2), size: 80),
            const SizedBox(height: 20),
            const Text("¡Solicitud Enviada!", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              widget.profile.actionType == 'booking'
                ? "Tu cita ha sido agendada con éxito. Recibirás un recordatorio pronto."
                : "El profesional ha recibido tu propuesta técnica y se pondrá en contacto para confirmar.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text("VOLVER AL CATÁLOGO", style: TextStyle(color: Color(0xFF00B2B2))),
              ),
            )
          ],
        ),
      ),
    );
  }
}