import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:proveedor_servicly_app/core/services/agenda_service.dart';
import '../data/models/agenda_event_model.dart';

class AgendaViewModel extends ChangeNotifier {
  final AgendaService _agendaService;
  final String _userId;

  StreamSubscription? _eventsSubscription;
  final Map<DateTime, List<AgendaEvent>> _eventsSource = {};

  final ValueNotifier<List<AgendaEvent>> selectedEvents;
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  AgendaViewModel({required AgendaService agendaService, required String userId})
      : _agendaService = agendaService,
        _userId = userId,
        selectedEvents = ValueNotifier([]) {
    _selectedDay = _focusedDay;
    selectedEvents.value = getEventsForDay(_selectedDay!);
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    selectedEvents.dispose();
    super.dispose();
  }

  // Getters
  DateTime get focusedDay => _focusedDay;
  DateTime? get selectedDay => _selectedDay;
  CalendarFormat get calendarFormat => _calendarFormat;

  List<AgendaEvent> getEventsForDay(DateTime day) {
    return _eventsSource[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  // --- MÉTODOS PARA LA UI ---
  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      selectedEvents.value = getEventsForDay(selectedDay);
      notifyListeners();
    }
  }
  
  void onFormatChanged(CalendarFormat format) {
    if (_calendarFormat != format) {
      _calendarFormat = format;
      notifyListeners();
    }
  }

  void onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    fetchEvents();
  }
  
  Future<void> fetchEvents() async {
    _eventsSubscription?.cancel();
    _eventsSubscription = _agendaService.getEventsForMonth(_userId, _focusedDay).listen((events) {
      _eventsSource.clear();
      for (final event in events) {
        final day = DateTime.utc(event.startTime.year, event.startTime.month, event.startTime.day);
        _eventsSource.putIfAbsent(day, () => []).add(event);
      }
      if (_selectedDay != null) {
        selectedEvents.value = getEventsForDay(_selectedDay!);
      }
      notifyListeners();
    });
  }

  /// Añade un nuevo evento a la base de datos y actualiza la UI de forma optimista.
  Future<void> addEvent(AgendaEvent event) async {
    // --- MODIFICACIÓN CLAVE: ACTUALIZACIÓN OPTIMISTA ---
    // 1. Actualizamos el estado local inmediatamente.
    final day = DateTime.utc(event.startTime.year, event.startTime.month, event.startTime.day);
    _eventsSource.putIfAbsent(day, () => []).add(event);
    if (isSameDay(_selectedDay, day)) {
      selectedEvents.value = getEventsForDay(day);
    }
    notifyListeners();

    // 2. Intentamos guardar en la base de datos.
    try {
      await _agendaService.addEvent(_userId, event);
    } catch (e) {
      // 3. Si falla, revertimos el cambio local y notificamos al usuario.
      _eventsSource[day]?.remove(event);
      if (isSameDay(_selectedDay, day)) {
        selectedEvents.value = getEventsForDay(day);
      }
      notifyListeners();
      // Propagamos el error para que la UI pueda mostrar un mensaje.
      rethrow;
    }
  }
}

