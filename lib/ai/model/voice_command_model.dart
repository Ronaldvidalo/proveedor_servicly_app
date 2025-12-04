// Define todas las intenciones que puede manejar el sistema.
enum VoiceIntent { 
  saludo,
  crear_evento,
  proxima_cita,
  cancelar_evento,
  anadir_cliente,
  cambiar_estado,
  // ... otras intenciones (stock, finanzas, etc.)
  desconocida,
}

/// Modelo que encapsula el resultado del NLU
class VoiceCommandResult {
  final VoiceIntent intent;
  final Map<String, dynamic> entities; // Los parámetros extraídos

  VoiceCommandResult({
    required this.intent,
    this.entities = const {},
  });
}