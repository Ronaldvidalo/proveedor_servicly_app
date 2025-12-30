// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 14/10/2025
// Style: Cyber Glow (Adaptive Light/Dark)
// QA FIX 26/11/2025: Theme Integration
// UPDATE 21/12/2025: Integración Marketplace Real (BrandProfiles) - FULL CODE
// UPDATE: Integración Notificaciones Push (Cliente)
// UPDATE: Servi AI Navigation Logic + Proactive Insights + Lead Coach
// FIX FINAL: Dashboard con Control de Voz (Mute Inteligente)
// ---------------------------------

import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui'; 
import 'package:audioplayers/audioplayers.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt; 
import 'package:cloud_firestore/cloud_firestore.dart'; 

// --- Imports de Utilidades ---
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- IMPORTS DE LA IA (SERVICIOS Y WIDGETS) ---
import 'package:proveedor_servicly_app/ai/services/voice_service.dart';
import 'package:proveedor_servicly_app/ai/widgets/servi_avatar.dart';

// --- IMPORTS PARA LA CONEXIÓN REAL (CEREBRO HÍBRIDO) ---
import 'package:proveedor_servicly_app/ai/services/gemini_service.dart';
import 'package:proveedor_servicly_app/ai/services/servi_api_connector_service.dart';

// --- IMPORTS PROACTIVOS (MARKETING & CRM) ---
import 'package:proveedor_servicly_app/features/promotion/services/proactive_insight_engine.dart';
import 'package:proveedor_servicly_app/features/promotion/screens/marketing_center_screen.dart';
import 'package:proveedor_servicly_app/features/promotion/models/smart_insight_model.dart'; 

// --- IMPORTS CRM (LEADS) ---
import 'package:proveedor_servicly_app/features/crm/services/proactive_lead_engine.dart';
import 'package:proveedor_servicly_app/features/crm/presentation/screens/lead_detail_screen.dart'; 
import 'package:proveedor_servicly_app/features/crm/data/models/cliente_model.dart';

// --- Importaciones de Modelos y Servicios ---
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/models/module_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/core/services/notification_service.dart';

// --- Importaciones de Módulos ---
import 'package:proveedor_servicly_app/features/catalogo/modules/modules_screen.dart';
import 'package:proveedor_servicly_app/features/profile/screens/create_profile_screen.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/public_profile_screen.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/presentation/screens/select_profile_template_screen.dart';
import 'package:proveedor_servicly_app/features/settings/screens/settings_screen.dart';

// --- Importaciones de Widgets Reutilizables ---
import 'package:proveedor_servicly_app/widgets/dashboard_header.dart';
import 'package:proveedor_servicly_app/widgets/grids/dashboard/module_grid.dart';
import 'package:proveedor_servicly_app/features/home/screens/home_screen.dart';

import 'package:proveedor_servicly_app/features/dashboard/widgets/dashboard_cards/dashboard_screen/dashboard_summary_cards.dart' as summary_widgets;
import 'package:proveedor_servicly_app/features/dashboard/widgets/dashboard_v1/dashboard_metrics_card.dart' as metric_widgets;

import 'package:proveedor_servicly_app/ai/screens/servi_chat_screen.dart'; 

// --- IMPORTS DE ACCIÓN (PARA NAVEGACIÓN IA) ---
import 'package:proveedor_servicly_app/features/budget/screens/quote_editor_screen.dart';
import 'package:proveedor_servicly_app/features/manage_store/presentation/screens/add_edit_product_screen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  
  static const List<Widget> _widgetOptions = <Widget>[
    _ProviderHomeTab(),              
    HomeScreen(),                    
    _PlaceholderScreen(title: 'Oportunidades'), 
    SettingsScreen(),                
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return Scaffold(
            backgroundColor: colors.surface,
            body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: colors.surface,
              selectedItemColor: colors.primary,
              unselectedItemColor: colors.onSurface.withValues(alpha: 0.6),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Inicio'),
                BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Explorar'),
                BottomNavigationBarItem(icon: Icon(Icons.lightbulb_outline_rounded), label: 'Oportunidades'),
                BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Ajustes'),
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
          );
        } else {
          return Scaffold(
            backgroundColor: colors.surface,
            body: Row(
              children: <Widget>[
                NavigationRail(
                  backgroundColor: colors.surface,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.dashboard_rounded), label: Text('Inicio')),
                    NavigationRailDestination(icon: Icon(Icons.map_outlined), label: Text('Explorar')),
                    NavigationRailDestination(icon: Icon(Icons.lightbulb_outline_rounded), label: Text('Oportunidades')),
                    NavigationRailDestination(icon: Icon(Icons.settings_outlined), label: Text('Ajustes')),
                  ],
                ),
                VerticalDivider(thickness: 1, width: 1, color: theme.dividerColor),
                Expanded(child: IndexedStack(index: _selectedIndex, children: _widgetOptions)),
              ],
            ),
          );
        }
      },
    );
  }
}

// ===================================================================
// --- PESTAÑA 0: INICIO (CON CEREBRO HÍBRIDO + FEEDBACK) ---
// ===================================================================

class _ProviderHomeTab extends StatefulWidget {
  const _ProviderHomeTab();

  @override
  State<_ProviderHomeTab> createState() => _ProviderHomeTabState();
}

class _ProviderHomeTabState extends State<_ProviderHomeTab> with SingleTickerProviderStateMixin {
  late Future<List<ModuleModel>> _modulesFuture;
  late AnimationController _animationController;

  final GlobalKey _keyHeader = GlobalKey();
  final GlobalKey _keyPrompt = GlobalKey();
  final GlobalKey _keyMetrics = GlobalKey();
  final GlobalKey _keySummaryCards = GlobalKey(); 
  final GlobalKey _keyPublicProfile = GlobalKey(); 
  final GlobalKey _keyModulesGrid = GlobalKey(); 

  final ServiVoiceService _voiceService = ServiVoiceService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  final ProactiveLeadEngine _leadEngine = ProactiveLeadEngine();
  StreamSubscription? _leadSubscription;
  SmartInsight? _currentInsight; 
  
  late ServiApiConnectorService _apiConnector; 
  
  bool _isSpeaking = false; 
  bool _isListening = false;
  bool _isThinking = false; 
  bool _isMuted = false; // 🔇 Estado de Silencio (Por defecto HABLA)
  
  bool _isTourCheckPending = true;

  final List<String> _fillers = [
    "A ver, bancame un segundo que reviso...",
    "Analizando tus datos, dame un toque...",
    "Procesando la información...",
    "Ahí me fijo en el sistema...",
    "Un momento, estoy chequeando eso...",
  ];

  @override
  void initState() {
    super.initState();
    
    final firestoreService = context.read<FirestoreService>();
    final geminiService = GeminiService(); 
    
    _apiConnector = ServiApiConnectorService(geminiService);

    _modulesFuture = firestoreService.getAvailableModules();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _initVoiceListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
        
        final user = context.read<UserModel?>();
        if (user != null) {
           // 1. ESCUCHA ACTIVA DE LEADS
           _leadSubscription = _leadEngine.listenForNewLeads(user.uid).listen((insight) {
              if (insight != null && mounted) {
                setState(() => _currentInsight = insight);
                _handleNewInsight(insight); 
              }
           });

           // 2. MARKETING PROACTIVO
           Future.delayed(const Duration(seconds: 3), () {
              if (_currentInsight == null) { 
                 _checkProactiveInsights(user);
              }
           });
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
       if (!mounted) return;
       final notificationService = context.read<NotificationService>();
       await notificationService.init();
       if (!mounted) return;
       await notificationService.saveTokenToDatabase();
       debugPrint("🔔 Notificaciones configuradas para el Dashboard de Proveedor");
    });
  }

  void _initVoiceListeners() {
    _voiceService.player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isSpeaking = state == PlayerState.playing);
      }
    });
  }

  // --- CONTROL DE VOZ ---
  Future<void> _speak(String text) async {
    if (_isMuted) return; // 🛑 Si está muteado, no habla.
    await _voiceService.speak(text);
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    // Feedback inmediato
    if (_isMuted) {
      _voiceService.stop(); // Calla inmediatamente
      // SnackBar visual en lugar de voz
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🔇 Servi silenciada"), duration: Duration(seconds: 1)));
    } else {
      _speak("Audio activado. Estoy atenta."); 
    }
  }

  void _handleNewInsight(SmartInsight insight) async {
    setState(() => _isThinking = true);

    String message = insight.message;
    String actionLabel = "VER";
    VoidCallback actionCallback = () {}; 

    if (insight.type == InsightType.newLead) {
       actionLabel = "ATENDER YA";
       actionCallback = () => _navigateToCRM(insight);
    } else {
       actionLabel = "VER OPORTUNIDAD";
       actionCallback = () => _navigateToPromoCreator(insight.suggestedPromo);
    }

    if (mounted) setState(() => _isThinking = false);

    _speak(message);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(insight.type == InsightType.newLead ? Icons.notifications_active : Icons.auto_awesome, color: Colors.amber), 
                const SizedBox(width: 8), 
                Text(insight.type == InsightType.newLead ? "NUEVO CLIENTE" : "OPORTUNIDAD", style: const TextStyle(fontWeight: FontWeight.bold))
              ]),
              Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
          backgroundColor: const Color(0xFF2D2D5A),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: actionLabel,
            textColor: Colors.greenAccent,
            onPressed: actionCallback,
          ),
        ),
      );
    }
  }

  void _navigateToCRM(SmartInsight insight) async {
     _leadEngine.markLeadAsAnalyzed(insight.id);
     setState(() => _isThinking = true);
     try {
       final docSnapshot = await FirebaseFirestore.instance.collection('leads').doc(insight.id).get();
       
       if (docSnapshot.exists && mounted) {
          final clienteModel = Cliente.fromFirestore(docSnapshot);
          setState(() => _isThinking = false);
          
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => LeadDetailScreen(lead: clienteModel)
          ));
       } else {
          if (mounted) setState(() => _isThinking = false);
          _speak("Parece que ese cliente ya no está disponible.");
       }
     } catch (e) {
       debugPrint("Error cargando cliente: $e");
       if (mounted) setState(() => _isThinking = false);
       _speak("Tuve un problema cargando los datos del cliente.");
     }
  }

  void _navigateToPromoCreator(Map<String, dynamic>? data) {
      if (data == null) return;
      int targetTab = 0;
      final String type = (data['type'] ?? '').toString().toUpperCase();
      if (type == 'GIFT_CARD') targetTab = 1; 
      else if (type == 'DISCOUNT' || type == 'LOW_DENSITY') targetTab = 0; 
      else targetTab = 2; 

      Navigator.push(context, MaterialPageRoute(
        builder: (context) => MarketingCenterScreen(
          initialData: data,
          initialTabIndex: targetTab,
        )
      ));
  }

  Future<void> _listen(UserModel user) async {
    if (_isListening || _isThinking) return; 

    if (_isSpeaking) {
      await _voiceService.stop();
    }

    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening') setState(() => _isListening = false);
      },
      onError: (error) {
        setState(() => _isListening = false);
        _speak("Perdón, no te escuché bien. ¿Podés repetir?");
      },
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) {
          if (val.finalResult) {
            setState(() => _isListening = false);
            _processVoiceCommand(val.recognizedWords, user);
          }
        },
        localeId: 'es_AR', 
      );
    } else {
      _speak("No pude acceder al micrófono. Revisá los permisos.");
    }
  }

  Future<void> _processVoiceCommand(String command, UserModel user) async {
    if (command.trim().isEmpty) return;

    setState(() => _isThinking = true);

    if (command.split(' ').length > 2) {
       _fillers.shuffle();
       _speak(_fillers.first); 
    }

    try {
        final responseMap = await _apiConnector.callServiLLM(command, user.uid);
        if (mounted) setState(() => _isThinking = false);
        
        String textoHablado = responseMap['TEXTO_VOZ'] ?? responseMap['TEXTO_ESCRITO'] ?? "Listo.";
        await _speak(textoHablado);

        if (responseMap.containsKey('ACCION') && responseMap['ACCION'] == 'NAVEGAR_PRESUPUESTO') {
            final datos = responseMap['DATOS_PRECARGA'] ?? {};
            await Future.delayed(const Duration(milliseconds: 1500));
            if (mounted) {
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => QuoteEditorScreen(
                        isNew: true,
                        initialClient: datos['cliente_nombre'],
                        initialConcept: datos['concepto'],
                        initialPrice: double.tryParse(datos['precio_estimado']?.toString() ?? '0'),
                        aiSuggestion: datos['sugerencia_ia']
                    )
                ));
            }
        }
        else if (responseMap.containsKey('ACCION') && responseMap['ACCION'] == 'NAVEGAR_PRODUCTO') {
            final datos = responseMap['DATOS_PRECARGA'] ?? {};
            await Future.delayed(const Duration(milliseconds: 1500));
            if (mounted) {
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AddEditProductScreen(
                        user: user, 
                        initialName: datos['nombre_producto'],
                        initialPrice: double.tryParse(datos['precio']?.toString() ?? '0'),
                        initialStock: double.tryParse(datos['stock']?.toString() ?? '0'),
                        aiDescription: datos['descripcion_ia'] ?? datos['aviso_ia'],
                    )
                ));
            }
        }
    } catch (e) {
        debugPrint("Error Servi Dashboard: $e");
        if (mounted) setState(() => _isThinking = false);
        _speak("Me mareé un poco con los datos. ¿Me preguntás de nuevo?");
    }
  }

  Future<void> _checkProactiveInsights(UserModel user) async {
      final insightEngine = ProactiveInsightEngine(); 
      final insight = await insightEngine.analyzeBookingTrends(user.uid);

      if (insight != null && mounted) {
          debugPrint("💡 SERVI MARKETER: ${insight.message}");
          _handleNewInsight(insight);
      }
  }

  String _getUserName(UserModel user) {
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!.trim().split(' ')[0];
    }
    return "Campeón"; 
  }

  String _getScriptForStep(GlobalKey key, UserModel user) {
    String name = _getUserName(user);
    if (key == _keyHeader) return "Hola $name. Bienvenido. Aquí arriba verás tus notificaciones.";
    if (key == _keyPrompt) return "Si no querés escribir, tocá el micrófono acá abajo y hablame. ¡Te escucho!";
    if (key == _keyMetrics) return "Métricas en tiempo real. Controlá tu tráfico.";
    if (key == _keySummaryCards) return "Tu resumen financiero y de agenda en un vistazo.";
    if (key == _keyPublicProfile) return "Tu Negocio Digital. Compartilo por WhatsApp para vender más.";
    if (key == _keyModulesGrid) return "Y tus herramientas. Acordate: mantené apretado cualquier botón para saber qué hace.";
    return "";
  }

  void _onShowcaseStepStart(int? index, GlobalKey key) {
    final user = context.read<UserModel>();
    String script = _getScriptForStep(key, user);
    if (key.currentContext != null) {
      Scrollable.ensureVisible(key.currentContext!, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut, alignment: 0.5);
    }
    if (script.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _speak(script);
      });
    }
  }

  Future<void> _checkIfFirstTime(BuildContext showcaseContext, UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final String tourKey = 'hasSeenDashboardTour_v12_${user.uid}'; 
    final bool hasSeenTour = prefs.getBool(tourKey) ?? false;

    if (!hasSeenTour) {
      String name = _getUserName(user);
      await _speak("Hola $name. Soy Servi. Ahora tengo oídos. Tocá mi avatar abajo para hablarme.");
      
      if (mounted && showcaseContext.mounted) {
        ShowCaseWidget.of(showcaseContext).startShowCase([_keyHeader, _keyPrompt, _keyMetrics, _keySummaryCards, _keyPublicProfile, _keyModulesGrid]);
        prefs.setBool(tourKey, true);
      }
    }
  }

  void _manualTourStart(BuildContext showcaseContext) {
    if(_isMuted) {
      setState(() => _isMuted = false); // ⚡ Auto-unmute para el tour
      _speak("Activando voz para el recorrido.");
    } else {
      _speak("Repasemos todo de nuevo.");
    }
    ShowCaseWidget.of(showcaseContext).startShowCase([_keyHeader, _keyPrompt, _keyMetrics, _keySummaryCards, _keyPublicProfile, _keyModulesGrid]);
  }

  void _handleAvatarTap(UserModel user) {
    if (_isThinking) return; 
    
    // ⚡ INTERACCIÓN DIRECTA = DESMUTEAR (Si tocas para hablar, quieres escuchar respuesta)
    if (_isMuted) {
       setState(() => _isMuted = false);
       // No hablamos aún, esperamos a que termine de escuchar
    }
    
    if (_isListening) {
      _listen(user); 
    } else if (_isSpeaking) {
      _voiceService.stop(); 
    } else {
      _speak("Te escucho..."); 
      Future.delayed(const Duration(milliseconds: 800), () => _listen(user));
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _voiceService.dispose();
    _speech.stop();
    _leadSubscription?.cancel(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userModel = context.watch<UserModel?>();
    final colors = Theme.of(context).colorScheme;

    if (userModel == null) return Center(child: CircularProgressIndicator(color: colors.primary));

    return ShowCaseWidget(
      onStart: (index, key) => _onShowcaseStepStart(index, key),
      onComplete: (index, key) { if (index == 5) _speak("¡Listo! Probá hablarme tocando el botón rojo."); },
      blurValue: 1, 
      builder: (context) { 
        if (_isTourCheckPending) {
          _isTourCheckPending = false;
          WidgetsBinding.instance.addPostFrameCallback((_) => _checkIfFirstTime(context, userModel));
        }

        return Scaffold(
          // APPBAR PARA CONTROLES DE SILENCIO (Transparente para no romper diseño)
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 50, // Pequeño y sutil
            actions: [
               IconButton(
                 icon: Icon(
                   _isMuted ? Icons.volume_off : Icons.volume_up, 
                   color: _isMuted ? Colors.redAccent : Colors.greenAccent
                 ),
                 onPressed: _toggleMute,
                 tooltip: _isMuted ? "Activar Voz de Servi" : "Silenciar Servi",
               ),
               IconButton(
                 icon: const Icon(Icons.help_outline, color: Colors.white54),
                 onPressed: () => _manualTourStart(context),
                 tooltip: "Ver Tour",
               ),
               const SizedBox(width: 8),
            ],
          ),
          extendBodyBehindAppBar: true, // Para que el header quede detrás
          
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: GestureDetector(
              onTap: () => _handleAvatarTap(userModel),
              onLongPress: () => _manualTourStart(context),
              // DEJAMOS EL SIMULADOR DISPONIBLE POR SI LO NECESITAS
              onDoubleTap: () async {
                  final user = context.read<UserModel>();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🧪 Simulando Lead...")));
                  try {
                    await FirebaseFirestore.instance.collection('leads').add({
                      'providerId': user.uid,
                      'ia_analyzed': false,
                      'status': 'new',
                      'nombreCompleto': 'Cliente Test Mute',
                      'serviceName': 'Prueba Silencio',
                      'source': 'Simulador',
                      'telefono': '111222333',
                      'email': 'mute@test.com',
                      'createdAt': FieldValue.serverTimestamp(),
                      'fechaAlta': FieldValue.serverTimestamp(),
                      'notasInternas': 'Test de Mute.',
                    });
                  } catch (e) { debugPrint("Error: $e"); }
              },
              child: ServiAvatar(
                isSpeaking: _isSpeaking,
                isListening: _isListening, 
                isThinking: _isThinking, 
                size: 65, 
              ),
            ),
          ),
          
          body: SafeArea(
            top: false, // Permitimos que el contenido suba detrás del AppBar transparente
            bottom: false,
            child: FutureBuilder<List<ModuleModel>>(
              future: _modulesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _LoadingSkeleton(userName: userModel.displayName);
                }
                if (snapshot.hasError || !snapshot.hasData) return Center(child: Text('Error al cargar.', style: Theme.of(context).textTheme.bodyMedium));

                final allModules = snapshot.data!;
                final activeModules = allModules.where((module) => userModel.activeModules.contains(module.moduleId)).toList()..sort((a, b) => a.defaultOrder.compareTo(b.defaultOrder));

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Showcase(
                        key: _keyHeader, title: 'Panel Principal', description: 'Aquí ves el resumen general.',
                        child: DashboardHeader(userModel: userModel),
                      ),
                    ),
                    _buildAnimatedContent(context, userModel, activeModules, allModules),
                  ],
                );
              },
            ),
          ),
        );
      }
    );
  }

  Widget _buildAnimatedContent(BuildContext context, UserModel userModel, List<ModuleModel> activeModules, List<ModuleModel> allModules) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate.fixed([
          if (!userModel.isProfileComplete)
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: _ProfileCompletionBanner(onCompleteProfile: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateProfileScreen()))),
            ),

          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text("Resumen en Vivo", style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70, fontWeight: FontWeight.w600)),
          ),
          
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Showcase(
              key: _keyPrompt, title: 'Tu Asistente IA', description: 'También puedes escribirme aquí.',
              child: const _ServiPromptBar(),
            ),
          ),

          Showcase(
            key: _keyMetrics, title: 'Métricas', description: 'Visitas y contactos recibidos.',
            child: metric_widgets.DashboardMetricsCard(userModel: userModel),
          ),
          const SizedBox(height: 32),
          
          Showcase(
            key: _keySummaryCards, title: 'Estado de tu Negocio', description: 'Finanzas, Citas y Solicitudes.',
            child: const summary_widgets.DashboardSummaryCards(),
          ),
          const SizedBox(height: 32),
          
          Showcase(
            key: _keyPublicProfile, 
            title: 'Tu Negocio Digital', 
            description: 'Comparte tu perfil con clientes.',
            child: _PublicProfileButton(userModel: userModel),
          ),
          const SizedBox(height: 32),

          Text('Mis Módulos', style: theme.textTheme.titleLarge?.copyWith(color: colors.onSurface, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          FadeTransition(
            opacity: CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut)),
              child: Showcase(
                key: _keyModulesGrid, title: 'Tus Herramientas', description: 'Mantené apretado para saber qué hace cada una.',
                child: ModulesGrid(activeModules: activeModules, user: userModel, onAddModule: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ModulesScreen(userModel: userModel, allModules: allModules)));
                }),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}

// ... (Widgets auxiliares sin cambios)
class _ServiPromptBar extends StatelessWidget {
    const _ServiPromptBar();
    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);
        return GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ServiChatScreen())),
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5))),
                child: Row(children: [Icon(Icons.mic_none, color: theme.colorScheme.primary), const SizedBox(width: 12), Expanded(child: Text("Escribile a SERVI...", style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))))]),
            ),
        );
    }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Theme.of(context).colorScheme.surface, body: Center(child: Text('Próximamente: $title')));
  }
}

class _ProfileCompletionBanner extends StatelessWidget {
  final VoidCallback onCompleteProfile;
  const _ProfileCompletionBanner({required this.onCompleteProfile});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.primary.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: colors.primary, size: 32),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Finaliza la configuración', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colors.onSurface)), const SizedBox(height: 4), Text('Completa tu perfil para desbloquear todas las funciones.', style: theme.textTheme.bodyMedium)])),
              const SizedBox(width: 16),
              FilledButton(onPressed: onCompleteProfile, child: const Text('COMPLETAR')),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicProfileButton extends StatelessWidget {
  final UserModel userModel;
  const _PublicProfileButton({required this.userModel});

  @override
  Widget build(BuildContext context) {
    final bool isProfileCreated = userModel.publicProfileCreated; 
    final String buttonText = isProfileCreated ? 'Ver mi Perfil Público' : 'Crear mi Perfil Público';
    final IconData buttonIcon = isProfileCreated ? Icons.visibility_outlined : Icons.add_circle_outline;

    void onPressedAction() {
      if (isProfileCreated) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PublicProfileScreen(providerId: userModel.uid),
        ));
      } else {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SelectProfileTemplateScreen(user: userModel),
        ));
      }
    }

    return OutlinedButton.icon(
      onPressed: onPressedAction,
      icon: Icon(buttonIcon),
      label: Text(buttonText),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  final String? userName;
  const _LoadingSkeleton({this.userName});
  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}