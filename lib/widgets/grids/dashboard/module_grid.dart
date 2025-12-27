import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';

// --- IMPORTACIÓN DEL SERVICIO DE VOZ ---
import 'package:proveedor_servicly_app/ai/services/voice_service.dart';

// --- Importaciones de Modelos ---
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/models/module_model.dart';
import 'package:proveedor_servicly_app/core/models/order_model.dart';

// --- Importaciones de Servicios ---
import 'package:proveedor_servicly_app/core/services/order_service.dart';

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
import 'package:proveedor_servicly_app/features/budget/screens/quote_list_screen.dart';
import 'package:proveedor_servicly_app/features/orders/screens/provider_orders_screen.dart';
import 'package:proveedor_servicly_app/features/orders/screens/client_orders_screen.dart';

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
  'quotes': Icons.description_outlined,
  'receipt_long_outlined': Icons.receipt_long_outlined,
  'shopping_bag_outlined': Icons.shopping_bag_outlined,
};

class ModulesGrid extends StatefulWidget {
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
  State<ModulesGrid> createState() => _ModulesGridState();
}

class _ModulesGridState extends State<ModulesGrid> with TickerProviderStateMixin {
  final ServiVoiceService _voiceService = ServiVoiceService();
  late AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _listController.forward();
  }

  @override
  void dispose() {
    _voiceService.dispose();
    _listController.dispose();
    super.dispose();
  }

  void _explainModule(String moduleId) {
    HapticFeedback.heavyImpact();
    String script = "";
    
    switch (moduleId) {
      case 'store_template': script = "Tu Vidriera Digital. Cargá tus productos y vendé las 24 horas."; break;
      case 'catalog_template': script = "Tu Portafolio Profesional. Mostrá tus trabajos y recibí pedidos."; break;
      case 'agenda': script = "Tu secretaria personal. Agendá turnos y recordatorios."; break;
      case 'clients': script = "Tu mina de oro. Gestioná los datos de tus clientes."; break;
      case 'advanced-finance': script = "Cuidá el mango. Controlá ingresos y egresos."; break;
      case 'inventory': script = "Controlá tu stock. No te quedes sin mercadería."; break;
      case 'fast_sales': script = "Tu caja registradora. Cobrá rápido en el mostrador."; break;
      case 'quotes': script = "Presupuestos profesionales en PDF para WhatsApp."; break;
      case 'cost_structure': script = "Tus costos fijos. Sabé cuánto te cuesta abrir cada día."; break;
      case 'orders-module': script = "Gestión de Pedidos. Revisá ventas y coordiná entregas."; break;
      case 'add_module': script = "Expandí tu potencial. Activá nuevas herramientas."; break;
      default: script = "Esta herramienta optimiza tu flujo de trabajo.";
    }
    _voiceService.speak(script);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return StreamBuilder<List<OrderModel>>(
      stream: widget.user.uid.isNotEmpty 
          ? context.read<OrderService>().getPendingOrders(widget.user.uid)
          : const Stream.empty(),
      builder: (context, snapshot) {
        int pendingCount = snapshot.hasData ? snapshot.data!.length : 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECCIÓN: PERFIL PÚBLICO (Destacado arriba) ---
            _buildSectionHeader(context, "Mi presencia online"),
            if (widget.user.publicProfileTemplate == 'store') 
              _buildLargeTile(
                title: 'Mi Tienda Digital',
                subtitle: 'Tu vidriera abierta 24/7',
                icon: _iconMap['storefront_outlined']!,
                color: theme.primaryColor,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ManageStoreScreen(user: widget.user))),
                onLongPress: () => _explainModule('store_template'),
              ),
            if (widget.user.publicProfileTemplate == 'catalog')
              _buildLargeTile(
                title: 'Catálogo Pro',
                subtitle: 'Servicios de alto impacto',
                icon: _iconMap['auto_stories_outlined']!,
                color: Colors.deepPurpleAccent,
                // CORRECCIÓN AQUÍ: Se cambia 'user: widget.user' por 'providerId: widget.user.uid'
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CatalogEditorScreen(providerId: widget.user.uid))),
                onLongPress: () => _explainModule('catalog_template'),
              ),

            const SizedBox(height: 24),
            
            // --- SECCIÓN: HERRAMIENTAS (Grid de 2 columnas) ---
            _buildSectionHeader(context, "Gestión del negocio"),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 110,
              ),
              itemCount: widget.activeModules.length + 1,
              itemBuilder: (context, index) {
                if (index == widget.activeModules.length) {
                  return _buildAddModuleCard();
                }
                
                final module = widget.activeModules[index];
                int badge = (module.moduleId == 'orders-module') ? pendingCount : 0;
                
                return _buildGridItem(
                  module: module,
                  index: index,
                  badge: badge,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  // Tarjeta grande para Tienda/Catálogo
  Widget _buildLargeTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    return _InnovationCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      accentColor: color,
      isLarge: true,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  // Item de la cuadrícula
  Widget _buildGridItem({
    required ModuleModel module,
    required int index,
    int badge = 0,
  }) {
    Color categoryColor = _getCategoryColor(module.moduleId);

    return AnimatedBuilder(
      animation: _listController,
      builder: (context, child) {
        final start = index * 0.08;
        final end = (start + 0.5).clamp(0.0, 1.0);
        final curve = CurvedAnimation(
          parent: _listController,
          curve: Interval(start, end, curve: Curves.easeOutBack),
        );
        return Transform.scale(
          scale: curve.value,
          child: Opacity(opacity: curve.value.clamp(0.0, 1.0), child: child),
        );
      },
      child: _InnovationCard(
        title: module.name,
        subtitle: _getModuleSubtitle(module.moduleId),
        icon: _iconMap[module.icon] ?? Icons.extension_outlined,
        accentColor: categoryColor,
        isLarge: false,
        badge: badge,
        onTap: () => _navigateToModule(context, module.moduleId, widget.user),
        onLongPress: () => _explainModule(module.moduleId),
      ),
    );
  }

  Color _getCategoryColor(String id) {
    switch (id) {
      case 'fast_sales':
      case 'orders-module': return Colors.orangeAccent; // Ventas
      case 'advanced-finance':
      case 'cost_structure': return Colors.tealAccent; // Finanzas
      case 'agenda':
      case 'clients': return Colors.blueAccent; // CRM/Agenda
      case 'inventory': return Colors.purpleAccent; // Logística
      default: return Colors.blueGrey;
    }
  }

  String _getModuleSubtitle(String id) {
    switch (id) {
      case 'agenda': return 'Turnos';
      case 'clients': return 'Base CRM';
      case 'advanced-finance': return 'Finanzas';
      case 'inventory': return 'Stock';
      case 'fast_sales': return 'Caja';
      case 'quotes': return 'PDFs';
      case 'cost_structure': return 'Costos';
      case 'orders-module': return 'Pedidos';
      default: return 'Gestión';
    }
  }

  Widget _buildAddModuleCard() {
    return GestureDetector(
      onTap: widget.onAddModule,
      child: DottedBorder(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        strokeWidth: 2,
        radius: const Radius.circular(20),
        borderType: BorderType.rRect,
        dashPattern: const [8, 4],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_to_photos_rounded, color: Theme.of(context).primaryColor, size: 28),
              const SizedBox(height: 8),
              Text(
                'Más herramientas',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToModule(BuildContext context, String moduleId, UserModel user) {
    Widget? destination;
    switch (moduleId) {
      case 'agenda': destination = AgendaScreen(user: user); break;
      case 'clients': destination = Provider<CrmRepository>(create: (_) => CrmRepository(), child: const ClientManagementScreen()); break;
      case 'advanced-finance': destination = const AdvancedFinanceScreen(); break;
      case 'cost_structure': destination = const BusinessConfigScreen(); break;
      case 'inventory': destination = const InventoryScreen(); break;
      case 'fast_sales': destination = const PosScreen(); break;
      case 'quotes': destination = const QuoteListScreen(); break;
      case 'orders-module': destination = const ProviderOrdersScreen(); break;
      case 'module_client_orders': destination = const ClientOrdersScreen(); break;
    }
    if (destination != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => destination!));
  }
}

class _InnovationCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool isLarge;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final int badge;

  const _InnovationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.isLarge,
    required this.onTap,
    required this.onLongPress,
    this.badge = 0,
  });

  @override
  State<_InnovationCard> createState() => _InnovationCardState();
}

class _InnovationCardState extends State<_InnovationCard> {
  bool _isTapDown = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapDown = true),
      onTapUp: (_) => setState(() => _isTapDown = false),
      onTapCancel: () => setState(() => _isTapDown = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _isTapDown ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: isDark ? 0.1 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: _isTapDown ? widget.accentColor : widget.accentColor.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Padding(
                padding: EdgeInsets.all(widget.isLarge ? 16 : 12),
                child: widget.isLarge ? _buildLargeLayout(isDark) : _buildGridLayout(isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLargeLayout(bool isDark) {
    return Row(
      children: [
        _buildIconContainer(48, 48, 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title.toUpperCase(), style: _titleStyle(isDark, 14)),
              Text(widget.subtitle, style: _subtitleStyle(isDark)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
      ],
    );
  }

  Widget _buildGridLayout(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildIconContainer(36, 36, 20),
        const SizedBox(height: 8),
        Text(widget.title, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: _titleStyle(isDark, 11)),
        const SizedBox(height: 2),
        Text(widget.subtitle, textAlign: TextAlign.center, style: _subtitleStyle(isDark, 9)),
      ],
    );
  }

  Widget _buildIconContainer(double w, double h, double iconSize) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: widget.accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(widget.icon, color: widget.accentColor, size: iconSize),
          if (widget.badge > 0)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                child: Text('${widget.badge}', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),
            ),
        ],
      ),
    );
  }

  TextStyle _titleStyle(bool isDark, double size) => TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: size,
    letterSpacing: 0.5,
    color: isDark ? Colors.white : Colors.black87,
  );

  TextStyle _subtitleStyle(bool isDark, [double size = 11]) => TextStyle(
    fontSize: size,
    color: isDark ? Colors.white54 : Colors.black45,
    fontStyle: FontStyle.italic,
  );
}

// ----------------------------------------------------------------------
// UTILIDAD: DottedBorder (Efecto Dash)
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
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.borderType,
    required this.dashPattern,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    Path path = Path();
    if (borderType == BorderType.rRect) {
      path.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        radius,
      ));
    } else {
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    Path dashPath = Path();
    for (ui.PathMetric pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < pathMetric.length) {
        double len = dashPattern[draw ? 0 : 1];
        if (draw) {
          dashPath.addPath(pathMetric.extractPath(distance, distance + len), Offset.zero);
        }
        distance += len;
        draw = !draw;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(_DottedPainter old) => old.color != color || old.strokeWidth != strokeWidth;
}