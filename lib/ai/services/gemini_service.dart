// /lib/ai/services/gemini_service.dart

import 'package:cloud_functions/cloud_functions.dart';
import 'package:proveedor_servicly_app/ai/model/ai_response_model.dart';
import 'dart:convert'; // Mantenemos por si se necesita para errores o logging
import 'package:flutter/foundation.dart'; // Usamos debugPrint en lugar de print

class GeminiService {
  // Inicializamos la instancia de FirebaseFunctions
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // --- MVP 1.0: OCR DE FACTURAS ---
  Future<Invoice> extractDataFromImage(String base64Image) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('extractInvoiceData');
      final HttpsCallableResult result = await callable.call({
        'image_data': base64Image,
      });
      final Map<String, dynamic> geminiResponse = result.data as Map<String, dynamic>;
      return Invoice.fromJson(geminiResponse);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Error de Functions: ${e.code} - ${e.message}');
      throw Exception('SERVI falló al analizar la factura: ${e.message}');
    } catch (e) {
      debugPrint('Error general de la IA: $e');
      throw Exception('Ocurrió un error inesperado al usar SERVI.');
    }
  }

  // --- MVP 1.2: CLASIFICACIÓN DE CATEGORÍAS (CATÁLOGO) ---
  Future<String> suggestCategory(String productName) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('suggestCategory');
      
      final HttpsCallableResult result = await callable.call({
        'product_name': productName,
      });
      
      final suggestedCategory = result.data as String;
      
      return suggestedCategory.isNotEmpty ? suggestedCategory : 'General';
      
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Error de Clasificación SERVI: ${e.message}');
      return 'General / Error de IA'; 
    } catch (e) {
      debugPrint('Error general al clasificar: $e');
      return 'General / Error'; 
    }
  }
  
  // --- MVP 1.4: CLASIFICACIÓN DE TRANSACCIONES FINANCIERAS ---
  Future<String> classifyTransaction(String description, List<String> categories) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('classifyTransaction');
      
      final HttpsCallableResult result = await callable.call({
        'transaction_description': description,
        'user_categories': categories,
      });
      
      final classification = result.data as String;
      return classification.isNotEmpty ? classification : 'Gasto General';
      
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Error de Clasificación Financiera SERVI: ${e.message}');
      return 'Gasto General / Error de IA'; 
    } catch (e) {
      debugPrint('Error general al clasificar transacción: $e');
      return 'Gasto General / Error'; 
    }
  }

  // --- MVP 1.5: RECOMENDACIONES PREDICTIVAS (CRM) ---
  /// Llama a la IA para obtener recomendaciones personalizadas para un cliente.
  Future<List<String>> predictClientRecommendations(String clientId, List<String> productNamesList, List<String> clientHistory) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('predictClientRecommendations');
      
      final HttpsCallableResult result = await callable.call({
        'client_id': clientId,
        'product_list': productNamesList, 
        'client_history': clientHistory,
      });
      
      // La función de Firebase devuelve List<dynamic> que debemos convertir a List<String>
      final recommendations = result.data as List<dynamic>;
      
      return recommendations.cast<String>();
      
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Error en SERVI al predecir recomendaciones: ${e.message}');
      return ['Error: Falló la predicción IA.']; 
    } catch (e) {
      debugPrint('Error general al predecir recomendaciones: $e');
      return ['Error: No se pudieron obtener las sugerencias.']; 
    }
  }
}
