// --- UX/UI Redesigned: Sandbox Implementation ---
// Fixed: Removed unused elements and parameters.
// Cleaned: Fixed sort order and unnecessary null checks.
// ------------------------------------------------

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

// --- Importaciones de Módulos y Pantallas ---
import 'package:proveedor_servicly_app/features/catalogo/modules/modules_screen.dart';
import 'package:proveedor_servicly_app/features/profile/screens/create_profile_screen.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/public_profile_screen.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/presentation/screens/select_profile_template_screen.dart';
import 'package:proveedor_servicly_app/features/settings/screens/settings_screen.dart';
import 'package:proveedor_servicly_app/features/home/screens/home_screen.dart';

// --- Widgets Externos ---
import 'package:proveedor_servicly_app/widgets/dashboard_header.dart';
import 'package:proveedor_servicly_app/widgets/grids/dashboard/module_grid.dart';
import 'package:proveedor_servicly_app/features/dashboard/widgets/dashboard_cards/dashboard_screen/dashboard_summary_cards.dart';

// --- MAPA DE ICONOS ---
const Map<String, IconData> _iconMap = {
  'people_outline': Icons.people_outline_rounded,
  'calendar_today_outlined': Icons.calendar_today_rounded,
  'insights': Icons.insights_rounded,
  'add_card': Icons.add_card_rounded,
  'add_circle_outline': Icons.add_circle_outline_rounded,
  'store_mall_directory_outlined': Icons.store_mall_directory_rounded,
  'person_search_outlined': Icons.person_search_rounded,
  'sync_alt_rounded': Icons.sync_alt_rounded,
  'help_outline': Icons.help_outline_rounded,
  'visibility_outlined': Icons.visibility_outlined,
  'storefront_outlined': Icons.storefront_outlined,
  'agenda': Icons.calendar_month_outlined,
  'auto_stories_outlined': Icons.auto_stories_outlined,
  'client_management': Icons.groups_2_outlined,
  'finance': Icons.monetization_on_outlined,
  'default': Icons.extension_outlined,
};

// ===================================================================
// --- ESTRUCTURA PRINCIPAL (SHELL) ---
// ===================================================================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // --- LISTA DE PANTALLAS ---
  static const List<Widget> _widgetOptions = <Widget>[
    _ProviderHomeTab(),                 // Index 0: Comando
    HomeScreen(),                       // Index 1: Explorar
    _PlaceholderScreen(title: 'Leads'), // Index 2: Leads
    SettingsScreen(),                   // Index 3: Cuenta
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
              // Vista Móvil
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
                  unselectedItemColor: colors.onSurface.withOpacity(0.6), // Corregido withAlpha
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.flash_on_rounded),
                      label: 'Comando',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.map_outlined),
                      label: 'Explorar',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.leaderboard_rounded),
                      label: 'Leads',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline_rounded),
                      label: 'Cuenta',
                    ),
                  ],
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                ),
              );
            } else {
              // Vista Tablet/Web
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
                        NavigationRailDestination(icon: Icon(Icons.flash_on_rounded), label: Text('Comando')),
                        NavigationRailDestination(icon: Icon(Icons.map_outlined), label: Text('Explorar')),
                        NavigationRailDestination(icon: Icon(Icons.leaderboard_rounded), label: Text('Leads')),
                        NavigationRailDestination(icon: Icon(Icons.person_outline_rounded), label: Text('Cuenta')),
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
// --- PESTAÑA 0: DASHBOARD ORIGINAL ---
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
        final showCaseContext = ShowCaseWidget.of(context);
        showCaseContext.startShowCase([
          _keyHeader,
          _keyMetrics,
          _keyPublicProfile,
          _keyModulesTitle,
        ]);
        prefs.setBool('hasSeenDashboardTour_v1', true);
      }
    }
  }

  void _startTour() {
    final showCaseContext = ShowCaseWidget.of(context);
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
              // CORRECCIÓN 1: Se asegura que se llame al constructor del widget _LoadingSkeleton
              return const _LoadingSkeleton(); 
            }

            if (_isTourCheckPending) {
              _isTourCheckPending = false;
              WidgetsBinding.instance.addPostFrameCallback((_) => _checkIfFirstTime());
            }

            final allModules = snapshot.data ?? [];
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
                    description: 'Este es tu panel de control.',
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
          const DevNavigationButton(
            label: '✨ Ver Centro de Comando (UX v2)',
            destinationScreen: _ProviderHomeTabRedesigned(),
            icon: Icons.rocket_launch_rounded,
          ),

          if (!userModel.isProfileComplete)
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: _ProfileCompletionBanner(
                onCompleteProfile: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateProfileScreen()),
                ),
              ),
            ),

          Showcase(
            key: _keyMetrics,
            title: 'Métricas',
            description: 'Resumen de actividad.',
            child: _MetricsSection(userModel: userModel),
          ),
          const SizedBox(height: 32),

          const DashboardSummaryCards(),
          const SizedBox(height: 32),

          Showcase(
            key: _keyPublicProfile,
            title: 'Perfil Público',
            description: 'Gestiona tu presencia online.',
            // CORRECCIÓN 2: Se llama al widget como una clase, no como un método.
            child: _PublicProfileButton(userModel: userModel), 
          ),
          const SizedBox(height: 32),

          Showcase(
            key: _keyModulesTitle,
            title: 'Módulos',
            description: 'Tus herramientas activas.',
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
// --- PANTALLA SANDBOX: NUEVO DISEÑO (CENTRO DE COMANDO) ---
// ===================================================================

class _ProviderHomeTabRedesigned extends StatelessWidget {
  const _ProviderHomeTabRedesigned();

  @override
  Widget build(BuildContext context) {
    final userModel = context.watch<UserModel?>();
    final colors = Theme.of(context).colorScheme;

    if (userModel == null) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    return FutureBuilder<List<ModuleModel>>(
        future: context.read<FirestoreService>().getAvailableModules(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator(color: colors.primary)));
          }
          final allModules = snapshot.data ?? [];
          final activeModules = allModules
              .where((module) => userModel.activeModules.contains(module.moduleId))
              .toList()
            ..sort((a, b) => a.defaultOrder.compareTo(b.defaultOrder));

          final topFourModules = activeModules.take(4).toList();

          return Scaffold(
            backgroundColor: colors.surface,
            floatingActionButton: FloatingActionButton.small(
              backgroundColor: colors.errorContainer,
              foregroundColor: colors.onErrorContainer,
              onPressed: () => Navigator.pop(context),
              tooltip: 'Salir del modo diseño',
              child: const Icon(Icons.close_rounded),
            ),
            body: SafeArea(
              bottom: false,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Bienvenido,', style: TextStyle(color: colors.onSurface.withOpacity(0.6), fontSize: 14)),
                                Text(
                                  userModel.displayName ?? 'Proveedor',
                                  style: TextStyle(color: colors.onSurface, fontSize: 20, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          _ProfileIconAction(userModel: userModel),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      child: const _MetricAlertCard(),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Row(
                        children: [
                          Icon(Icons.bolt_rounded, color: colors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Acceso Rápido',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    sliver: SliverGrid.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                      children: topFourModules.map((module) {
                        return _ModuleTileCompact(module: module, userModel: userModel);
                      }).toList(),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.apps_rounded),
                        label: const Text('Ver todas las herramientas'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          side: BorderSide(color: colors.outline.withOpacity(0.3)),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
          );
        }
    );
  }
}

// ===================================================================
// --- WIDGETS AUXILIARES ---
// ===================================================================

class DevNavigationButton extends StatelessWidget {
  final String label;
  final Widget destinationScreen;
  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const DevNavigationButton({
    super.key,
    required this.destinationScreen,
    this.label = '🚧 Ver Nuevo Diseño (Beta)',
    this.icon = Icons.science_outlined,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: backgroundColor ?? colors.tertiaryContainer,
            foregroundColor: foregroundColor ?? colors.onTertiaryContainer,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: (foregroundColor ?? colors.onTertiaryContainer).withOpacity(0.2),
                width: 1,
              ),
            ),
            elevation: 2,
          ),
          icon: Icon(icon),
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => destinationScreen),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileIconAction extends StatelessWidget {
  final UserModel? userModel;
  const _ProfileIconAction({this.userModel});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isCreated = userModel?.publicProfileCreated ?? false;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.4), // Fix surfaceVariant
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
            Icons.share_outlined,
            color: isCreated ? colors.primary : colors.onSurface.withOpacity(0.4)
        ),
        onPressed: () {
          if (isCreated && userModel != null) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PublicProfileScreen(providerId: userModel!.uid),
            ));
          }
        },
      ),
    );
  }
}

class _MetricAlertCard extends StatelessWidget {
  const _MetricAlertCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.secondaryContainer, colors.secondaryContainer.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.leaderboard, size: 120, color: colors.onSecondaryContainer.withOpacity(0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.surface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_active_rounded, color: colors.primary, size: 16),
                      const SizedBox(width: 8),
                      Text('2 Mensajes', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: colors.onSurface)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '4',
                  style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.onSecondaryContainer,
                      height: 1.0
                  ),
                ),
                Text('Leads Potenciales Hoy', style: theme.textTheme.titleMedium?.copyWith(color: colors.onSecondaryContainer.withOpacity(0.8))),
                const SizedBox(height: 16),
                Divider(color: colors.onSecondaryContainer.withOpacity(0.2)),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {},
                    style: TextButton.styleFrom(foregroundColor: colors.onSecondaryContainer),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Ver Detalles'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleTileCompact extends StatelessWidget {
  final ModuleModel module;
  final UserModel userModel;

  const _ModuleTileCompact({required this.module, required this.userModel});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final iconData = _iconMap[module.icon] ?? Icons.extension_rounded;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.3), // surfaceContainerLow replacement
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Abriendo: ${module.name}')),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: colors.primary, size: 24),
                ),
                Text(
                  module.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
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
      body: Center(child: Text('Próximamente: $title', style: TextStyle(color: colors.onSurface))),
    );
  }
}

class _ProfileCompletionBanner extends StatelessWidget {
  final VoidCallback onCompleteProfile;
  const _ProfileCompletionBanner({required this.onCompleteProfile});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: colors.surface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.primary.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: colors.primary, size: 32),
              const SizedBox(width: 16),
              Expanded(child: Text('Completa tu perfil para continuar.', style: TextStyle(color: colors.onSurface))),
              FilledButton(onPressed: onCompleteProfile, child: const Text('COMPLETAR')),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGET DE MÉTRICAS (Refactorizado) ---
class _MetricsSection extends StatelessWidget {
  final UserModel userModel;
  // CORRECCIÓN 3: Constructor corregido
  const _MetricsSection({super.key, required this.userModel}); 

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final String? photoURL = userModel.personalization['logoUrl'] as String?;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.primary.withOpacity(0.5), width: 1),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: colors.primary.withOpacity(0.1),
                  backgroundImage: photoURL != null && photoURL.isNotEmpty ? NetworkImage(photoURL) : null,
                  child: photoURL == null || photoURL.isEmpty ? Icon(Icons.person, color: colors.primary) : null,
                ),
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pantalla de métricas detalladas (Próximamente).'))
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: colors.primary,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Detalles', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, size: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Divider(height: 24, color: colors.onSurface.withOpacity(0.1)),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MetricItem(icon: Icons.visibility_outlined, label: 'Visitas', value: '128'),
              _MetricItem(icon: Icons.person_add_alt_1_outlined, label: 'Contactos', value: '12'),
              _MetricItem(icon: Icons.star_border_rounded, label: 'Rating', value: '4.8'),
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

  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: colors.primary.withOpacity(0.8), size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.onSurface
          )
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurface.withOpacity(0.6)
          )
        ),
      ],
    );
  }
}

class _PublicProfileButton extends StatelessWidget {
  final UserModel userModel;
  const _PublicProfileButton({super.key, required this.userModel}); // CORRECCIÓN 2: Se asegura la llamada con argumentos

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        if (userModel.publicProfileCreated) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => PublicProfileScreen(providerId: userModel.uid)));
        } else {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => SelectProfileTemplateScreen(user: userModel)));
        }
      },
      icon: const Icon(Icons.store),
      label: Text(userModel.publicProfileCreated ? 'Ver Perfil' : 'Crear Perfil'),
    );
  }
}

// --- Skeleton Loading ---
class _LoadingSkeleton extends StatefulWidget {
  // CORRECCIÓN 1: Se agrega super.key al constructor
  const _LoadingSkeleton({super.key}); 

  @override
  State<_LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<_LoadingSkeleton> with SingleTickerProviderStateMixin {
  // El controller y su lógica se dejó simplificada en la corrección anterior,
  // por lo que solo mantengo la estructura básica del State.

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Se ha simplificado para solo mostrar un indicador de progreso central
    return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
  }
}
