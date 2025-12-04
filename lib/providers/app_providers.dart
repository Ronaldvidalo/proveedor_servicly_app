// /lib/providers/app_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proveedor_servicly_app/ai/services/ai_config_service.dart'; // Importa el servicio de configuración
import 'package:proveedor_servicly_app/ai/services/gemini_service.dart'; // Importa la clase GeminiService
import 'package:firebase_auth/firebase_auth.dart'; // Necesario para la inicialización (si es el provider central)
import 'package:cloud_firestore/cloud_firestore.dart'; // Necesario para la inicialización (si es el provider central)

// --- PROVIDER DE SERVICIO DE GEMINI (NUEVO) ---
// Este es el provider que faltaba y que resolvía el Undefined Name.
final geminiServiceProvider = Provider<GeminiService>((ref) {
  // Asumimos que GeminiService no necesita repositorios para inicializarse,
  // solo la instancia de FirebaseFunctions que es interna en el servicio.
  return GeminiService();
});

// --- PROVIDER DE CONFIGURACIÓN DE IA (MVP 2.0) ---
final aiConfigServiceProvider = Provider<AiConfigService>((ref) {
  return AiConfigService();
});

// StreamProvider para el estado de la configuración (observabilidad)
final aiConfigStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
    return ref.watch(aiConfigServiceProvider).getAiConfigStream();
});

// --- OTROS PROVIDERS BASE (Ejemplos asumidos, si ya están en otros archivos, esto puede ser redundante) ---

// Provider simple para la instancia de FirebaseAuth, si lo usas en otros providers
final authProvider = Provider((ref) => FirebaseAuth.instance);

// Provider simple para la instancia de Firestore
final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

// Provider que expone la ID del usuario para inyección
final userIdProvider = Provider((ref) => ref.watch(authProvider).currentUser?.uid ?? '');
