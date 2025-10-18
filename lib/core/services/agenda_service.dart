import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proveedor_servicly_app/features/agenda/data/models/agenda_event_model.dart';

/// Un servicio dedicado a gestionar las operaciones CRUD para la subcolección 'agenda_events'.
class AgendaService {
  final FirebaseFirestore _db;

  AgendaService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _eventsCollection(String userId) {
    return _db.collection('users').doc(userId).collection('agenda_events');
  }

  Stream<List<AgendaEvent>> getEventsForMonth(String userId, DateTime month) {
    DateTime firstDayOfMonth = DateTime.utc(month.year, month.month, 1);
    DateTime lastDayOfMonth = DateTime.utc(month.year, month.month + 1, 0).add(const Duration(days: 1));

    return _eventsCollection(userId)
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
        .where('startTime', isLessThan: Timestamp.fromDate(lastDayOfMonth))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AgendaEvent.fromFirestore(doc)).toList();
    });
  }

  Future<void> addEvent(String userId, AgendaEvent event) async {
    await _eventsCollection(userId).add(event.toJson());
  }

  Future<void> updateEvent(String userId, AgendaEvent event) async {
    await _eventsCollection(userId).doc(event.id).update(event.toJson());
  }
  
  // --- NUEVO MÉTODO ---
  /// Crea una cita (appointment) iniciada por el cliente.
  Future<void> createAppointmentByClient({
    required String providerId,
    required DateTime startTime,
    required int durationInMinutes,
    required String clientName,
    required String clientPhone,
  }) async {
    final newEvent = AgendaEvent(
      title: 'Cita con $clientName',
      description: 'Reservado por el cliente. Contacto: $clientPhone',
      startTime: startTime,
      endTime: startTime.add(Duration(minutes: durationInMinutes)),
      eventType: EventType.appointment,
      eventStatus: EventStatus.confirmed, // O 'pending' si el proveedor debe confirmar
      providerId: providerId,
      // Guardamos el nombre del cliente directamente en el evento
      clientId: clientName, 
    );
    await _eventsCollection(providerId).add(newEvent.toJson());
  }

  Future<void> updateEventStatus(String userId, String eventId, EventStatus status) async {
    await _eventsCollection(userId).doc(eventId).update({'eventStatus': status.name});
  }

  Future<void> deleteEvent(String userId, String eventId) async {
    await _eventsCollection(userId).doc(eventId).delete();
  }
}

