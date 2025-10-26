// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 25/10/2025 // Updated date
// Style: Cyber Glow
// This screen was refactored into a "Digital Hub" dashboard, styled with the
// "Cyber Glow" aesthetic. It features a dynamic header, metrics section,
// interactive module cards, shimmer loading skeleton, and responsive grid layout.
// --- MODIFICACIÓN: 26/10/2025 ---
// Refactored to act as the main app "Shell" with a BottomNavigationBar.
// The original dashboard content is now in the `_ProviderHomeTab` widget.
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart' show listEquals;

// --- Modelos y Servicios ---
// Asegúrate de que las rutas de importación sean correctas para tu proyecto
import '../../../core/models/user_model.dart';
import '../../../core/models/module_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../modules/screens/modules_screen.dart';
import '../../profile/screens/create_profile_screen.dart';
import '../../public_profile/screens/public_profile_screen.dart';
import '../../public_profile/screens/presentation/screens/select_profile_template_screen.dart';
// Asegúrate de importar ManageStoreScreen desde su ubicación correcta
import '../../manage_store/presentation/screens/manage_store_screen.dart';
// Asegúrate de importar AgendaScreen desde su ubicación correcta
import '../../agenda/presentation/screens/agenda_screen.dart';
import 'package:proveedor_servicly_app/features/settings/screens/settings_screen.dart';
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
/// Ahora actúa como un "Shell" que contiene la barra de navegación inferior.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0; // Estado para la pestaña activa

  // Lista de las pantallas (pestañas) que se mostrarán
  static const List<Widget> _widgetOptions = <Widget>[
    _ProviderHomeTab(), // Tu dashboard anterior
    _OpportunitiesTab(), // Placeholder
    SettingsScreen(), // Placeholder
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- Definición del Tema "Cyber Glow" ---
    const primaryColor = Color(0xFF00BFFF); // Azul eléctrico brillante
    const backgroundColor = Color(0xFF1A1A2E); // Azul oscuro casi negro
    const surfaceColor = Color(0xFF2D2D5A); // Superficie ligeramente más clara

    return Scaffold(
      backgroundColor: backgroundColor,
      // El cuerpo de la app ahora cambia según la pestaña seleccionada
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
        // --- Estilo "Cyber Glow" para la barra de navegación ---
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed, // Para que el fondo sea sólido
        elevation: 10,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        showUnselectedLabels: true,
      ),
    );
  }
}

// ===================================================================
// --- PESTAÑA 1: INICIO (Tu antiguo DashboardScreen) ---
// ===================================================================

class _ProviderHomeTab extends StatefulWidget {
  const _ProviderHomeTab();

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
    const backgroundColor = Color(0xFF1A1A2E);

    if (userModel == null) {
      return Container(
        color: backgroundColor,
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF00BFFF)))
      );
    }

    // El widget raíz ahora es el Container con el color de fondo.
    // La SafeArea se aplica aquí para asegurar que el contenido no se solape
    // con la barra de estado o muescas del dispositivo.
    return Container(
      color: backgroundColor,
      child: SafeArea(
        bottom: false, // La SafeArea inferior es manejada por el Scaffold
        child: FutureBuilder<List<ModuleModel>>(
          future: _modulesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Muestra el esqueleto de carga mientras se obtienen los módulos
              return _LoadingSkeleton(
                userName: userModel.displayName,
                businessName: userModel.personalization['businessName'] as String?,
              );
            }

            if (snapshot.hasError || !snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
              // Muestra un error si la carga de módulos falla
              return const Center(child: Text('Error al cargar la configuración.', style: TextStyle(color: Colors.white70)));
            }

            // Datos listos
            final allModules = snapshot.data!;
            final activeModules = allModules
                .where((module) => userModel.activeModules.contains(module.moduleId))
                .toList()
              ..sort((a, b) => a.defaultOrder.compareTo(b.defaultOrder));

            // El CustomScrollView es el contenido principal de esta pantalla
            return CustomScrollView(
              slivers: [
                _DashboardHeader(userModel: userModel),
                _buildAnimatedContent(context, userModel, activeModules, allModules),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Construye el contenido principal de la pantalla con una animación de entrada.
  Widget _buildAnimatedContent(BuildContext context, UserModel userModel, List<ModuleModel> activeModules, List<ModuleModel> allModules) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate.fixed([
          // Banner para completar perfil si es necesario
          if (!userModel.isProfileComplete)
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: _ProfileCompletionBanner(
                onCompleteProfile: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateProfileScreen()),
                ),
              ),
            ),

          // --- Sección de Métricas (Placeholder) ---
          const _MetricsSectionPlaceholder(),
          const SizedBox(height: 32),

          // Botón para gestionar/crear perfil público
          _PublicProfileButton(userModel: userModel),
          const SizedBox(height: 32),

          // Título de la sección de módulos
          Text(
            'Mis Módulos',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Grid animado de módulos
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
          // Añadir padding inferior para que el contenido no quede pegado
          // a la barra de navegación inferior del ProviderShell.
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}

// ===================================================================
// --- PESTAÑA 2: OPORTUNIDADES (Placeholder) ---
// ===================================================================

class _OpportunitiesTab extends StatelessWidget {
  const _OpportunitiesTab();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Text('Pantalla de Oportunidades (Próximamente)', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}


// ===================================================================
// --- PESTAÑA 3: CONFIGURACIÓN (Placeholder) ---
// ===================================================================

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Text('Pantalla de Configuración (Próximamente)', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}


// --- TODOS TUS WIDGETS PERSONALIZADOS (_DashboardHeader, _ProfileCompletionBanner, etc.) ---
// --- SE MANTIENEN EXACTAMENTE IGUAL ---

// Copia y pega aquí todos tus widgets auxiliares desde tu archivo original
// Ejemplo:
class _DashboardHeader extends StatelessWidget {
  final UserModel userModel;
  const _DashboardHeader({required this.userModel});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    // Esta línea es la que reportaba 'dead_code'. La lógica es correcta
    // ya que userModel.displayName SÍ es nullable. Ignoramos el lint.
    final businessName = userModel.personalization['businessName'] as String? ?? userModel.displayName ?? 'Mi Negocio';
    const accentColor = Color(0xFF00BFFF);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8), // Reducido padding superior
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start, // Alinea arriba
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
                  Text(
                    businessName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        // CORRECCIÓN: .withOpacity() obsoleto, usar .withAlpha()
                        Shadow(color: accentColor.withAlpha(128), blurRadius: 10), // 0.5
                        Shadow(color: accentColor.withAlpha(77), blurRadius: 20), // 0.3
                      ],
                    ),
                    maxLines: 2, // Permite 2 líneas para nombres largos
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16), // Espacio antes del botón
            Material(
              color: const Color(0xFF2D2D5A),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () async {
                  // Añadir confirmación antes de cerrar sesión
                   final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF2D2D5A),
                        title: const Text('Confirmar', style: TextStyle(color: Colors.white)),
                        content: const Text('¿Seguro que quieres cerrar sesión?', style: TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                            child: const Text('Cerrar Sesión'),
                          ),
                        ],
                      ),
                    ) ?? false; // Si el usuario cierra el diálogo, es false

                   if (confirm) {
                     if (context.mounted) { // Buena práctica post-await
                       await authService.signOut();
                     }
                     // No necesitas navegar aquí, el AuthWrapper se encargará
                   }
                },
                borderRadius: BorderRadius.circular(30),
                splashColor: accentColor.withAlpha(77), // 0.3
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
            color: surfaceColor.withAlpha(178), // 0.7
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withAlpha(128)), // 0.5
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: accentColor, size: 32),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Finaliza la configuración', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                    SizedBox(height: 4),
                    Text('Completa tu perfil para desbloquear todas las funciones.', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: onCompleteProfile,
                style: FilledButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.black),
                child: const Text('COMPLETAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Widget para la Sección de Métricas (Placeholder) ---
class _MetricsSectionPlaceholder extends StatelessWidget {
  const _MetricsSectionPlaceholder();

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
         border: Border.all(color: accentColor.withAlpha(77)), // 0.3
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             children: [
               const Icon(Icons.insights_rounded, color: accentColor, size: 20),
               const SizedBox(width: 8),
               Text(
                 'Actividad Reciente',
                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
                       color: Colors.white,
                       fontWeight: FontWeight.bold,
                     ),
               ),
             ],
           ),
          const SizedBox(height: 16),
          // Placeholder para las métricas (ej. visitas al perfil)
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MetricItemPlaceholder(icon: Icons.visibility_outlined, label: 'Visitas Hoy', value: '--'), // Placeholder
              _MetricItemPlaceholder(icon: Icons.person_add_alt_1_outlined, label: 'Contactos', value: '--'), // Placeholder
              _MetricItemPlaceholder(icon: Icons.star_border_rounded, label: 'Valoración', value: '--'), // Placeholder
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () { /* TODO: Navegar a pantalla de métricas detalladas */
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Pantalla de métricas detalladas (Próximamente).'))
                 );
               },
              style: TextButton.styleFrom(foregroundColor: accentColor),
              child: const Text('Ver más detalles'),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget auxiliar para el placeholder de métricas
class _MetricItemPlaceholder extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricItemPlaceholder({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 28),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ],
    );
  }
}


class _PublicProfileButton extends StatelessWidget {
  final UserModel userModel;
  const _PublicProfileButton({required this.userModel});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00BFFF);
    final bool isProfileCreated = userModel.publicProfileCreated ?? false; // Manejo de nulo

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
        foregroundColor: accentColor,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: const BorderSide(color: accentColor, width: 2),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ModulesGrid extends StatelessWidget {
  final List<ModuleModel> activeModules;
  final VoidCallback onAddModule;
  final UserModel user;

  const _ModulesGrid({
    required this.activeModules,
    required this.onAddModule,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ajusta el ancho base para controlar el tamaño de las tarjetas
        final double cardBaseWidth = 160.0;
        final crossAxisCount = (constraints.maxWidth / (cardBaseWidth + 16)).floor().clamp(2, 5); // +16 for spacing

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
             // Botón "Gestionar Tienda"
            if (user.publicProfileTemplate == 'store') // Lógica de negocio
              _ModuleCard(
                title: 'Gestionar Tienda',
                icon: _iconMap['storefront_outlined'] ?? Icons.storefront_outlined,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ManageStoreScreen(user: user),
                  ));
                },
              ),

            // Módulos activos
            ...activeModules.map((module) {
              return _ModuleCard(
                title: module.name,
                icon: _iconMap[module.icon] ?? Icons.extension_outlined,
                onTap: () {
                  _navigateToModule(context, module.moduleId, user);
                },
              );
            }),

            // Tarjeta para añadir módulo
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
        // --- CORRECCIÓN: Pasar el parámetro 'user' requerido ---
        destination = AgendaScreen(user: user);
        break;
      case 'clients':
        // destination = ClientsScreen(user: user);
        break;
      // Añade más casos aquí...
    }

    if (destination != null) {
      // 'destination' es Widget?, pero el builder espera Widget.
      // Usamos el operador '!' porque ya comprobamos que no es nulo.
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => destination!));
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
          boxShadow: [
            BoxShadow(
              color: _isHovered ? accentColor.withAlpha(128) : accentColor.withAlpha(64),
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
            splashColor: accentColor.withAlpha(77),
            highlightColor: accentColor.withAlpha(38),
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
        splashColor: accentColor.withAlpha(77),
        highlightColor: accentColor.withAlpha(38),
        child: DottedBorder(
          color: accentColor.withAlpha(153),
          strokeWidth: 2,
          radius: const Radius.circular(16),
          borderType: BorderType.rRect,
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

// --- DottedBorder y Widgets Relacionados ---
// (Tu código existente para DottedBorder, _DottedPainter, BorderType)
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
      !listEquals(oldDelegate.dashPattern, dashPattern); // Comparar listas correctamente
}


// --- Widgets de Carga ---
// (Tu código existente para _LoadingSkeleton, _ShimmerObject, _SlidingGradientTransform)
class _LoadingSkeleton extends StatefulWidget {
  final String? userName;
  final String? businessName;
  const _LoadingSkeleton({this.userName, this.businessName});

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
              sliver: SliverToBoxAdapter(child: _ShimmerObject(height: 120, gradient: _shimmerGradient)),
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

