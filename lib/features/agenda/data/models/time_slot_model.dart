import 'package:flutter/material.dart';

/// Representa un único bloque de tiempo de trabajo (ej: 08:00 a 12:00).
class TimeSlot {
  TimeOfDay start;
  TimeOfDay end;

  TimeSlot({
    required this.start,
    required this.end,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      start: TimeOfDay(hour: int.parse(json['start'].split(':')[0]), minute: int.parse(json['start'].split(':')[1])),
      end: TimeOfDay(hour: int.parse(json['end'].split(':')[0]), minute: int.parse(json['end'].split(':')[1])),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
      'end': '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
    };
  }
}
