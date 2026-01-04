import 'package:cloud_firestore/cloud_firestore.dart';

// --- ACTUALIZACIÓN: TIPOS DE EVENTOS UNIFICADOS ---
enum EventType { 
  visit,              // Visita técnica / Cita presencial
  personalReminder,   // Recordatorio personal
  appointment,        // Reunión virtual / Llamada
  paymentReminder,    // Cuentas por Pagar (Facturas)
  collectionReminder, // Cuentas por Cobrar (A clientes)
  quoteNegotiation,   // Pedido de presupuesto desde catálogo (Negociación)
  clientBooking       // Cita agendada automáticamente desde catálogo
}

// --- ACTUALIZACIÓN: ESTADOS UNIFICADOS PARA NEGOCIACIÓN ---
enum EventStatus { 
  pending, 
  pendingApproval,    // Estado para negociación de contraoferta
  confirmed, 
  completed, 
  cancelled 
}

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

  // --- NUEVO CAMPO TÉCNICO ---
  /// Almacena datos adicionales como lista de servicios, nombre del cliente o fuente.
  final Map<String, dynamic>? metadata;

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
    this.metadata,
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
    Map<String, dynamic>? metadata,
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
      metadata: metadata ?? this.metadata,
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
      // Mapeo robusto de Enum para tipos de eventos
      eventType: EventType.values.firstWhere(
          (e) => e.name == data['eventType'], 
          orElse: () => EventType.personalReminder
      ),
      // Mapeo robusto para estados de negociación
      eventStatus: EventStatus.values.firstWhere(
          (e) => e.name == data['eventStatus'], 
          orElse: () => EventStatus.pending
      ),
      providerId: data['providerId'] ?? '',
      clientId: data['clientId'],
      amount: (data['amount'] as num?)?.toDouble(),
      isAllDay: data['isAllDay'] ?? false,
      metadata: data['metadata'] != null ? Map<String, dynamic>.from(data['metadata']) : null,
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
      'metadata': metadata,
    };
  }
}