import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/agenda_event_model.dart';

/// Repositorio unificado para la gestión de eventos de agenda.
/// Maneja el CRUD de eventos y la integración técnica con el catálogo público.
class AgendaRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AgendaRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  String? get _userId => _auth.currentUser?.uid;

  // ==========================================
  // 1. STREAMS DE VISUALIZACIÓN
  // ==========================================

  /// Obtiene eventos de un rango de fechas para las vistas de calendario.
  /// Filtra por providerId y optimiza el consumo de lectura.
  Stream<List<AgendaEvent>> getEventsStream({required DateTime start, required DateTime end}) {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('events')
        .where('providerId', isEqualTo: _userId)
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AgendaEvent.fromFirestore(doc))
            .toList());
  }

  /// Obtiene la PRÓXIMA cita futura para el Dashboard Widget.
  /// Excluye eventos cancelados y prioriza por tiempo de inicio.
  Stream<AgendaEvent?> getNextAppointmentStream() {
    if (_userId == null) return Stream.value(null);
    
    final now = DateTime.now();

    return _firestore
        .collection('events')
        .where('providerId', isEqualTo: _userId)
        .where('startTime', isGreaterThan: Timestamp.fromDate(now))
        .where('eventStatus', isNotEqualTo: EventStatus.cancelled.name) 
        .orderBy('startTime') 
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return AgendaEvent.fromFirestore(snapshot.docs.first);
        });
  }

  // ==========================================
  // 2. INTEGRACIÓN CON CATÁLOGO PÚBLICO
  // ==========================================

  /// Crea un evento de agenda originado desde el catálogo de servicios.
  /// Soporta tanto reserva inmediata como negociación de presupuesto.
  Future<void> createEventFromCatalog({
    required String providerId,
    required DateTime date,
    required List<Map<String, dynamic>> services,
    required String actionType, // 'booking' o 'quote'
    required String clientName,
    required String clientPhone,
  }) async {
    // Definimos si es cita fija o negociación según el perfil
    final bool isNegotiation = actionType != 'booking';
    
    final double totalAmount = services.fold(0.0, (sum, item) => sum + (item['price'] as num).toDouble());

    final event = AgendaEvent(
      providerId: providerId,
      startTime: date,
      endTime: date.add(const Duration(minutes: 60)), // Duración técnica base
      title: isNegotiation ? "Presupuesto: $clientName" : "Cita: $clientName",
      description: "Servicios: ${services.map((s) => s['name']).join(', ')}",
      eventType: isNegotiation ? EventType.quoteNegotiation : EventType.clientBooking,
      eventStatus: isNegotiation ? EventStatus.pendingApproval : EventStatus.confirmed,
      metadata: {
        'services': services,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'totalAmount': totalAmount,
        'source': 'public_catalog',
      },
    );

    // 1. Persistencia en la colección raíz 'events'
    await _firestore.collection('events').add(event.toJson());

    // 2. DISPARO DE NOTIFICACIÓN PUSH
    await _queuePushNotification(
      providerId: providerId, 
      isNeg: isNegotiation, 
      clientName: clientName
    );
  }

  /// Inyecta una tarea en la cola de notificaciones para el backend.
  Future<void> _queuePushNotification({
    required String providerId, 
    required bool isNeg, 
    required String clientName
  }) async {
    await _firestore.collection('notifications_queue').add({
      'toId': providerId,
      'title': isNeg ? "Nuevo Pedido de Presupuesto" : "¡Tienes una nueva Cita!",
      'body': "$clientName ha solicitado tus servicios desde el catálogo.",
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ==========================================
  // 3. OPERACIONES CRUD ESTÁNDAR
  // ==========================================

  Future<void> addEvent(AgendaEvent event) async {
    if (_userId == null) throw Exception("Usuario no autenticado");
    await _firestore.collection('events').add(event.toJson());
  }

  Future<void> updateEvent(AgendaEvent event) async {
    if (event.id == null) return;
    await _firestore.collection('events').doc(event.id).update(event.toJson());
  }

  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
  }
  
  /// Actualiza el estado de un evento (Confirmar, Cancelar, Finalizar).
  Future<void> updateEventStatus(String eventId, EventStatus status) async {
    await _firestore.collection('events').doc(eventId).update({
      'eventStatus': status.name,
    });
  }
}