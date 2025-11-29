// /lib/providers/app_providers.dart (FRAGMENTO DE ADICIÓN)

// ... (tus imports existentes)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proveedor_servicly_app/ai/services/ai_config_service.dart'; // Importa el servicio creado

// Provider para el servicio de configuración de IA
final aiConfigServiceProvider = Provider<AiConfigService>((ref) {
  return AiConfigService();
});

// StreamProvider para el estado de la configuración (observabilidad)
final aiConfigStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
    return ref.watch(aiConfigServiceProvider).getAiConfigStream();
});
// ... (continúan otros providers)