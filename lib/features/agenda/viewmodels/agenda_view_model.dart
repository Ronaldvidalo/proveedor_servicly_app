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

  // --- MÉTODOS ---

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

  Future<void> addEvent(AgendaEvent event) async {
    final day = DateTime.utc(event.startTime.year, event.startTime.month, event.startTime.day);
    _eventsSource.putIfAbsent(day, () => []).add(event);
    if (isSameDay(_selectedDay, day)) {
      selectedEvents.value = getEventsForDay(day);
    }
    notifyListeners();

    try {
      await _agendaService.addEvent(_userId, event);
    } catch (e) {
      _eventsSource[day]?.remove(event);
      if (isSameDay(_selectedDay, day)) {
        selectedEvents.value = getEventsForDay(day);
      }
      notifyListeners();
      rethrow;
    }
  }

  /// Actualiza un evento existente en la base de datos.
  Future<void> updateEvent(AgendaEvent event) async {
    final day = DateTime.utc(event.startTime.year, event.startTime.month, event.startTime.day);
    final eventList = _eventsSource[day];
    if (eventList != null) {
      final index = eventList.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        // Guardamos el evento original para poder revertir si falla la operación.
        final originalEvent = eventList[index];
        eventList[index] = event;
        if (isSameDay(_selectedDay, day)) {
          selectedEvents.value = List.from(eventList);
        }
        notifyListeners();
        
        try {
          await _agendaService.updateEvent(_userId, event);
        } catch (e) {
          // Si falla, revertimos el cambio en la UI.
          eventList[index] = originalEvent;
           if (isSameDay(_selectedDay, day)) {
            selectedEvents.value = List.from(eventList);
          }
          notifyListeners();
          rethrow;
        }
      }
    } else {
      // Si el evento no está en la lista local, lo enviamos directamente.
       try {
        await _agendaService.updateEvent(_userId, event);
      } catch (e) {
        rethrow;
      }
    }
  }

  Future<void> cancelEvent(AgendaEvent event) async {
    if (event.id == null) return;
    
    final cancelledEvent = event.copyWith(eventStatus: EventStatus.cancelled);
    final day = DateTime.utc(event.startTime.year, event.startTime.month, event.startTime.day);
    
    final eventList = _eventsSource[day];
    if (eventList != null) {
      final eventIndex = eventList.indexWhere((e) => e.id == event.id);
      if (eventIndex != -1) {
        eventList[eventIndex] = cancelledEvent;
        if (isSameDay(_selectedDay, day)) {
          selectedEvents.value = List.from(eventList);
        }
        notifyListeners();
      }
    }

    try {
      await _agendaService.updateEventStatus(_userId, event.id!, EventStatus.cancelled);
    } catch (e) {
      if (eventList != null) {
        final eventIndex = eventList.indexWhere((e) => e.id == event.id);
        if (eventIndex != -1) {
          eventList[eventIndex] = event;
           if (isSameDay(_selectedDay, day)) {
            selectedEvents.value = List.from(eventList);
          }
          notifyListeners();
        }
      }
      rethrow;
    }
  }
}

