import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proveedor_servicly_app/features/agenda/data/models/availability_model.dart';

/// Un servicio dedicado a gestionar la disponibilidad horaria de un proveedor.
class AvailabilityService {
  final FirebaseFirestore _db;

  AvailabilityService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  /// Obtiene una referencia a la subcolección 'availability' de un usuario específico.
  CollectionReference<Map<String, dynamic>> _availabilityCollection(String userId) {
    return _db.collection('users').doc(userId).collection('availability');
  }

  /// Obtiene la configuración de disponibilidad completa para un usuario.
  /// Devuelve un mapa con el día de la semana como clave (ej: 'monday').
  Future<Map<String, DayAvailability>> getAvailability(String userId) async {
    final snapshot = await _availabilityCollection(userId).get();

    final availabilityMap = <String, DayAvailability>{};
    for (var doc in snapshot.docs) {
      availabilityMap[doc.id] = DayAvailability.fromFirestore(doc);
    }
    
    // Si no hay datos, inicializa con valores por defecto.
    if (availabilityMap.isEmpty) {
      final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
      for (var day in days) {
        availabilityMap[day] = DayAvailability(dayOfWeek: day);
      }
    }

    return availabilityMap;
  }

  /// Actualiza la configuración de un día específico de la semana.
  Future<void> updateDayAvailability(String userId, DayAvailability dayAvailability) async {
    await _availabilityCollection(userId)
        .doc(dayAvailability.dayOfWeek)
        .set(dayAvailability.toJson());
  }
}
