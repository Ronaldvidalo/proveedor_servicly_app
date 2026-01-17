import 'dart:convert';
import 'dart:typed_data'; 
import 'package:crypto/crypto.dart'; 
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart'; 
import 'package:path_provider/path_provider.dart'; 

// 🔧 CORRECCIÓN: Importamos IO con prefijo para evitar conflictos con HTML en Web
// Esto evita el error de "Too few positional arguments"
import 'dart:io' as io; 

class ServiVoiceService {
  // TU CLAVE DE GOOGLE CLOUD
  static const String _googleApiKey = "AIzaSyDhl0qY42r6sk8jtFL2c2bwYw2DzHqI9_0";

  final AudioPlayer player = AudioPlayer();

  // Caché en RAM para Web
  final Map<String, String> _webRamCache = {}; 

  ServiVoiceService() {
    player.setReleaseMode(ReleaseMode.stop); 
  }

  Future<void> speak(String text) async {
    try {
      await player.stop();

      if (text.trim().isEmpty) return;

      // Truco fonético
      String textToSpeak = text.replaceAll(RegExp(r'Servicly', caseSensitive: false), 'Serviclai');

      // Hash único
      var bytes = utf8.encode(textToSpeak);
      var digest = md5.convert(bytes);
      String filename = "servi_google_${digest.toString()}.mp3";

      // ============================================================
      // 🌐 ESTRATEGIA WEB: DATA URI 
      // ============================================================
      if (kIsWeb) {
        debugPrint("🌐 Modo Web detectado para TTS");

        // 1. Revisar Caché RAM
        if (_webRamCache.containsKey(filename)) {
           debugPrint("🔊 Web: Reproduciendo desde RAM");
           await player.play(UrlSource(_webRamCache[filename]!));
           return;
        }

        // 2. Descargar
        Uint8List? audioBytes = await _fetchAudioFromGoogle(textToSpeak);
        
        if (audioBytes != null) {
          // 3. Convertir a Data URI (Base64)
          String base64Audio = base64Encode(audioBytes);
          String audioUri = "data:audio/mp3;base64,$base64Audio";

          // Guardamos en RAM
          _webRamCache[filename] = audioUri;

          debugPrint("🔊 Web: Reproduciendo desde API (Data URI)");
          await player.play(UrlSource(audioUri));
        }
        return; 
      }

      // ============================================================
      // 📱 ESTRATEGIA MÓVIL: ARCHIVOS (USANDO PREFIJO io.)
      // ============================================================
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$filename';
      
      // ✅ CORRECCIÓN AQUÍ: Usamos io.File explícitamente
      final file = io.File(filePath);

      if (await file.exists()) {
        debugPrint("🔊 Móvil: Reproduciendo desde caché de disco");
        await player.play(DeviceFileSource(filePath));
        return;
      }

      Uint8List? audioBytes = await _fetchAudioFromGoogle(textToSpeak);

      if (audioBytes != null) {
        await file.writeAsBytes(audioBytes);
        debugPrint("🔊 Móvil: Guardado y reproduciendo");
        await player.play(DeviceFileSource(filePath));
      }

    } catch (e) {
      debugPrint("❌ Error VoiceService: $e");
    }
  }

  // Lógica API (Compartida)
  Future<Uint8List?> _fetchAudioFromGoogle(String textToSpeak) async {
      final url = Uri.parse(
          'https://texttospeech.googleapis.com/v1/text:synthesize?key=$_googleApiKey');

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'input': {'text': textToSpeak},
            'voice': {'languageCode': 'es-US', 'name': 'es-US-Neural2-A'},
            'audioConfig': {'audioEncoding': 'MP3', 'speakingRate': 1.0}
          }),
        );

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          return base64Decode(jsonResponse['audioContent']);
        } else {
          debugPrint("❌ Error API Google: ${response.body}");
          return null;
        }
      } catch (e) {
        debugPrint("❌ Error Red: $e");
        return null;
      }
  }

  Future<void> stop() async {
    await player.stop();
  }

  void dispose() {
    player.dispose();
  }
}