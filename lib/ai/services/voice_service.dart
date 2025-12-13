import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart'; 
import 'package:flutter/foundation.dart'; 
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart'; 
import 'package:audioplayers/audioplayers.dart'; 

class ServiVoiceService {
  // TU CLAVE DE GOOGLE CLOUD
  static const String _googleApiKey = "AIzaSyDhl0qY42r6sk8jtFL2c2bwYw2DzHqI9_0";

  final AudioPlayer player = AudioPlayer();

  Future<void> speak(String text) async {
    try {
      await player.stop();

      if (text.isEmpty) return;

      // --- TRUCO DE PRONUNCIACIÓN (AQUÍ ESTÁ LA MAGIA) ---
      // Reemplazamos "Servicly" por su fonética "Serviclai" solo para el audio.
      // Así el usuario lee "Servicly" pero escucha "Serviclai".
      String textToSpeak = text.replaceAll(RegExp(r'Servicly', caseSensitive: false), 'Serviclai');

      // 1. Generar hash único (Usamos el texto ORIGINAL para el nombre del archivo)
      // Esto es importante: si ya descargaste el audio de "Bienvenido a Servicly", 
      // el hash cambiará ahora porque el audio será diferente.
      var bytes = utf8.encode(textToSpeak); // Usamos el texto fonético para el hash también
      var digest = md5.convert(bytes);
      String filename = "servi_google_${digest.toString()}.mp3";

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$filename';
      final file = File(filePath);

      // 2. Revisar si ya existe
      if (await file.exists()) {
        debugPrint("🔊 Google TTS: Reproduciendo desde caché");
        await player.play(DeviceFileSource(filePath));
        return;
      }

      debugPrint("☁️ Conectando con Google Cloud TTS...");

      // 3. Petición a Google Cloud (Enviamos textToSpeak, NO text)
      final url = Uri.parse(
          'https://texttospeech.googleapis.com/v1/text:synthesize?key=$_googleApiKey');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'input': {'text': textToSpeak}, // <--- AQUÍ VA LA FONÉTICA
          'voice': {
            'languageCode': 'es-US', 
            'name': 'es-US-Neural2-A', 
          },
          'audioConfig': {
            'audioEncoding': 'MP3',
            'pitch': 0.0,
            'speakingRate': 1.0
          }
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        String audioContent = jsonResponse['audioContent'];
        List<int> audioBytes = base64Decode(audioContent);

        await file.writeAsBytes(audioBytes);
        await player.play(DeviceFileSource(filePath));
      } else {
        debugPrint("❌ Error Google API: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Error grave en servicio de voz: $e");
    }
  }

  Future<void> stop() async {
    await player.stop();
  }

  void dispose() {
    player.dispose();
  }
}