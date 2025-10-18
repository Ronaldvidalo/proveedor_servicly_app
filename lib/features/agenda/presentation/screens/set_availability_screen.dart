import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/availability_service.dart';
import 'package:proveedor_servicly_app/features/agenda/data/models/availability_model.dart';
import 'package:proveedor_servicly_app/features/agenda/data/models/time_slot_model.dart';


/// Una pantalla donde los proveedores pueden configurar sus horas de trabajo semanales.
class SetAvailabilityScreen extends StatefulWidget {
  final UserModel user;

  const SetAvailabilityScreen({super.key, required this.user});

  @override
  State<SetAvailabilityScreen> createState() => _SetAvailabilityScreenState();
}

class _SetAvailabilityScreenState extends State<SetAvailabilityScreen> {
  late Future<Map<String, DayAvailability>> _availabilityFuture;
  Map<String, DayAvailability> _availabilityData = {};
  bool _isLoading = false;

  final List<String> _dayOrder = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  ];
  final Map<String, String> _dayTranslations = {
    'monday': 'Lunes', 'tuesday': 'Martes', 'wednesday': 'Miércoles',
    'thursday': 'Jueves', 'friday': 'Viernes', 'saturday': 'Sábado', 'sunday': 'Domingo'
  };


  @override
  void initState() {
    super.initState();
    _availabilityFuture = context.read<AvailabilityService>().getAvailability(widget.user.uid);
  }

  Future<void> _saveAvailability() async {
    setState(() => _isLoading = true);
    final availabilityService = context.read<AvailabilityService>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Guardamos todos los días en un batch para eficiencia.
      for (final day in _availabilityData.values) {
        await availabilityService.updateDayAvailability(widget.user.uid, day);
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Disponibilidad guardada con éxito.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Configurar Disponibilidad'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          _isLoading
              ? const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white)))
              : IconButton(
                  icon: const Icon(Icons.save_alt_outlined),
                  tooltip: 'Guardar Cambios',
                  onPressed: _saveAvailability,
                ),
        ],
      ),
      body: FutureBuilder<Map<String, DayAvailability>>(
        future: _availabilityFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No se pudo cargar la configuración.', style: TextStyle(color: Colors.white70)));
          }

          if(_availabilityData.isEmpty) {
            _availabilityData = snapshot.data!;
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _dayOrder.length,
            itemBuilder: (context, index) {
              final dayKey = _dayOrder[index];
              final dayData = _availabilityData[dayKey]!;
              return _DayAvailabilityCard(
                dayName: _dayTranslations[dayKey]!,
                dayAvailability: dayData,
                onChanged: (updatedDayData) {
                  setState(() {
                    _availabilityData[dayKey] = updatedDayData;
                  });
                },
                accentColor: accentColor,
              );
            },
          );
        },
      ),
    );
  }
}

/// Una tarjeta para configurar la disponibilidad de un día de la semana.
class _DayAvailabilityCard extends StatelessWidget {
  final String dayName;
  final DayAvailability dayAvailability;
  final ValueChanged<DayAvailability> onChanged;
  final Color accentColor;

  const _DayAvailabilityCard({
    required this.dayName,
    required this.dayAvailability,
    required this.onChanged,
    required this.accentColor,
  });
  
  void _addSlot() {
    final lastEndTime = dayAvailability.workSlots.isNotEmpty 
      ? dayAvailability.workSlots.last.end 
      : const TimeOfDay(hour: 8, minute: 0);
      
    final newStart = TimeOfDay(hour: lastEndTime.hour + 1, minute: lastEndTime.minute);
    final newEnd = TimeOfDay(hour: lastEndTime.hour + 2, minute: lastEndTime.minute);

    dayAvailability.workSlots.add(TimeSlot(start: newStart, end: newEnd));
    onChanged(dayAvailability);
  }

  void _updateSlot(int index, TimeSlot newSlot) {
    dayAvailability.workSlots[index] = newSlot;
    onChanged(dayAvailability);
  }
  
  void _removeSlot(int index) {
    dayAvailability.workSlots.removeAt(index);
    onChanged(dayAvailability);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2D2D5A),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: dayAvailability.isEnabled ? accentColor : Colors.transparent, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dayName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Switch(
                  value: dayAvailability.isEnabled,
                  onChanged: (value) {
                    dayAvailability.isEnabled = value;
                    onChanged(dayAvailability);
                  },
                  activeColor: accentColor,
                ),
              ],
            ),
            if (dayAvailability.isEnabled) ...[
              const Divider(color: Colors.white24, height: 24),
              ...dayAvailability.workSlots.asMap().entries.map((entry) {
                int index = entry.key;
                TimeSlot slot = entry.value;
                return _TimeSlotTile(
                  slot: slot,
                  accentColor: accentColor,
                  onStartTimeChanged: (newTime) => _updateSlot(index, TimeSlot(start: newTime, end: slot.end)),
                  onEndTimeChanged: (newTime) => _updateSlot(index, TimeSlot(start: slot.start, end: newTime)),
                  onDelete: () => _removeSlot(index),
                );
              }).toList(),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _addSlot,
                icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
                label: const Text('Añadir bloque horario', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimeSlotTile extends StatelessWidget {
  final TimeSlot slot;
  final Color accentColor;
  final ValueChanged<TimeOfDay> onStartTimeChanged;
  final ValueChanged<TimeOfDay> onEndTimeChanged;
  final VoidCallback onDelete;

  const _TimeSlotTile({
    required this.slot,
    required this.accentColor,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
    required this.onDelete,
  });

  Future<void> _pickTime(BuildContext context, bool isStart) async {
    final initialTime = isStart ? slot.start : slot.end;
    final newTime = await showTimePicker(context: context, initialTime: initialTime);
    if (newTime != null) {
      if (isStart) {
        onStartTimeChanged(newTime);
      } else {
        onEndTimeChanged(newTime);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: _TimeChip(time: slot.start.format(context), onTap: () => _pickTime(context, true))),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('-', style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
          Expanded(child: _TimeChip(time: slot.end.format(context), onTap: () => _pickTime(context, false))),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String time;
  final VoidCallback onTap;

  const _TimeChip({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(time, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
