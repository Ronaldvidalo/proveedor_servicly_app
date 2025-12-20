import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint
import 'package:proveedor_servicly_app/core/models/order_model.dart';

/// Un servicio dedicado a gestionar todas las operaciones
/// relacionadas con la colección 'orders'.
class OrderService {
  final FirebaseFirestore _db;

  OrderService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  /// 1. createOrder(OrderModel order)
  /// Lo llama el cliente al pagar (después de subir el comprobante).
  Future<DocumentReference> createOrder(OrderModel order) async {
    try {
      final data = order.toJson();
      // Usamos .add() para que Firestore cree el ID del documento
      final docRef = await _db.collection('orders').add(data);
      return docRef;
    } catch (e) {
      debugPrint('[OrderService] Error al crear la orden: $e');
      rethrow;
    }
  }

  /// 2. getPendingOrders(String providerId)
  /// Devuelve un Stream de las órdenes pendientes para el proveedor.
  Stream<List<OrderModel>> getPendingOrders(String providerId) {
    return _db
        .collection('orders')
        .where('providerId', isEqualTo: providerId)
        .where('status', isEqualTo: OrderStatus.pending_verification.name)
        .orderBy('createdAt', descending: false) // Las más antiguas primero
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    });
  }

  /// 3. getCompletedOrders(String providerId)
  /// Devuelve un Stream de las órdenes completadas.
  Stream<List<OrderModel>> getCompletedOrders(String providerId) {
    return _db
        .collection('orders')
        .where('providerId', isEqualTo: providerId)
        .where('status', isEqualTo: OrderStatus.completed.name)
        .orderBy('updatedAt', descending: true) // Las más recientes primero
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    });
  }

  /// 4. getCancelledOrders(String providerId)
  /// Devuelve un Stream de las órdenes rechazadas o canceladas.
  Stream<List<OrderModel>> getCancelledOrders(String providerId) {
    return _db
        .collection('orders')
        .where('providerId', isEqualTo: providerId)
        .where('status', isEqualTo: OrderStatus.cancelled.name)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    });
  }

  /// 5. updateOrderStatus(String orderId, OrderStatus newStatus)
  /// Lo llama el proveedor al aprobar o rechazar un pedido.
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'status': newStatus.name,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('[OrderService] Error al actualizar estado de la orden: $e');
      rethrow;
    }
  }

  /// 6. getMyOrders(String clientId)
  /// Para que el cliente vea sus propias compras.
  Stream<List<OrderModel>> getMyOrders(String clientId) {
    return _db
        .collection('orders')
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    });
  }

  // --- 7. NUEVO MÉTODO PARA CALIFICAR PROVEEDOR ---
  /// Calcula el nuevo promedio del proveedor, guarda la reseña 
  /// y marca la orden como calificada en una sola transacción.
  Future<void> rateProvider({
    required String orderId,
    required String providerId,
    required String clientId,
    required double rating,
    required String comment,
  }) async {
    final providerRef = _db.collection('users').doc(providerId);
    final orderRef = _db.collection('orders').doc(orderId);
    final reviewRef = _db.collection('reviews').doc(); // ID automático para la review

    return _db.runTransaction((transaction) async {
      final providerDoc = await transaction.get(providerRef);
      
      if (!providerDoc.exists) throw Exception("El proveedor no existe");

      // 1. Obtener datos actuales del proveedor
      final data = providerDoc.data()!;
      // Nos aseguramos de manejar nulos y tipos correctamente
      double currentAvg = (data['ratingAvg'] ?? 0).toDouble();
      int currentCount = (data['ratingCount'] ?? 0) as int;

      // 2. Calcular nuevo promedio ponderado
      // Fórmula: ((PromedioActual * Cantidad) + NuevoRating) / (Cantidad + 1)
      double newAvg = ((currentAvg * currentCount) + rating) / (currentCount + 1);

      // 3. Actualizar estadísticas del Proveedor
      transaction.update(providerRef, {
        'ratingAvg': newAvg,
        'ratingCount': currentCount + 1,
      });

      // 4. Marcar la Orden como "Calificada"
      transaction.update(orderRef, {
        'isRated': true,
      });

      // 5. Guardar la Reseña en la colección 'reviews'
      transaction.set(reviewRef, {
        'providerId': providerId,
        'clientId': clientId,
        'orderId': orderId,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}