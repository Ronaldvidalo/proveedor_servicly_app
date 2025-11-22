import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint

/// Servicio responsable de registrar eventos de comportamiento del cliente
/// en el perfil público. Estos datos alimentan las analíticas Pro.
class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Ruta de la colección central para eventos de analíticas.
  /// Usamos una ruta simple ya que estos datos son específicos del proveedor.
  CollectionReference _getEventsCollection(String providerId) {
    return _firestore.collection('users').doc(providerId).collection('public_events');
  }

  /// Registra un evento de comportamiento del cliente/visitante.
  /// Ejemplos de eventos: 'product_viewed', 'cart_abandoned', 'profile_visited'.
  Future<void> logEvent({
    required String eventName,
    required String providerId,
    required Map<String, dynamic> metadata,
  }) async {
    // 1. Obtener una ID única para el visitante actual (simulación: ID de sesión anónima)
    // En una aplicación real, usarías un ID de sesión persistente o anonimizado.
    final sessionId = _getAnonymousSessionId();

    try {
      await _getEventsCollection(providerId).add({
        'sessionId': sessionId,
        'eventName': eventName,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': metadata,
        'is_pro_event': true, // Marcamos estos como eventos PRO
      });
      debugPrint('Analytics Logged: $eventName for provider $providerId');
    } catch (e) {
      debugPrint('Error logging event to Firestore: $e');
    }
  }

  /// Genera un ID anónimo simple para la sesión del visitante.
  String _getAnonymousSessionId() {
    // Simulación de un ID anónimo, podría ser mejor con localStorage o cookies en web.
    // Usamos el tiempo y un hash simple para mantenerlo corto.
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'anon_${timestamp.substring(timestamp.length - 6)}';
  }
}