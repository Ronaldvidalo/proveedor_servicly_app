import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proveedor_servicly_app/features/agenda/data/models/agenda_event_model.dart';

/// Un servicio dedicado a gestionar las operaciones CRUD para la subcolección 'agenda_events'.
class AgendaService {
  final FirebaseFirestore _db;

  AgendaService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  /// Obtiene una referencia a la subcolección 'agenda_events' de un usuario específico.
  CollectionReference<Map<String, dynamic>> _eventsCollection(String userId) {
    return _db.collection('users').doc(userId).collection('agenda_events');
  }

  /// Obtiene un stream con los eventos de un mes específico para un usuario.
  /// Esto es eficiente para no descargar toda la agenda de una vez.
  Stream<List<AgendaEvent>> getEventsForMonth(String userId, DateTime month) {
    // Calcula el primer y último día del mes para la consulta.
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

  /// Añade un nuevo evento a la agenda del usuario.
  Future<void> addEvent(String userId, AgendaEvent event) async {
    await _eventsCollection(userId).add(event.toJson());
  }

  /// Actualiza un evento existente.
  Future<void> updateEvent(String userId, AgendaEvent event) async {
    await _eventsCollection(userId).doc(event.id).update(event.toJson());
  }

  /// Elimina un evento.
  Future<void> deleteEvent(String userId, String eventId) async {
    await _eventsCollection(userId).doc(eventId).delete();
  }
}
