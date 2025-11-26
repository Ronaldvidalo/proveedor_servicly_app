import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/features/agenda/data/models/agenda_event_model.dart';
// Importamos el provider del repositorio
import 'package:proveedor_servicly_app/features/agenda/providers/agenda_providers.dart';

class AddEditEventScreen extends ConsumerStatefulWidget {
  final DateTime selectedDay;
  final UserModel user;
  final AgendaEvent? eventToEdit;

  const AddEditEventScreen({
    super.key,
    required this.selectedDay,
    required this.user,
    this.eventToEdit,
  });

  @override
  ConsumerState<AddEditEventScreen> createState() => _AddEditEventScreenState();
}

class _AddEditEventScreenState extends ConsumerState<AddEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late EventType _selectedType;
  late DateTime _startTime;
  late DateTime _endTime;
  bool _isLoading = false;

  bool get _isEditing => widget.eventToEdit != null;

  @override
  void initState() {
    super.initState();
    final event = widget.eventToEdit;

    if (_isEditing) {
      _titleController = TextEditingController(text: event!.title);
      _descriptionController = TextEditingController(text: event.description);
      _selectedType = event.eventType;
      _startTime = event.startTime;
      _endTime = event.endTime;
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _selectedType = EventType.personal_reminder;
      
      // Hora por defecto: hora siguiente al momento actual o 9am del día seleccionado
      final now = DateTime.now();
      final isToday = widget.selectedDay.year == now.year && 
                      widget.selectedDay.month == now.month && 
                      widget.selectedDay.day == now.day;
                      
      final baseTime = isToday ? now.add(const Duration(minutes: 30)) : widget.selectedDay.add(const Duration(hours: 9));
      
      _startTime = DateTime(
        widget.selectedDay.year,
        widget.selectedDay.month,
        widget.selectedDay.day,
        baseTime.hour,
        0, // Minutos en 00 para limpieza
      );
      _endTime = _startTime.add(const Duration(hours: 1));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStartTime) async {
    final initialTime = TimeOfDay.fromDateTime(isStartTime ? _startTime : _endTime);
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      setState(() {
        final date = isStartTime ? _startTime : _endTime;
        final newDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        if (isStartTime) {
          _startTime = newDateTime;
          // Si la nueva hora de inicio es después del fin, movemos el fin 1 hora adelante
          if (_endTime.isBefore(_startTime)) {
            _endTime = _startTime.add(const Duration(hours: 1));
          }
        } else {
          _endTime = newDateTime;
        }
      });
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    // Leemos el repositorio
    final agendaRepo = ref.read(agendaRepositoryProvider);
    final navigator = Navigator.of(context);

    if (_endTime.isBefore(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: La hora de fin no puede ser anterior a la de inicio.'), backgroundColor: Colors.redAccent),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      if (_isEditing) {
        final updatedEvent = widget.eventToEdit!.copyWith(
          title: _titleController.text,
          description: _descriptionController.text,
          startTime: _startTime,
          endTime: _endTime,
          eventType: _selectedType,
        );
        await agendaRepo.updateEvent(updatedEvent);
      } else {
        final newEvent = AgendaEvent(
          title: _titleController.text,
          description: _descriptionController.text,
          startTime: _startTime,
          endTime: _endTime,
          eventType: _selectedType,
          providerId: widget.user.uid,
        );
        await agendaRepo.addEvent(newEvent);
      }
      
      if (navigator.canPop()) navigator.pop();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  // Función auxiliar para borrar evento si estamos editando
  Future<void> _deleteEvent() async {
     if (!_isEditing) return;
     
     final agendaRepo = ref.read(agendaRepositoryProvider);
     final navigator = Navigator.of(context);
     
     // Confirmación básica
     final confirm = await showDialog<bool>(
       context: context,
       builder: (ctx) => AlertDialog(
         backgroundColor: const Color(0xFF2D2D5A),
         title: const Text('Eliminar Evento', style: TextStyle(color: Colors.white)),
         content: const Text('¿Estás seguro? No se puede deshacer.', style: TextStyle(color: Colors.white70)),
         actions: [
           TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
           FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Eliminar')),
         ],
       ),
     );

     if (confirm == true) {
       await agendaRepo.deleteEvent(widget.eventToEdit!.id!);
       if (navigator.canPop()) navigator.pop();
     }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Evento' : 'Nuevo Evento'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _deleteEvent,
            )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text("Tipo de Evento", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            // --- SELECTOR DE TIPO (CHIPS WRAP) ---
            // Usamos Wrap + ChoiceChip porque 5 opciones no caben en un SegmentedButton móvil
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TypeChoiceChip(label: 'Personal', icon: Icons.person, type: EventType.personal_reminder, selectedType: _selectedType, onSelected: (t) => setState(() => _selectedType = t)),
                _TypeChoiceChip(label: 'Visita', icon: Icons.business_center, type: EventType.visit, selectedType: _selectedType, onSelected: (t) => setState(() => _selectedType = t)),
                _TypeChoiceChip(label: 'Cita', icon: Icons.video_call, type: EventType.appointment, selectedType: _selectedType, onSelected: (t) => setState(() => _selectedType = t)),
                _TypeChoiceChip(label: 'Pago', icon: Icons.money_off, type: EventType.payment_reminder, selectedType: _selectedType, onSelected: (t) => setState(() => _selectedType = t)),
                _TypeChoiceChip(label: 'Cobro', icon: Icons.attach_money, type: EventType.collection_reminder, selectedType: _selectedType, onSelected: (t) => setState(() => _selectedType = t)),
              ],
            ),
            
            const SizedBox(height: 24),

            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Título',
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: surfaceColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
              ),
              validator: (value) => (value == null || value.isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Descripción (Opcional)',
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: surfaceColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 32),
            Text('Horario (${DateFormat('dd/MM').format(_startTime)})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TimePickerTile(
                    label: 'Inicio',
                    time: TimeOfDay.fromDateTime(_startTime),
                    onTap: () => _pickTime(true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _TimePickerTile(
                    label: 'Fin',
                    time: TimeOfDay.fromDateTime(_endTime),
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _saveEvent,
                icon: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.save_alt_outlined),
                label: Text(_isEditing ? 'Guardar Cambios' : 'Crear Evento'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D5A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget Interno para los Chips de Selección
class _TypeChoiceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final EventType type;
  final EventType selectedType;
  final ValueChanged<EventType> onSelected;

  const _TypeChoiceChip({
    required this.label,
    required this.icon,
    required this.type,
    required this.selectedType,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = type == selectedType;
    return ChoiceChip(
      label: Text(label),
      avatar: Icon(icon, size: 18, color: isSelected ? Colors.black : Colors.white),
      selected: isSelected,
      onSelected: (_) => onSelected(type),
      selectedColor: const Color(0xFF00BFFF),
      backgroundColor: const Color(0xFF2D2D5A),
      labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
      side: BorderSide.none,
    );
  }
}