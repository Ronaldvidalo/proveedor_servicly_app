import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; 
import 'package:proveedor_servicly_app/features/crm/core/crm_enums.dart'; // Necesario para el estado del lead

/// Servicio responsable de registrar eventos, métricas y notificaciones de sistema.
class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- 1. MÉTODO EXISTENTE (Raw Events) ---
  /// Registra un evento crudo para historial (útil para gráficas futuras).
  Future<void> logEvent({
    required String eventName,
    required String providerId,
    required Map<String, dynamic> metadata,
  }) async {
    final sessionId = _getAnonymousSessionId();
    try {
      // Guardamos en una subcolección de 'users' para no saturar 'brandProfiles'
      await _firestore.collection('users').doc(providerId).collection('public_events').add({
        'sessionId': sessionId,
        'eventName': eventName,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': metadata,
        'is_pro_event': true,
      });
      // debugPrint('Analytics Logged: $eventName');
    } catch (e) {
      debugPrint('Error logging event: $e');
    }
  }

  // --- 2. NUEVO MÉTODO: TRACKING INTELIGENTE CON HITOS ---
  /// Incrementa el contador de visitas y genera una notificación (Lead de Sistema)
  /// si se alcanza un hito según el plan (ej. cada 10 o 50 visitas).
  Future<void> trackProductView({
    required String providerId,
    required String planType,
    required String productName,
  }) async {
    // Guardamos los contadores en 'brandProfiles' para acceso rápido público
    final statsRef = _firestore
        .collection('brandProfiles')
        .doc(providerId)
        .collection('stats')
        .doc('visits'); 

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(statsRef);
        
        int totalVisits = 0;
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null && data.containsKey('total_product_views')) {
             totalVisits = data['total_product_views'] as int;
          }
        }

        // A. Incrementar Contador
        int newTotal = totalVisits + 1;
        
        transaction.set(statsRef, {
          'total_product_views': newTotal,
          'last_view_at': FieldValue.serverTimestamp(),
          // Opcional: Guardar último producto visto
          'last_product_seen': productName,
        }, SetOptions(merge: true));

        // B. Lógica de Notificación (Gamificación)
        int threshold = 10; // Default para Free (Agresivo)
        
        if (planType == 'pro' || planType == 'max') {
          threshold = 50; // Balanceado para planes pagos
        }

        // Si cruzamos el hito (ej: 10, 20, 30... o 50, 100...)
        if (newTotal > 0 && newTotal % threshold == 0) {
          _injectSystemLead(transaction, providerId, newTotal, planType);
        }
      });
    } catch (e) {
      // Los errores de analítica no deben romper la app
      debugPrint("⚠️ Error en AnalyticsService (Transaction): $e");
    }
  }

  // --- 3. HELPER: INYECTOR DE LEADS ---
  /// Crea un "Lead de Sistema" directamente en la transacción.
  /// Aparecerá en la pestaña CRM como un mensaje nuevo.
  void _injectSystemLead(Transaction transaction, String providerId, int count, String planType) {
    final newLeadRef = _firestore
        .collection('users')
        .doc(providerId)
        .collection('clientes')
        .doc(); // ID Automático

    String message = "🚀 ¡Felicidades! Tu tienda ha alcanzado $count visitas a productos.";
    
    if (planType == 'free') {
      message += "\n\n💡 Consejo: Los usuarios PRO convierten 3x más ventas contactando a quienes abandonan el carrito.";
    }

    transaction.set(newLeadRef, {
      'nombreCompleto': 'Asistente Servicly 🤖',
      'email': '',
      'telefono': '',
      // Usamos 'leadNuevo' para que aparezca arriba y active notificaciones
      'estadoCRM': CrmEstado.leadNuevo.name, 
      'fechaAlta': FieldValue.serverTimestamp(),
      'ultimaInteraccion': FieldValue.serverTimestamp(),
      'source': 'system_milestone', // Fuente especial para identificarlo (puedes ponerle icono de trofeo luego)
      'montoTotalFacturado': 0.0,
      'etiquetas': ['sistema', 'hito_trafico'],
      'notasInternas': message,
      // Icono especial para el sistema
      'photoUrl': 'https://cdn-icons-png.flaticon.com/512/3237/3237472.png', 
      'location': 'Sistema',
    });
    
    debugPrint("🔔 Notificación de Hito enviada: $count visitas");
  }

  String _getAnonymousSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'anon_${timestamp.substring(timestamp.length - 6)}';
  }
}