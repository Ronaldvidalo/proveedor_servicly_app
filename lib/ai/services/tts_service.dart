// Archivo: lib/services/tts_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();

  TtsService() {
    _initTts();
  }

  void _initTts() async {
    // 1. Configuración de Listeners (Sintaxis correcta)
    _flutterTts.setStartHandler(() => debugPrint("TTS STATUS: Speaking started."));
    _flutterTts.setCompletionHandler(() => debugPrint("TTS STATUS: Speaking finished."));
    
    _flutterTts.setErrorHandler((msg) {
      debugPrint("TTS ERROR: $msg");
    });

    // 2. Configuración de parámetros (Métodos universales)
    await _flutterTts.setLanguage("es-ES");
    await _flutterTts.setSpeechRate(0.5); 
    
    // Configuración de Volumen (CRÍTICO: Aseguramos que el volumen esté al máximo)
    await _flutterTts.setVolume(1.0);
    
    debugPrint("TTS SERVICE: Inicialización completada.");
  }

  Future<void> speak(String text) async {
    // No chequeamos isInitialized, confiamos en el chequeo de la aplicación.
    if (text.isEmpty) return;

    await _flutterTts.stop(); 
    
    // Reproducir el texto
    var result = await _flutterTts.speak(text);
    
    if (result == 1) {
      debugPrint("TTS speaking successfully: $text");
    } else {
      // Si resulta != 1, es un error del sistema (idioma no descargado, volumen 0, etc.)
      debugPrint("TTS FAILED: El comando 'speak' fue rechazado por el motor (result: $result).");
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}