// /lib/ai/services/gemini_service.dart

import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart'; 
import 'package:http/http.dart' as http; 
import 'package:flutter/services.dart'; // Para rootBundle
import 'dart:async'; // Necesario para Future

// Asumimos que esta ruta contiene la definición de la clase Invoice que USAMOS en extractDataFromImage
// import 'package:proveedor_servicly_app/ai/model/ai_response_model.dart'; 

// --- DEFINICIONES GLOBALES ---
const String GEMINI_API_KEY_DIRECT = "AIzaSyCdllmf1WIWgiIGdQQWqjRYs1IcRet6cvw"; 
const String MODEL_TO_CALL = 'gemini-2.5-flash';
// -----------------------------


class GeminiService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;


  // --- MÉTODOS EXISTENTES (OCR, Clasificación) ---

  // NOTA: Para resolver el conflicto de tipos en la pantalla de escaneo, 
  // esta función debe devolver la clase Invoice definida en ai_response_model.dart
  Future<Invoice> extractDataFromImage(String base64Image) async {
      throw UnimplementedError('extractDataFromImage not fully implemented in example');
  }

  Future<String> suggestCategory(String productName) async {
      return 'General';
  }
  
  Future<String> classifyTransaction(String description, List<String> categories) async {
      return 'Gasto General';
  }

  Future<List<String>> predictClientRecommendations(String clientId, List<String> productNamesList, List<String> clientHistory) async {
      return ['Error: No se pudieron obtener las sugerencias.'];
  }
  
  // --- FUNCIÓN HELPER: LECTURA DEL PROMPT DE SERVI ---
  Future<String> _readSystemPromptFromFile() async {
    try {
      const String promptPath = 'assets/prompts/servi_system_prompt.txt'; 
      return await rootBundle.loadString(promptPath);
    } catch (e) {
      debugPrint('Error al leer el prompt del sistema: $e');
      // Mensaje de respaldo que sigue el formato de SERVI
      return "ROL: Eres SERVI, un asistente experto. Sé conciso y profesional. Devuelve solo JSON estricto: { \"TEXTO_ESCRITO\": \"...\", \"TEXTO_VOZ\": \"...\" }";
    }
  }

  // FUNCIÓN HELPER: Parseo robusto del JSON
  String _cleanAndIsolateJson(String rawText) {
      final regex = RegExp(r'\{.*\}', dotAll: true);
      final match = regex.firstMatch(rawText);
      
      if (match != null) {
          return match.group(0)!.trim();
      }
      debugPrint('ERROR PARSING: No se encontró JSON en la respuesta del LLM.');
      return '{}';
  }


  // --- MVP 3.0: ASISTENTE CONVERSACIONAL CONTEXTUAL (MÉTODO CENTRAL) ---
  
  /// IMPLEMENTACIÓN DEL MÉTODO REQUERIDO: callContextualLLM
  Future<Map<String, dynamic>> callContextualLLM(
      String query, 
      Map<String, dynamic> context
  ) async {
    try {
      
      // 1. Cargar el Prompt del Sistema
      final String systemPrompt = await _readSystemPromptFromFile();
      final String apiEndpoint = 'https://generativelanguage.googleapis.com/v1beta/models/$MODEL_TO_CALL:generateContent?key=$GEMINI_API_KEY_DIRECT';
      
      // 2. Ensamblar Contenido del Usuario
      final String contextJsonString = json.encode(context);
      final String userContent = (
        "--- CONTEXTO DINÁMICO DE LA EMPRESA ---\n\n"
        "${contextJsonString}\n\n"
        "--- PREGUNTA DEL USUARIO ---\n\n"
        "${query}"
      );
      
      // 3. Estructura de la Solicitud JSON (Payload con roles system y user)
      final Map<String, dynamic> requestBody = {
        "contents": [
          // Rol del Sistema
          {
            "role": "system",
            "parts": [{"text": systemPrompt}]
          },
          // Rol del Usuario
          {
            "role": "user",
            "parts": [{"text": userContent}]
          }
        ],
        "config": { 
            "temperature": 0.1, 
            "responseMimeType": "application/json"
        }
      };
      
      final response = await http.post(
          Uri.parse(apiEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestBody),
      );
      
      if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          
          final rawText = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
          
          // 4. Limpieza y Parseo Robusto
          final cleanedJsonText = _cleanAndIsolateJson(rawText);
          
          // Devolvemos el Mapa JSON limpio (TEXTO_ESCRITO y TEXTO_VOZ)
          return json.decode(cleanedJsonText) as Map<String, dynamic>;
      } else {
          debugPrint('Error LLM (código ${response.statusCode}): ${response.body}');
          throw Exception('SERVI falló en la llamada a la IA: Código ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error CRÍTICO en callContextualLLM: $e');
      return {
          "TEXTO_ESCRITO": "¡Error crítico! El servicio SERVI falló al procesar su solicitud. Intente de nuevo.",
          "TEXTO_VOZ": "Hubo un error crítico en el sistema de SERVI.",
      };
    }
  }
}

// Clase placeholder necesaria para el código original:
class Invoice {
  Invoice.fromJson(Map<String, dynamic> json);
}