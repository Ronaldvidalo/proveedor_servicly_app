import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// --- CONFIGURACIÓN ---
// Mantenemos tu API Key y tu modelo preferido
const String _kApiKey = "AIzaSyAE0EYo632PQ6hxscpFsSqBrTn_O_y19T8"; 
const String _kModelName = 'gemini-2.5-flash'; 

class GeminiService {
  late final GenerativeModel _model;
  late final GenerativeModel _jsonModel;

  GeminiService() {
    // 1. Modelo Estándar (Texto general)
    _model = GenerativeModel(
      model: _kModelName,
      apiKey: _kApiKey,
    );

    // 2. Modelo Configurado para JSON (Para el asistente contextual y OCR)
    // Esto asegura que la IA responda siempre con JSON válido.
    _jsonModel = GenerativeModel(
      model: _kModelName,
      apiKey: _kApiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json', 
        temperature: 0.4,
      ),
    );
  }

  // --- MVP 1.0: EXTRACT DATA FROM IMAGE (OCR INTELIGENTE) ---
  Future<Invoice?> extractDataFromImage(String base64Image) async {
    try {
      // Decodificamos la imagen
      final Uint8List imageBytes = base64Decode(base64Image);

      final prompt = TextPart(
        "Eres un experto en digitalización. Extrae los siguientes datos de esta factura: "
        "'vendorName', 'invoiceNumber', 'totalAmount' (número), y 'lineItems' (lista). "
        "Responde solo con JSON."
      );

      final imagePart = DataPart('image/jpeg', imageBytes);

      // Usamos el modelo JSON para asegurar parseo fácil
      final response = await _jsonModel.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      if (response.text == null) return null;

      final jsonMap = jsonDecode(response.text!) as Map<String, dynamic>;
      return Invoice.fromJson(jsonMap);

    } catch (e) {
      debugPrint('Error en OCR Gemini: $e');
      return null;
    }
  }

  // --- MVP 3.0: ASISTENTE CONVERSACIONAL CONTEXTUAL ---
  Future<Map<String, dynamic>> callContextualLLM(
      String query, 
      Map<String, dynamic> context
  ) async {
    try {
      final String systemPrompt = await _readSystemPromptFromFile();
      
      // Construimos el prompt enriquecido
      final fullPrompt = """
      INSTRUCCIONES DEL SISTEMA:
      $systemPrompt

      CONTEXTO DEL NEGOCIO (JSON):
      ${jsonEncode(context)}

      PREGUNTA DEL USUARIO:
      $query
      """;

      // Llamamos al modelo JSON. Ya no necesitamos expresiones regulares complejas.
      final response = await _jsonModel.generateContent([
        Content.text(fullPrompt)
      ]);

      if (response.text == null) throw Exception("Respuesta vacía de Gemini");

      return jsonDecode(response.text!) as Map<String, dynamic>;

    } catch (e) {
      debugPrint('Error CRÍTICO en callContextualLLM: $e');
      // Respuesta de fallback segura
      return {
        "TEXTO_ESCRITO": "Lo siento, hubo un error técnico al procesar tu solicitud.",
        "TEXTO_VOZ": "Ocurrió un error en el sistema.",
      };
    }
  }

  // --- GENERACIÓN DE TEXTO SIMPLE ---
  Future<String?> generateText(String prompt) async {
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text;
    } catch (e) {
      debugPrint("Error generando texto: $e");
      return null;
    }
  }

  // --- HELPER: CLASIFICACIÓN ---
  Future<String> classifyTransaction(String description, List<String> categories) async {
    try {
      final prompt = "Clasifica la transacción '$description' en una de estas categorías: ${categories.join(', ')}. Responde SOLO con el nombre de la categoría.";
      final response = await _model.generateContent([Content.text(prompt)]);
      // Limpieza básica por si la IA pone punto final o comillas
      return response.text?.trim().replaceAll(RegExp(r"['\.]"), "") ?? 'Gasto General';
    } catch (e) {
      return 'Gasto General';
    }
  }

  // --- HELPER: RECOMENDACIONES ---
  Future<List<String>> predictClientRecommendations(String clientId, List<String> productNamesList, List<String> clientHistory) async {
    try {
      final prompt = """
      Historial Cliente: ${clientHistory.join(', ')}.
      Productos Disponibles: ${productNamesList.join(', ')}.
      Sugiere 3 productos para venta cruzada.
      Responde SOLO con un Array JSON de Strings.
      """;
      
      final response = await _jsonModel.generateContent([Content.text(prompt)]);
      
      if (response.text == null) return [];
      
      final List<dynamic> jsonList = jsonDecode(response.text!);
      return jsonList.map((e) => e.toString()).toList();
    } catch (e) {
      debugPrint("Error recomendaciones: $e");
      return [];
    }
  }

  // --- HELPER: LECTURA DE ASSETS ---
  Future<String> _readSystemPromptFromFile() async {
    try {
      return await rootBundle.loadString('assets/prompts/servi_system_prompt.txt');
    } catch (e) {
      // Fallback si falla la lectura del archivo
      return "Responde siempre en formato JSON: { \"TEXTO_ESCRITO\": \"...\", \"TEXTO_VOZ\": \"...\" }";
    }
  }

  // --- HELPER: SUGERENCIA DE CATEGORÍA SIMPLE ---
  Future<String> suggestCategory(String productName) async {
     try {
       final response = await _model.generateContent([
         Content.text("Categoría general para el producto: $productName. Solo una palabra.")
       ]);
       return response.text?.trim() ?? 'General';
     } catch (e) {
       return 'General';
     }
  }
}

// --- CLASE DTO (Data Transfer Object) ---
class Invoice {
  final String? vendorName;
  final String? invoiceNumber;
  final double? totalAmount;
  
  Invoice({this.vendorName, this.invoiceNumber, this.totalAmount});

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      vendorName: json['vendorName'],
      invoiceNumber: json['invoiceNumber'],
      // Manejo seguro de números que pueden venir como String o Double
      totalAmount: double.tryParse(json['totalAmount']?.toString() ?? '0'),
    );
  }
}