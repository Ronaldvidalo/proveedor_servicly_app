// /lib/ai/services/servi_conversational_service.dart

import 'package:proveedor_servicly_app/ai/services/gemini_service.dart';
import 'package:proveedor_servicly_app/ai/model/intention_result_model.dart'; 
import 'dart:async'; 
import 'dart:convert'; 
import 'package:flutter/foundation.dart'; // Para debugPrint

// CLAVE: Importamos el conector dedicado con un prefijo para que el compilador lo distinga.
import 'package:proveedor_servicly_app/ai/services/servi_api_connector_service.dart' as Connector; 


// --- CLASE SERVICIO CONVERSACIONAL (Paso 5: Mapeo Final) ---
class ServiConversationalService {
    
    // El constructor espera el tipo del archivo dedicado (usando el prefijo).
    final Connector.ServiApiConnectorService _apiConnector; 
    
    ServiConversationalService(this._apiConnector);

    /// Orquesta el proceso de respuesta. La lógica de INTENCIONES y BYPASS
    /// se ejecuta dentro de _apiConnector.callServiLLM.
    Future<IntentionResultModel> processQueryAndRespond(String query, String userId) async {
        
        try {
            // 1. LLAMADA AL CONECTOR CONTEXTUAL (Paso 2, 3, 4)
            // Esta función internamente:
            // a) Ejecuta el bypass para "hola" y "quien eres?".
            // b) Construye el COMPANY_CONTEXT (para itinerario, ventas, etc.).
            // c) Llama a la API de Gemini (con el system prompt y el contexto).
            
            final Map<String, dynamic> rawLlmResponse = await _apiConnector.callServiLLM(query, userId); 
            
            // 2. MAPEO DE SALIDA (Paso 5)
            // Mapeamos el JSON limpio a nuestro modelo IntentionResultModel (TEXTO_ESCRITO / TEXTO_VOZ).
            final result = IntentionResultModel.fromJson(rawLlmResponse);

            return result;
        } catch (e) {
            debugPrint('Error en ServiConversationalService: $e');
            // Devolver un error en el formato de salida esperado si la llamada falla.
            return IntentionResultModel(
                responseText: "Error crítico al contactar al asistente. Intenta de nuevo.",
                ttsText: "Error crítico."
            );
        }
    }
}