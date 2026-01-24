import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:firebase_auth/firebase_auth.dart'; // IMPORTANTE: Para cerrar sesión

// --- Imports de Utilidades ---
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- IMPORTS DE LA IA ---
import 'package:proveedor_servicly_app/ai/services/voice_service.dart';
import 'package:proveedor_servicly_app/ai/widgets/servi_avatar.dart';
import 'package:proveedor_servicly_app/ai/screens/servi_chat_screen.dart';

// --- IMPORTS PROACTIVOS ---
import 'package:proveedor_servicly_app/features/crm/services/proactive_lead_engine.dart';
import 'package:proveedor_servicly_app/features/promotion/models/smart_insight_model.dart';

// --- Modelos y Servicios ---
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/models/module_model.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/core/services/notification_service.dart';

// --- Pantallas de Autenticación (Ajusta la ruta si es diferente) ---
import 'package:proveedor_servicly_app/features/auth/screens/auth_screen.dart';

// --- Módulos ---
import 'package:proveedor_servicly_app/features/profile/screens/create_profile_screen.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/public_profile_screen.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/presentation/screens/select_profile_template_screen.dart';
import 'package:proveedor_servicly_app/features/settings/screens/settings_screen.dart';
import 'package:proveedor_servicly_app/features/home/screens/home_screen.dart';
import 'package:proveedor_servicly_app/widgets/grids/dashboard/module_grid.dart'; 

// --- Header y Provider ---
import 'package:proveedor_servicly_app/features/dashboard/providers/dashboard_context_provider.dart';

// --- Widgets de Métricas y Nuevos Diseños ---
import 'package:proveedor_servicly_app/features/dashboard/widgets/dashboard_v1/unified_control_center.dart'; 
import 'package:proveedor_servicly_app/features/inventory/widgets/critical_stock_card.dart';

// --- Layout ---
import 'package:proveedor_servicly_app/widgets/layout/adaptive_center.dart';
import 'package:proveedor_servicly_app/widgets/navigation/servicly_sidebar.dart';

// ---------------------------------------------------------------------------
// CONSTANTES
// ---------------------------------------------------------------------------
const double kMobileBreakpoint = 1024.0; 
const double kMaxWebWidth = 1000.0; 

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardContext(),
      child: const _DashboardContent(),
    );
  }
}

class _DashboardContent extends StatefulWidget {
  const _DashboardContent();

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isMenuOpen = false;
  final ScrollController _mainScrollController = ScrollController();

  late Future<List<ModuleModel>> _modulesFuture;
  late Stream<List<ProviderProfileModel>> _profilesStream;
  late AnimationController _animationController;
  late AnimationController _menuController;

  final GlobalKey _keyHeader = GlobalKey();
  final GlobalKey _keyPrompt = GlobalKey();
  final GlobalKey _keyMetrics = GlobalKey();
  final GlobalKey _keyTools = GlobalKey(); 
  final GlobalKey _keyPublicProfile = GlobalKey();

  final ServiVoiceService _voiceService = ServiVoiceService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  bool _isSpeaking = false;
  final bool _isListening = false;
  final bool _isThinking = false;
  bool _isMuted = false;
  
  final ProactiveLeadEngine _leadEngine = ProactiveLeadEngine();
  StreamSubscription? _leadSubscription;
  SmartInsight? _currentInsight;
  bool _isTourCheckPending = true;

  @override
  void initState() {
    super.initState();
    _initServices();
    _initAnimations();
    _initVoiceListeners();
  }

  void _initServices() {
    final firestoreService = context.read<FirestoreService>();
    final user = context.read<UserModel?>();

    _modulesFuture = firestoreService.getAvailableModules();

    if (user != null) {
      _profilesStream = firestoreService.getUserProviderProfiles(user.uid);
    } else {
      _profilesStream = Stream.value([]);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (user != null) {
          _leadSubscription = _leadEngine.listenForNewLeads(user.uid).listen((insight) {
            if (insight != null && mounted) {
              setState(() => _currentInsight = insight);
              _handleNewInsight(insight);
            }
          });
          Future.delayed(const Duration(seconds: 3), () {
            if (_currentInsight == null && mounted) _checkProactiveInsights(user);
          });
      }
      final notificationService = context.read<NotificationService>();
      await notificationService.init();
      if (mounted) await notificationService.saveTokenToDatabase();
    });
  }

  void _initAnimations() {
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _menuController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
  }

  void _initVoiceListeners() {
    _voiceService.player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isSpeaking = state == PlayerState.playing);
    });
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  Future<void> _speak(String text) async {
    if (_isMuted) return;
    await _voiceService.speak(text);
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    if (_isMuted) {
      _voiceService.stop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🔇 Servi silenciada"), duration: Duration(seconds: 1)));
    } else {
      _speak("Audio activado.");
    }
    _toggleMenu(false);
  }

  void _toggleMenu([bool? forceState]) {
    final newState = forceState ?? !_isMenuOpen;
    setState(() => _isMenuOpen = newState);
    _isMenuOpen ? _menuController.forward() : _menuController.reverse();
  }

  void _handleAvatarTap(UserModel user) {
    if (_isMenuOpen) { _toggleMenu(false); return; }
    if (_isThinking) return;
    if (_isMuted) setState(() => _isMuted = false);
    
    if (_isListening) {
      _listen(user);
    } else if (_isSpeaking) {
      _voiceService.stop();
    } else {
      _speak("Te escucho...");
      Future.delayed(const Duration(milliseconds: 800), () => _listen(user));
    }
  }

  Future<void> _listen(UserModel user) async {}
  void _handleNewInsight(SmartInsight insight) {}
  Future<void> _checkProactiveInsights(UserModel user) async {}

  void _manualTourStart(BuildContext context) {
      _toggleMenu(false);
      ShowCaseWidget.of(context).startShowCase([_keyHeader, _keyPrompt, _keyMetrics, _keyPublicProfile, _keyTools]);
  }
  
  Future<void> _checkIfFirstTime(BuildContext context, UserModel user) async {
       final prefs = await SharedPreferences.getInstance();
       final String tourKey = 'hasSeenNewDashboard_v6_${user.uid}'; 
       
       if (!mounted) return;

       if (!(prefs.getBool(tourKey) ?? false)) {
           ShowCaseWidget.of(context).startShowCase([_keyHeader, _keyPrompt, _keyMetrics, _keyPublicProfile, _keyTools]);
           prefs.setBool(tourKey, true);
       }
  }

  // --- LÓGICA DE CIERRE DE SESIÓN ---
  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.logout, color: Colors.redAccent), SizedBox(width: 10), Text("Cerrar Sesión")]),
        content: const Text("¿Estás seguro que deseas salir de Servicly?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: Text("Cancelar", style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface))
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Salir")
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()), 
          (route) => false
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _menuController.dispose();
    _voiceService.dispose();
    _speech.stop();
    _leadSubscription?.cancel();
    _mainScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userModel = context.watch<UserModel?>();
    final dashboardContext = context.watch<DashboardContext>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (userModel == null) return Center(child: CircularProgressIndicator(color: colors.primary));

    return ShowCaseWidget(
      onStart: (index, key) { },
      onComplete: (index, key) { if (index == 4) _speak("¡Todo listo!"); },
      blurValue: 1,
      builder: (context) {
        if (_isTourCheckPending) {
          _isTourCheckPending = false;
          WidgetsBinding.instance.addPostFrameCallback((_) => _checkIfFirstTime(context, userModel));
        }

        return FutureBuilder<List<ModuleModel>>(
          future: _modulesFuture,
          builder: (context, moduleSnapshot) {
            if (moduleSnapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
            
            final allModules = moduleSnapshot.data ?? [];
            
            return StreamBuilder<List<ProviderProfileModel>>(
              stream: _profilesStream,
              builder: (context, profileSnapshot) {
                final profiles = profileSnapshot.data ?? [];

                return _ResponsiveShell(
                  selectedIndex: _selectedIndex,
                  onNavigationChanged: _onItemTapped,
                  floatingActionButton: _buildAiFloatingAction(context, colors, userModel),
                  body: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      // TAB 0: DASHBOARD
                      _buildDashboardTab(context, userModel, dashboardContext, profiles, allModules),
                      // OTROS TABS
                      const HomeScreen(),
                      const _PlaceholderScreen(title: 'Oportunidades'),
                      const SettingsScreen(),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // --- BUILDERS ESPECÍFICOS ---

  Widget _buildDashboardTab(
    BuildContext context,
    UserModel userModel,
    DashboardContext dashboardContext,
    List<ProviderProfileModel> profiles,
    List<ModuleModel> allModules,
  ) {
    return Scrollbar(
      controller: _mainScrollController,
      thumbVisibility: kIsWeb, 
      trackVisibility: kIsWeb,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > kMobileBreakpoint) {
            // WEB: Centrado y Compacto
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kMaxWebWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
                  child: _buildWebDashboardLayout(context, userModel, dashboardContext, allModules, Theme.of(context), profiles),
                ),
              ),
            );
          } else {
            // MÓVIL: Scroll Normal con Padding Superior Ajustado
            return CustomScrollView(
              controller: _mainScrollController,
              slivers: [
                SliverPadding(
                  // PADDING AJUSTADO: 60px arriba para evitar solapamiento con la barra de estado
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate.fixed([
                      _buildMobileContent(context, userModel, dashboardContext, allModules, Theme.of(context), profiles)
                    ]),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          }
        },
      ),
    );
  }

  // -----------------------------------------------------------
  // DISEÑO WEB: SINGLE STACK (Depurado)
  // -----------------------------------------------------------
  Widget _buildWebDashboardLayout(
    BuildContext context,
    UserModel userModel,
    DashboardContext dashboardContext,
    List<ModuleModel> allModules,
    ThemeData theme,
    List<ProviderProfileModel> profiles,
  ) {
    final selectedProfile = dashboardContext.selectedProfile;

    return SingleChildScrollView(
      controller: _mainScrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. TOP BAR COMPACTA (Search + Notificaciones + LOGOUT)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 24.0),
                  child: Showcase(
                    key: _keyPrompt, title: 'IA', description: 'Asistente.',
                    child: const _ServiPromptBarCompact(),
                  ),
                ),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_outlined)),
              const SizedBox(width: 8),
              // BOTÓN LOGOUT WEB
              IconButton(
                onPressed: () => _confirmLogout(context), 
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                tooltip: "Cerrar Sesión",
              ),
              const SizedBox(width: 12),
              CircleAvatar(backgroundImage: NetworkImage(userModel.photoUrl ?? ''), radius: 20),
            ],
          ),
          
          const SizedBox(height: 32),

          // 2. UNIFIED CONTROL CENTER (NIVEL 1 - HERO)
          Showcase(
            key: _keyMetrics, title: 'Centro de Control', description: 'Visión general.',
            child: UnifiedControlCenter(userModel: userModel, profiles: profiles),
          ),

          const SizedBox(height: 24),

          // 3. TIENDA DIGITAL (NIVEL 2)
          Showcase(
            key: _keyPublicProfile, title: 'Tu Negocio Digital', description: 'Compartilo.',
            child: _StoreStatusCard(userModel: userModel, selectedProfileId: selectedProfile?.id),
          ),
          
          const SizedBox(height: 24),

          // 4. GRID DE HERRAMIENTAS (NIVEL 3)
          _WebDashboardCard(
            title: "Herramientas de Gestión",
            child: Showcase(
              key: _keyTools, title: 'Apps', description: 'Activa tus módulos.',
              child: ModulesGrid(
                allModules: allModules, 
                user: userModel, 
              ),
            ),
          ),
          
          const SizedBox(height: 40), 
        ],
      ),
    );
  }

  // --- LAYOUT MÓVIL CON HEADER SUPERIOR ---
  Widget _buildMobileContent(
    BuildContext context,
    UserModel userModel,
    DashboardContext dashboardContext,
    List<ModuleModel> allModules,
    ThemeData theme,
    List<ProviderProfileModel> profiles,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- NUEVO HEADER MÓVIL (Logo + Logout) ---
        Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo/Marca
              RichText(
                text: TextSpan(
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1),
                  children: [
                    TextSpan(text: 'SERVIC', style: TextStyle(color: theme.colorScheme.onSurface)),
                    TextSpan(text: 'LY', style: TextStyle(color: theme.colorScheme.primary)),
                  ],
                ),
              ),
              // Botón Logout
              IconButton(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
        ),

        if (!userModel.isProfileComplete && dashboardContext.selectedProfile == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: AdaptiveCenter(child: _ProfileCompletionBanner(onCompleteProfile: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateProfileScreen())))),
          ),

        // 1. UNIFIED CONTROL CENTER (Hero)
        Showcase(
          key: _keyMetrics, title: 'Centro de Control', description: 'Tus números y estado.', 
          child: UnifiedControlCenter(userModel: userModel, profiles: profiles),
        ),
        
        const SizedBox(height: 20),

        // 2. SEARCH BAR
        Showcase(
          key: _keyPrompt, title: 'IA', description: 'Asistente.',
          child: const _ServiPromptBar(),
        ),

        const SizedBox(height: 24),
        
        // 3. Tarjeta de Tienda
        Showcase(key: _keyPublicProfile, title: 'Perfil', description: 'Ver perfil.', child: AdaptiveCenter(maxWebWidth: 500, child: _StoreStatusCard(userModel: userModel, selectedProfileId: dashboardContext.selectedProfile?.id))),
        const SizedBox(height: 24),

        // 4. Grid de Herramientas
        _WebDashboardCard(
          title: "Mis Herramientas",
          child: Showcase(
            key: _keyTools, 
            title: 'Apps', 
            description: 'Tus herramientas.', 
            child: ModulesGrid(
              allModules: allModules, 
              user: userModel, 
            )
          ),
        ),

        if (dashboardContext.selectedProfile == null || dashboardContext.selectedProfile?.publicProfileTemplate == 'store') ...[
          const SizedBox(height: 24),
          CriticalStockCard(user: userModel), 
        ],
      ],
    );
  }

  // 3. FAB
  Widget _buildAiFloatingAction(BuildContext context, ColorScheme colors, UserModel userModel) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ScaleTransition(
          scale: CurvedAnimation(parent: _menuController, curve: const Interval(0.0, 1.0, curve: Curves.easeOutBack)),
          child: Padding(padding: const EdgeInsets.only(bottom: 12), child: FloatingActionButton.small(heroTag: "help", backgroundColor: colors.surface, foregroundColor: colors.onSurface, onPressed: () => _manualTourStart(context), child: const Icon(Icons.help_outline))),
        ),
        ScaleTransition(
          scale: CurvedAnimation(parent: _menuController, curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack)),
          child: Padding(padding: const EdgeInsets.only(bottom: 12), child: FloatingActionButton.small(heroTag: "mute", backgroundColor: _isMuted ? Colors.redAccent : Colors.greenAccent, foregroundColor: Colors.white, onPressed: _toggleMute, child: Icon(_isMuted ? Icons.volume_off : Icons.volume_up))),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _handleAvatarTap(userModel),
            onLongPress: () => _toggleMenu(),
            child: ServiAvatar(isSpeaking: _isSpeaking, isListening: _isListening, isThinking: _isThinking, size: 65),
          ),
        ),
      ],
    );
  }
}

class _ResponsiveShell extends StatelessWidget {
  final Widget body;
  final Widget floatingActionButton;
  final int selectedIndex;
  final ValueChanged<int> onNavigationChanged;

  const _ResponsiveShell({required this.body, required this.floatingActionButton, required this.selectedIndex, required this.onNavigationChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < kMobileBreakpoint) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor, 
          extendBodyBehindAppBar: true,
          body: body,
          floatingActionButton: Padding(padding: const EdgeInsets.only(bottom: 16.0), child: floatingActionButton),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: theme.cardColor, 
            selectedItemColor: colors.primary,
            unselectedItemColor: colors.onSurface.withValues(alpha: 0.6),
            currentIndex: selectedIndex,
            onTap: onNavigationChanged,
            elevation: 8,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Inicio'),
              BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Explorar'),
              BottomNavigationBarItem(icon: Icon(Icons.lightbulb_outline_rounded), label: 'Ideas'),
              BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Ajustes'),
            ],
          ),
        );
      } else {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor, 
          floatingActionButton: floatingActionButton,
          body: Row(
            children: [
              ServiclySidebar(selectedIndex: selectedIndex, onDestinationSelected: onNavigationChanged),
              Expanded(child: body),
            ],
          ),
        );
      }
    });
  }
}

// --- WIDGETS AUXILIARES ---

class _ServiPromptBar extends StatelessWidget {
    const _ServiPromptBar();
    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ServiChatScreen())),
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.cardColor, 
                  borderRadius: BorderRadius.circular(16), 
                  border: Border.all(
                    color: isDark 
                        ? theme.colorScheme.primary.withValues(alpha: 0.3) 
                        : Colors.black.withValues(alpha: 0.08), 
                    width: 1
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark 
                          ? theme.colorScheme.primary.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4)
                    )
                  ]
                ),
                child: Row(children: [Icon(Icons.mic_none, color: theme.colorScheme.primary), const SizedBox(width: 12), Expanded(child: Text("Escribile a SERVI...", style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))))]),
            ),
          ),
        );
    }
}

class _ServiPromptBarCompact extends StatelessWidget {
    const _ServiPromptBarCompact();
    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ServiChatScreen())),
            child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.cardColor, 
                  borderRadius: BorderRadius.circular(20), 
                  border: Border.all(
                    color: isDark 
                        ? theme.colorScheme.outline.withValues(alpha: 0.2) 
                        : Colors.black.withValues(alpha: 0.1)
                  )
                ),
                child: Row(children: [Icon(Icons.search, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)), const SizedBox(width: 8), Expanded(child: Text("Preguntar a IA...", style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))))]),
            ),
          ),
        );
    }
}

// WIDGET ADAPTABLE: Tarjeta contenedora para secciones
class _WebDashboardCard extends StatelessWidget {
  final String? title;
  final Widget child;
  const _WebDashboardCard({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.1) 
              : Colors.black.withValues(alpha: 0.08), 
          width: 1
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.2) 
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 16, 
            offset: const Offset(0, 6)
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(title!, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.9))),
            ),
            Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5)),
          ],
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _StoreStatusCard extends StatelessWidget {
  final UserModel userModel;
  final String? selectedProfileId;
  const _StoreStatusCard({required this.userModel, this.selectedProfileId});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isCreated = userModel.publicProfileCreated;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors.primary, colors.secondary]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
            BoxShadow(
                color: colors.primary.withValues(alpha: 0.3), 
                blurRadius: 12, 
                offset: const Offset(0, 6)
            )
        ]
      ),
      child: Row(
        children: [
          Icon(isCreated ? Icons.store : Icons.add_business, color: colors.onPrimary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isCreated ? "Tienda Activa" : "Crear Tienda", style: TextStyle(color: colors.onPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                if (!isCreated) Text("Empieza a vender", style: TextStyle(color: colors.onPrimary.withValues(alpha: 0.9), fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
               if (isCreated) {
                 Navigator.of(context).push(MaterialPageRoute(builder: (_) => PublicProfileScreen(providerId: userModel.uid)));
               } else {
                 Navigator.of(context).push(MaterialPageRoute(builder: (_) => SelectProfileTemplateScreen(user: userModel)));
               }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: colors.surface, 
                foregroundColor: colors.primary, 
                elevation: 0, 
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
                minimumSize: const Size(60, 30),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            child: Text(isCreated ? "Ver" : "Crear", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Theme.of(context).colorScheme.surface, body: Center(child: Text('Próximamente: $title', style: TextStyle(color: Theme.of(context).colorScheme.onSurface))));
  }
}

class _ProfileCompletionBanner extends StatelessWidget {
  final VoidCallback onCompleteProfile;
  const _ProfileCompletionBanner({required this.onCompleteProfile});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ClipRRect(borderRadius: BorderRadius.circular(24), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), child: Container(padding: const EdgeInsets.all(16.0), decoration: BoxDecoration(color: colors.surface.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(24), border: Border.all(color: colors.primary.withValues(alpha: 0.5))), child: Row(children: [Icon(Icons.info_outline_rounded, color: colors.primary, size: 32), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Finaliza la configuración', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colors.onSurface)), const SizedBox(height: 4), Text('Completa tu perfil para usar todo.', style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurface))])), FilledButton(onPressed: onCompleteProfile, child: const Text('COMPLETAR'))]))));
  }
}