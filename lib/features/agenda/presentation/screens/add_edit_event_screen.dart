import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/features/agenda/data/models/agenda_event_model.dart';
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
      _selectedType = EventType.personalReminder;
      
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
        0, 
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final agendaRepo = ref.read(agendaRepositoryProvider);
    final navigator = Navigator.of(context);

    if (_endTime.isBefore(_startTime)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: La hora de fin no puede ser anterior a la de inicio.'), backgroundColor: Colors.redAccent),
        );
      }
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
      
      if (!mounted) return;
      if (navigator.canPop()) navigator.pop();
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _deleteEvent() async {
      if (!_isEditing) return;
      final agendaRepo = ref.read(agendaRepositoryProvider);
      final navigator = Navigator.of(context);
      final theme = Theme.of(context);
      
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: theme.cardTheme.color,
          title: Text('Eliminar Evento', style: TextStyle(color: theme.colorScheme.onSurface)),
          content: Text('¿Estás seguro? No se puede deshacer.', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Eliminar')),
          ],
        ),
      );

      if (confirm == true) {
        await agendaRepo.deleteEvent(widget.eventToEdit!.id!);
        if (!mounted) return;
        if (navigator.canPop()) navigator.pop();
      }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Configuración de inputs desde el tema
    final inputDecorationTheme = theme.inputDecorationTheme;
    final baseInputDecoration = InputDecoration(
      labelStyle: inputDecorationTheme.labelStyle,
      filled: true,
      fillColor: inputDecorationTheme.fillColor,
      border: inputDecorationTheme.border,
      focusedBorder: inputDecorationTheme.focusedBorder,
      enabledBorder: inputDecorationTheme.enabledBorder,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Inputs un poco más compactos
    );
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Evento' : 'Nuevo Evento'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _deleteEvent,
            )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Aumentamos el breakpoint para asegurar espacio para 2 columnas
          final isWeb = constraints.maxWidth > 800; 

          // --- DEFINICIÓN DE WIDGETS REUTILIZABLES ---
          // (Para no repetir código en los dos layouts)

          final titleField = TextFormField(
            controller: _titleController,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: baseInputDecoration.copyWith(labelText: 'Título'),
            validator: (value) => (value == null || value.isEmpty) ? 'Requerido' : null,
          );

          final descriptionField = TextFormField(
            controller: _descriptionController,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: baseInputDecoration.copyWith(labelText: 'Descripción (Opcional)', alignLabelWithHint: true),
            maxLines: isWeb ? 4 : 3, // Un poco más alto en web si hay espacio
          );

          final typeSelector = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text("Tipo de Evento", style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.bold, fontSize: 13)),
               const SizedBox(height: 8),
               Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TypeChoiceChip(label: 'Personal', icon: Icons.person, type: EventType.personalReminder, selectedType: _selectedType, onSelected: (t) => setState(() => _selectedType = t)),
                    _TypeChoiceChip(label: 'Visita', icon: Icons.business_center, type: EventType.visit, selectedType: _selectedType, onSelected: (t) => setState(() => _selectedType = t)),
                    _TypeChoiceChip(label: 'Cita', icon: Icons.video_call, type: EventType.appointment, selectedType: _selectedType, onSelected: (t) => setState(() => _selectedType = t)),
                    _TypeChoiceChip(label: 'Pago', icon: Icons.money_off, type: EventType.paymentReminder, selectedType: _selectedType, onSelected: (t) => setState(() => _selectedType = t)),
                    _TypeChoiceChip(label: 'Cobro', icon: Icons.attach_money, type: EventType.collectionReminder, selectedType: _selectedType, onSelected: (t) => setState(() => _selectedType = t)),
                  ],
                ),
            ],
          );

          final timePickers = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text('Horario (${DateFormat('dd/MM').format(_startTime)})', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
               const SizedBox(height: 12),
               Row(
                  children: [
                    Expanded(child: _TimePickerTile(label: 'Inicio', time: TimeOfDay.fromDateTime(_startTime), onTap: () => _pickTime(true))),
                    const SizedBox(width: 12),
                    Expanded(child: _TimePickerTile(label: 'Fin', time: TimeOfDay.fromDateTime(_endTime), onTap: () => _pickTime(false))),
                  ],
                ),
            ],
          );

          final saveButton = SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _saveEvent,
              icon: _isLoading 
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary))
                : const Icon(Icons.save_alt_outlined),
              label: Text(_isEditing ? 'Guardar Cambios' : 'Crear Evento'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          );

          // ----------------------------------------------------
          // 🖥️ DISEÑO WEB: TARJETA REORGANIZADA (2 COLUMNAS)
          // ----------------------------------------------------
          if (isWeb) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Container(
                  // Hacemos la tarjeta un poco más ancha para que quepan las 2 columnas cómodamente
                  width: 750, 
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 4))]
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing ? "Editar detalles" : "Detalles del evento",
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        
                        // --- AQUÍ ESTÁ LA MAGIA: ROW PARA DIVIDIR EN COLUMNAS ---
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // COLUMNA IZQUIERDA (Inputs de texto y Tipo) - 60% ancho
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  titleField,
                                  const SizedBox(height: 16),
                                  descriptionField,
                                  const SizedBox(height: 24),
                                  typeSelector,
                                ],
                              ),
                            ),
                            
                            const SizedBox(width: 32), // Espacio entre columnas

                            // COLUMNA DERECHA (Horario y Botón) - 40% ancho
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  timePickers,
                                  const SizedBox(height: 32),
                                  saveButton,
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          // ----------------------------------------------------
          // 📱 DISEÑO MÓVIL: LISTA VERTICAL (Original)
          // ----------------------------------------------------
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                typeSelector,
                const SizedBox(height: 24),
                titleField,
                const SizedBox(height: 16),
                descriptionField,
                const SizedBox(height: 32),
                timePickers,
                const SizedBox(height: 32),
                saveButton,
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- WIDGETS AUXILIARES (Sin cambios, solo usando withValues) ---

class _TimePickerTile extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimePickerTile({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5))
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChoiceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final EventType type;
  final EventType selectedType;
  final ValueChanged<EventType> onSelected;

  const _TypeChoiceChip({required this.label, required this.icon, required this.type, required this.selectedType, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = type == selectedType;
    
    return ChoiceChip(
      label: Text(label),
      avatar: Icon(icon, size: 16, color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface),
      selected: isSelected,
      onSelected: (_) => onSelected(type),
      selectedColor: colorScheme.primary,
      backgroundColor: theme.cardTheme.color,
      labelStyle: TextStyle(color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface, fontSize: 13),
      side: isSelected ? BorderSide.none : BorderSide(color: theme.dividerColor),
      padding: const EdgeInsets.symmetric(horizontal: 4), // Chips más compactos
    );
  }
}