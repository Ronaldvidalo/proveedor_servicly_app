// --- UX/UI Enhancement Comment ---
// Modelo: Quote (Cotización)
// Responsabilidad: Definir la estructura principal de la cotización.
// Actualización: Se agrega 'items', 'copyWith' y mapeo completo para corregir errores del repositorio.

import 'package:cloud_firestore/cloud_firestore.dart';
// Asegúrate de importar el modelo del ítem
import 'package:proveedor_servicly_app/features/budget/models/quote_item_model.dart';

class Quote {
  final String id;
  final String number; // Ej: COT-001
  final String clientId;
  final String clientName; // Snapshot: Nombre al momento de crear
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String status; // 'draft', 'sent', 'viewed', 'accepted', 'rejected'
  final double total;
  final String currency; // 'USD', 'MXN', 'EUR'
  final bool hasUnreadUpdates; // Para el Badge
  
  // --- CAMPOS AGREGADOS ---
  final List<QuoteItem> items; // Lista de productos
  final double taxRate; // Impuesto global (opcional)

  Quote({
    required this.id,
    required this.number,
    required this.clientId,
    required this.clientName,
    required this.createdAt,
    this.expiresAt,
    this.status = 'draft',
    this.total = 0.0,
    this.currency = 'USD',
    this.hasUnreadUpdates = false,
    this.items = const [],
    this.taxRate = 0.0,
  });

  // Factory para crear desde Firestore
  factory Quote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Quote(
      id: doc.id,
      number: data['number'] ?? '---',
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? 'Cliente Desconocido',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'draft',
      total: (data['total'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'USD',
      hasUnreadUpdates: data['hasUnreadUpdates'] ?? false,
      // Mapeo seguro de la lista de ítems
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => QuoteItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      taxRate: (data['taxRate'] ?? 0.0).toDouble(),
    );
  }

  // Convertir a Map para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'clientId': clientId,
      'clientName': clientName,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'status': status,
      'total': total,
      'currency': currency,
      'hasUnreadUpdates': hasUnreadUpdates,
      // Convertimos cada ítem a mapa
      'items': items.map((item) => item.toMap()).toList(),
      'taxRate': taxRate,
    };
  }

  // --- MÉTODO COPYWITH (Soluciona el error del repositorio) ---
  Quote copyWith({
    String? id,
    String? number,
    String? clientId,
    String? clientName,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? status,
    double? total,
    String? currency,
    bool? hasUnreadUpdates,
    List<QuoteItem>? items,
    double? taxRate,
  }) {
    return Quote(
      id: id ?? this.id,
      number: number ?? this.number,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      hasUnreadUpdates: hasUnreadUpdates ?? this.hasUnreadUpdates,
      items: items ?? this.items,
      taxRate: taxRate ?? this.taxRate,
    );
  }
}