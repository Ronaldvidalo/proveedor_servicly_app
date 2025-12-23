import 'package:cloud_firestore/cloud_firestore.dart';

// --- ACTUALIZACIÓN: NUEVOS TIPOS DE EVENTOS ---
enum EventType { 
  visit,              // Visita técnica / Cita presencial
  personalReminder,  // Recordatorio personal
  appointment,        // Reunión virtual / Llamada
  paymentReminder,   // Cuentas por Pagar (Facturas)
  collectionReminder // Cuentas por Cobrar (A clientes)
}

enum EventStatus { pending, confirmed, completed, cancelled }

class AgendaEvent {
  final String? id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final EventType eventType;
  final EventStatus eventStatus;
  final String providerId;
  final String? clientId;
  
  // Para vincular con finanzas (opcional)
  final double? amount; 
  final bool isAllDay;

  AgendaEvent({
    this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.eventType,
    this.eventStatus = EventStatus.pending,
    required this.providerId,
    this.clientId,
    this.amount,
    this.isAllDay = false,
  });

  AgendaEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    EventType? eventType,
    EventStatus? eventStatus,
    String? providerId,
    String? clientId,
    double? amount,
    bool? isAllDay,
  }) {
    return AgendaEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      eventType: eventType ?? this.eventType,
      eventStatus: eventStatus ?? this.eventStatus,
      providerId: providerId ?? this.providerId,
      clientId: clientId ?? this.clientId,
      amount: amount ?? this.amount,
      isAllDay: isAllDay ?? this.isAllDay,
    );
  }

  factory AgendaEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AgendaEvent(
      id: doc.id,
      title: data['title'] ?? 'Sin Título',
      description: data['description'],
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      // Mapeo robusto de Enum
      eventType: EventType.values.firstWhere(
          (e) => e.name == data['eventType'], 
          orElse: () => EventType.personalReminder
      ),
      eventStatus: EventStatus.values.firstWhere(
          (e) => e.name == data['eventStatus'], 
          orElse: () => EventStatus.pending
      ),
      providerId: data['providerId'],
      clientId: data['clientId'],
      amount: (data['amount'] as num?)?.toDouble(),
      isAllDay: data['isAllDay'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'eventType': eventType.name,
      'eventStatus': eventStatus.name,
      'providerId': providerId,
      'clientId': clientId,
      'amount': amount,
      'isAllDay': isAllDay,
    };
  }
}