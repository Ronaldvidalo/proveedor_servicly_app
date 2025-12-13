import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart'; 
import 'package:http/http.dart' as http; 
import 'package:flutter/services.dart'; 
import 'dart:async'; 

// --- DEFINICIONES GLOBALES ---
const String GEMINI_API_KEY_DIRECT = "AIzaSyAE0EYo632PQ6hxscpFsSqBrTn_O_y19T8"; 

// 🔴 USAMOS TU MODELO DISPONIBLE Y POTENTE
const String MODEL_TO_CALL = 'gemini-2.5-flash'; 
// -----------------------------


class GeminiService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;


  // --- MÉTODOS EXISTENTES ---

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
  
  // --- FUNCIÓN HELPER: LECTURA DEL PROMPT ---
  Future<String> _readSystemPromptFromFile() async {
    try {
      const String promptPath = 'assets/prompts/servi_system_prompt.txt'; 
      return await rootBundle.loadString(promptPath);
    } catch (e) {
      debugPrint('Error al leer el prompt del sistema: $e');
      return "ROL: Eres SERVI, un asistente experto. Sé conciso y profesional. Devuelve solo JSON estricto: { \"TEXTO_ESCRITO\": \"...\", \"TEXTO_VOZ\": \"...\" }";
    }
  }

  String _cleanAndIsolateJson(String rawText) {
      final regex = RegExp(r'\{.*\}', dotAll: true);
      final match = regex.firstMatch(rawText);
      if (match != null) return match.group(0)!.trim();
      return '{}';
  }


  // --- MVP 3.0: ASISTENTE CONVERSACIONAL CONTEXTUAL ---
  
  Future<Map<String, dynamic>> callContextualLLM(
      String query, 
      Map<String, dynamic> context
  ) async {
    try {
      
      final String systemPrompt = await _readSystemPromptFromFile();
      
      // 🔴 CAMBIO 1: API V1 (ESTABLE)
      final String apiEndpoint = 'https://generativelanguage.googleapis.com/v1/models/$MODEL_TO_CALL:generateContent?key=$GEMINI_API_KEY_DIRECT';
      
      debugPrint("📡 Conectando a Gemini ($MODEL_TO_CALL) en v1");

      final String contextJsonString = json.encode(context);
      final String userContent = (
        "--- CONTEXTO DINÁMICO DE LA EMPRESA ---\n\n"
        "${contextJsonString}\n\n"
        "--- PREGUNTA DEL USUARIO ---\n\n"
        "${query}"
      );
      
      final Map<String, dynamic> requestBody = {
        "contents": [
          // 🔴 CAMBIO 2: Roles separados (System / User)
          // Nota: En la API REST v1, a veces 'system' no se soporta como rol en 'contents'.
          // Si esto falla con 400, volveremos a fusionarlos, pero probemos la estructura ideal primero.
          // Para máxima seguridad en v1 REST, usaré la estructura de fusionado que NUNCA falla:
          {
            "role": "user",
            "parts": [{"text": "INSTRUCCIONES DEL SISTEMA:\n$systemPrompt\n\nDATOS DEL USUARIO:\n$userContent"}]
          }
        ],
        // 🔴 CAMBIO 3: Configuración limpia + Safety Settings
        "generationConfig": { 
            "temperature": 0.4
        },
        "safetySettings": [
          {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE"},
          {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_NONE"},
          {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_NONE"},
          {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_NONE"}
        ]
      };
      
      final response = await http.post(
          Uri.parse(apiEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestBody),
      );
      
      if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          
          if (jsonResponse['candidates'] == null || jsonResponse['candidates'].isEmpty) {
             throw Exception('Gemini devolvió una respuesta vacía.');
          }

          final rawText = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
          final cleanedJsonText = _cleanAndIsolateJson(rawText);
          
          return json.decode(cleanedJsonText) as Map<String, dynamic>;
      } else {
          debugPrint('Error LLM (código ${response.statusCode}): ${response.body}');
          throw Exception('SERVI falló en la llamada a la IA: Código ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error CRÍTICO en callContextualLLM: $e');
      return {
          "TEXTO_ESCRITO": "¡Error crítico! El servicio SERVI falló al procesar su solicitud. Intente de nuevo.",
          "TEXTO_VOZ": "Hubo un error crítico en el sistema de SERVI.",
      };
    }
  }

  // --- NUEVO MÉTODO: GENERACIÓN DE TEXTO SIMPLE ---
  Future<String?> generateText(String prompt) async {
    try {
      final String apiEndpoint = 'https://generativelanguage.googleapis.com/v1/models/$MODEL_TO_CALL:generateContent?key=$GEMINI_API_KEY_DIRECT';
      
      final Map<String, dynamic> requestBody = {
        "contents": [
          { "parts": [{"text": prompt}] }
        ],
        "generationConfig": { "temperature": 0.7 }
      };

      final response = await http.post(
          Uri.parse(apiEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          final text = jsonResponse['candidates']?[0]['content']?['parts']?[0]['text'];
          return text?.toString().trim();
      } else {
          return null;
      }
    } catch (e) {
      return null;
    }
  }
}

class Invoice {
  Invoice.fromJson(Map<String, dynamic> json);
}