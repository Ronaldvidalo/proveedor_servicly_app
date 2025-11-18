// lib/common/widgets/grids/module_grid.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';

// --- Importaciones de Modelos, Pantallas y Repositorios (Ajusta tus rutas) ---
import '../../../../core/models/user_model.dart'; // Ajustar ruta
import '../../../../core/models/module_model.dart'; // Ajustar ruta
// Pantallas
import 'package:proveedor_servicly_app/features/agenda/presentation/screens/agenda_screen.dart';// Ajustar ruta
import 'package:proveedor_servicly_app/features/crm/data/repositories/screens/client_management_screen.dart'; // Ajustar ruta
import 'package:proveedor_servicly_app/features/finance/presentation/screens/advanced_finance_screen.dart'; // Ajustar ruta
import 'package:proveedor_servicly_app/features/manage_store/presentation/screens/manage_store_screen.dart'; // Ajustar ruta
import 'package:proveedor_servicly_app/features/catalogo/screens/catalog_editor_screen.dart';// Ajustar ruta
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart';


// --- Estilos Globales (Constantes) ---
const Color _accentColor = Color(0xFF00BFFF); // Azul eléctrico brillante
const Color _surfaceColor = Color(0xFF2D2D5A); // Superficie de la tarjeta

// --- Mapa de Iconos (Para evitar la dependencia directa en una clase de mapeo) ---
// DEBES tener este mapa disponible en tu app o pasarlo como parámetro
const Map<String, IconData> _iconMap = {
  'storefront_outlined': Icons.storefront_outlined,
  'auto_stories_outlined': Icons.auto_stories_outlined,
  'calendar_today_outlined': Icons.calendar_today_outlined,
  'group_outlined': Icons.group_outlined,
  'bar_chart_outlined': Icons.bar_chart_outlined,
  'extension_outlined': Icons.extension_outlined, // Default
};


// ----------------------------------------------------------------------
// WIDGET PRINCIPAL: La Cuadrícula de Módulos
// ----------------------------------------------------------------------

class ModulesGrid extends StatelessWidget {
  final List<ModuleModel> activeModules;
  final VoidCallback onAddModule;
  final UserModel user;
  
  // Renombramos de _ModulesGrid a ModulesGrid
  const ModulesGrid({
    super.key,
    required this.activeModules,
    required this.onAddModule,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    // --- MODIFICACIÓN: Simplificado a una cuadrícula fija de 4 columnas ---
    return GridView.count(
      crossAxisCount: 4, // 4 columnas
      crossAxisSpacing: 12, // Espacio reducido
      mainAxisSpacing: 12, // Espacio reducido
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Botón "Gestionar Tienda" (Lógica de negocio condicional)
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
        // Botón "Gestionar Catálogo" (Lógica de negocio condicional)
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

        // Módulos activos mapeados
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
  }

  /// Lógica de navegación a la pantalla de cada módulo
  void _navigateToModule(BuildContext context, String moduleId, UserModel user) {
    Widget? destination;
    switch (moduleId) {
      case 'agenda':
        destination = AgendaScreen(user: user);
        break;
      case 'client-management':
        // Se inyecta el repositorio solo en esta pantalla si es necesario
        destination = Provider<CrmRepository>( 
          create: (_) => CrmRepository(),
          child: const ClientManagementScreen(),
        );
        break;
      case 'advanced-finance':
        destination = const AdvancedFinanceScreen();
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
// WIDGET AUXILIAR: Tarjeta de Módulo Individual (con hover)
// ----------------------------------------------------------------------

class _ModuleCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ModuleCard(
      {required this.title, required this.icon, required this.onTap});

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? _accentColor.withAlpha(128)
                  : _accentColor.withAlpha(64),
              blurRadius: _isHovered ? 12 : 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Material(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: _accentColor.withAlpha(77),
            highlightColor: _accentColor.withAlpha(38),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 32, color: _accentColor), 
                const SizedBox(height: 8), 
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0), 
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
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
// WIDGET AUXILIAR: Tarjeta para Añadir Módulo
// ----------------------------------------------------------------------

class _AddModuleCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddModuleCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12), 
        splashColor: _accentColor.withAlpha(77),
        highlightColor: _accentColor.withAlpha(38),
        child: DottedBorder(
          color: _accentColor.withAlpha(153),
          strokeWidth: 2,
          radius: const Radius.circular(12), 
          borderType: BorderType.rRect,
          dashPattern: const [8, 6],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 32, color: _accentColor),
                const SizedBox(height: 8), 
                const Text(
                  'Añadir\nMódulo', 
                  textAlign: TextAlign.center, 
                  style: TextStyle(
                    color: Colors.white,
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
// UTILIDAD: DottedBorder (Para la tarjeta de Añadir Módulo)
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