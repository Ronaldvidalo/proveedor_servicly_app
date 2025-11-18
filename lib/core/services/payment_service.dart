import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proveedor_servicly_app/core/models/payment_method_model.dart';

/// Servicio para gestionar los métodos de pago P2P del proveedor en Firestore.
class PaymentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Devuelve la referencia a la subcolección de métodos de pago de un usuario.
  CollectionReference<Map<String, dynamic>> _getMethodsCollection(String userId) {
    return _db.collection('brandProfiles').doc(userId).collection('paymentMethods');
  }

  // =========================================================================
  //                            MÉTODOS DE LECTURA
  // =========================================================================

  /// Obtiene un Stream de la lista de métodos de pago.
  Stream<List<PaymentMethodModel>> getPaymentMethodsStream(String userId) {
    return _getMethodsCollection(userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentMethodModel.fromFirestore(doc))
            .toList());
  }

  /// Obtiene un documento de método de pago específico por su ID.
  ///
  /// Usado por el cliente para ver los detalles del método utilizado en la orden.
  Future<DocumentSnapshot> getPaymentMethodDoc(String userId, String methodId) {
    return _getMethodsCollection(userId).doc(methodId).get();
  }

  // =========================================================================
  //                          MÉTODOS DE ESCRITURA
  // =========================================================================

  /// Añade un nuevo método de pago.
  ///
  /// Si es el primer método del usuario, lo marca automáticamente como primario.
  Future<void> addPaymentMethod(String userId, PaymentMethodModel method) async {
    // Si este es el PRIMER método, lo marcamos como primario por defecto.
    final snapshot = await _getMethodsCollection(userId).limit(1).get();
    final bool isFirstMethod = snapshot.docs.isEmpty;

    final newMethod = method.copyWith(isPrimary: isFirstMethod);
    await _getMethodsCollection(userId).add(newMethod.toJson());
  }

  /// Actualiza un método de pago existente.
  Future<void> updatePaymentMethod(String userId, PaymentMethodModel method) async {
    await _getMethodsCollection(userId).doc(method.id).update(method.toJson());
  }

  /// Elimina un método de pago.
  ///
  /// Si el método eliminado era el primario, asigna uno nuevo (si queda alguno).
  Future<void> deletePaymentMethod(String userId, String methodId) async {
    final docRef = _getMethodsCollection(userId).doc(methodId);
    final doc = await docRef.get();

    if (!doc.exists) return; // Ya no existe

    final wasPrimary = (doc.data() as Map<String, dynamic>)['isPrimary'] as bool? ?? false;

    await docRef.delete();

    // Si el eliminado era el primario, reasignamos.
    if (wasPrimary) {
      final remainingMethods = await _getMethodsCollection(userId).limit(1).get();
      if (remainingMethods.docs.isNotEmpty) {
        // Asigna el primero que encuentra como primario
        await setPrimaryMethod(userId, remainingMethods.docs.first.id);
      }
    }
  }

  // =========================================================================
  //                             UTILIDADES
  // =========================================================================

  /// Establece un método como primario y desmarca todos los demás.
  Future<void> setPrimaryMethod(String userId, String newPrimaryMethodId) async {
    final batch = _db.batch();
    final collectionRef = _getMethodsCollection(userId);

    // 1. Obtiene todos los métodos actuales
    final snapshot = await collectionRef.get();

    for (var doc in snapshot.docs) {
      if (doc.id == newPrimaryMethodId) {
        // 2. Marca el nuevo como primario
        batch.update(doc.reference, {'isPrimary': true});
      } else {
        // 3. Desmarca cualquier otro que fuera primario
        final data = doc.data() as Map<String, dynamic>;
        if (data['isPrimary'] == true) {
          batch.update(doc.reference, {'isPrimary': false});
        }
      }
    }

    await batch.commit();
  }
}