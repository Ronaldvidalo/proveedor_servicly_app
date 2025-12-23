import 'package:cloud_firestore/cloud_firestore.dart';

// --- ENUMS ---

// 1. Estados de la Orden (Flujo P2P)
enum OrderStatus {
  pendingPayment,      // El cliente creó la orden pero no ha subido comprobante
  pendingVerification, // El cliente subió comprobante, proveedor revisa
  inProgress,
  completed,            // Proveedor confirmó pago y entregó producto
  cancelled,            // Cancelada por cualquiera de las partes
  disputed              // En disputa (futuro)
}

// 2. Tipos de Entrega (Logística)
enum DeliveryType { 
  pickup,   // Retiro en tienda
  delivery  // Envío a domicilio
}

/// Modelo que representa una orden de compra/servicio.
class OrderModel {
  final String id;
  final String providerId; 
  final String clientId;   
  final String? providerNote;

  // --- Detalles del Cliente ---
  final String clientName;
  final String clientEmail;
  
  // --- Detalles del Producto ---
  final List<Map<String, dynamic>> items;
  final double total;
  
  // --- Estados y Fechas ---
  final OrderStatus status; 
  final Timestamp createdAt;
  Timestamp? updatedAt; 

  // --- Datos de Pago (P2P) ---
  final String paymentProofUrl; 
  final String paymentMethodId; 
  final String? clientNotes;

  // --- Datos de Logística ---
  final DeliveryType deliveryType; 
  final String shippingAddress;    
  final double shippingCost;       

  // --- Sistema de Reputación (NUEVO) ---
  final bool isRated; // Indica si el cliente ya calificó esta orden

  OrderModel({
    required this.id,
    required this.providerId,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    required this.paymentProofUrl,
    required this.paymentMethodId,
    this.clientNotes,
    this.deliveryType = DeliveryType.pickup, 
    this.shippingAddress = '',
    this.shippingCost = 0.0,
    this.isRated = false, // Por defecto no está calificada
    this.providerNote,
  });

  /// Factory: Desde Firestore -> Modelo Dart
  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Conversión segura de Items
    final List<Map<String, dynamic>> itemsList = (data['items'] as List<dynamic>?)
        ?.map((item) => Map<String, dynamic>.from(item as Map))
        .toList() ?? [];
    
    // Conversión de Status (String -> Enum)
    final String statusString = data['status'] as String? ?? 'pending_payment';
    final OrderStatus status = OrderStatus.values.firstWhere(
      (e) => e.name == statusString,
      orElse: () => OrderStatus.pendingPayment,
    );

    // Conversión de DeliveryType (String -> Enum)
    final String deliveryString = data['deliveryType'] as String? ?? 'pickup';
    final DeliveryType deliveryType = DeliveryType.values.firstWhere(
      (e) => e.name == deliveryString,
      orElse: () => DeliveryType.pickup,
    );

    return OrderModel(
      id: doc.id,
      providerId: data['providerId'] as String? ?? '',
      clientId: data['clientId'] as String? ?? '',
      clientName: data['clientName'] as String? ?? 'N/A',
      clientEmail: data['clientEmail'] as String? ?? 'N/A',
      items: itemsList,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      status: status,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
      paymentProofUrl: data['paymentProofUrl'] as String? ?? '',
      paymentMethodId: data['paymentMethodId'] as String? ?? '',
      clientNotes: data['clientNotes'] as String?,
      providerNote: data['providerNote'],
      
      // Campos logísticos
      deliveryType: deliveryType,
      shippingAddress: data['shippingAddress'] as String? ?? '',
      shippingCost: (data['shippingCost'] as num?)?.toDouble() ?? 0.0,

      // Campo de reputación (NUEVO)
      isRated: data['isRated'] as bool? ?? false, 
    );
  }

  /// Método: Modelo Dart -> Mapa JSON (Firestore)
  Map<String, dynamic> toJson() {
    return {
      'providerId': providerId,
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'items': items,
      'total': total,
      'status': status.name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'paymentProofUrl': paymentProofUrl,
      'paymentMethodId': paymentMethodId,
      'clientNotes': clientNotes,
      'providerNote': providerNote,
      
      // Campos logísticos
      'deliveryType': deliveryType.name,
      'shippingAddress': shippingAddress,
      'shippingCost': shippingCost,

      // Campo de reputación (NUEVO)
      'isRated': isRated,
    };
  }
}