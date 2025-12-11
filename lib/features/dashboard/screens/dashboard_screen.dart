import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui'; // Para ImageFilter
import 'package:audioplayers/audioplayers.dart'; // Para controlar el estado del reproductor

// --- Imports de Utilidades ---
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- IMPORTACIÓN DEL SERVICIO DE VOZ ---
import 'package:proveedor_servicly_app/ai/services/voice_service.dart';

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

// --- Widget de Métricas Extraído ---
import 'package:proveedor_servicly_app/features/dashboard/widgets/dashboard_v1/dashboard_metrics_card.dart';

// --- IMPORTACIÓN CLAVE SERVI (MVP 3.0) ---
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
    setState(() {
      _selectedIndex = index;
    });
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
            body: IndexedStack(
              index: _selectedIndex,
              children: _widgetOptions,
            ),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: colors.surface,
              selectedItemColor: colors.primary,
              unselectedItemColor: colors.onSurface.withValues(alpha: 0.6),
              items: const <BottomNavigationBarItem>[
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
                  destinations: const <NavigationRailDestination>[
                    NavigationRailDestination(icon: Icon(Icons.dashboard_rounded), label: Text('Inicio')),
                    NavigationRailDestination(icon: Icon(Icons.map_outlined), label: Text('Explorar')),
                    NavigationRailDestination(icon: Icon(Icons.lightbulb_outline_rounded), label: Text('Oportunidades')),
                    NavigationRailDestination(icon: Icon(Icons.settings_outlined), label: Text('Ajustes')),
                  ],
                ),
                VerticalDivider(thickness: 1, width: 1, color: theme.dividerColor),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _widgetOptions,
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

// ===================================================================
// --- PESTAÑA 0: INICIO (CON TOUR COMPLETO) ---
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
  final GlobalKey _keySummaryCards = GlobalKey(); // Key para el resumen
  final GlobalKey _keyPublicProfile = GlobalKey();
  final GlobalKey _keyModulesGrid = GlobalKey(); // Key para la grilla de módulos

  // --- VARIABLES DE IA (Servi) ---
  final ServiVoiceService _voiceService = ServiVoiceService();
  bool _isSpeaking = false; 
  bool _isTourCheckPending = true;

  @override
  void initState() {
    super.initState();
    _modulesFuture = context.read<FirestoreService>().getAvailableModules();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _initVoiceListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  void _initVoiceListeners() {
    _voiceService.player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isSpeaking = state == PlayerState.playing;
        });
      }
    });
  }

  Future<void> _speak(String text) async {
    await _voiceService.speak(text);
  }

  // --- LÓGICA PARA OBTENER EL NOMBRE REAL ---
  String _getUserName(UserModel user) {
    // 1. Intentar con displayName (Google/Auth)
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!.trim().split(' ')[0];
    }
    // 2. Intentar con el nombre del negocio
    if (user.personalization['businessName'] != null) {
      String businessName = user.personalization['businessName'].toString();
      if (businessName.trim().isNotEmpty) {
        return businessName;
      }
    }
    // 3. Fallback
    return "Campeón"; 
  }

  // --- EL GUION DEL TOUR MEJORADO ---
  String _getScriptForStep(GlobalKey key, UserModel user) {
    String name = _getUserName(user);

    if (key == _keyHeader) {
      return "Hola $name. Bienvenido. Aquí arriba verás tus notificaciones importantes.";
    } else if (key == _keyPrompt) {
      return "Aquí estoy yo. Tócame para preguntarme dudas o consejos para vender más.";
    } else if (key == _keyMetrics) {
      return "Métricas en tiempo real. Controla cuánta gente visita tu perfil hoy.";
    } else if (key == _keySummaryCards) {
      // Explicación de las tarjetas de resumen
      return "Este es el corazón de tu operación. Aquí ves el resumen de tus finanzas, citas pendientes y solicitudes nuevas en un solo vistazo.";
    } else if (key == _keyPublicProfile) {
      return "Este botón es clave. Configura tu Negocio Digital y compártelo por WhatsApp.";
    } else if (key == _keyModulesGrid) {
      // Explicación detallada de módulos
      return "Y aquí tu arsenal de herramientas: Usa 'Finanzas' para ver gastos, 'Caja Rápida' para cobrar al instante, y 'Tienda' para subir tus productos. ¡Tú tienes el control!";
    }
    return "";
  }

  // --- CALLBACK INTELIGENTE DEL TOUR ---
  void _onShowcaseStepStart(int? index, GlobalKey key) {
    final user = context.read<UserModel>();
    String script = _getScriptForStep(key, user);
    
    // SCROLL AUTOMÁTICO para asegurar visibilidad
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 600), 
        curve: Curves.easeInOut,
        alignment: 0.5, // Centra el widget en la pantalla
      );
    }

    if (script.isNotEmpty) {
      // Pequeño delay para esperar el scroll
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _speak(script);
      });
    }
  }

  Future<void> _checkIfFirstTime(BuildContext showcaseContext) async {
    final prefs = await SharedPreferences.getInstance();
    // V9: Nueva versión para incluir los nuevos pasos
    final bool hasSeenTour = prefs.getBool('hasSeenDashboardTour_v9') ?? false;

    if (!hasSeenTour) {
      final user = context.read<UserModel>();
      String name = _getUserName(user);
      
      await _speak("Hola $name. Soy Servi. Vamos a revisar tu panel de control completo.");

      if (mounted) {
        ShowCaseWidget.of(showcaseContext).startShowCase([
          _keyHeader,
          _keyPrompt, 
          _keyMetrics,
          _keySummaryCards, // NUEVO PASO
          _keyPublicProfile,
          _keyModulesGrid,  // NUEVO PASO
        ]);
        prefs.setBool('hasSeenDashboardTour_v9', true);
      }
    }
  }

  void _manualTourStart(BuildContext showcaseContext) {
    _speak("Repasemos todas tus herramientas.");
    ShowCaseWidget.of(showcaseContext).startShowCase([
      _keyHeader,
      _keyPrompt,
      _keyMetrics,
      _keySummaryCards,
      _keyPublicProfile,
      _keyModulesGrid,
    ]);
  }

  void _giveContextualHelp(UserModel user) {
    if (_isSpeaking) {
      _voiceService.stop();
      return;
    }
    
    if (!user.isProfileComplete) {
      _speak("Tu perfil está incompleto. Termínalo para generar confianza.");
    } else if (user.publicProfileCreated == false) {
      _speak("Tienes todo listo, pero tu negocio está oculto. ¡Publica tu perfil ahora!");
    } else {
      _speak("Todo se ve genial. Si necesitas ayuda con Finanzas o Ventas, pregúntame.");
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userModel = context.watch<UserModel?>();
    final colors = Theme.of(context).colorScheme;

    if (userModel == null) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    return ShowCaseWidget(
      onStart: (index, key) => _onShowcaseStepStart(index, key),
      onComplete: (index, key) {
        // Ajustado el índice final
        if (index == 5) _speak("¡Listo! A trabajar."); 
      },
      blurValue: 1, 
      builder: (context) { 
        if (_isTourCheckPending) {
          _isTourCheckPending = false;
          WidgetsBinding.instance.addPostFrameCallback((_) => _checkIfFirstTime(context));
        }

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 0,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: GestureDetector(
              onTap: () => _giveContextualHelp(userModel),
              onLongPress: () => _manualTourStart(context),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: _isSpeaking ? 75 : 56,
                width: _isSpeaking ? 75 : 56,
                decoration: BoxDecoration(
                  color: _isSpeaking ? colors.primary : colors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.primary, 
                    width: _isSpeaking ? 0 : 2
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: _isSpeaking ? 0.6 : 0.2),
                      blurRadius: _isSpeaking ? 25 : 8,
                      spreadRadius: _isSpeaking ? 8 : 0,
                    )
                  ],
                ),
                child: _isSpeaking 
                  ? const Icon(Icons.graphic_eq, color: Colors.white, size: 35)
                  : Icon(Icons.smart_toy_rounded, color: colors.primary, size: 24),
              ),
            ),
          ),
          
          body: SafeArea(
            bottom: false,
            child: FutureBuilder<List<ModuleModel>>(
              future: _modulesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _LoadingSkeleton(
                    userName: userModel.displayName,
                    businessName: userModel.personalization['businessName'] as String?,
                  );
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return Center(child: Text('Error al cargar.', style: Theme.of(context).textTheme.bodyMedium));
                }

                final allModules = snapshot.data!;
                final activeModules = allModules
                    .where((module) => userModel.activeModules.contains(module.moduleId))
                    .toList()
                  ..sort((a, b) => a.defaultOrder.compareTo(b.defaultOrder));

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Showcase(
                        key: _keyHeader,
                        title: 'Panel Principal',
                        description: 'Aquí ves el resumen general.',
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
              child: _ProfileCompletionBanner(
                onCompleteProfile: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateProfileScreen()),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              "Resumen en Vivo",
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70, fontWeight: FontWeight.w600),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Showcase(
              key: _keyPrompt,
              title: 'Tu Asistente IA',
              description: 'Habla con Servi para obtener ayuda.',
              child: const _ServiPromptBar(),
            ),
          ),

          Showcase(
            key: _keyMetrics,
            title: 'Métricas',
            description: 'Visitas y contactos recibidos.',
            child: DashboardMetricsCard(userModel: userModel),
          ),

          const SizedBox(height: 32),

          // --- NUEVO: SHOWCASE PARA LOS SUMMARY CARDS ---
          Showcase(
            key: _keySummaryCards,
            title: 'Estado de tu Negocio',
            description: 'Finanzas, Citas y Solicitudes.',
            child: const DashboardSummaryCards(),
          ),

          const SizedBox(height: 32),

          Showcase(
            key: _keyPublicProfile,
            title: 'Tu Negocio Digital', // Cambio de texto solicitado
            description: 'Comparte tu perfil con clientes.',
            child: _PublicProfileButton(userModel: userModel),
          ),
          const SizedBox(height: 32),

          Text(
            'Mis Módulos',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          FadeTransition(
            opacity: CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut)),
              
              // --- NUEVO: SHOWCASE ENVOLVIENDO LA GRILLA DE MÓDULOS ---
              child: Showcase(
                key: _keyModulesGrid,
                title: 'Tus Herramientas',
                description: 'Finanzas, Caja, Tienda y más.',
                child: ModulesGrid(
                  activeModules: activeModules,
                  user: userModel,
                  onAddModule: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ModulesScreen(
                        userModel: userModel,
                        allModules: allModules,
                      )),
                    );
                  },
                ),
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
        final colorScheme = theme.colorScheme;
        
        return GestureDetector(
            onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ServiChatScreen(),
                ));
            },
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.5)),
                ),
                child: Row(
                    children: [
                        Icon(Icons.mic_none, color: colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(
                                "¿Pregúntale a SERVI: 'Cuál es mi próxima cita?'",
                                style: TextStyle(
                                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                                    fontStyle: FontStyle.italic,
                                ),
                            ),
                        ),
                        Icon(Icons.assistant_direction, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                    ],
                ),
            ),
        );
    }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              title == 'Oportunidades' ? Icons.lightbulb_outline_rounded : Icons.construction_rounded,
              color: colors.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 24),
            Text(
              'Próximamente: $title',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Text(
                title == 'Oportunidades'
                    ? 'Estamos construyendo esta sección para conectarte con nuevas oportunidades de negocio.'
                    : 'Esta sección está en desarrollo.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurface.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
      ),
    );
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Finaliza la configuración', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colors.onSurface)),
                    const SizedBox(height: 4),
                    Text('Completa tu perfil para desbloquear todas las funciones.', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: onCompleteProfile,
                child: const Text('COMPLETAR'),
              ),
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
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _LoadingSkeleton extends StatefulWidget {
  final String? userName;
  final String? businessName;
  const _LoadingSkeleton({this.userName, this.businessName});

  @override
  _LoadingSkeletonState createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<_LoadingSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  LinearGradient get _shimmerGradient {
    final color = Theme.of(context).colorScheme.surface;
    final highlightColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);

    return LinearGradient(
      colors: [color, highlightColor, color],
      stops: const [0.1, 0.3, 0.4],
      begin: const Alignment(-1.0, -0.3),
      end: const Alignment(1.0, 0.3),
      tileMode: TileMode.clamp,
      transform: _SlidingGradientTransform(slidePercent: _shimmerController.value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ShimmerObject(width: 150, height: 16, gradient: _shimmerGradient),
                            const SizedBox(height: 8),
                            _ShimmerObject(width: 220, height: 28, gradient: _shimmerGradient),
                          ],
                        ),
                      ),
                      _ShimmerObject(width: 44, height: 44, gradient: _shimmerGradient, isCircle: true),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                sliver: SliverToBoxAdapter(child: _ShimmerObject(height: 100, gradient: _shimmerGradient)),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                sliver: SliverToBoxAdapter(child: _ShimmerObject(height: 50, gradient: _shimmerGradient)),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24.0),
                sliver: SliverGrid.count(
                  crossAxisCount: (MediaQuery.of(context).size.width / 180).floor().clamp(2, 5),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: List.generate(6, (index) => _ShimmerObject(gradient: _shimmerGradient)),
                ),
              ),
            ],
          );
        }
    );
  }
}

class _ShimmerObject extends StatelessWidget {
  final double? width;
  final double? height;
  final bool isCircle;
  final LinearGradient gradient;

  const _ShimmerObject({
    required this.gradient,
    this.width,
    this.height,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: isCircle ? null : BorderRadius.circular(16),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});
  final double slidePercent;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final translationX = bounds.width * slidePercent * 2.0 - bounds.width;
    return Matrix4.translationValues(translationX, 0.0, 0.0);
  }
}