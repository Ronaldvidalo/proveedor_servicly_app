import 'package:cloud_firestore/cloud_firestore.dart';

// --- NUEVO ENUM CON 'pending_payment' AÑADIDO ---
// Usar un Enum para los estados de la orden es una práctica mucho
// más limpia y segura que usar Strings sueltos.
enum OrderStatus {
  pending_payment,      // <--- ¡NUEVO! El cliente NO ha subido el comprobante (ej. acaba de crear la orden)
  pending_verification, // El cliente subió el comprobante, el proveedor debe revisar
  completed,            // El proveedor confirmó el pago
  cancelled,            // El proveedor o cliente canceló la orden
  disputed              // (Futuro) El cliente o proveedor inició una disputa
}
// --- FIN NUEVO ENUM ---

/// Modelo que representa una orden de compra/servicio.
/// Creado para el flujo de pago P2P (verificación manual).
class OrderModel {
  final String id;
  final String providerId; // A quién se le compró
  final String clientId;   // Quién compró

  // --- Detalles del Cliente (Copia) ---
  // Guardamos una copia por si el cliente borra su cuenta,
  // la orden mantiene su información.
  final String clientName;
  final String clientEmail;
  
  // --- Detalles del Producto/Servicio ---
  // Guardamos los items como una lista de mapas.
  // Esto permite carritos de compra (múltiples productos).
  final List<Map<String, dynamic>> items;
  // Ejemplo de un item:
  // {
  // 	'productId': 'xyz123',
  // 	'name': 'Servicio de Plomería',
  // 	'price': 50.00,
  // 	'quantity': 1,
  // }

  final double total;
  final OrderStatus status; // <-- ¡Usamos el Enum!
  final Timestamp createdAt;
  Timestamp? updatedAt; // Para saber cuándo se completó o canceló

  // --- ¡Datos Clave para P2P! ---
  
  /// La URL (en Firebase Storage) de la foto del comprobante de pago
  /// que subió el cliente.
  final String paymentProofUrl; 
  
  /// El ID del método de pago que usó el cliente (para referencia).
  /// Ej: 'method_abc123' (que apunta a la cuenta de Banco Galicia del proveedor).
  final String paymentMethodId; 
  
  /// Notas opcionales que el cliente puede añadir al pagar.
  final String? clientNotes;

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
  });

  /// Convierte un documento de Firestore a una instancia de [OrderModel].
  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Conversión segura de Lista de Items
    final List<Map<String, dynamic>> itemsList = (data['items'] as List<dynamic>?)
        ?.map((item) => Map<String, dynamic>.from(item as Map))
        .toList() ??
        [];
    
    // Conversión segura del String del 'status' al Enum 'OrderStatus'
    final String statusString = data['status'] as String? ?? 'pending_verification';
    final OrderStatus status = OrderStatus.values.firstWhere(
      (e) => e.name == statusString,
      // Si el estado no se encuentra, usamos 'pending_payment' como un default seguro
      // en lugar de 'pending_verification' si la orden es nueva, aunque 'pending_verification'
      // también es una opción válida si prefieres ese default. 
      // Mantenemos 'pending_verification' como lo tenías.
      orElse: () => OrderStatus.pending_verification,
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
    );
  }

  /// Convierte la instancia del modelo a un mapa para guardarlo en Firestore.
  Map<String, dynamic> toJson() {
    return {
      'providerId': providerId,
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'items': items,
      'total': total,
      'status': status.name, // <-- Guardamos el Enum como String
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'paymentProofUrl': paymentProofUrl,
      'paymentMethodId': paymentMethodId,
      'clientNotes': clientNotes,
    };
  }
}