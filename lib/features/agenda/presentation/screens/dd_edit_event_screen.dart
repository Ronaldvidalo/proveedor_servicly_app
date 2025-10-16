import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import '../../data/models/agenda_event_model.dart';
import '../../viewmodels/agenda_view_model.dart';

class AddEditEventScreen extends StatefulWidget {
  final DateTime selectedDay;
  // --- MODIFICACIÓN CLAVE ---
  // Aceptamos el UserModel para que la pantalla sepa quién es el usuario.
  final UserModel user;

  const AddEditEventScreen({
    super.key, 
    required this.selectedDay,
    required this.user,
  });

  @override
  _AddEditEventScreenState createState() => _AddEditEventScreenState();
}

class _AddEditEventScreenState extends State<AddEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  EventType _selectedType = EventType.personal_reminder;
  late DateTime _startTime;
  late DateTime _endTime;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // La fecha es la que ya seleccionamos, solo ajustamos la hora.
    _startTime = DateTime(
      widget.selectedDay.year,
      widget.selectedDay.month,
      widget.selectedDay.day,
      now.hour + 1, // Por defecto, la siguiente hora
    );
    _endTime = _startTime.add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Muestra un selector de hora y actualiza el estado.
  Future<void> _pickTime(bool isStartTime) async {
    final initialTime = TimeOfDay.fromDateTime(isStartTime ? _startTime : _endTime);
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      setState(() {
        final selectedDate = widget.selectedDay;
        final newDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        if (isStartTime) {
          _startTime = newDateTime;
          // Si la nueva hora de inicio es después de la de fin, ajustamos la de fin.
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
    // --- MODIFICACIÓN CLAVE ---
    // Usamos el usuario que recibimos por el constructor, eliminando la necesidad
    // de buscarlo en el contexto y solucionando el error.
    final user = widget.user;
    final navigator = Navigator.of(context);

    if (_endTime.isBefore(_startTime)) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: La hora de fin no puede ser anterior a la de inicio.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final newEvent = AgendaEvent(
      title: _titleController.text,
      description: _descriptionController.text,
      startTime: _startTime,
      endTime: _endTime,
      eventType: _selectedType,
      providerId: user.uid,
    );

    try {
      await viewModel.addEvent(newEvent);
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
        title: const Text('Nuevo Evento'),
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
                    hintText: 'Buscar cliente...', // TODO: Implementar búsqueda de clientes
                    prefixIcon: Icon(Icons.person_search_outlined),
                  ),
                ),
              ),

            const SizedBox(height: 32),
            Text('Horario para el día ${DateFormat('d MMMM yyyy', 'es_ES').format(widget.selectedDay)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
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
              label: const Text('Guardar Evento'),
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

