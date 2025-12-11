// --- UX/UI Enhancement Comment ---
// Modelo: Quote (Cotización)
// Responsabilidad: Definir la estructura de datos.
// Actualización: 
// 1. Se renombra 'expiresAt' a 'validUntil' para lógica de vencimiento.
// 2. Se agrega campo 'notes' para guardar las condiciones.
// ---------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proveedor_servicly_app/features/budget/models/quote_item_model.dart';

class Quote {
  final String id;
  final String number; // Ej: COT-001
  final String clientId;
  final String clientName; 
  final DateTime createdAt;
  
  // --- CAMPO CLAVE PARA TU REGLA DE BORRADO ---
  final DateTime validUntil; // Fecha de vencimiento de la oferta
  
  final String status; // 'draft', 'sent', 'viewed', 'accepted', 'rejected'
  final double total;
  final String currency; // 'USD', 'MXN', 'EUR'
  final bool hasUnreadUpdates; 
  
  final List<QuoteItem> items; 
  final double taxRate; 
  
  // --- CAMPO NUEVO PARA EL EDITOR ---
  final String notes; // Condiciones de la cotización (Pago, entrega, etc.)

  Quote({
    required this.id,
    required this.number,
    required this.clientId,
    required this.clientName,
    required this.createdAt,
    required this.validUntil, // Ahora es requerido
    this.status = 'draft',
    this.total = 0.0,
    this.currency = 'USD',
    this.hasUnreadUpdates = false,
    this.items = const [],
    this.taxRate = 0.0,
    this.notes = '',
  });

  // Factory para crear desde Firestore
  factory Quote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Lógica de seguridad para fechas
    final created = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    
    return Quote(
      id: doc.id,
      number: data['number'] ?? '---',
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? 'Cliente Desconocido',
      createdAt: created,
      
      // Si no existe fecha de validez, por defecto 30 días después de creada
      validUntil: (data['validUntil'] as Timestamp?)?.toDate() ?? created.add(const Duration(days: 30)),
      
      status: data['status'] ?? 'draft',
      total: (data['total'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'USD',
      hasUnreadUpdates: data['hasUnreadUpdates'] ?? false,
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => QuoteItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      taxRate: (data['taxRate'] ?? 0.0).toDouble(),
      notes: data['notes'] ?? '', // Recuperamos las notas
    );
  }

  // Convertir a Map para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'clientId': clientId,
      'clientName': clientName,
      'createdAt': Timestamp.fromDate(createdAt),
      'validUntil': Timestamp.fromDate(validUntil), // Guardamos la validez
      'status': status,
      'total': total,
      'currency': currency,
      'hasUnreadUpdates': hasUnreadUpdates,
      'items': items.map((item) => item.toMap()).toList(),
      'taxRate': taxRate,
      'notes': notes, // Guardamos las notas
    };
  }

  // --- COPYWITH ACTUALIZADO ---
  Quote copyWith({
    String? id,
    String? number,
    String? clientId,
    String? clientName,
    DateTime? createdAt,
    DateTime? validUntil,
    String? status,
    double? total,
    String? currency,
    bool? hasUnreadUpdates,
    List<QuoteItem>? items,
    double? taxRate,
    String? notes,
  }) {
    return Quote(
      id: id ?? this.id,
      number: number ?? this.number,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      createdAt: createdAt ?? this.createdAt,
      validUntil: validUntil ?? this.validUntil,
      status: status ?? this.status,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      hasUnreadUpdates: hasUnreadUpdates ?? this.hasUnreadUpdates,
      items: items ?? this.items,
      taxRate: taxRate ?? this.taxRate,
      notes: notes ?? this.notes,
    );
  }
}