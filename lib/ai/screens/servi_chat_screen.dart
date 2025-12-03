import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart'; 

// --- IMPORTACIONES CLAVE DE PROVIDERS Y FEATURES ---
import 'package:proveedor_servicly_app/providers/app_providers.dart' hide userIdProvider; 
import 'package:proveedor_servicly_app/features/agenda/providers/agenda_providers.dart'; 
import 'package:proveedor_servicly_app/features/inventory/providers/inventory_providers.dart'; 

// Importaciones de Clases REALES
import 'package:proveedor_servicly_app/ai/model/intention_result_model.dart';
import 'package:proveedor_servicly_app/ai/services/tts_service.dart'; 
import 'package:proveedor_servicly_app/ai/services/gemini_service.dart'; 

// 🚨 SOLUCIÓN AL ERROR DE AMBIGÜEDAD (Severity 8):
// 1. Ocultamos el conector de la importación del servicio conversacional para eliminar la duplicidad.
import 'package:proveedor_servicly_app/ai/services/servi_conversational_service.dart' hide ServiApiConnectorService;

// 2. Importamos el conector dedicado con un PREFIJO para que el compilador lo distinga.
import 'package:proveedor_servicly_app/ai/services/servi_api_connector_service.dart' as Connector; 


// -----------------------------------------------------------
// --- DEFINICIÓN DE PROVIDERS ---
// -----------------------------------------------------------

final ttsServiceProvider = Provider<TtsService>((ref) {
    return TtsService(); 
});

final serviConversationalServiceProvider = Provider<ServiConversationalService>((ref) {
    final geminiService = ref.watch(geminiServiceProvider); 
    final agendaRepo = ref.watch(agendaRepositoryProvider); 
    final inventoryRepo = ref.watch(inventoryRepositoryProvider); 
    final intelligenceService = ref.watch(inventoryIntelligenceServiceProvider); 
    
    // 2. CREAR EL CONECTOR DE API (Usando la clase importada del archivo dedicado)
    final apiConnector = Connector.ServiApiConnectorService( 
        geminiService, 
        agendaRepo, 
        inventoryRepo, 
        intelligenceService
    );
    
    // 3. CONSTRUIR EL SERVICIO CONVERSACIONAL (Pasando el conector)
    return ServiConversationalService(apiConnector);
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
        // Inicializa el servicio TTS desde el provider
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
            // Utilizamos el modelo real IntentionResultModel
            final IntentionResultModel result = await conversationalService.processQueryAndRespond(text, userId);
            
            setState(() {
                _messages.insert(0, {"sender": "servi", "text": result.responseText}); 
            });
            
            // Lanza el texto a voz
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

    // Método para la funcionalidad de voz (STT) - Con manejo de permisos
    void _startListening() async {
        // 1. Verificar y solicitar permiso de Micrófono
        var status = await Permission.microphone.status;
        if (status.isDenied) {
            status = await Permission.microphone.request();
        }
        
        // 2. Si el permiso es concedido, iniciar el STT
        if (status.isGranted) {
            setState(() => _isListening = true);
            
            // Simulación de respuesta STT después de 3 segundos:
            Future.delayed(const Duration(seconds: 3), () {
                setState(() => _isListening = false);
                // Usamos la prueba de bypass de Rol
                _handleSubmitted("quien eres?"); 
            });
        } else {
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