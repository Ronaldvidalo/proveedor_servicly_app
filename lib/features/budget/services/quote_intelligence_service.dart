// --- UX/UI Enhancement Comment ---
// Servicio: QuoteIntelligenceService
// Ubicación: lib/features/budget/services/quote_intelligence_service.dart
// Responsabilidad: Utilizar Gemini para profesionalizar textos de cotizaciones.

import 'package:proveedor_servicly_app/ai/services/gemini_service.dart';

class QuoteIntelligenceService {
  final GeminiService _geminiService;

  QuoteIntelligenceService(this._geminiService);

  /// Toma un texto informal y lo convierte en términos comerciales profesionales.
  Future<String> professionalizeTerms(String rawText) async {
    if (rawText.trim().isEmpty) return "";

    try {
      // Construimos un prompt específico para reescritura
      final prompt = """
      Actúa como un experto en redacción comercial y legal para contratos de servicios.
      Tu tarea es reescribir el siguiente texto informal que un proveedor escribió en sus notas de cotización.
      
      Texto original: "$rawText"
      
      Reglas:
      1. Convierte el texto en un lenguaje formal, educado y profesional.
      2. Mantén el sentido original (no cambies precios ni fechas si no están claros).
      3. Mejora la ortografía y gramática.
      4. Si es sobre pagos, usa términos como "Anticipo", "Contra entrega", "Saldo".
      5. Devuelve SOLAMENTE el texto reescrito, sin introducciones ni comillas.
      """;

      // Llamamos a Gemini (asumiendo que tu GeminiService tiene un método generateText o similar)
      // Ajusta 'generateText' al nombre real del método en tu GeminiService
      final response = await _geminiService.generateText(prompt); 
      
      return response ?? rawText; // Si falla, devolvemos el original
    } catch (e) {
      print("Error en IA: $e");
      return rawText; // Fallback seguro
    }
  }
}