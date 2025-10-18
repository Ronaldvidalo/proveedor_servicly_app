import 'package:cloud_firestore/cloud_firestore.dart';
import 'time_slot_model.dart';

/// Representa la disponibilidad para un día específico de la semana.
class DayAvailability {
  final String dayOfWeek; // ej: 'monday'
  bool isEnabled;
  List<TimeSlot> workSlots;

  DayAvailability({
    required this.dayOfWeek,
    this.isEnabled = false,
    this.workSlots = const [],
  });

  factory DayAvailability.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DayAvailability(
      dayOfWeek: doc.id,
      isEnabled: data['isEnabled'] ?? false,
      workSlots: (data['workSlots'] as List<dynamic>?)
          ?.map((slot) => TimeSlot.fromJson(slot as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'workSlots': workSlots.map((slot) => slot.toJson()).toList(),
    };
  }
}
