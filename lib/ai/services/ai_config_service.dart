// /lib/core/services/ai_config_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint

class AiConfigService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Colección para la configuración global de la IA
  // ✅ CORRECCIÓN: Nombre cambiado a lowerCamelCase
  static const String _configDocPath = 'settings/ai_config';

  /// Obtiene la configuración de SERVI en tiempo real (Stream).
  Stream<Map<String, dynamic>> getAiConfigStream() {
    return _firestore.doc(_configDocPath)
        .snapshots()
        .map((snapshot) => snapshot.data() ?? {
          // Valores por defecto seguros (Fallback)
          "ocr_model": "gemini-2.5-flash", 
          "cost_alert_threshold": 0.20,
          "is_ai_enabled": true,
          "recommendation_engine": "gemini-2.5-flash"
        });
  }

  /// Obtiene la configuración una sola vez (Future).
  Future<Map<String, dynamic>> getAiConfigOnce() async {
    try {
      final doc = await _firestore.doc(_configDocPath).get();
      return doc.data() ?? {
          "ocr_model": "gemini-2.5-flash", 
          "cost_alert_threshold": 0.20,
          "is_ai_enabled": true,
          "recommendation_engine": "gemini-2.5-flash"
      };
    } catch (e) {
      debugPrint("Error al obtener configuración de AI desde Firestore: $e");
       return {
          "ocr_model": "gemini-2.5-flash", 
          "cost_alert_threshold": 0.20,
          "is_ai_enabled": true
      };
    }
  }
}