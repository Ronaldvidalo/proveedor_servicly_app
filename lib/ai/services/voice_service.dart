import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart'; // Para generar hash único del audio
import 'package:flutter/foundation.dart'; // Para debugPrint
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart'; // Para guardar archivos
import 'package:audioplayers/audioplayers.dart'; // Para reproducir

class ServiVoiceService {
  // TU CLAVE DE GOOGLE CLOUD (Ya configurada)
  static const String _googleApiKey = "AIzaSyDhl0qY42r6sk8jtFL2c2bwYw2DzHqI9_0";

  final AudioPlayer player = AudioPlayer();

  /// Convierte texto a voz usando Google Cloud TTS y lo reproduce.
  /// Guarda el audio en caché local para ahorrar costos.
  Future<void> speak(String text) async {
    try {
      // Detener cualquier audio previo
      await player.stop();

      if (text.isEmpty) return;

      // 1. Generar hash único para el nombre del archivo (Sistema de Ahorro)
      var bytes = utf8.encode(text);
      var digest = md5.convert(bytes);
      String filename = "servi_google_${digest.toString()}.mp3";

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$filename';
      final file = File(filePath);

      // 2. Revisar si ya existe en el teléfono (Caché)
      if (await file.exists()) {
        debugPrint("🔊 Google TTS: Reproduciendo desde caché (Gratis)");
        await player.play(DeviceFileSource(filePath));
        return;
      }

      debugPrint("☁️ Conectando con Google Cloud TTS...");

      // 3. Petición a Google Cloud
      final url = Uri.parse(
          'https://texttospeech.googleapis.com/v1/text:synthesize?key=$_googleApiKey');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'input': {'text': text},
          'voice': {
            'languageCode': 'es-US', // Español Latino (Neutro)
            'name': 'es-US-Neural2-A', // Voz Femenina Neuronal (Premium)
          },
          'audioConfig': {
            'audioEncoding': 'MP3',
            'pitch': 0.0,
            'speakingRate': 1.0
          }
        }),
      );

      if (response.statusCode == 200) {
        // 4. Decodificar el audio que envía Google
        final jsonResponse = jsonDecode(response.body);
        String audioContent = jsonResponse['audioContent'];
        List<int> audioBytes = base64Decode(audioContent);

        // 5. Guardar y reproducir
        await file.writeAsBytes(audioBytes);
        await player.play(DeviceFileSource(filePath));
      } else {
        debugPrint("❌ Error Google API: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Error grave en servicio de voz: $e");
    }
  }

  /// Detiene la reproducción actual.
  Future<void> stop() async {
    await player.stop();
  }

  /// Libera recursos.
  void dispose() {
    player.dispose();
  }
}