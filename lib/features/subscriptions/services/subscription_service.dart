import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Actualiza el perfil del usuario tras un pago exitoso
  Future<void> upgradeUserPlan({
    required String userId,
    required String planId, // 'plan_pro' o 'plan_corp'
    required double amountPaid,
  }) async {
    try {
      // Calculamos la fecha de expiración (Ej: 30 días desde hoy)
      final DateTime now = DateTime.now();
      final DateTime expiryDate = now.add(const Duration(days: 30));

      // Determinamos el tipo de plan string para la DB
      String planType = 'free';
      if (planId == 'plan_pro') planType = 'pro';
      if (planId == 'plan_corp') planType = 'corporate';

      // 1. Actualizamos el documento del usuario
      await _firestore.collection('users').doc(userId).set({
        'planType': planType,
        'isPremium': true,
        'subscriptionExpiry': Timestamp.fromDate(expiryDate),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Guardar registro de la transacción
      await _firestore.collection('users').doc(userId).collection('payments').add({
        'amount': amountPaid,
        'planId': planId,
        'status': 'completed',
        'provider': 'paypal',
        'date': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print("✅ Usuario $userId actualizado a plan $planType");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error actualizando suscripción: $e");
      }
      throw Exception('Error al activar la suscripción en base de datos.');
    }
  } // <--- ESTA LLAVE FALTABA EN TU CÓDIGO ANTERIOR

  /// Verifica si la suscripción ha vencido y degrada al usuario si es necesario.
  Future<void> checkSubscriptionStatus(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final isPremium = data['isPremium'] ?? false;
      final Timestamp? expiryTimestamp = data['subscriptionExpiry'];

      // Si no es premium, no hay nada que revisar
      if (!isPremium || expiryTimestamp == null) return;

      final DateTime expiryDate = expiryTimestamp.toDate();
      final DateTime now = DateTime.now();

      // SI YA VENCIÓ
      if (expiryDate.isBefore(now)) {
        if (kDebugMode) {
          print("⚠️ Suscripción vencida para $userId. Degradando a FREE.");
        }
        
        // Degradamos el usuario a FREE
        await _firestore.collection('users').doc(userId).update({
          'isPremium': false,
          'planType': 'free',
          'role': null, 
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error verificando suscripción: $e");
      }
    }
  }
}