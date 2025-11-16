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
  ///
  /// Toma un modelo de orden (sin ID) y lo añade a Firestore,
  /// dejando que Firestore genere el ID único.
  Future<DocumentReference> createOrder(OrderModel order) async {
    try {
      // Convertimos el modelo a JSON (el ID no se incluye en toJson)
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
  /// Lo llama el proveedor en ManageStoreScreen para ver qué ventas debe aprobar.
  ///
  /// Devuelve un Stream en tiempo real de las órdenes pendientes.
  Stream<List<OrderModel>> getPendingOrders(String providerId) {
    return _db
        .collection('orders')
        .where('providerId', isEqualTo: providerId)
        .where('status', isEqualTo: OrderStatus.pending_verification.name) // Filtra solo por pendientes
        .orderBy('createdAt', descending: false) // Muestra las más antiguas (urgentes) primero
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    });
    // Nota: Es posible que necesites un índice compuesto de Firestore para esta consulta.
    // Si ves un error en la consola, Firebase te dará el link para crearlo con un clic.
  }

  // --- ¡NUEVO MÉTODO AÑADIDO! ---
  /// 3. getCompletedOrders(String providerId)
  /// Devuelve un Stream de las órdenes que ya fueron aprobadas.
  Stream<List<OrderModel>> getCompletedOrders(String providerId) {
    return _db
        .collection('orders')
        .where('providerId', isEqualTo: providerId)
        .where('status', isEqualTo: OrderStatus.completed.name) // Filtra solo por completadas
        .orderBy('updatedAt', descending: true) // Muestra las más recientes primero
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    });
  }

  // --- ¡NUEVO MÉTODO AÑADIDO! ---
  /// 4. getCancelledOrders(String providerId)
  /// Devuelve un Stream de las órdenes que fueron rechazadas o canceladas.
  Stream<List<OrderModel>> getCancelledOrders(String providerId) {
    return _db
        .collection('orders')
        .where('providerId', isEqualTo: providerId)
        .where('status', isEqualTo: OrderStatus.cancelled.name) // Filtra solo por canceladas
        .orderBy('updatedAt', descending: true) // Muestra las más recientes primero
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    });
  }


  /// 5. updateOrderStatus(String orderId, OrderStatus newStatus)
  /// Lo llama el proveedor al aprobar ('completed') o rechazar ('cancelled') un pago.
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'status': newStatus.name,      // Actualiza el estado (como string)
        'updatedAt': Timestamp.now(), // Registra cuándo se hizo el cambio
      });
    } catch (e) {
      debugPrint('[OrderService] Error al actualizar estado de la orden: $e');
      rethrow;
    }
  }

  // (Opcional) Un método para que el cliente vea sus propias compras
  Stream<List<OrderModel>> getMyOrders(String clientId) {
     return _db
        .collection('orders')
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true) // Muestra las más nuevas primero
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    });
  }
}