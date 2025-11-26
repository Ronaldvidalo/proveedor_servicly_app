import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proveedor_servicly_app/core/models/order_model.dart';

class SalesRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SalesRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  String? get _userId => _auth.currentUser?.uid;

  /// Obtiene las ventas del usuario ordenadas por fecha (más reciente primero)
  Stream<List<OrderModel>> getSalesStream({int limit = 50}) {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('orders')
        .where('providerId', isEqualTo: _userId) // Solo mis ventas
        .orderBy('createdAt', descending: true) // Las nuevas arriba
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    });
  }
}