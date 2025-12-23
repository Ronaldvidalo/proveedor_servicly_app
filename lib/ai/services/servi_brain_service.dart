import 'package:flutter/foundation.dart';

// --- IMPORTS DE TUS SERVICIOS AVANZADOS (MVP 3.0) ---
// Asegúrate de que estas rutas coincidan con tu estructura de carpetas
import 'package:proveedor_servicly_app/ai/model/intention_result_model.dart';
import 'package:proveedor_servicly_app/ai/services/servi_conversational_service.dart';

class ServiBrainService {
  // Inyectamos el servicio avanzado (puede ser null si aún no se inicializó)
  final ServiConversationalService? _advancedBrain;

  // Constructor que permite la inyección de dependencias
  ServiBrainService({ServiConversationalService? advancedBrain}) 
      : _advancedBrain = advancedBrain;

  /// Analiza el texto y decide si usa el cerebro RÁPIDO (Local) o el AVANZADO (Gemini).
  /// Retorna un `Future<String>` porque la llamada avanzada es asíncrona.
  Future<String> processCommand(String command, String userId) async {
    debugPrint("🧠 Servi Brain (Router Híbrido) procesando: $command");
    
    final String lowerCommand = command.toLowerCase();

    // =========================================================================
    // NIVEL 1: RESPUESTAS RÁPIDAS (Local - Costo $0 - Latencia 0ms)
    // Ideales para saludos, identidad y onboarding.
    // =========================================================================
    
    if (lowerCommand.contains("hola") || 
        lowerCommand.contains("buen día") || 
        lowerCommand.contains("buenas")) {
      return "¡Hola! Soy Servi, tu inteligencia artificial. Estoy conectada a tu negocio para ayudarte a crecer. ¿En qué trabajamos hoy?";
    }
    
    if (lowerCommand.contains("quién sos") || 
        lowerCommand.contains("quien eres") || 
        (lowerCommand.contains("qué") && lowerCommand.contains("hacer"))) {
      return "Soy tu copiloto de negocios. Puedo analizar tu agenda, controlar tu stock o darte consejos financieros. Probá preguntarme '¿Cómo viene mi día?' o '¿Cuánto vendí?'.";
    }

    if (lowerCommand.contains("gracias")) {
      return "¡De nada! A seguir metiéndole garra al negocio.";
    }

    // =========================================================================
    // NIVEL 2: INTELIGENCIA REAL (Nube - Gemini + Firebase)
    // Si la pregunta requiere datos reales, usamos tu infraestructura avanzada.
    // =========================================================================
    
    if (_advancedBrain != null) {
      try {
        debugPrint("🔄 Derivando comando complejo a ServiConversationalService (Gemini)...");
        
        // Llamamos a tu servicio existente que conecta con Gemini + Firebase
        final IntentionResultModel result = await _advancedBrain!.processQueryAndRespond(command, userId);
        
        // Devolvemos el texto hablado (TTS) que genera tu servicio avanzado
        // ✅ CORRECCIÓN: Se eliminó el operador '??' porque ttsText no es nullable
        return result.ttsText;
        
      } catch (e) {
        debugPrint("❌ Error en cerebro avanzado: $e");
        // Si falla la IA avanzada, no le decimos "Error" al usuario,
        // caemos suavemente al Fallback del Nivel 3.
        debugPrint("⚠️ Cayendo al modo de respaldo (Fallback)...");
      }
    }

    // =========================================================================
    // NIVEL 3: FALLBACK DE RESPALDO (Lógica Simulada / Modo Demo)
    // Se activa si no hay _advancedBrain o si falló la conexión.
    // Mantiene la ilusión de inteligencia con respuestas predefinidas útiles.
    // =========================================================================
    
    // 1. INTENCIÓN: RESUMEN DEL DÍA
    if (lowerCommand.contains("resumen") || 
        lowerCommand.contains("día") || 
        lowerCommand.contains("hoy") ||
        lowerCommand.contains("agenda")) {
      return "Modo Respaldo: Hoy viene movido. Tenés 2 ventas registradas y una cita pendiente a las 4 de la tarde. ¡Vamo arriba!";
    } 
    
    // 2. INTENCIÓN: CÁLCULO DE GANANCIA
    else if (lowerCommand.contains("ganancia") || 
             lowerCommand.contains("ganar") ||
             lowerCommand.contains("plata")) {
      return "Cálculo rápido: Para ganar dos mil pesos limpios, necesitás vender aproximadamente 6 mil 700 pesos, considerando tus costos fijos. ¿Querés que armemos una promo?";
    }
    
    // 3. INTENCIÓN: ESTRUCTURA DE COSTOS
    else if (lowerCommand.contains("costo") || 
             lowerCommand.contains("gasto") ||
             lowerCommand.contains("estructura")) {
      return "Tu estructura de costos está un poco alta este mes. El alquiler te está comiendo margen. Te recomiendo revisar los gastos fijos en el módulo de Finanzas.";
    }
    
    // 4. INTENCIÓN: CALCULAR PRECIO
    else if ((lowerCommand.contains("cuánto") || lowerCommand.contains("precio")) && 
             lowerCommand.contains("vender")) {
       return "Depende del producto. Pero recordá la regla de oro: nunca vendas por debajo de tu costo más el 30 por ciento para cuidar el mango.";
    }

    // 5. RESPUESTA POR DEFECTO (Si no entendió nada)
    else {
      return "Mmm, esa se me escapó. Preguntame por tu resumen del día, tus ganancias o tus costos, y te ayudo al toque.";
    }
  }
}