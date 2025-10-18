import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import '../../data/models/agenda_event_model.dart';
import '../../viewmodels/agenda_view_model.dart';

class AddEditEventScreen extends StatefulWidget {
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
  _AddEditEventScreenState createState() => _AddEditEventScreenState();
}

class _AddEditEventScreenState extends State<AddEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late EventType _selectedType;
  late DateTime _startTime;
  late DateTime _endTime;

  bool get _isEditing => widget.eventToEdit != null;

  @override
  void initState() {
    super.initState();
    final event = widget.eventToEdit;

    if (_isEditing) {
      // Si estamos editando, cargamos los datos del evento existente.
      _titleController = TextEditingController(text: event!.title);
      _descriptionController = TextEditingController(text: event.description);
      _selectedType = event.eventType;
      _startTime = event.startTime;
      _endTime = event.endTime;
    } else {
      // Si estamos creando, establecemos valores por defecto.
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _selectedType = EventType.personal_reminder;
      final now = DateTime.now();
      _startTime = DateTime(
        widget.selectedDay.year,
        widget.selectedDay.month,
        widget.selectedDay.day,
        now.hour + 1,
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final viewModel = context.read<AgendaViewModel>();
    final user = widget.user;
    final navigator = Navigator.of(context);

    if (_endTime.isBefore(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: La hora de fin no puede ser anterior a la de inicio.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    try {
      if (_isEditing) {
        // --- LÓGICA DE EDICIÓN ---
        final updatedEvent = widget.eventToEdit!.copyWith(
          title: _titleController.text,
          description: _descriptionController.text,
          startTime: _startTime,
          endTime: _endTime,
          eventType: _selectedType,
        );
        await viewModel.updateEvent(updatedEvent);
      } else {
        // --- LÓGICA DE CREACIÓN ---
        final newEvent = AgendaEvent(
          title: _titleController.text,
          description: _descriptionController.text,
          startTime: _startTime,
          endTime: _endTime,
          eventType: _selectedType,
          providerId: user.uid,
        );
        await viewModel.addEvent(newEvent);
      }
      navigator.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar el evento: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Evento' : 'Nuevo Evento'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            SegmentedButton<EventType>(
              style: SegmentedButton.styleFrom(
                backgroundColor: const Color(0xFF2D2D5A),
                foregroundColor: Colors.white70,
                selectedForegroundColor: Colors.black,
                selectedBackgroundColor: accentColor,
              ),
              segments: const [
                ButtonSegment(value: EventType.personal_reminder, label: Text('Personal'), icon: Icon(Icons.person_outline)),
                ButtonSegment(value: EventType.visit, label: Text('Visita Técnica'), icon: Icon(Icons.business_center_outlined)),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<EventType> newSelection) {
                setState(() {
                  _selectedType = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Título del Evento'),
              validator: (value) => (value == null || value.isEmpty) ? 'El título es obligatorio' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Descripción (Opcional)'),
              maxLines: 3,
            ),
            
            if (_selectedType == EventType.visit)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: TextFormField(
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Cliente',
                    hintText: 'Buscar cliente...',
                    prefixIcon: Icon(Icons.person_search_outlined),
                  ),
                ),
              ),

            const SizedBox(height: 32),
            Text('Horario para el día ${DateFormat('d MMMM yyyy', 'es_ES').format(_startTime)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
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
            FilledButton.icon(
              onPressed: _saveEvent,
              icon: const Icon(Icons.save_alt_outlined),
              label: Text(_isEditing ? 'Guardar Cambios' : 'Guardar Evento'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
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

