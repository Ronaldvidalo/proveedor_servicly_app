import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';

class WeeklyScheduleEditor extends StatefulWidget {
  /// El horario inicial usando el modelo TimeRange
  final Map<int, List<TimeRange>> initialSchedule;
  /// Política de feriados
  final bool initialWorksOnHolidays;
  /// Callback de retorno: (horario, trabaja_feriados)
  final Function(Map<int, List<TimeRange>>, bool) onChanged;
  final Color accentColor;

  const WeeklyScheduleEditor({
    super.key,
    required this.initialSchedule,
    required this.initialWorksOnHolidays,
    required this.onChanged,
    this.accentColor = const Color(0xFF00B2B2),
  });

  @override
  State<WeeklyScheduleEditor> createState() => _WeeklyScheduleEditorState();
}

class _WeeklyScheduleEditorState extends State<WeeklyScheduleEditor> {
  late Map<int, List<TimeRange>> _currentSchedule;
  late bool _worksOnHolidays;
  
  // ✅ Control de expansión para minimizar el detalle
  final Set<int> _expandedDays = {};

  final List<String> _dayNames = [
    "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"
  ];

  @override
  void initState() {
    super.initState();
    _worksOnHolidays = widget.initialWorksOnHolidays;
    // Clonación profunda del horario inicial
    _currentSchedule = widget.initialSchedule.map(
      (key, value) => MapEntry(key, List<TimeRange>.from(value)),
    );
  }

  void _notifyChanges() {
    widget.onChanged(_currentSchedule, _worksOnHolidays);
  }

  // --- LÓGICA DE PREAJUSTES (PRESETS) ---

  Future<void> _applyPreset(List<int> days, String title) async {
    final TimeRange? range = await _askForTimeRange(title);
    if (range != null) {
      setState(() {
        for (var day in days) {
          _currentSchedule[day] = [range];
        }
      });
      _notifyChanges();
    }
  }

  Future<TimeRange?> _askForTimeRange(String title) async {
    TimeOfDay? start = await showTimePicker(
      context: context, 
      initialTime: const TimeOfDay(hour: 9, minute: 0), 
      helpText: "$title - INICIO"
    );
    if (start == null) return null;
    
    TimeOfDay? end = await showTimePicker(
      context: context, 
      initialTime: const TimeOfDay(hour: 18, minute: 0), 
      helpText: "$title - FIN"
    );
    if (end == null) return null;

    return TimeRange(
      start: "${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}",
      end: "${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}",
    );
  }

  // --- GESTIÓN DE TIEMPOS ---

  void _toggleDay(int dayIndex) {
    setState(() {
      if (_currentSchedule.containsKey(dayIndex)) {
        _currentSchedule.remove(dayIndex);
        _expandedDays.remove(dayIndex);
      } else {
        _currentSchedule[dayIndex] = [TimeRange(start: '09:00', end: '18:00')];
      }
    });
    _notifyChanges();
  }

  Future<void> _editTime(int dayIndex, int rangeIndex, bool isStart) async {
    final range = _currentSchedule[dayIndex]![rangeIndex];
    final initialTimeStr = isStart ? range.start : range.end;
    final parts = initialTimeStr.split(':');
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts[1]) ?? 0,
      ),
    );

    if (picked != null) {
      final newTime = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      setState(() {
        final oldRange = _currentSchedule[dayIndex]![rangeIndex];
        _currentSchedule[dayIndex]![rangeIndex] = TimeRange(
          start: isStart ? newTime : oldRange.start,
          end: isStart ? oldRange.end : newTime,
        );
      });
      _notifyChanges();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. POLÍTICA DE FERIADOS
        _buildHolidayToggle(),
        
        const SizedBox(height: 24),
        
        // 2. CONFIGURACIÓN RÁPIDA
        const Text(
          "ACCIONES RÁPIDAS",
          style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildPresetBtn("Lunes a Viernes", () => _applyPreset([1,2,3,4,5], "Lunes a Viernes")),
            const SizedBox(width: 8),
            _buildPresetBtn("Sábados", () => _applyPreset([6], "Sábados")),
          ],
        ),

        const SizedBox(height: 32),

        // 3. DETALLE POR DÍA (MINIMIZADO)
        const Text(
          "DISPONIBILIDAD POR DÍA",
          style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 7,
          itemBuilder: (context, index) {
            final dayInt = index + 1;
            final isActive = _currentSchedule.containsKey(dayInt);
            final isExpanded = _expandedDays.contains(dayInt);
            return _buildDayRow(dayInt, isActive, isExpanded);
          },
        ),
      ],
    );
  }

  Widget _buildHolidayToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _worksOnHolidays ? widget.accentColor.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _worksOnHolidays ? widget.accentColor.withValues(alpha: 0.3) : Colors.white10),
      ),
      child: Row(
        children: [
          Icon(Icons.event_available, color: _worksOnHolidays ? widget.accentColor : Colors.white24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Atención en Feriados", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  _worksOnHolidays ? "Tu agenda permanecerá abierta." : "Se bloquearán citas automáticamente.",
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: _worksOnHolidays,
            activeColor: widget.accentColor,
            onChanged: (val) {
              setState(() => _worksOnHolidays = val);
              _notifyChanges();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPresetBtn(String label, VoidCallback onTap) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ),
    );
  }

  Widget _buildDayRow(int dayInt, bool isActive, bool isExpanded) {
    final List<TimeRange> ranges = _currentSchedule[dayInt] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withValues(alpha: 0.03) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? Colors.white10 : Colors.white.withValues(alpha: 0.02)),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            title: Text(
              _dayNames[dayInt - 1],
              style: TextStyle(color: isActive ? Colors.white : Colors.white24, fontWeight: FontWeight.bold),
            ),
            subtitle: isActive && !isExpanded 
              ? Text("${ranges.length} turno(s) configurado(s)", style: TextStyle(color: widget.accentColor.withValues(alpha: 0.6), fontSize: 11))
              : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isActive)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (_expandedDays.contains(dayInt)) {
                          _expandedDays.remove(dayInt);
                        } else {
                          _expandedDays.add(dayInt);
                        }
                      });
                    },
                    child: Text(
                      isExpanded ? "CERRAR" : "PERSONALIZAR",
                      style: TextStyle(color: widget.accentColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                Switch(
                  value: isActive,
                  activeColor: widget.accentColor,
                  onChanged: (_) => _toggleDay(dayInt),
                ),
              ],
            ),
          ),
          
          // ✅ SECCIÓN DE PERSONALIZACIÓN EXPANDIBLE
          if (isActive && isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                children: [
                  const Divider(color: Colors.white10, height: 20),
                  ...ranges.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final range = entry.value;
                    return _buildTimeEditorRow(dayInt, idx, range);
                  }).toList(),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _currentSchedule[dayInt]!.add(TimeRange(start: '14:00', end: '18:00')));
                      _notifyChanges();
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 14),
                    label: const Text("Añadir turno partido", style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(foregroundColor: widget.accentColor),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeEditorRow(int dayInt, int idx, TimeRange range) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          _timeChip(range.start, () => _editTime(dayInt, idx, true)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text("a", style: TextStyle(color: Colors.white24, fontSize: 12)),
          ),
          _timeChip(range.end, () => _editTime(dayInt, idx, false)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 18),
            onPressed: () {
              setState(() {
                _currentSchedule[dayInt]!.removeAt(idx);
                if (_currentSchedule[dayInt]!.isEmpty) {
                  _currentSchedule.remove(dayInt);
                  _expandedDays.remove(dayInt);
                }
              });
              _notifyChanges();
            },
          )
        ],
      ),
    );
  }

  Widget _timeChip(String time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Text(time, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ),
    );
  }
}