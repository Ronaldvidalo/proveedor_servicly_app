import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui'; // Para ImageFilter

// --- Imports para el Tour ---
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  // (Fix: Eliminado _showCaseContext no utilizado)

  static const List<Widget> _widgetOptions = <Widget>[
    _ProviderHomeTab(),              // Index 0: Dashboard (Inicio)
    HomeScreen(),                    // Index 1: Explorar
    _PlaceholderScreen(title: 'Oportunidades'), // Index 2: Oportunidades
    SettingsScreen(),                // Index 3: Configuración
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

    return ShowCaseWidget(
      builder: (context) {
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
                  unselectedItemColor: colors.onSurface.withAlpha(150),
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard_rounded),
                      label: 'Inicio',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.map_outlined),
                      label: 'Explorar',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.lightbulb_outline_rounded),
                      label: 'Oportunidades',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings_outlined),
                      label: 'Ajustes',
                    ),
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
      },
    );
  }
}

// ===================================================================
// --- PESTAÑA 0: INICIO ---
// ===================================================================

class _ProviderHomeTab extends StatefulWidget {
  const _ProviderHomeTab(); // (Fix: key removido en widget privado si no se usa)

  @override
  State<_ProviderHomeTab> createState() => _ProviderHomeTabState();
}

class _ProviderHomeTabState extends State<_ProviderHomeTab> with SingleTickerProviderStateMixin {
  late Future<List<ModuleModel>> _modulesFuture;
  late AnimationController _animationController;

  final GlobalKey _keyHeader = GlobalKey();
  final GlobalKey _keyMetrics = GlobalKey();
  final GlobalKey _keyPublicProfile = GlobalKey();
  final GlobalKey _keyModulesTitle = GlobalKey();

  bool _isTourCheckPending = true;

  @override
  void initState() {
    super.initState();
    _modulesFuture = context.read<FirestoreService>().getAvailableModules();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  Future<void> _checkIfFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenTour = prefs.getBool('hasSeenDashboardTour_v1') ?? false;

    if (!hasSeenTour) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _startTour();
        prefs.setBool('hasSeenDashboardTour_v1', true);
      }
    }
  }

  void _startTour() {
    final showCaseContext = ShowCaseWidget.of(context);
    // (Fix: Eliminada verificación nula innecesaria según el linter)
    showCaseContext.startShowCase([
      _keyHeader,
      _keyMetrics,
      _keyPublicProfile,
      _keyModulesTitle,
    ]);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userModel = context.watch<UserModel?>();
    final colors = Theme.of(context).colorScheme;

    if (userModel == null) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: FloatingActionButton.small(
          onPressed: _startTour,
          backgroundColor: colors.surface,
          foregroundColor: colors.onSurface,
          tooltip: 'Ayuda del Dashboard',
          child: const Icon(Icons.help_outline_rounded),
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

            if (snapshot.hasError || !snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
              return Center(child: Text('Error al cargar la configuración.', style: Theme.of(context).textTheme.bodyMedium));
            }

            if (_isTourCheckPending) {
              _isTourCheckPending = false;
              WidgetsBinding.instance.addPostFrameCallback((_) => _checkIfFirstTime());
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
                    title: 'Bienvenido',
                    description: 'Este es tu panel de control. Aquí verás un resumen de tu negocio.',
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

  Widget _buildAnimatedContent(BuildContext context, UserModel userModel, List<ModuleModel> activeModules, List<ModuleModel> allModules) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      // (Fix Crítico: Cambiado 'slivers' por 'sliver' porque SliverPadding toma un solo hijo)
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
          
          // --- A. NUEVO: BARRA DE PROMPT SERVI (MVP 3.0) ---
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: _ServiPromptBar(),
          ),
          // --- FIN NUEVO ---

          Showcase(
            key: _keyMetrics,
            title: 'Métricas Rápidas',
            description: 'Consulta visitas y contactos de un vistazo.',
            child: DashboardMetricsCard(userModel: userModel),
          ),

          const SizedBox(height: 32),

          const DashboardSummaryCards(),

          const SizedBox(height: 32),

          Showcase(
            key: _keyPublicProfile,
            title: 'Tu Tienda Online',
            description: 'Configura y comparte tu perfil público con tus clientes.',
            child: _PublicProfileButton(userModel: userModel),
          ),
          const SizedBox(height: 32),

          Showcase(
            key: _keyModulesTitle,
            title: 'Tus Herramientas',
            description: 'Accede a tus módulos activos o añade nuevos desde aquí.',
            child: Text(
              'Mis Módulos',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.bold,
              ),
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
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}

// ===================================================================
// --- WIDGETS AUXILIARES (SERVI IMPLEMENTATION) ---
// ===================================================================

/// Componente de entrada de texto que lleva al chat conversacional de SERVI.
class _ServiPromptBar extends StatelessWidget {
    const _ServiPromptBar();

    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
        return GestureDetector(
            onTap: () {
                // Navegación CLAVE: Al tocar, lleva a la pantalla de chat.
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ServiChatScreen(),
                ));
            },
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                    color: theme.cardTheme.color, // Fondo de la tarjeta
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.primary.withOpacity(0.5)),
                ),
                child: Row(
                    children: [
                        Icon(Icons.mic_none, color: colorScheme.primary),
                        const SizedBox(width: 12),
                        // El texto guía al usuario a interactuar con la IA
                        Expanded(
                            child: Text(
                                "¿Pregúntale a SERVI: 'Cuál es mi próxima cita?'",
                                style: TextStyle(
                                    color: colorScheme.onSurface.withOpacity(0.6),
                                    fontStyle: FontStyle.italic,
                                ),
                            ),
                        ),
                        Icon(Icons.assistant_direction, color: colorScheme.onSurface.withOpacity(0.3)),
                    ],
                ),
            ),
        );
    }
}

class _PlaceholderScreen extends StatelessWidget {
// ... (resto de _PlaceholderScreen)
  final String title;
  const _PlaceholderScreen({required this.title}); // (Fix: key removido)

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
              color: colors.onSurface.withAlpha(50),
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
                style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurface.withAlpha(178)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCompletionBanner extends StatelessWidget {
// ... (resto de _ProfileCompletionBanner)
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
            color: colors.surface.withAlpha(178),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.primary.withAlpha(128)),
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
// ... (resto de _PublicProfileButton)
  final UserModel userModel;
  const _PublicProfileButton({required this.userModel});

  @override
  Widget build(BuildContext context) {
    final bool isProfileCreated = userModel.publicProfileCreated ?? false; 
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
// ... (resto de _LoadingSkeleton)
  final String? userName;
  final String? businessName;
  const _LoadingSkeleton({this.userName, this.businessName}); // (Fix: key removido)

  @override
  _LoadingSkeletonState createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<_LoadingSkeleton> with SingleTickerProviderStateMixin {
// ... (resto de _LoadingSkeletonState)
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
    final highlightColor = Theme.of(context).colorScheme.onSurface.withAlpha(30);

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
// ... (resto de _ShimmerObject)
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
