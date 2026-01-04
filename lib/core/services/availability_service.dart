import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Importación de modelos técnicos
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';

/// Motor de Disponibilidad Profesional: Gestiona turnos partidos, 
/// agendas comerciales y flujos de negociación técnica.
class AvailabilityService extends ChangeNotifier {
  final FirebaseFirestore _db;

  AvailabilityService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // ==========================================
  // 1. GENERACIÓN DE SLOTS (CALENDARIO)
  // ==========================================

  /// Genera los "huecos" (slots) disponibles basados en el horario del proveedor.
  /// Implementa soporte para horarios cortados (Split Shifts).
  Future<List<DateTime>> getAvailableSlots({
    required ProviderProfileModel profile,
    required DateTime date,
  }) async {
    // Obtener el día de la semana (1-7) según el estándar del modelo
    final int dayOfWeek = date.weekday;

    // Extraer los rangos de tiempo del modelo (mañana/tarde)
    final List<TimeRange>? dayRanges = profile.weeklySchedule?[dayOfWeek];

    if (dayRanges == null || dayRanges.isEmpty) {
      return []; // El proveedor no tiene horario configurado para este día
    }

    List<DateTime> allAvailableSlots = [];

    // Procesar cada rango horario de forma independiente (Soporta turnos partidos)
    for (var range in dayRanges) {
      allAvailableSlots.addAll(
        _generateTimeBlocks(date, range, profile.slotDuration),
      );
    }

    // Filtrar slots que ya están bloqueados por citas confirmadas
    final List<DateTime> bookedSlots = await _fetchConfirmedAppointments(profile.providerId, date);
    
    allAvailableSlots.removeWhere((slot) => 
      bookedSlots.any((booked) => booked.hour == slot.hour && booked.minute == slot.minute)
    );

    return allAvailableSlots;
  }

  /// Divide un rango de tiempo técnico en bloques según la duración configurada (slotDuration).
  List<DateTime> _generateTimeBlocks(DateTime date, TimeRange range, int duration) {
    List<DateTime> slots = [];
    
    final startParts = range.start.split(':');
    final endParts = range.end.split(':');

    if (startParts.length < 2 || endParts.length < 2) return [];

    DateTime current = DateTime(
      date.year, date.month, date.day,
      int.parse(startParts[0]), int.parse(startParts[1]),
    );

    final DateTime limit = DateTime(
      date.year, date.month, date.day,
      int.parse(endParts[0]), int.parse(endParts[1]),
    );

    // Iterar hasta alcanzar el límite del rango (ej: fin de turno mañana)
    while (current.isBefore(limit)) {
      slots.add(current);
      current = current.add(Duration(minutes: duration));
    }

    return slots;
  }

  /// Consulta las citas ya confirmadas en Firestore para evitar colisiones.
  Future<List<DateTime>> _fetchConfirmedAppointments(String providerId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59);

    final snapshot = await _db.collection('appointments')
        .where('providerId', isEqualTo: providerId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .where('status', isEqualTo: 'confirmed')
        .get();

    return snapshot.docs.map((doc) => (doc.data()['date'] as Timestamp).toDate()).toList();
  }

  // ==========================================
  // 2. PERSISTENCIA Y NOTIFICACIONES
  // ==========================================

  /// Registra la cita en la base de datos y dispara la notificación Push.
  /// [actionType] define si es reserva inmediata ('booking') o negociación ('quote').
  Future<void> createAppointment({
    required String providerId,
    required List<ProductModel> services,
    required DateTime selectedDate,
    required String actionType,
  }) async {
    // Si no es booking, es una visita técnica negociable.
    final bool isNegotiation = actionType != 'booking';

    final appointmentData = {
      'providerId': providerId,
      'services': services.map((s) => {
        'id': s.id,
        'name': s.name,
        'price': s.price,
      }).toList(),
      'date': Timestamp.fromDate(selectedDate),
      'status': isNegotiation ? 'pending_approval' : 'confirmed',
      'type': isNegotiation ? 'negotiation' : 'fixed_slot',
      'totalAmount': services.fold(0.0, (sum, item) => sum + item.price),
      'createdAt': FieldValue.serverTimestamp(),
      'clientName': 'Visitante Catálogo',
      'clientContact': 'Pendiente', // Se completará en el flujo de Auth/WhatsApp
    };

    // 1. Guardar en la colección raíz 'appointments' para visibilidad global
    await _db.collection('appointments').add(appointmentData);

    // 2. DISPARO DE NOTIFICACIÓN PUSH AL PROVEEDOR
    await _db.collection('notifications_queue').add({
      'toId': providerId,
      'title': isNegotiation ? "Nueva Solicitud de Presupuesto" : "¡Nueva Cita Agendada!",
      'body': "Interés en: ${services.map((s) => s.name).join(', ')}",
      'data': {
        'type': isNegotiation ? 'NEGOTIATION' : 'BOOKING',
        'date': DateFormat('dd/MM/yyyy HH:mm').format(selectedDate),
      },
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    notifyListeners();
  }

  // ==========================================
  // 3. LEGACY MIGRATION (Mantenimiento de compatibilidad)
  // ==========================================

  /// Este método se mantiene para compatibilidad con la edición de horarios manual,
  /// pero utiliza la nueva lógica del ProviderProfileModel si es posible.
  Future<void> updateProviderSchedule(String providerId, Map<int, List<TimeRange>> schedule) async {
    final Map<String, dynamic> dataToUpdate = {
      'weeklySchedule': schedule.map((key, value) {
        return MapEntry(key.toString(), value.map((v) => v.toMap()).toList());
      }),
    };

    await _db.collection('users').doc(providerId).update(dataToUpdate);
    notifyListeners();
  }
}