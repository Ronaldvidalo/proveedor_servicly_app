import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Usamos Provider estándar, no Riverpod, para consistencia con el Dashboard
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

// --- IMPORTACIONES CLAVE ---
import 'package:proveedor_servicly_app/core/models/user_model.dart';
// Removed unused import: firestore_service.dart
import 'package:proveedor_servicly_app/ai/services/gemini_service.dart';

// --- NUEVOS SERVICIOS UNIFICADOS ---
import 'package:proveedor_servicly_app/ai/services/voice_service.dart';
import 'package:proveedor_servicly_app/ai/services/servi_brain_service.dart';
import 'package:proveedor_servicly_app/ai/services/servi_conversational_service.dart';
import 'package:proveedor_servicly_app/ai/services/servi_api_connector_service.dart';

class ServiChatScreen extends StatefulWidget {
  const ServiChatScreen({super.key});

  @override
  State<ServiChatScreen> createState() => _ServiChatScreenState();
}

class _ServiChatScreenState extends State<ServiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isListening = false;
  bool _isTyping = false;

  // --- CEREBRO UNIFICADO ---
  late ServiBrainService _serviBrain;
  final ServiVoiceService _voiceService = ServiVoiceService();
  final stt.SpeechToText _speech = stt.SpeechToText();

  @override
  void initState() {
    super.initState();
    
    // --- INICIALIZACIÓN DEL CEREBRO (Igual que en Dashboard) ---
    // Esto garantiza que el Chat y el Dashboard respondan IGUAL.
    
    final geminiService = GeminiService(); // O Provider si lo tienes
    // ✅ CORRECCIÓN: ServiApiConnectorService solo recibe geminiService ahora
    final apiConnector = ServiApiConnectorService(geminiService);
    final conversationalService = ServiConversationalService(apiConnector);
    
    _serviBrain = ServiBrainService(advancedBrain: conversationalService);

    // Mensaje de bienvenida silencioso (solo texto)
    _addMessage("servi", "Hola. Soy Servi. Escribime o hablame, estoy lista.");
  }

  @override
  void dispose() {
    _voiceService.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _addMessage(String sender, String text) {
    if (!mounted) return;
    setState(() {
      _messages.insert(0, {"sender": sender, "text": text});
    });
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty || _isTyping) return;
    _textController.clear();
    
    _addMessage("user", text);
    setState(() => _isTyping = true);

    try {
      final user = context.read<UserModel>();
      
      // --- USAMOS EL MISMO CEREBRO QUE EL DASHBOARD ---
      String response = await _serviBrain.processCommand(text, user.uid);
      
      _addMessage("servi", response);
      
      // Opcional: Que lea la respuesta en voz alta también en el chat
      _voiceService.speak(response);

    } catch (e) {
      debugPrint("Error en Chat: $e");
      _addMessage("servi", "Tuve un problema de conexión. ¿Probamos de nuevo?");
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  // --- LÓGICA DE VOZ (STT) REUTILIZADA ---
  void _startListening() async {
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    var status = await Permission.microphone.request();
    if (status.isGranted) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening') setState(() => _isListening = false);
        },
        onError: (val) => setState(() => _isListening = false),
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            _textController.text = val.recognizedWords;
            if (val.finalResult) {
              setState(() => _isListening = false);
              _handleSubmitted(val.recognizedWords); // Enviar automático al terminar
            }
          },
          localeId: 'es_AR',
        );
      }
    }
  }

  // --- UI DEL CHAT (Mantenemos tu diseño limpio) ---
  Widget _buildTextComposer() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24), // Bordes más redondos estilo chat moderno
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
            color: _isListening ? Colors.redAccent : theme.colorScheme.primary,
            onPressed: _startListening,
          ),
          Flexible(
            child: TextField(
              controller: _textController,
              onSubmitted: _handleSubmitted,
              decoration: const InputDecoration.collapsed(hintText: "Escribí tu consulta..."),
              enabled: !_isTyping,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send_rounded),
            color: theme.colorScheme.primary,
            onPressed: _isTyping ? null : () => _handleSubmitted(_textController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, String> message) {
    final isUser = message['sender'] == 'user';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end, // Alineación abajo para avatares
        children: [
          if (!isUser) 
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Image.asset('assets/images/servicly_logo.png', width: 24), // Logo real
              ),
            ),
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? colorScheme.primary : theme.cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                ),
                boxShadow: [
                  // ✅ CORRECCIÓN: withValues en lugar de withOpacity
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
                ],
              ),
              child: Text(
                message['text']!,
                style: TextStyle(
                  color: isUser ? colorScheme.onPrimary : theme.textTheme.bodyLarge?.color,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat con Servi"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              reverse: true,
              itemBuilder: (_, int index) => _buildMessage(_messages[index]),
              itemCount: _messages.length,
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(minHeight: 2), // Indicador sutil de "pensando"
            ),
          const Divider(height: 1.0),
          SafeArea(child: _buildTextComposer()),
        ],
      ),
    );
  }
}