// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 19/11/2025
// Style: Cyber Glow
// Feature: Virtual Tour (ShowCaseView)
//
// 1. (¡NUEVO!) Integrado ShowCaseWidget en la raíz del Dashboard.
// 2. Implementada lógica para iniciar el tour AUTOMÁTICAMENTE
//    solo cuando los datos (FutureBuilder) terminan de cargar.
// 3. Añadidos pasos del tour: Header, Métricas, Perfil Público y Módulos.
// 4. Botón de ayuda (?) en el AppBar para reiniciar el tour manualmente.
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'dart:ui'; // Para ImageFilter

// --- Imports para el Tour ---
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Importaciones de Modelos y Servicios ---
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/models/module_model.dart';
import 'package:proveedor_servicly_app/core/services/auth_service.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/providers/theme_provider.dart';
import 'package:proveedor_servicly_app/widgets/loading/shimmer_loading.dart';
import 'package:proveedor_servicly_app/shared/theme/screens/theme_selection_screen.dart';
import 'package:proveedor_servicly_app/core/services/theme_service.dart';

// --- Importaciones de Módulos ---
import 'package:proveedor_servicly_app/features/catalogo/modules/modules_screen.dart';
import 'package:proveedor_servicly_app/features/profile/screens/create_profile_screen.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/public_profile_screen.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/presentation/screens/select_profile_template_screen.dart';
import 'package:proveedor_servicly_app/features/manage_store/presentation/screens/manage_store_screen.dart';
import 'package:proveedor_servicly_app/features/agenda/presentation/screens/agenda_screen.dart';
import 'package:proveedor_servicly_app/features/settings/screens/settings_screen.dart';
import 'package:proveedor_servicly_app/widgets/dashboard_header.dart';
import 'package:proveedor_servicly_app/widgets/grids/dashboard/module_grid.dart';
import 'package:proveedor_servicly_app/features/home/screens/home_screen.dart';
import 'package:proveedor_servicly_app/features/finance/presentation/screens/advanced_finance_screen.dart';
import 'package:proveedor_servicly_app/features/catalogo/screens/catalog_editor_screen.dart';
import 'package:proveedor_servicly_app/features/settings/screens/brand_settings_screen.dart';

// --- IMPORTACIONES CRM ---
import 'package:proveedor_servicly_app/features/crm/data/repositories/screens/client_management_screen.dart';
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart';

/// La pantalla principal y dashboard para el usuario proveedor.
/// Actúa como un "Shell" que contiene la barra de navegación.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0; 
  BuildContext? _showCaseContext; // Contexto para el tour

  static const List<Widget> _widgetOptions = <Widget>[
    _ProviderHomeTab(), // Pestaña 0: El contenido del dashboard con Tour
    _PlaceholderScreen(title: 'Oportunidades'), // Pestaña 1: Placeholder
    SettingsScreen(), // Pestaña 2: Configuración
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

    // --- WRAPPER DEL TOUR (ShowCaseWidget) ---
    // Envolvemos todo el Scaffold para que el overlay funcione sobre todo
    return ShowCaseWidget(
      builder: (context) {
        _showCaseContext = context; // Capturamos el contexto válido

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 640) {
              return Scaffold(
                backgroundColor: colors.background,
                body: IndexedStack(
                  index: _selectedIndex,
                  children: _widgetOptions,
                ),
                bottomNavigationBar: BottomNavigationBar(
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_filled),
                      label: 'Inicio',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.lightbulb_outline_rounded),
                      label: 'Oportunidades',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings_outlined),
                      label: 'Configuración',
                    ),
                  ],
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                ),
              );
            } else {
              return Scaffold(
                backgroundColor: colors.background,
                body: Row(
                  children: <Widget>[
                    NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: _onItemTapped,
                      labelType: NavigationRailLabelType.all,
                      destinations: const <NavigationRailDestination>[
                          NavigationRailDestination(icon: Icon(Icons.home_filled), label: Text('Inicio')),
                          NavigationRailDestination(icon: Icon(Icons.lightbulb_outline_rounded), label: Text('Oportunidades')),
                          NavigationRailDestination(icon: Icon(Icons.settings_outlined), label: Text('Configuración')),
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
// --- PESTAÑA 0: INICIO (Contenido del Dashboard con Tour) ---
// ===================================================================

class _ProviderHomeTab extends StatefulWidget {
  const _ProviderHomeTab({super.key});

  @override
  State<_ProviderHomeTab> createState() => _ProviderHomeTabState();
}

class _ProviderHomeTabState extends State<_ProviderHomeTab> with SingleTickerProviderStateMixin {
  late Future<List<ModuleModel>> _modulesFuture;
  late AnimationController _animationController;

  // --- Claves Globales para el Tour ---
  final GlobalKey _keyHeader = GlobalKey();
  final GlobalKey _keyMetrics = GlobalKey();
  final GlobalKey _keyPublicProfile = GlobalKey();
  final GlobalKey _keyModulesTitle = GlobalKey();

  // Bandera para asegurar que el chequeo del tour solo ocurra una vez al cargar datos
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

  /// Comprueba si es la primera vez y lanza el tour
  Future<void> _checkIfFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenTour = prefs.getBool('hasSeenDashboardTour_v1') ?? false;

    if (!hasSeenTour) {
      // Pequeño delay para asegurar que el UI esté renderizado
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _startTour();
        prefs.setBool('hasSeenDashboardTour_v1', true);
      }
    }
  }

  /// Inicia la secuencia de Showcase
  void _startTour() {
    // Buscamos el ShowCaseWidget en el árbol (proviene de DashboardScreen)
    final showCaseContext = ShowCaseWidget.of(context);
    // ignore: unnecessary_null_comparison
    if (showCaseContext != null) {
      showCaseContext.startShowCase([
        _keyHeader,
        _keyMetrics,
        _keyPublicProfile,
        _keyModulesTitle,
      ]);
    }
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
      // AppBar interno para el botón de ayuda del Tour
      appBar: AppBar(
        toolbarHeight: 0, // Oculto visualmente pero presente para estructura
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // Botón flotante para repetir el tour (Opcional, o usar un icono en un AppBar real)
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Ajuste para no tapar el FAB de módulos si hubiera
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

            // --- INICIAR TOUR CUANDO LOS DATOS ESTÉN LISTOS ---
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
                // --- HEADER DEL DASHBOARD ---
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

          // --- MÉTRICAS ---
          Showcase(
            key: _keyMetrics,
            title: 'Métricas Rápidas',
            description: 'Consulta visitas y contactos de un vistazo.',
            child: _MetricsSection(userModel: userModel),
          ),
          const SizedBox(height: 32),

          // --- BOTÓN PERFIL PÚBLICO ---
          Showcase(
            key: _keyPublicProfile,
            title: 'Tu Tienda Online',
            description: 'Configura y comparte tu perfil público con tus clientes.',
            child: _PublicProfileButton(userModel: userModel),
          ),
          const SizedBox(height: 32),

          // --- TÍTULO MÓDULOS ---
          Showcase(
            key: _keyModulesTitle,
            title: 'Tus Herramientas',
            description: 'Accede a tus módulos activos o añade nuevos desde aquí.',
            child: Text(
              'Mis Módulos',
              style: theme.textTheme.titleLarge?.copyWith(
                    color: colors.onBackground, 
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
              child: ModulesGrid( // Usamos el widget importado
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
// --- WIDGETS AUXILIARES Y PLACEHOLDERS ---
// ===================================================================

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(
              title == 'Oportunidades' ? Icons.lightbulb_outline_rounded : Icons.construction_rounded, 
              size: 80,
              color: colors.onSurface.withOpacity(0.24)
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
                style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurface.withOpacity(0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Banner de Completar Perfil ---
class _ProfileCompletionBanner extends StatelessWidget {
  final VoidCallback onCompleteProfile;
  const _ProfileCompletionBanner({required this.onCompleteProfile, super.key});

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

// --- Sección de Métricas ---
class _MetricsSection extends StatelessWidget {
  final UserModel userModel;
  const _MetricsSection({required this.userModel, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final String? photoURL = userModel.personalization['logoUrl'] as String?;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: colors.surface, 
        borderRadius: BorderRadius.circular(16),
         border: Border.all(color: colors.primary.withAlpha(77)),
      ),
      child: Column(
        children: [
          Row(
             crossAxisAlignment: CrossAxisAlignment.center,
             children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colors.primary.withAlpha(50), 
                  backgroundImage: photoURL != null && photoURL.isNotEmpty ? NetworkImage(photoURL) : null,
                  child: photoURL == null || photoURL.isEmpty ? Icon(Icons.person, color: colors.primary) : null, 
                ),
               const SizedBox(width: 12),
               Text(
                 'Actividad Reciente',
                 style: theme.textTheme.titleMedium?.copyWith(
                       color: colors.onSurface,
                       fontWeight: FontWeight.bold,
                     ),
               ),
               const Spacer(),
                SizedBox(
                  height: 30,
                  child: TextButton(
                    onPressed: () { /* TODO: Navegar a pantalla de métricas detalladas */
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pantalla de métricas detalladas (Próximamente).'))
                        );
                     },
                    child: const Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Text('Detalles'),
                         Icon(Icons.arrow_forward_ios_rounded, size: 14),
                       ],
                     ),
                  ),
                ),
             ],
           ),
          Divider(height: 24, color: theme.dividerColor),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MetricItem(icon: Icons.visibility_outlined, label: 'Visitas', value: '--'),
              _MetricItem(icon: Icons.person_add_alt_1_outlined, label: 'Contactos', value: '--'),
              _MetricItem(icon: Icons.star_border_rounded, label: 'Valoración', value: '--'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricItem({required this.icon, required this.label, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: colors.onSurface.withOpacity(0.7), size: 24),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

// --- Botón de Perfil Público ---
class _PublicProfileButton extends StatelessWidget {
  final UserModel userModel;
  const _PublicProfileButton({required this.userModel, super.key});

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

// --- Widgets de Carga ---
class _LoadingSkeleton extends StatefulWidget {
  final String? userName;
  final String? businessName;
  const _LoadingSkeleton({this.userName, this.businessName, super.key});

  @override
  // ignore: library_private_types_in_public_api
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
             // Placeholder para Métricas
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              sliver: SliverToBoxAdapter(child: _ShimmerObject(height: 100, gradient: _shimmerGradient)),
            ),
             // Placeholder para Botón Perfil Público
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
    super.key
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
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final translationX = bounds.width * slidePercent * 2.0 - bounds.width;
    return Matrix4.translationValues(translationX, 0.0, 0.0);
  }
}