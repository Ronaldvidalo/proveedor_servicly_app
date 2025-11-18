import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'dart:ui';
// --- Importaciones de Modelos y Servicios ---
import '../../../core/models/user_model.dart';
import '../../../core/models/module_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
// --- MEJORA 4: RUTA ASUMIDA para el ThemeProvider ---
import 'package:proveedor_servicly_app/providers/theme_provider.dart';
import 'package:proveedor_servicly_app/widgets/loading/shimmer_loading.dart';


import 'package:proveedor_servicly_app/shared/theme/screens/theme_selection_screen.dart';
import '../../../core/services/theme_service.dart';

// --- Importaciones de Módulos ---
import 'package:proveedor_servicly_app/features/catalogo/modules/modules_screen.dart';
import '../../profile/screens/create_profile_screen.dart';
import '../../public_profile/screens/public_profile_screen.dart';
import '../../public_profile/screens/presentation/screens/select_profile_template_screen.dart';
import '../../manage_store/presentation/screens/manage_store_screen.dart';
import '../../agenda/presentation/screens/agenda_screen.dart';
import 'package:proveedor_servicly_app/features/settings/screens/settings_screen.dart';
import 'package:proveedor_servicly_app/widgets/dashboard_header.dart';
import 'package:proveedor_servicly_app/widgets/grids/dashboard/module_grid.dart';
// --- MEJORA 3: Importación de Home Screen ---
import 'package:proveedor_servicly_app/features/home/screens/home_screen.dart';
import 'package:proveedor_servicly_app/features/finance/presentation/screens/advanced_finance_screen.dart';
import 'package:proveedor_servicly_app/features/catalogo/screens/catalog_editor_screen.dart';
import 'package:proveedor_servicly_app/features/settings/screens/brand_settings_screen.dart';

// --- IMPORTACIONES CRM ---
import 'package:proveedor_servicly_app/features/crm/data/repositories/screens/client_management_screen.dart';
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart'; // NECESARIO PARA LA INYECCIÓN

// Importar DottedBorder si está en un archivo separado, si no, mantenerlo abajo.
// import 'package:dotted_border/dotted_border.dart'; // Si decides usar el paquete

/// Mapa para convertir los nombres de los íconos (String desde Firestore) a objetos IconData.
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
  'agenda': Icons.calendar_month_outlined, // Icono añadido para agenda
};

/// La pantalla principal y dashboard para el usuario proveedor.
/// Ahora actúa como un "Shell" que contiene la barra de navegación.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0; // Estado para la pestaña activa

  static const List<Widget> _widgetOptions = <Widget>[
    _ProviderHomeTab(), // Pestaña 0: El contenido del dashboard
    _PlaceholderScreen(title: 'Oportunidades'), // Pestaña 1: Placeholder
    SettingsScreen(), // Pestaña 2: Tu pantalla de Configuración real
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
            backgroundColor: colors.background, // Usa el tema
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
              // Estilos automáticos desde ThemeService
            ),
          );
        } else {
          return Scaffold(
            backgroundColor: colors.background, // Usa el tema
            body: Row(
              children: <Widget>[
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  labelType: NavigationRailLabelType.all,
                  // Estilos automáticos desde ThemeService
                  destinations: const <NavigationRailDestination>[
                     NavigationRailDestination(icon: Icon(Icons.home_filled), label: Text('Inicio')),
                     NavigationRailDestination(icon: Icon(Icons.lightbulb_outline_rounded), label: Text('Oportunidades')),
                     NavigationRailDestination(icon: Icon(Icons.settings_outlined), label: Text('Configuración')),
                  ],
                ),
                VerticalDivider(thickness: 1, width: 1, color: theme.dividerColor), // Usa el tema
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
// --- PESTAÑA 0: INICIO (Contenido del Dashboard) ---
// ===================================================================

class _ProviderHomeTab extends StatefulWidget {
  const _ProviderHomeTab({super.key});

  @override
  State<_ProviderHomeTab> createState() => _ProviderHomeTabState();
}

class _ProviderHomeTabState extends State<_ProviderHomeTab> with SingleTickerProviderStateMixin {
  late Future<List<ModuleModel>> _modulesFuture;
  late AnimationController _animationController;

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

    return SafeArea(
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

          final allModules = snapshot.data!;
          final activeModules = allModules
              .where((module) => userModel.activeModules.contains(module.moduleId))
              .toList()
            ..sort((a, b) => a.defaultOrder.compareTo(b.defaultOrder));

          return CustomScrollView(
            slivers: [
              // --- USA EL WIDGET REUTILIZABLE ---
              DashboardHeader(userModel: userModel), 
              _buildAnimatedContent(context, userModel, activeModules, allModules),
            ],
          );
        },
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

          _MetricsSection(userModel: userModel),
          const SizedBox(height: 32),

          _PublicProfileButton(userModel: userModel),
          const SizedBox(height: 32),

          Text(
            'Mis Módulos',
            style: theme.textTheme.titleLarge?.copyWith(
                  color: colors.onBackground, 
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
              child: _ModulesGrid(
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

// --- Grilla de Módulos ---
class _ModulesGrid extends StatelessWidget {
  final List<ModuleModel> activeModules;
  final VoidCallback onAddModule;
  final UserModel user;

  const _ModulesGrid({
    required this.activeModules,
    required this.onAddModule,
    required this.user,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardBaseWidth = 160.0;
        final crossAxisCount = (constraints.maxWidth / (cardBaseWidth + 16)).floor().clamp(2, 5);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            if (user.personalization['publicProfileTemplate'] == 'store')
              _ModuleCard(
                title: 'Gestionar Tienda',
                icon: _iconMap['storefront_outlined'] ?? Icons.storefront_outlined,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ManageStoreScreen(user: user),
                  ));
                },
              ),

            ...activeModules.map((module) {
              return _ModuleCard(
                title: module.name,
                icon: _iconMap[module.icon] ?? Icons.extension_outlined,
                onTap: () {
                   _navigateToModule(context, module.moduleId, user);
                },
              );
            }),

            _AddModuleCard(onTap: onAddModule),
          ],
        );
      },
    );
  }

   void _navigateToModule(BuildContext context, String moduleId, UserModel user) {
  Widget? destination;
  switch (moduleId) {
    case 'agenda':
      destination = AgendaScreen(user: user);
      break;
    case 'clients':
      // destination = ClientsScreen(user: user);
      break;
  }

  if (destination != null) {
    // --- LA SOLUCIÓN ---
    // Creamos una variable local 'final' no nula.
    // El 'builder' ahora recibe una variable que NUNCA puede ser nula.
    final Widget destinationWidget = destination;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => destinationWidget));
    // --- FIN DE LA SOLUCIÓN ---

  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navegación para "$moduleId" no implementada.'))
    );
  }
}
}

class _ModuleCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ModuleCard({required this.title, required this.icon, required this.onTap, super.key});

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? colors.primary.withAlpha(128) : colors.primary.withAlpha(64),
              blurRadius: _isHovered ? 15 : 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: colors.primary.withAlpha(77),
            highlightColor: colors.primary.withAlpha(38),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 40, color: colors.primary),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddModuleCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddModuleCard({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: colors.primary.withAlpha(77),
        highlightColor: colors.primary.withAlpha(38),
        child: DottedBorder(
          color: colors.primary.withAlpha(153),
          strokeWidth: 2,
          radius: const Radius.circular(16),
          borderType: BorderType.rRect,
          dashPattern: const [8, 6],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 40, color: colors.primary),
                const SizedBox(height: 12),
                Text('Añadir Módulo', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- DottedBorder y Widgets Relacionados ---
enum BorderType { rect, rRect }

class DottedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final Radius radius;
  final BorderType borderType;
  final List<double> dashPattern;

  const DottedBorder({
    super.key,
    required this.child,
    this.color = Colors.black,
    this.strokeWidth = 1,
    this.radius = const Radius.circular(0),
    this.borderType = BorderType.rect,
    this.dashPattern = const <double>[3, 1],
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedPainter(
        color: color,
        strokeWidth: strokeWidth,
        radius: radius,
        borderType: borderType,
        dashPattern: dashPattern,
      ),
      child: child,
    );
  }
}

class _DottedPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final Radius radius;
  final BorderType borderType;
  final List<double> dashPattern;

  _DottedPainter({
    this.color = Colors.black,
    this.strokeWidth = 1,
    this.radius = const Radius.circular(0),
    this.borderType = BorderType.rect,
    this.dashPattern = const <double>[3, 1],
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    Path path;
    if (borderType == BorderType.rRect) {
      final validRadius = Radius.elliptical(radius.x.abs(), radius.y.abs());
      path = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), validRadius));
    } else {
      path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    Path dashPath = Path();
    double distance = 0.0;
    if (dashPattern.isNotEmpty && dashPattern[0] > 0) {
       final double dashLength = dashPattern[0];
       final double gapLength = dashPattern.length > 1 ? dashPattern[1] : 0;
       final double totalDashPatternLength = dashLength + gapLength;

        if (totalDashPatternLength > 0) {
           for (PathMetric pathMetric in path.computeMetrics()) {
             while (distance < pathMetric.length) {
               final double end = (distance + dashLength).clamp(0.0, pathMetric.length);
               dashPath.addPath(
                 pathMetric.extractPath(distance, end),
                 Offset.zero,
               );
               distance += totalDashPatternLength;
             }
           }
         } else {
            dashPath = path;
         }
     } else {
        dashPath = path;
     }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(_DottedPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.radius != radius ||
      oldDelegate.borderType != borderType ||
      !listEquals(oldDelegate.dashPattern, dashPattern);
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