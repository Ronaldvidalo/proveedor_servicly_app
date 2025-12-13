import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui'; 
import 'package:audioplayers/audioplayers.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt; 

// --- Imports de Utilidades ---
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- IMPORTS DE LA IA (SERVICIOS Y WIDGETS) ---
import 'package:proveedor_servicly_app/ai/services/voice_service.dart';
import 'package:proveedor_servicly_app/ai/services/servi_brain_service.dart'; 
import 'package:proveedor_servicly_app/ai/widgets/servi_avatar.dart';

// --- IMPORTS PARA LA CONEXIÓN REAL (CEREBRO HÍBRIDO) ---
import 'package:proveedor_servicly_app/ai/services/gemini_service.dart';
import 'package:proveedor_servicly_app/ai/services/servi_api_connector_service.dart';
import 'package:proveedor_servicly_app/ai/services/servi_conversational_service.dart';

// --- Importaciones de Modelos y Servicios ---
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/models/module_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';

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
import 'package:proveedor_servicly_app/features/dashboard/widgets/dashboard_cards/dashboard_screen/dashboard_summary_cards.dart';
import 'package:proveedor_servicly_app/features/dashboard/widgets/dashboard_v1/dashboard_metrics_card.dart';
import 'package:proveedor_servicly_app/ai/screens/servi_chat_screen.dart'; 

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

  // --- KEYS PARA EL TOUR ---
  final GlobalKey _keyHeader = GlobalKey();
  final GlobalKey _keyPrompt = GlobalKey();
  final GlobalKey _keyMetrics = GlobalKey();
  final GlobalKey _keySummaryCards = GlobalKey(); 
  final GlobalKey _keyPublicProfile = GlobalKey(); 
  final GlobalKey _keyModulesGrid = GlobalKey(); 

  // --- IA SERVICIOS ---
  final ServiVoiceService _voiceService = ServiVoiceService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  late ServiBrainService _serviBrain; 
  
  // Estados de la IA
  bool _isSpeaking = false; 
  bool _isListening = false;
  bool _isThinking = false; // ESTADO NUEVO: Pensando
  
  bool _isTourCheckPending = true;

  // --- MULETILLAS ARGENTINAS (Para llenar silencios) ---
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
    
    // --- 🧠 INICIALIZACIÓN DEL CEREBRO HÍBRIDO ---
    final firestoreService = context.read<FirestoreService>();
    final geminiService = GeminiService(); 
    
    final apiConnector = ServiApiConnectorService(geminiService, firestoreService);
    final conversationalService = ServiConversationalService(apiConnector);
    
    _serviBrain = ServiBrainService(advancedBrain: conversationalService);

    // --- Resto de inicializaciones ---
    _modulesFuture = context.read<FirestoreService>().getAvailableModules();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _initVoiceListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animationController.forward();
    });
  }

  void _initVoiceListeners() {
    _voiceService.player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isSpeaking = state == PlayerState.playing);
      }
    });
  }

  Future<void> _speak(String text) async {
    await _voiceService.speak(text);
  }

  // --- LÓGICA DE ESCUCHA (STT) ---
  Future<void> _listen() async {
    if (_isListening || _isThinking) return; // No interrumpir si piensa

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
            _processVoiceCommand(val.recognizedWords);
          }
        },
        localeId: 'es_AR', 
      );
    } else {
      _speak("No pude acceder al micrófono. Revisá los permisos.");
    }
  }

  // --- CEREBRO: PROCESAMIENTO CON FEEDBACK ---
  Future<void> _processVoiceCommand(String command) async {
    if (command.trim().isEmpty) return;

    // 1. Activar Feedback Visual (Avatar girando)
    setState(() => _isThinking = true);

    // 2. Feedback Auditivo (Muletilla) si la pregunta es compleja (> 2 palabras)
    // Esto hace que el usuario sienta que la IA "le contestó rápido" aunque tarde en buscar datos.
    if (command.split(' ').length > 2) {
       _fillers.shuffle();
       _speak(_fillers.first); // Habla sin esperar (async)
    }

    try {
        final user = context.read<UserModel>();
        
        // 3. Procesamiento Real (Puede tardar 2-4 seg)
        String response = await _serviBrain.processCommand(command, user.uid);
        
        // 4. Apagar Feedback Visual
        if (mounted) setState(() => _isThinking = false);
        
        // 5. Respuesta Final
        _speak(response);
    } catch (e) {
        if (mounted) setState(() => _isThinking = false);
        _speak("Me mareé un poco con los datos. ¿Me preguntás de nuevo?");
    }
  }

  // --- UTILIDADES DEL TOUR ---
  String _getUserName(UserModel user) {
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!.trim().split(' ')[0];
    }
    if (user.personalization['businessName'] != null) {
      return user.personalization['businessName'];
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

  Future<void> _checkIfFirstTime(BuildContext showcaseContext) async {
    final prefs = await SharedPreferences.getInstance();
    final user = context.read<UserModel>();
    final String tourKey = 'hasSeenDashboardTour_v12_${user.uid}'; 
    final bool hasSeenTour = prefs.getBool(tourKey) ?? false;

    if (!hasSeenTour) {
      String name = _getUserName(user);
      await _speak("Hola $name. Soy Servi. Ahora tengo oídos. Tocá mi avatar abajo para hablarme.");
      if (mounted) {
        ShowCaseWidget.of(showcaseContext).startShowCase([_keyHeader, _keyPrompt, _keyMetrics, _keySummaryCards, _keyPublicProfile, _keyModulesGrid]);
        prefs.setBool(tourKey, true);
      }
    }
  }

  void _manualTourStart(BuildContext showcaseContext) {
    _speak("Repasemos todo de nuevo.");
    ShowCaseWidget.of(showcaseContext).startShowCase([_keyHeader, _keyPrompt, _keyMetrics, _keySummaryCards, _keyPublicProfile, _keyModulesGrid]);
  }

  // --- GESTIÓN DEL BOTÓN FLOTANTE INTELIGENTE ---
  void _handleAvatarTap(UserModel user) {
    if (_isThinking) return; // Si piensa, no interrumpir con toques
    
    if (_isListening) {
      _listen(); 
    } else if (_isSpeaking) {
      _voiceService.stop(); 
    } else {
      _speak("Te escucho..."); 
      Future.delayed(const Duration(milliseconds: 800), _listen);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _voiceService.dispose();
    _speech.stop();
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
          WidgetsBinding.instance.addPostFrameCallback((_) => _checkIfFirstTime(context));
        }

        return Scaffold(
          appBar: AppBar(toolbarHeight: 0, backgroundColor: Colors.transparent, elevation: 0),
          
          // --- SERVI AVATAR FLOTANTE (BOTÓN DE ESCUCHA) ---
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: GestureDetector(
              onTap: () => _handleAvatarTap(userModel),
              onLongPress: () => _manualTourStart(context),
              child: ServiAvatar(
                isSpeaking: _isSpeaking,
                isListening: _isListening, 
                isThinking: _isThinking, // <--- Estado Conectado
                size: 65, 
              ),
            ),
          ),
          
          body: SafeArea(
            bottom: false,
            child: FutureBuilder<List<ModuleModel>>(
              future: _modulesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _LoadingSkeleton(userName: userModel.displayName, businessName: userModel.personalization['businessName'] as String?);
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
          
          // Barra de Chat
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Showcase(
              key: _keyPrompt, title: 'Tu Asistente IA', description: 'También puedes escribirme aquí.',
              child: const _ServiPromptBar(),
            ),
          ),

          Showcase(
            key: _keyMetrics, title: 'Métricas', description: 'Visitas y contactos recibidos.',
            child: DashboardMetricsCard(userModel: userModel),
          ),
          const SizedBox(height: 32),
          
          Showcase(
            key: _keySummaryCards, title: 'Estado de tu Negocio', description: 'Finanzas, Citas y Solicitudes.',
            child: const DashboardSummaryCards(),
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

// ===================================================================
// --- WIDGETS AUXILIARES ---
// ===================================================================

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
  final String? businessName;
  const _LoadingSkeleton({this.userName, this.businessName});
  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}