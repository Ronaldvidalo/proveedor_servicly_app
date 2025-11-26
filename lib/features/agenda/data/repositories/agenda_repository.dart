import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/agenda_event_model.dart';

class AgendaRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AgendaRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  String? get _userId => _auth.currentUser?.uid;

  /// Obtiene eventos de un rango de fechas (para la vista mensual/semanal)
  Stream<List<AgendaEvent>> getEventsStream({required DateTime start, required DateTime end}) {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('events') // Asegúrate que esta sea la colección correcta en tu Firebase
        .where('providerId', isEqualTo: _userId)
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AgendaEvent.fromFirestore(doc))
            .toList());
  }

  /// Obtiene la PRÓXIMA cita futura (Para el Dashboard Widget)
  Stream<AgendaEvent?> getNextAppointmentStream() {
    if (_userId == null) return Stream.value(null);
    
    final now = DateTime.now();

    return _firestore
        .collection('events')
        .where('providerId', isEqualTo: _userId)
        .where('startTime', isGreaterThan: Timestamp.fromDate(now)) // Solo futuro
        // Nota: Asegúrate de que el campo 'eventStatus' se guarde como string en Firebase para esta consulta
        .where('eventStatus', isNotEqualTo: 'cancelled') 
        .orderBy('startTime') // La más cercana
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return AgendaEvent.fromFirestore(snapshot.docs.first);
        });
  }

  Future<void> addEvent(AgendaEvent event) async {
    if (_userId == null) throw Exception("Usuario no autenticado");
    // Convertimos a JSON antes de guardar
    await _firestore.collection('events').add(event.toJson());
  }

  Future<void> updateEvent(AgendaEvent event) async {
    if (event.id == null) return;
    await _firestore.collection('events').doc(event.id).update(event.toJson());
  }

  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
  }
  
  // Método auxiliar para actualizar solo el estado (usado al cancelar)
  Future<void> updateEventStatus(String eventId, EventStatus status) async {
    await _firestore.collection('events').doc(eventId).update({'eventStatus': status.name});
  }
}