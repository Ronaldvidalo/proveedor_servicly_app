import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/features/agenda/data/models/availability_model.dart';
import 'package:proveedor_servicly_app/features/agenda/data/models/time_slot_model.dart';
// Importamos los providers de la agenda (donde incluimos los de disponibilidad)
import 'package:proveedor_servicly_app/features/agenda/providers/agenda_providers.dart';

class SetAvailabilityScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const SetAvailabilityScreen({super.key, required this.user});

  @override
  ConsumerState<SetAvailabilityScreen> createState() => _SetAvailabilityScreenState();
}

class _SetAvailabilityScreenState extends ConsumerState<SetAvailabilityScreen> {
  // Orden visual de los días
  final List<String> _dayOrder = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
  final Map<String, String> _dayTranslations = {
    'monday': 'Lunes', 'tuesday': 'Martes', 'wednesday': 'Miércoles',
    'thursday': 'Jueves', 'friday': 'Viernes', 'saturday': 'Sábado', 'sunday': 'Domingo'
  };
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Inicializar datos por defecto si es la primera vez que entra
    // Usamos addPostFrameCallback para ejecutarlo después del build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(availabilityRepositoryProvider).initializeDefaultAvailability();
    });
  }

  Future<void> _saveDay(DayAvailability day) async {
    // No necesitamos setState global para esto, el cambio es local en el widget hijo
    // o optimista. Pero si queremos mostrar feedback:
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('Guardando...'), duration: Duration(milliseconds: 500), backgroundColor: Colors.blue),
    );

    try {
      await ref.read(availabilityRepositoryProvider).updateDayAvailability(day);
      if(mounted) {
         ScaffoldMessenger.of(context).hideCurrentSnackBar();
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Horario actualizado'), backgroundColor: Colors.green),
         );
      }
    } catch (e) {
      if(mounted) {
         ScaffoldMessenger.of(context).hideCurrentSnackBar();
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos el stream de disponibilidad
    final availabilityAsync = ref.watch(availabilityStreamProvider);
    
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Configurar Horarios'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: availabilityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: accentColor)),
        error: (e, _) => Center(child: Text("Error: $e", style: const TextStyle(color: Colors.red))),
        data: (daysList) {
          if (daysList.isEmpty) {
             // Si está vacío (aún no se inicializó), mostramos carga mientras el initState hace su trabajo
             return const Center(child: CircularProgressIndicator(color: accentColor));
          }

          // Convertimos la lista a un mapa para acceder fácil por nombre de día
          final Map<String, DayAvailability> daysMap = {
            for (var day in daysList) day.dayOfWeek: day
          };

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _dayOrder.length,
            itemBuilder: (context, index) {
              final dayKey = _dayOrder[index];
              // Si por alguna razón no existe el día en Firebase, usamos uno por defecto
              final dayData = daysMap[dayKey] ?? DayAvailability(dayOfWeek: dayKey);
              
              return _DayCard(
                dayName: _dayTranslations[dayKey]!,
                dayData: dayData,
                accentColor: accentColor,
                onUpdate: (updatedDay) => _saveDay(updatedDay),
              );
            },
          );
        },
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final String dayName;
  final DayAvailability dayData;
  final Color accentColor;
  final Function(DayAvailability) onUpdate;

  const _DayCard({required this.dayName, required this.dayData, required this.accentColor, required this.onUpdate});

  void _toggleDay(bool value) {
    // Creamos una copia o modificamos directamente (depende de inmutabilidad, aquí Firestore devuelve objetos mutables por ahora)
    dayData.isEnabled = value;
    onUpdate(dayData);
  }

  void _addSlot() {
    final lastEnd = dayData.workSlots.isNotEmpty ? dayData.workSlots.last.end : const TimeOfDay(hour: 9, minute: 0);
    // Nuevo slot de 1 hora después del último
    final newStart = TimeOfDay(hour: lastEnd.hour, minute: lastEnd.minute); 
    final newEnd = TimeOfDay(hour: lastEnd.hour + 1, minute: lastEnd.minute);
    
    dayData.workSlots.add(TimeSlot(start: newStart, end: newEnd));
    onUpdate(dayData);
  }

  void _removeSlot(int index) {
    dayData.workSlots.removeAt(index);
    onUpdate(dayData);
  }
  
  void _updateTime(int index, TimeOfDay newTime, bool isStart) {
    if (isStart) dayData.workSlots[index].start = newTime;
    else dayData.workSlots[index].end = newTime;
    onUpdate(dayData);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2D2D5A),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: dayData.isEnabled ? accentColor : Colors.transparent),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dayName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Switch(
                  value: dayData.isEnabled,
                  onChanged: _toggleDay,
                  activeColor: accentColor,
                ),
              ],
            ),
            if (dayData.isEnabled) ...[
              const Divider(color: Colors.white12),
              ...dayData.workSlots.asMap().entries.map((e) => _SlotRow(
                slot: e.value, 
                onDelete: () => _removeSlot(e.key),
                onUpdate: (time, isStart) => _updateTime(e.key, time, isStart),
              )),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Agregar Bloque"),
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
                onPressed: _addSlot,
              )
            ]
          ],
        ),
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  final TimeSlot slot;
  final VoidCallback onDelete;
  final Function(TimeOfDay, bool) onUpdate;

  const _SlotRow({required this.slot, required this.onDelete, required this.onUpdate});

  Future<void> _pickTime(BuildContext context, bool isStart) async {
    final picked = await showTimePicker(
      context: context, 
      initialTime: isStart ? slot.start : slot.end
    );
    if (picked != null) onUpdate(picked, isStart);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _TimeBtn(time: slot.start, onTap: () => _pickTime(context, true))),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("-", style: TextStyle(color: Colors.white))),
        Expanded(child: _TimeBtn(time: slot.end, onTap: () => _pickTime(context, false))),
        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: onDelete),
      ],
    );
  }
}

class _TimeBtn extends StatelessWidget {
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimeBtn({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(8)),
        child: Text(time.format(context), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}