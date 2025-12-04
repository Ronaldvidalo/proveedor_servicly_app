// Corresponde al JSON de salida {"TEXTO_ESCRITO": "...", "TEXTO_VOZ": "..."}

class IntentionResultModel {
  // TEXTO_ESCRITO: La versión formal y detallada para mostrar en el chat.
  final String responseText; 
  
  // TEXTO_VOZ: La versión corta y conversacional para el motor TTS.
  final String ttsText;

  final bool success;
  
  IntentionResultModel({
    required this.responseText,
    required this.ttsText,
    this.success = true,
  });

  // Constructor de fábrica para mapear el JSON de la API
  factory IntentionResultModel.fromJson(Map<String, dynamic> json) {
    return IntentionResultModel(
      responseText: json['TEXTO_ESCRITO'] ?? 'Error de formato: Falta TEXTO_ESCRITO.',
      ttsText: json['TEXTO_VOZ'] ?? 'Error de formato: Falta TEXTO_VOZ.',
    );
  }
}