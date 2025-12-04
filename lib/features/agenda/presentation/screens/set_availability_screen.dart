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
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(availabilityRepositoryProvider).initializeDefaultAvailability();
    });
  }

  Future<void> _saveDay(DayAvailability day) async {
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
    
    // QA FIX: Colores del tema
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // Fondo dinámico
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Configurar Horarios'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: availabilityAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.primary)),
        error: (e, _) => Center(child: Text("Error: $e", style: TextStyle(color: colorScheme.error))),
        data: (daysList) {
          if (daysList.isEmpty) {
             return Center(child: CircularProgressIndicator(color: colorScheme.primary));
          }

          final Map<String, DayAvailability> daysMap = {
            for (var day in daysList) day.dayOfWeek: day
          };

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _dayOrder.length,
            itemBuilder: (context, index) {
              final dayKey = _dayOrder[index];
              final dayData = daysMap[dayKey] ?? DayAvailability(dayOfWeek: dayKey);
              
              return _DayCard(
                dayName: _dayTranslations[dayKey]!,
                dayData: dayData,
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
  final Function(DayAvailability) onUpdate;

  const _DayCard({required this.dayName, required this.dayData, required this.onUpdate});

  void _toggleDay(bool value) {
    dayData.isEnabled = value;
    onUpdate(dayData);
  }

  void _addSlot() {
    final lastEnd = dayData.workSlots.isNotEmpty ? dayData.workSlots.last.end : const TimeOfDay(hour: 9, minute: 0);
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
    if (isStart) {
      dayData.workSlots[index].start = newTime;
    } else {
      dayData.workSlots[index].end = newTime;
    }
    onUpdate(dayData);
  }

  @override
  Widget build(BuildContext context) {
    // QA FIX: Colores del tema
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = colorScheme.primary;

    return Card(
      // QA FIX: Color de tarjeta dinámico
      color: theme.cardTheme.color,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // Borde visible si está habilitado
        side: BorderSide(color: dayData.isEnabled ? accentColor : Colors.transparent),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dayName, style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                Switch(
                  value: dayData.isEnabled,
                  onChanged: _toggleDay,
                  activeThumbColor: accentColor,
                ),
              ],
            ),
            if (dayData.isEnabled) ...[
              Divider(color: theme.dividerColor),
              ...dayData.workSlots.asMap().entries.map((e) => _SlotRow(
                slot: e.value, 
                onDelete: () => _removeSlot(e.key),
                onUpdate: (time, isStart) => _updateTime(e.key, time, isStart),
              )),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Agregar Bloque"),
                style: TextButton.styleFrom(foregroundColor: colorScheme.onSurface.withValues(alpha: 0.7)),
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
    // QA FIX: Necesitamos el tema para los textos
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Expanded(child: _TimeBtn(time: slot.start, onTap: () => _pickTime(context, true))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text("-", style: TextStyle(color: theme.colorScheme.onSurface))),
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
    // QA FIX: Colores del tema
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          // QA FIX: Fondo del botón de hora es ligeramente distinto al fondo de la tarjeta
          color: theme.scaffoldBackgroundColor, 
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dividerColor)
        ),
        child: Text(
          time.format(context), 
          style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)
        ),
      ),
    );
  }
}