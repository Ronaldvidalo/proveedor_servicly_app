import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// 🔥 Tu clave (sirve para la prueba)
const String geminiKeyDirect = "AIzaSyCdllmf1WIWgiIGdQQWqjRYs1IcRet6cvw";
const String modelName = 'gemini-2.5-flash'; // Usamos un modelo válido

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('===================================================');
  print('🧪 INICIANDO PRUEBA GEMINI');
  print('===================================================');

  try {
    // Cliente correcto según el package actual
    final model = GenerativeModel(
      model: modelName,
      apiKey: geminiKeyDirect,
    );

    final response = await model.generateContent([
      Content.text('¿Cuál es mi rol como proveedor?'),
    ]);

    print('===================================================');
    print('✅ PRUEBA DE CONEXIÓN EXITOSA.');
    print('Respuesta: ${response.text}');
  } catch (e) {
    print('===================================================');
    print('❌ ERROR CRÍTICO');
    print('Error: $e');
  } finally {
    exit(0);
  }
}
