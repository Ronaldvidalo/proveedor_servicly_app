import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

// --- Modelos y Servicios ---
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/core/services/availability_service.dart';

class BookingScreen extends StatefulWidget {
  final String providerId;
  final List<ProductModel> selectedServices;

  const BookingScreen({
    super.key, 
    required this.providerId,
    this.selectedServices = const [],
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<DateTime> _availableSlots = [];
  bool _isLoadingSlots = false;
  bool _hasError = false;

  // ✅ CONTROL DE FLUJO: Evita que el build dispare la carga infinitamente
  DateTime? _lastProcessedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  /// 🔍 LÓGICA DE BÚSQUEDA PROACTIVA: Encuentra la cita más cercana disponible
  Future<void> _findNextAvailable(ProviderProfileModel profile) async {
    setState(() => _isLoadingSlots = true);
    final service = context.read<AvailabilityService>();
    
    // Escaneamos los próximos 30 días buscando el primer hueco libre
    for (int i = 0; i < 30; i++) {
      DateTime checkDate = DateTime.now().add(Duration(days: i));
      
      // Solo revisamos si el día está en su horario laboral
      if (profile.weeklySchedule?.containsKey(checkDate.weekday) ?? false) {
        try {
          final slots = await service.getAvailableSlots(profile: profile, date: checkDate);
          if (slots.isNotEmpty) {
            setState(() {
              _selectedDay = checkDate;
              _focusedDay = checkDate;
              _availableSlots = slots;
              _lastProcessedDay = checkDate;
              _isLoadingSlots = false;
              _hasError = false;
            });
            return;
          }
        } catch (e) {
          debugPrint("Error silencioso en búsqueda proactiva: $e");
        }
      }
    }

    if (mounted) {
      setState(() => _isLoadingSlots = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se encontraron turnos libres en los próximos 30 días."))
      );
    }
  }

  /// Carga los turnos para un día específico con protección de parpadeo
  Future<void> _loadAvailableSlots(ProviderProfileModel profile, DateTime date) async {
    // Si ya estamos procesando este día o estamos cargando, cancelamos la ejecución duplicada
    if (_isLoadingSlots || (_lastProcessedDay != null && isSameDay(_lastProcessedDay, date) && _availableSlots.isNotEmpty)) return;

    setState(() {
      _isLoadingSlots = true;
      _lastProcessedDay = date;
      _availableSlots = [];
    });
    
    try {
      final service = context.read<AvailabilityService>();
      final slots = await service.getAvailableSlots(profile: profile, date: date);
      
      if (mounted) {
        setState(() {
          _availableSlots = slots;
          _isLoadingSlots = false;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint("Error en motor de turnos: $e");
      if (mounted) {
        setState(() {
          _isLoadingSlots = false;
          _hasError = true;
        });
      }
    }
  }

  void _onSlotPressed(DateTime slot, ProviderProfileModel profile) {
    _showBookingConfirmationDialog(context, slot, profile);
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF0D0D1A);
    const cardColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00B2B2);
    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Agenda de Citas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: cardColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<ProviderProfileModel?>(
        stream: firestoreService.getCatalogStream(widget.providerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: accentColor));
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Error al conectar con el perfil.", style: TextStyle(color: Colors.white24)));
          }

          final profile = snapshot.data!;

          // Carga inicial controlada por estado local para evitar redibujados infinitos
          if (_lastProcessedDay == null && !_isLoadingSlots) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _loadAvailableSlots(profile, _selectedDay!));
          }

          return Column(
            children: [
              // --- CABECERA DE BÚSQUEDA RÁPIDA ---
              _buildQuickSearchHeader(profile, accentColor),

              // --- CALENDARIO CON INDICADORES VISUALES ---
              TableCalendar(
                locale: 'es_ES',
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 90)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _hasError = false;
                  });
                  _loadAvailableSlots(profile, selectedDay);
                },
                // ✅ DISEÑO TÉCNICO: Resaltamos los días que el proveedor SÍ trabaja
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final bool isWorkDay = profile.weeklySchedule?.containsKey(day.weekday) ?? false;
                    if (isWorkDay) {
                      return _buildWorkDayMarker(day, accentColor, false);
                    }
                    return null; 
                  },
                  disabledBuilder: (context, day, focusedDay) {
                    final bool isWorkDay = profile.weeklySchedule?.containsKey(day.weekday) ?? false;
                    if (isWorkDay) {
                      return _buildWorkDayMarker(day, accentColor, true);
                    }
                    return null;
                  },
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(color: Colors.white, fontSize: 16),
                  leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white54),
                  rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white54),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  selectedDecoration: const BoxDecoration(color: accentColor, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(color: accentColor.withValues(alpha: 0.2), shape: BoxShape.circle),
                  defaultTextStyle: const TextStyle(color: Colors.white38),
                  weekendTextStyle: TextStyle(color: Colors.redAccent.withValues(alpha: 0.5)),
                  disabledTextStyle: const TextStyle(color: Colors.white10),
                ),
                // ✅ Predicado: Si el horario está vacío habilitamos para ver el error, si tiene datos restringimos
                enabledDayPredicate: (day) {
                  if (profile.weeklySchedule == null || profile.weeklySchedule!.isEmpty) return true;
                  return profile.weeklySchedule!.containsKey(day.weekday);
                },
              ),

              const Divider(color: Colors.white10, height: 1),

              // --- LISTADO DINÁMICO DE TURNOS ---
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: cardColor.withValues(alpha: 0.3),
                  child: _isLoadingSlots 
                    ? const Center(child: CircularProgressIndicator(color: accentColor))
                    : (_hasError 
                        ? _buildErrorPlaceholder() 
                        : _buildAvailableSlotsGrid(profile, accentColor)),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  // ✅ WIDGET AUXILIAR PARA EL RESALTE TURQUESA DE DÍAS DISPONIBLES
  Widget _buildWorkDayMarker(DateTime day, Color accentColor, bool isDisabled) {
    return Container(
      margin: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        '${day.day}', 
        style: TextStyle(
          color: isDisabled ? Colors.white24 : Colors.white, 
          fontWeight: FontWeight.bold
        )
      ),
    );
  }

  Widget _buildQuickSearchHeader(ProviderProfileModel profile, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        border: Border(bottom: BorderSide(color: Colors.white10))
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Disponibilidad real", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              Text("Días resaltados = Laborables", style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          TextButton.icon(
            onPressed: () => _findNextAvailable(profile),
            icon: Icon(Icons.bolt, color: accentColor, size: 18),
            label: Text("BUSCAR PRÓXIMO", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
            style: TextButton.styleFrom(
              backgroundColor: accentColor.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableSlotsGrid(ProviderProfileModel profile, Color accentColor) {
    if (_availableSlots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, color: Colors.white10, size: 48),
            const SizedBox(height: 12),
            Text(
              profile.weeklySchedule?.isEmpty ?? true 
                ? "El profesional no ha configurado horarios." 
                : "No hay turnos disponibles para este día.",
              style: const TextStyle(color: Colors.white24, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, 
        childAspectRatio: 2.2, 
        crossAxisSpacing: 10, 
        mainAxisSpacing: 10
      ),
      itemCount: _availableSlots.length,
      itemBuilder: (context, index) {
        final slot = _availableSlots[index];
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor, 
            foregroundColor: Colors.white, 
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
          ),
          onPressed: () => _onSlotPressed(slot, profile),
          child: Text(DateFormat.Hm().format(slot), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        );
      },
    );
  }

  Widget _buildErrorPlaceholder() {
    return const Center(
      child: Text("Error al cargar la agenda.\nIntenta seleccionar el día de nuevo.", 
        textAlign: TextAlign.center, 
        style: TextStyle(color: Colors.white24, fontSize: 12)
      ),
    );
  }

  void _showBookingConfirmationDialog(BuildContext context, DateTime slot, ProviderProfileModel profile) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Confirmar Cita", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Agendar para el ${DateFormat('EEEE d MMMM', 'es_ES').format(slot)} a las ${DateFormat.Hm().format(slot)} hs.",
                    style: const TextStyle(color: Color(0xFF00B2B2), fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _buildInputDeco("Nombre completo", Icons.person_outline),
                    validator: (v) => (v == null || v.isEmpty) ? "Requerido" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.phone,
                    decoration: _buildInputDeco("WhatsApp", Icons.phone_android),
                    validator: (v) => (v == null || v.isEmpty) ? "Requerido" : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isProcessing ? null : () => Navigator.pop(dialogContext), 
              child: const Text("CANCELAR", style: TextStyle(color: Colors.white24))
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00B2B2)),
              onPressed: isProcessing ? null : () async {
                if (formKey.currentState!.validate()) {
                  setDialogState(() => isProcessing = true);
                  try {
                    await context.read<AvailabilityService>().createAppointment(
                      providerId: widget.providerId,
                      services: widget.selectedServices,
                      selectedDate: slot,
                      actionType: profile.actionType,
                    );
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      _showSuccessAnimation();
                    }
                  } catch (e) {
                    setDialogState(() => isProcessing = false);
                  }
                }
              }, 
              child: isProcessing 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("AGENDAR TURNO")
            )
          ],
        ),
      ),
    );
  }

  void _showSuccessAnimation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      isDismissible: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF00B2B2), size: 80),
            const SizedBox(height: 16),
            const Text("¡Cita Solicitada!", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              "El profesional ha sido notificado. Recibirás una confirmación en breve.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, 
              height: 54, 
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00B2B2)),
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst), 
                child: const Text("VOLVER AL INICIO", style: TextStyle(fontWeight: FontWeight.bold))
              )
            )
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF00B2B2), size: 18),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}