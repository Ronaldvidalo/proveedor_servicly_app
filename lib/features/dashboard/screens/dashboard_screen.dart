import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui'; // Necesario para el efecto de desenfoque.

// --- Modelos y Servicios (sin cambios) ---
import '../../../core/models/user_model.dart';
import '../../../core/models/module_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../modules/screens/simple_modules_screen.dart';

// --- Placeholders de Pantallas para que el código sea ejecutable ---
// Asegúrate de reemplazar estos con tus implementaciones reales.
class CreateProfileScreen extends StatelessWidget {
  const CreateProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Crear Perfil")));
}
class ModulesScreen extends StatelessWidget {
  final UserModel userModel;
  const ModulesScreen({super.key, required this.userModel});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Módulos")));
}
// -----------------------------------------------------------------


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
};

/// La pantalla principal y dashboard para el usuario proveedor.
/// Rediseñada como un "Hub Digital" con estilo "Cyber Glow".
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late Future<List<ModuleModel>> _modulesFuture;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _modulesFuture = context.read<FirestoreService>().getAvailableModules();
    // Controlador para las animaciones de entrada.
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToCreateProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userModel = context.watch<UserModel?>();

    // --- Definición del Tema "Cyber Glow" ---
    const backgroundColor = Color(0xFF1A1A2E);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: userModel == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: FutureBuilder<List<ModuleModel>>(
                future: _modulesFuture,
                builder: (context, snapshot) {
                  // UX Improvement: Muestra un esqueleto de carga elegante en lugar de un simple spinner.
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _LoadingSkeleton(
                      userName: userModel.displayName, 
                      businessName: userModel.personalization['businessName'] as String?
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Error al cargar los módulos.', style: TextStyle(color: Colors.white70)));
                  }

                  final allModules = snapshot.data!;
                  final activeModules = allModules
                      .where((module) => userModel.activeModules.contains(module.moduleId))
                      .toList()
                    ..sort((a, b) => a.defaultOrder.compareTo(b.defaultOrder));
                  
                  // UI Polish: Usa CustomScrollView para un layout más dinámico y animado.
                  return CustomScrollView(
                    slivers: [
                      _DashboardHeader(userModel: userModel),
                      _buildAnimatedContent(context, userModel, activeModules),
                    ],
                  );
                },
              ),
            ),
    );
  }

  /// Construye el contenido principal de la pantalla con una animación de entrada.
  Widget _buildAnimatedContent(BuildContext context, UserModel userModel, List<ModuleModel> activeModules) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate.fixed([
          if (!userModel.isProfileComplete)
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: _ProfileCompletionBanner(
                onCompleteProfile: () => _navigateToCreateProfile(context),
              ),
            ),
          
          Text(
            'Mis Módulos',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // UI Polish: El Grid de módulos se anima al entrar.
          FadeTransition(
            opacity: CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut)),
              child: _ModulesGrid(
                activeModules: activeModules,
                onAddModule: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_)=> ModulesScreen(userModel: userModel)),
                  );
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }
}


// --- WIDGETS PERSONALIZADOS Y REDISEÑADOS ---

/// Un encabezado de dashboard elegante que reemplaza el AppBar estándar.
class _DashboardHeader extends StatelessWidget {
  final UserModel userModel;
  const _DashboardHeader({required this.userModel});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final businessName = userModel.personalization['businessName'] as String? ?? 'Mi Negocio';
    const accentColor = Color(0xFF00BFFF);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Hola, ${userModel.displayName ?? 'bienvenido'}!',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // UI Polish: El nombre del negocio tiene un efecto de "glow".
                  Text(
                    businessName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: accentColor.withAlpha((255 * 0.5).round()), blurRadius: 10),
                        Shadow(color: accentColor.withAlpha((255 * 0.3).round()), blurRadius: 20),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // UI Polish: Botón de logout con estilo.
            Material(
              color: const Color(0xFF2D2D5A),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () async => await authService.signOut(),
                borderRadius: BorderRadius.circular(30),
                splashColor: accentColor.withAlpha((255 * 0.3).round()),
                child: const Tooltip(
                  message: 'Cerrar Sesión',
                  child: Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Icon(Icons.logout_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner rediseñado para completar perfil con estilo "Cyber Glow".
class _ProfileCompletionBanner extends StatelessWidget {
  final VoidCallback onCompleteProfile;
  const _ProfileCompletionBanner({required this.onCompleteProfile});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: surfaceColor.withAlpha((255 * 0.7).round()),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withAlpha((255 * 0.5).round())),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: accentColor, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Finaliza la configuración', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text('Completa tu perfil para desbloquear todas las funciones.', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: onCompleteProfile,
                style: FilledButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.white),
                child: const Text('COMPLETAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un grid responsivo para mostrar los módulos.
class _ModulesGrid extends StatelessWidget {
  final List<ModuleModel> activeModules;
  final VoidCallback onAddModule;
  
  const _ModulesGrid({required this.activeModules, required this.onAddModule});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // UI Polish: Grid adaptable a cualquier tamaño de pantalla.
        final crossAxisCount = (constraints.maxWidth / 180).floor().clamp(2, 5);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            ...activeModules.map((module) {
              return _ModuleCard(
                title: module.name,
                icon: _iconMap[module.icon] ?? Icons.help_outline,
                onTap: () {
                  // TODO: Implementar navegación real al módulo
                },
              );
            }),
            _AddModuleCard(onTap: onAddModule),
          ],
        );
      },
    );
  }
}

/// La tarjeta de módulo, el corazón visual del dashboard.
class _ModuleCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ModuleCard({required this.title, required this.icon, required this.onTap});

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // UI Polish: El efecto "glow" se intensifica en hover.
          boxShadow: [
            BoxShadow(
              color: _isHovered ? accentColor.withAlpha((255 * 0.5).round()) : accentColor.withAlpha((255 * 0.25).round()),
              blurRadius: _isHovered ? 15 : 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: accentColor.withAlpha((255 * 0.3).round()),
            highlightColor: accentColor.withAlpha((255 * 0.15).round()),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 40, color: accentColor),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
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

/// Una tarjeta visualmente distinta para la acción de añadir un nuevo módulo.
class _AddModuleCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddModuleCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00BFFF);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: accentColor.withAlpha((255 * 0.3).round()),
        highlightColor: accentColor.withAlpha((255 * 0.15).round()),
        child: DottedBorder(
          color: accentColor.withAlpha((255 * 0.6).round()),
          strokeWidth: 2,
          radius: const Radius.circular(16),
          borderType: BorderType.RRect,
          dashPattern: const [8, 6],
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 40, color: accentColor),
                SizedBox(height: 12),
                Text('Añadir Módulo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// CORRECCIÓN: Se define el enum faltante.
enum BorderType { Rect, RRect }

/// Widget para simular un borde punteado.
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
    this.borderType = BorderType.Rect,
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
    this.borderType = BorderType.Rect,
    this.dashPattern = const <double>[3, 1],
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    Path path;
    if (borderType == BorderType.RRect) {
      path = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), radius));
    } else {
      path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    Path dashPath = Path();
    double distance = 0.0;
    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashPattern[0]),
          Offset.zero,
        );
        distance += dashPattern[0] + dashPattern[1];
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

/// Esqueleto de carga con efecto "shimmer" para una UX superior.
class _LoadingSkeleton extends StatefulWidget {
  final String? userName;
  final String? businessName;
  const _LoadingSkeleton({this.userName, this.businessName});
  
  @override
  __LoadingSkeletonState createState() => __LoadingSkeletonState();
}

class __LoadingSkeletonState extends State<_LoadingSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    // --- CORRECCIÓN DEL ERROR ---
    // Se cambia AnimationController.unbounded por una implementación estándar
    // que es más estable y soluciona la Assertion Error.
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
    return LinearGradient(
      colors: const [Color(0xFF2D2D5A), Color(0xFF3A3A6E), Color(0xFF2D2D5A)],
      stops: const [0.1, 0.3, 0.4],
      begin: const Alignment(-1.0, -0.3),
      end: const Alignment(1.0, 0.3),
      tileMode: TileMode.clamp,
      transform: _SlidingGradientTransform(slidePercent: _shimmerController.value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
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
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

