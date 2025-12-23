import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:ui'; 
import 'package:provider/provider.dart'; 

// --- IMPORTAR SHOWCASE & IA ---
import 'package:showcaseview/showcaseview.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- SERVICIOS DE IA ---
import 'package:proveedor_servicly_app/ai/services/voice_service.dart';
import 'package:proveedor_servicly_app/ai/widgets/servi_avatar.dart';
import 'package:proveedor_servicly_app/ai/services/gemini_service.dart';
import 'package:proveedor_servicly_app/ai/services/servi_api_connector_service.dart';

// Modelos y ViewModels
import 'package:proveedor_servicly_app/features/crm/data/models/cliente_model.dart';
import 'package:proveedor_servicly_app/features/crm/core/crm_enums.dart';
import 'package:proveedor_servicly_app/features/crm/core/lead_access_helper.dart'; 
import 'package:proveedor_servicly_app/features/crm/presentation/providers/lead_list_viewmodel.dart'; 

// Pantallas
import 'package:proveedor_servicly_app/features/crm/presentation/screens/lead_detail_screen.dart';
import 'package:proveedor_servicly_app/features/budget/screens/quote_editor_screen.dart';
import 'package:proveedor_servicly_app/features/manage_store/presentation/screens/add_edit_product_screen.dart'; // Asegúrate que esta ruta sea correcta

class SimpleLeadsTab extends StatefulWidget {
  const SimpleLeadsTab({super.key});

  @override
  State<SimpleLeadsTab> createState() => _SimpleLeadsTabState();
}

class _SimpleLeadsTabState extends State<SimpleLeadsTab> with SingleTickerProviderStateMixin {
  
  // --- IA SERVI INTEGRADA ---
  final ServiVoiceService _voiceService = ServiVoiceService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  bool _isSpeaking = false;
  bool _isListening = false;
  bool _isThinking = false;
  bool _isTourCheckPending = true;

  // --- KEYS PARA EL TOUR VIRTUAL ---
  final GlobalKey _keyLeadList = GlobalKey(); // Foco en la lista
  final GlobalKey _keyLockedLead = GlobalKey(); // Foco en un lead bloqueado (si hay)

  final List<String> _fillers = [
    "Revisando tu cartera de clientes...",
    "Buscando en el CRM...",
    "Dame un segundo que chequeo...",
  ];

  @override
  void initState() {
    super.initState();
    _initVoiceListeners();
  }

  void _initVoiceListeners() {
    _voiceService.player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isSpeaking = state == PlayerState.playing);
      }
    });
  }

  void _updateSpeakingState(bool speaking) {
      if(mounted) setState(() => _isSpeaking = speaking);
  }

  Future<void> _speak(String text) async {
    _updateSpeakingState(true);
    await _voiceService.speak(text);
  }

  Future<void> _listen() async {
    if (_isListening || _isThinking) return;

    if (_isSpeaking) {
      await _voiceService.stop();
      _updateSpeakingState(false);
    }

    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening') setState(() => _isListening = false);
      },
      onError: (error) {
        setState(() => _isListening = false);
        _speak("No te entendí bien. ¿Repetimos?");
      },
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) {
          if (val.finalResult) {
            setState(() => _isListening = false);
            _processVoiceCommand(val.recognizedWords);
          }
        },
        localeId: 'es_AR',
      );
    } else {
      _speak("Habilitá el micrófono por favor.");
    }
  }

  Future<void> _processVoiceCommand(String command) async {
    if (command.trim().isEmpty) return;
    
    // 1. Estado "Pensando"
    setState(() => _isThinking = true);
    
    // Filler para no dejar silencio si es largo
    if (command.split(' ').length > 4) {
       _fillers.shuffle();
       _speak(_fillers.first);
    }

    try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
            
            // 2. Llamada al Cerebro (Api Connector)
            final geminiService = GeminiService();
            final apiConnector = ServiApiConnectorService(geminiService);

            final responseMap = await apiConnector.callServiLLM(command, userId);
            
            // 3. Procesar Respuesta
            String textoHablado = responseMap['TEXTO_VOZ'] ?? responseMap['TEXTO_ESCRITO'] ?? "Listo.";
            
            // Hablamos primero para dar feedback
            await _speak(textoHablado);

            // 4. DETECCIÓN DE COMANDO DE NAVEGACIÓN
            
            // --- CASO A: PRESUPUESTO ---
            if (responseMap.containsKey('ACCION') && responseMap['ACCION'] == 'NAVEGAR_PRESUPUESTO') {
                
                debugPrint("🚀 SERVI: Ejecutando navegación a Presupuesto...");
                final datos = responseMap['DATOS_PRECARGA'] ?? {};
                
                // Pequeño delay para que termine de hablar antes de cambiar de pantalla
                await Future.delayed(const Duration(milliseconds: 1500));

                if (mounted) {
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => QuoteEditorScreen(
                            isNew: true,
                            initialClient: datos['cliente_nombre'],
                            initialConcept: datos['concepto'],
                            // Convertimos a String y luego a Double para evitar errores de tipo int/double
                            initialPrice: double.tryParse(datos['precio_estimado']?.toString() ?? '0'),
                            aiSuggestion: datos['sugerencia_ia']
                        )
                    ));
                }
            }
            // --- CASO B: PRODUCTO (NUEVO BLOQUE 📦) ---
            else if (responseMap.containsKey('ACCION') && responseMap['ACCION'] == 'NAVEGAR_PRODUCTO') {
                
                debugPrint("📦 SERVI: Navegando a Nuevo Producto...");
                final datos = responseMap['DATOS_PRECARGA'] ?? {};
                
                // Esperamos que termine de hablar
                await Future.delayed(const Duration(milliseconds: 1500));

                if (mounted) {
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AddEditProductScreen(
                            // OJO: Asegúrate que tu AddEditProductScreen acepte estos parámetros.
                            // Si no, tendremos que actualizar ese archivo también.
                            initialName: datos['nombre_producto'],
                            initialPrice: double.tryParse(datos['precio']?.toString() ?? '0'),
                            initialStock: double.tryParse(datos['stock']?.toString() ?? '0'),
                            aiDescription: datos['descripcion_ia'], // O aviso_ia
                        )
                    ));
                }
            }
            
            // Terminamos de pensar
            if (mounted) setState(() => _isThinking = false);

        }
    } catch (e) {
        debugPrint("Error procesando voz: $e");
        if (mounted) setState(() => _isThinking = false);
        _speak("Tuve un problema técnico. Intenta de nuevo.");
    }
  }
  
  void _handleAvatarTap() {
    if (_isThinking) return;
    if (_isListening) {
      _listen(); 
    } else if (_isSpeaking) {
      _voiceService.stop();
      _updateSpeakingState(false);
    } else {
      _speak("¿Buscás algún cliente en particular?"); 
      Future.delayed(const Duration(milliseconds: 1500), _listen);
    }
  }

  // --- TOUR HABLADO ---
  String _getScriptForStep(GlobalKey key) {
    if (key == _keyLeadList) return "Esta es tu mina de oro. Aquí están todos los interesados en tus servicios.";
    if (key == _keyLockedLead) return "¡Atención! Estos candados son oportunidades perdidas. Mejorá tu plan para ver quién quiso comprarte.";
    return "";
  }

  void _onShowcaseStepStart(int? index, GlobalKey key) {
    if (key.currentContext != null) {
      Scrollable.ensureVisible(key.currentContext!, duration: const Duration(milliseconds: 500), alignment: 0.5);
    }
    String script = _getScriptForStep(key);
    if (script.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _speak(script);
      });
    }
  }

  Future<void> _checkIfFirstTime(BuildContext showcaseContext) async {
    final prefs = await SharedPreferences.getInstance();
    const String tourKey = 'hasSeenCrmTour_v1'; 
    final bool hasSeenTour = prefs.getBool(tourKey) ?? false;

    if (!hasSeenTour) {
      await _speak("Bienvenido al CRM. Acá gestionamos tus relaciones comerciales.");
      if (mounted && showcaseContext.mounted) {
        ShowCaseWidget.of(showcaseContext).startShowCase([_keyLeadList]);
        prefs.setBool(tourKey, true);
      }
    }
  }

  @override
  void dispose() {
    _voiceService.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final leadViewModel = context.watch<LeadListViewModel>();
    const String userPlan = 'free'; 

    if (userId == null) return const Center(child: Text('Error: No usuario'));

    return ShowCaseWidget(
      onStart: (index, key) => _onShowcaseStepStart(index, key),
      builder: (context) {
        if (_isTourCheckPending) {
          _isTourCheckPending = false;
          WidgetsBinding.instance.addPostFrameCallback((_) => _checkIfFirstTime(context));
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          
          // --- BOTÓN FLOTANTE IA ---
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: GestureDetector(
              onTap: _handleAvatarTap,
              child: ServiAvatar(
                isSpeaking: _isSpeaking,
                isListening: _isListening, 
                isThinking: _isThinking, 
                size: 60, 
              ),
            ),
          ),

          body: StreamBuilder<List<Cliente>>(
            stream: leadViewModel.filteredLeadsStream, 
            builder: (context, snapshot) {
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: colorScheme.primary));
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error: ${snapshot.error}', style: TextStyle(color: colorScheme.error), textAlign: TextAlign.center),
                  ),
                );
              }

              final leads = snapshot.data ?? [];

              if (leads.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 80, color: colorScheme.onSurface.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text(
                        'No hay leads recientes',
                        style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: leads.length, 
                itemBuilder: (context, index) {
                  final cliente = leads[index];
                  final bool hasAccess = LeadAccessHelper.canAccessLead(userPlan, cliente.source);

                  Widget card = _LeadCard(
                    lead: cliente, 
                    hasAccess: hasAccess, 
                    userPlan: userPlan
                  );

                  if (index == 0) {
                    return Showcase(
                      key: _keyLeadList,
                      title: 'Tus Oportunidades',
                      description: 'Gestiona aquí el contacto con tus clientes.',
                      child: card,
                    );
                  }
                  
                  return card;
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _LeadCard extends StatelessWidget {
  final Cliente lead;
  final bool hasAccess; 
  final String userPlan;
  
  const _LeadCard({
    required this.lead, 
    required this.hasAccess,
    required this.userPlan,
  });

  String _getFriendlySource(String? source) {
    if (source == null) return 'Consulta';
    final s = source.toLowerCase();
    if (s.contains('whatsapp')) return 'WhatsApp';
    if (s.contains('view_product')) return 'Vio Producto';
    if (s.contains('cart')) return 'Carrito Abandonado'; 
    if (s.contains('like')) return 'Le gustó un Producto'; 
    if (s.contains('telefono')) return 'Llamada';
    if (s.contains('email')) return 'Email';
    if (s.contains('presupuesto')) return 'Presupuesto';
    return 'Consulta';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceColor = theme.cardTheme.color;
    
    final displayName = hasAccess ? lead.nombreCompleto : 'Oportunidad Detectada'; 
    final displaySource = hasAccess ? _getFriendlySource(lead.source) : "Carrito/Interés (Solo PRO)";

    Color statusColor = Colors.blueGrey;
    String statusText = lead.estadoCRM.name; 

    if (lead.estadoCRM == CrmEstado.leadNuevo) {
      statusColor = Colors.blueAccent;
      statusText = 'NUEVO';
    } else if (lead.estadoCRM == CrmEstado.contactado) {
      statusColor = Colors.orange;
      statusText = 'Contactado';
    } else if (lead.estadoCRM == CrmEstado.clienteActivo) {
      statusColor = Colors.green;
      statusText = 'Cliente';
    }

    final dateStr = DateFormat('dd MMM - HH:mm').format(lead.fechaAlta);

    return Card(
      color: surfaceColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (hasAccess) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => LeadDetailScreen(lead: lead)));
          } else {
              _showUpgradeDialog(context, theme);
          }
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                    Container(
                    width: 4, height: 40,
                    decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2)),
                  ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          hasAccess 
                            ? Text(displayName, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16))
                            : ImageFiltered(
                               imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                               child: Text(displayName, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.bold, fontSize: 16)),
                             ),
                          const SizedBox(height: 4),
                          Text(
                            displaySource,
                            style: TextStyle(
                              color: hasAccess ? colorScheme.onSurface.withValues(alpha: 0.7) : Colors.amber, 
                              fontSize: 13, 
                              fontWeight: hasAccess ? FontWeight.normal : FontWeight.bold
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                                ),
                                child: Text(statusText.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                              const Spacer(),
                              Text(dateStr, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 10)),
                            ],
                          )
                        ],
                      ),
                    ),
                    if (hasAccess)
                     Icon(Icons.arrow_forward_ios, color: colorScheme.onSurface.withValues(alpha: 0.3), size: 16),
                ],
              ),
            ),
            
            if (!hasAccess)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.amber),
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.black.withValues(alpha: 0.5)
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.lock, color: Colors.amber, size: 16),
                          SizedBox(width: 8),
                          Text("Solo PRO", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [const Icon(Icons.star, color: Colors.amber), const SizedBox(width: 8), Text('Oportunidad Perdida', style: TextStyle(color: theme.colorScheme.onSurface))]),
        content: Text(
          'Un cliente mostró interés pero no te contactó directamente.\n\nLos usuarios PRO pueden ver estos datos y contactar al cliente proactivamente.',
          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(child: Text('Cerrar', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))), onPressed: () => Navigator.pop(ctx)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            child: const Text('MEJORAR PLAN'),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Redirigiendo a planes...')));
            }, 
          ),
        ],
      ),
    );
  }
}