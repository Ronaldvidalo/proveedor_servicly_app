import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart'; // 👈 IMPORTACIÓN AGREGADA

// --- IMPORTACIONES CLAVE DE PROVIDERS Y FEATURES ---
import 'package:proveedor_servicly_app/providers/app_providers.dart' hide userIdProvider; 
import 'package:proveedor_servicly_app/features/agenda/providers/agenda_providers.dart'; 
import 'package:proveedor_servicly_app/features/inventory/providers/inventory_providers.dart'; 
// Asumimos que estas son las rutas correctas:
// import 'package:proveedor_servicly_app/ai/model/intention_result_model.dart';
// import 'package:proveedor_servicly_app/ai/services/servi_conversational_service.dart';


// --- PLACEHOLDERS ---
class IntentionResult {
    final String responseText;
    final String ttsText;
    IntentionResult(this.responseText, this.ttsText);
}

class TtsService {
    Future<void> speak(String text) async {
        debugPrint("TTS SPEAKING: $text");
    }
}
class ServiConversationalService {
    ServiConversationalService(geminiService, agendaRepo, inventoryRepo, intelligenceService);
    Future<IntentionResult> processQueryAndRespond(String query, String userId) async {
        await Future.delayed(const Duration(seconds: 1));
        return IntentionResult(
            "Tienes 1 cita y 2 pagos críticos.\n* Cita: Reunión con Proveedor X a las 10:00.\n* Pagos: Nómina vencida hoy (\$3,000.00).",
            "Para hoy, tienes una cita importante y dos pagos críticos, incluyendo la nómina que vence hoy."
        );
    }
}
// --- FIN PLACEHOLDERS ---


// --- DEFINICIÓN DE PROVIDERS ---

final ttsServiceProvider = Provider<TtsService>((ref) {
    return TtsService(); 
});

final serviConversationalServiceProvider = Provider<ServiConversationalService>((ref) {
    final geminiService = ref.watch(geminiServiceProvider); 
    final agendaRepo = ref.watch(agendaRepositoryProvider); 
    final inventoryRepo = ref.watch(inventoryRepositoryProvider); 
    final intelligenceService = ref.watch(inventoryIntelligenceServiceProvider); 
    
    return ServiConversationalService(geminiService, agendaRepo, inventoryRepo, intelligenceService);
});


class ServiChatScreen extends ConsumerStatefulWidget {
    const ServiChatScreen({super.key});

    @override
    ConsumerState<ServiChatScreen> createState() => _ServiChatScreenState();
}

class _ServiChatScreenState extends ConsumerState<ServiChatScreen> {
    final TextEditingController _textController = TextEditingController();
    final List<Map<String, String>> _messages = [];
    bool _isListening = false;
    bool _isTyping = false;
    
    late final TtsService _ttsService;

    @override
    void initState() {
        super.initState();
        _ttsService = ref.read(ttsServiceProvider);
    }
    
    void _handleSubmitted(String text) async {
        if (text.isEmpty || _isTyping) return;
        _textController.clear();
        
        setState(() {
            _messages.insert(0, {"sender": "user", "text": text});
            _isTyping = true;
        });

        final conversationalService = ref.read(serviConversationalServiceProvider);
        final userId = ref.read(userIdProvider);
        
        try {
            final IntentionResult result = await conversationalService.processQueryAndRespond(text, userId);
            
            setState(() {
                _messages.insert(0, {"sender": "servi", "text": result.responseText}); 
            });
            
            _ttsService.speak(result.ttsText);
            
        } catch (e) {
            debugPrint('Error en SERVI Chat: $e');
            setState(() {
                _messages.insert(0, {"sender": "servi", "text": "¡Ups! Tuvimos un error al consultar la IA. Inténtalo de nuevo."});
            });
        } finally {
            setState(() {
                _isTyping = false;
            });
        }
    }

    // Método para la funcionalidad de voz (STT) - Ahora con solicitud de permiso
    void _startListening() async {
        // 1. Verificar y solicitar permiso
        var status = await Permission.microphone.status;
        if (status.isDenied) {
            status = await Permission.microphone.request();
        }
        
        // 2. Si el permiso es concedido, iniciar el STT
        if (status.isGranted) {
            setState(() => _isListening = true);
            
            // **AQUÍ VA EL CÓDIGO REAL DE STT** (e.g., speech_to_text package)
            // Esto es solo la simulación del tiempo de escucha.
            Future.delayed(const Duration(seconds: 3), () {
                setState(() => _isListening = false);
                _handleSubmitted("Consulta transcrita por STT"); // Llama con el texto transcrito
            });
        } else {
            // Manejo de permiso denegado
            // Muestra un SnackBar o alerta
            debugPrint("Permiso de micrófono denegado.");
        }
    }

    // Esqueleto de la barra de entrada de texto/voz
    Widget _buildTextComposer() {
        final colorScheme = Theme.of(context).colorScheme;
        return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: Row(
                children: [
                    Flexible(
                        child: TextField(
                            controller: _textController,
                            onSubmitted: _handleSubmitted,
                            decoration: const InputDecoration.collapsed(hintText: "Pregunta a SERVI..."),
                            enabled: !_isTyping,
                        ),
                    ),
                    Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: IconButton(
                            icon: Icon(_isListening ? Icons.mic_off : Icons.mic, color: _isListening ? Colors.red : colorScheme.primary),
                            onPressed: _isTyping ? null : _startListening,
                            tooltip: 'Hablar con SERVI',
                        ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _isTyping ? null : () => _handleSubmitted(_textController.text),
                    ),
                ],
            ),
        );
    }
    
    // Widget para mostrar un mensaje
    Widget _buildMessage(Map<String, String> message, Color colorSchemePrimary) {
        final isUser = message['sender'] == 'user';
        final color = isUser ? colorSchemePrimary : Colors.grey.shade700;
        
        return Container(
            margin: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
                mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    if (!isUser) 
                        const CircleAvatar(child: Text("S")),
                    
                    Flexible(
                        child: Container(
                            margin: isUser ? const EdgeInsets.only(left: 80) : const EdgeInsets.only(right: 80),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                // Los warnings de deprecated_member_use (withOpacity) son de severidad baja y cosméticos.
                                color: isUser ? colorSchemePrimary.withOpacity(0.1) : Theme.of(context).cardTheme.color,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: color.withOpacity(0.3)),
                            ),
                            child: Text(
                                message['text']!,
                                style: TextStyle(color: isUser ? colorSchemePrimary : Theme.of(context).colorScheme.onSurface),
                            ),
                        ),
                    ),
                    if (isUser)
                        const CircleAvatar(child: Text("Yo")),
                ],
            ),
        );
    }


    @override
    Widget build(BuildContext context) {
        final colorScheme = Theme.of(context).colorScheme;
        
        return Scaffold(
            appBar: AppBar(title: const Text("SERVI: Asistente Inteligente")),
            body: Column(
                children: [
                    Flexible(
                        child: ListView.builder(
                            padding: const EdgeInsets.all(8.0),
                            reverse: true,
                            itemBuilder: (_, int index) => _buildMessage(_messages[index], colorScheme.primary),
                            itemCount: _messages.length,
                        ),
                    ),
                    const Divider(height: 1.0),
                    Container(
                        decoration: BoxDecoration(color: Theme.of(context).cardColor),
                        child: _buildTextComposer(),
                    ),
                ],
            ),
        );
    }
}