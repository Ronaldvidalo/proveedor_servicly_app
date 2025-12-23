// Define todas las intenciones que puede manejar el sistema.
enum VoiceIntent { 
  saludo,
  crearEvento,
  proximaCita,
  cancelarEvento,
  anadirCliente,
  cambiarEstado,
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