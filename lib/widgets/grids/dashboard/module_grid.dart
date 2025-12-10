import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';

// --- Importaciones de Modelos ---
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/models/module_model.dart';

// --- Importaciones de Pantallas ---
import 'package:proveedor_servicly_app/features/agenda/presentation/screens/agenda_screen.dart';
import 'package:proveedor_servicly_app/features/crm/data/repositories/screens/client_management_screen.dart';
import 'package:proveedor_servicly_app/features/finance/presentation/screens/advanced_finance_screen.dart';
import 'package:proveedor_servicly_app/features/manage_store/presentation/screens/manage_store_screen.dart';
import 'package:proveedor_servicly_app/features/catalogo/screens/catalog_editor_screen.dart';
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart';
import 'package:proveedor_servicly_app/features/sales/screens/pos_screen.dart';
import 'package:proveedor_servicly_app/features/cost_structure/screen/business_config_screen.dart';
import 'package:proveedor_servicly_app/features/inventory/screens/inventory_screen.dart';
// IMPORTANTE: Asegúrate de tener creada esta pantalla o comenta la línea si aún no existe
import 'package:proveedor_servicly_app/features/budget/models/quote_model.dart';
import 'package:proveedor_servicly_app/features/budget/screens/quote_list_screen.dart';

// --- Mapa de Iconos ---
const Map<String, IconData> _iconMap = {
  'storefront_outlined': Icons.storefront_outlined,
  'auto_stories_outlined': Icons.auto_stories_outlined,
  'calendar_today_outlined': Icons.calendar_today_outlined,
  'group_outlined': Icons.people_alt_rounded,
  'clients': Icons.people_alt_rounded,
  'bar_chart_outlined': Icons.bar_chart_rounded,
  'calculate': Icons.calculate_outlined,
  'inventory_2': Icons.inventory_2_outlined,
  'point_of_sale': Icons.point_of_sale_rounded,
  'fast_sales': Icons.price_check_rounded,
  'extension_outlined': Icons.extension_outlined, 
  // NUEVO ICONO PARA COTIZACIONES
  'quotes': Icons.description_outlined,
};

// ----------------------------------------------------------------------
// WIDGET PRINCIPAL: La Cuadrícula de Módulos
// ----------------------------------------------------------------------

class ModulesGrid extends StatelessWidget {
  final List<ModuleModel> activeModules;
  final VoidCallback onAddModule;
  final UserModel user;
  
  const ModulesGrid({
    super.key,
    required this.activeModules,
    required this.onAddModule,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    // AQUÍ CONECTARÍAS TU PROVIDER REAL DE NOTIFICACIONES
    // Por ahora simulamos que hay 3 cotizaciones nuevas para ver el badge
    final int quoteNotifications = 3; 

    return GridView.count(
      crossAxisCount: 4, 
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Botón "Gestionar Tienda"
        if (user.publicProfileTemplate == 'store') 
          _ModuleCard(
            title: 'Tienda', 
            icon: _iconMap['storefront_outlined'] ?? Icons.storefront_outlined,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ManageStoreScreen(user: user),
              ));
            },
          ),
        // Botón "Gestionar Catálogo"
        if (user.publicProfileTemplate == 'catalog') 
          _ModuleCard(
            title: 'Catálogo', 
            icon: _iconMap['auto_stories_outlined'] ?? Icons.auto_stories_outlined,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => CatalogEditorScreen(user: user),
              ));
            },
          ),

        // Módulos activos mapeados desde Firebase
        ...activeModules.map((module) {
          // Lógica para detectar si este módulo lleva Badge
          int badgeCount = 0;
          if (module.moduleId == 'quotes') {
            badgeCount = quoteNotifications;
          }

          return _ModuleCard(
            title: module.name,
            icon: _iconMap[module.icon] ?? Icons.extension_outlined,
            notificationCount: badgeCount, // Pasamos el contador
            onTap: () {
              _navigateToModule(context, module.moduleId, user);
            },
          );
        }),

        // Tarjeta para añadir módulo
        _AddModuleCard(onTap: onAddModule),
      ],
    );
  }

  /// Lógica de navegación
  void _navigateToModule(BuildContext context, String moduleId, UserModel user) {
    Widget? destination;
    
    switch (moduleId) {
      case 'agenda':
        destination = AgendaScreen(user: user);
        break;
      case 'client-management':
        destination = Provider<CrmRepository>( 
          create: (_) => CrmRepository(),
          child: const ClientManagementScreen(),
        );
        break;
      case 'finance':
      case 'advanced-finance':
        destination = const AdvancedFinanceScreen();
        break;
      case 'cost_structure':
        destination = const BusinessConfigScreen();
        break;
      case 'inventory':
        destination = const InventoryScreen();
        break;
      case 'pos_system':
        destination = const PosScreen();
        break;
      // NUEVO CASO DE NAVEGACIÓN
      case 'quotes':
        destination = const QuoteListScreen(); 
        break;
    }

    if (destination != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => destination!));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navegación para "$moduleId" no implementada.')));
    }
  }
}

// ----------------------------------------------------------------------
// WIDGET AUXILIAR: Tarjeta de Módulo Individual (CON BADGE)
// ----------------------------------------------------------------------

class _ModuleCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final int notificationCount; // Nuevo parámetro para el Badge

  const _ModuleCard({
    required this.title, 
    required this.icon, 
    required this.onTap,
    this.notificationCount = 0, // Por defecto 0 (sin badge)
  });

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = colorScheme.primary; 
    final cardColor = theme.cardTheme.color;  
    final textColor = colorScheme.onSurface;  

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Stack(
        clipBehavior: Clip.none, // Permite que el badge sobresalga un poco si se desea
        children: [
          // --- TARJETA PRINCIPAL ---
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                if (isDark)
                  BoxShadow(
                    color: _isHovered
                        ? primaryColor.withValues(alpha: 0.5)
                        : primaryColor.withValues(alpha: 0.25),
                    blurRadius: _isHovered ? 12 : 8,
                    spreadRadius: 1,
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Material(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                // Borde solo en modo claro para contraste
                side: !isDark 
                    ? BorderSide(color: theme.dividerColor.withValues(alpha: 0.5))
                    : BorderSide.none,
              ),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(12),
                splashColor: primaryColor.withValues(alpha: 0.3),
                highlightColor: primaryColor.withValues(alpha: 0.1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(widget.icon, size: 32, color: primaryColor), 
                    const SizedBox(height: 8), 
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0), 
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- BADGE DE NOTIFICACIÓN ---
          if (widget.notificationCount > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.redAccent, // Color de alerta vibrante
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: cardColor ?? Colors.white, width: 1.5), // Borde para separar del fondo
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Center(
                  child: Text(
                    widget.notificationCount > 99 ? '99+' : widget.notificationCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// WIDGET AUXILIAR: Tarjeta para Añadir Módulo (SIN CAMBIOS)
// ----------------------------------------------------------------------

class _AddModuleCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddModuleCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12), 
        splashColor: primaryColor.withValues(alpha: 0.3),
        highlightColor: primaryColor.withValues(alpha: 0.1),
        child: DottedBorder(
          color: primaryColor.withValues(alpha: 0.6),
          strokeWidth: 2,
          radius: const Radius.circular(12), 
          borderType: BorderType.rRect,
          dashPattern: const [8, 6],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 32, color: primaryColor),
                const SizedBox(height: 8), 
                Text(
                  'Añadir\nMódulo', 
                  textAlign: TextAlign.center, 
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
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


// ----------------------------------------------------------------------
// UTILIDAD: DottedBorder (SIN CAMBIOS)
// ----------------------------------------------------------------------

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
      path = Path()
        ..addRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height), validRadius));
    } else {
      path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    Path dashPath = Path();

    if (dashPattern.isNotEmpty && dashPattern[0] > 0) {
      final double dashLength = dashPattern[0];
      final double gapLength = dashPattern.length > 1 ? dashPattern[1] : 0;
      final double totalDashPatternLength = dashLength + gapLength;

      if (totalDashPatternLength > 0) {
        for (ui.PathMetric pathMetric in path.computeMetrics()) {
          double distance = 0.0; 
          while (distance < pathMetric.length) {
            final double end =
                (distance + dashLength).clamp(0.0, pathMetric.length);
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