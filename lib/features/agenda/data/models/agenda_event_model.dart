import 'package:cloud_firestore/cloud_firestore.dart';

enum EventType { visit, personal_reminder, appointment }
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
  final String? relatedContractId;
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
    this.relatedContractId,
    this.isAllDay = false,
  });

  // --- NUEVO MÉTODO ---
  /// Crea una copia de esta instancia de evento con los campos proporcionados reemplazados.
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
    String? relatedContractId,
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
      relatedContractId: relatedContractId ?? this.relatedContractId,
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
      eventType: EventType.values.firstWhere((e) => e.name == data['eventType'], orElse: () => EventType.personal_reminder),
      eventStatus: EventStatus.values.firstWhere((e) => e.name == data['eventStatus'], orElse: () => EventStatus.pending),
      providerId: data['providerId'],
      clientId: data['clientId'],
      relatedContractId: data['relatedContractId'],
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
      'relatedContractId': relatedContractId,
      'isAllDay': isAllDay,
    };
  }
}

