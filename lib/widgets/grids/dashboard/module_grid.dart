import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- IMPORTACIÓN DEL SERVICIO DE VOZ ---
import 'package:proveedor_servicly_app/ai/services/voice_service.dart';

// --- Importaciones de Modelos ---
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/models/module_model.dart';
import 'package:proveedor_servicly_app/core/models/order_model.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart'; // Asegura tener este modelo

// --- Importaciones de Servicios y Providers ---
import 'package:proveedor_servicly_app/core/services/order_service.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
// FIX: Importamos el contexto del Dashboard para obtener el perfil seleccionado
import 'package:proveedor_servicly_app/features/dashboard/providers/dashboard_context_provider.dart';

// --- Importaciones de Pantallas (Rutas de Navegación) ---
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
import 'package:proveedor_servicly_app/features/promotion/screens/marketing_center_screen.dart';

// --- Mapa de Iconos ---
const Map<String, IconData> _iconMap = {
  'storefront_outlined': Icons.storefront_outlined,
  'auto_stories_outlined': Icons.auto_stories_outlined,
  'calendar_today_outlined': Icons.calendar_today_outlined,
  'group_outlined': Icons.people_alt_rounded,
  'clients': Icons.people_alt_rounded,
  'crm': Icons.people_alt_rounded,
  'client-management': Icons.people_alt_rounded,
  'bar_chart_outlined': Icons.bar_chart_rounded,
  'calculate': Icons.calculate_outlined,
  'inventory_2': Icons.inventory_2_outlined,
  'point_of_sale': Icons.point_of_sale_rounded,
  'fast_sales': Icons.price_check_rounded,
  'fast-sales': Icons.price_check_rounded,
  'pos': Icons.price_check_rounded,
  'extension_outlined': Icons.extension_outlined, 
  'quotes': Icons.description_outlined,
  'receipt_long_outlined': Icons.receipt_long_outlined,
  'shopping_bag_outlined': Icons.shopping_bag_outlined,
  'campaign_outlined': Icons.campaign_outlined,
  'people_outline': Icons.people_outline_rounded,
  'insights': Icons.insights_rounded,
  'add_card': Icons.add_card_rounded,
  'help_outline': Icons.help_outline_rounded,
};

class ModulesGrid extends StatefulWidget {
  final List<ModuleModel> allModules; 
  final UserModel user;
  final bool enableListView; 
  
  const ModulesGrid({
    super.key,
    required this.allModules,
    required this.user,
    this.enableListView = false, 
  });

  @override
  State<ModulesGrid> createState() => _ModulesGridState();
}

class _ModulesGridState extends State<ModulesGrid> with TickerProviderStateMixin {
  final ServiVoiceService _voiceService = ServiVoiceService();
  late AnimationController _listController;
  
  String? _loadingModuleId;
  static const int _freePlanModuleLimit = 4;

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

  // --- 1. LÓGICA DE ACTIVACIÓN ---
  Future<void> _toggleModuleState(ModuleModel module, bool value) async {
    if (_loadingModuleId != null) return;

    if (value) {
      if (module.isPremium && widget.user.planType == 'free') {
        _explainModule("premium_error");
        _showUpgradeDialog('Este módulo es Premium. Actualizá tu plan para desbloquearlo.');
        return;
      }
      if (widget.user.planType == 'free' && widget.user.activeModules.length >= _freePlanModuleLimit) {
        _explainModule("limit_error");
        _showUpgradeDialog('Llegaste al límite de $_freePlanModuleLimit herramientas del plan gratuito.');
        return;
      }
      setState(() => _loadingModuleId = module.moduleId);
      HapticFeedback.mediumImpact();
      try {
        await context.read<FirestoreService>().updateUser(widget.user.uid, {
          'activeModules': FieldValue.arrayUnion([module.moduleId])
        });
        _voiceService.speak("${module.name} activado.");
      } catch (e) {
        _showErrorSnackBar(e.toString());
      } finally {
        if (mounted) setState(() => _loadingModuleId = null);
      }
    } else {
      setState(() => _loadingModuleId = module.moduleId);
      HapticFeedback.lightImpact();
      try {
        await context.read<FirestoreService>().updateUser(widget.user.uid, {
          'activeModules': FieldValue.arrayRemove([module.moduleId])
        });
      } catch (e) {
        _showErrorSnackBar(e.toString());
      } finally {
        if (mounted) setState(() => _loadingModuleId = null);
      }
    }
  }

  // --- 2. LÓGICA DE NAVEGACIÓN ---
  void _handleCardTap(ModuleModel module, bool isActive) {
    if (isActive) {
      _navigateToModule(context, module.moduleId, widget.user);
    } else {
      _toggleModuleState(module, true);
    }
  }

  void _navigateToModule(BuildContext context, String moduleId, UserModel user) {
    Widget? destination;
    
    switch (moduleId) {
      case 'agenda': 
        destination = AgendaScreen(user: user); 
        break;
      case 'clients':
      case 'crm':
      case 'client-management': 
        destination = Provider<CrmRepository>(
          create: (_) => CrmRepository(), 
          child: const ClientManagementScreen()
        ); 
        break;
      case 'advanced-finance': 
        destination = const AdvancedFinanceScreen(); 
        break;
      case 'cost_structure': 
        destination = const BusinessConfigScreen(); 
        break;
      case 'inventory': 
        destination = const InventoryScreen(); 
        break;
      case 'fast_sales':
      case 'fast-sales': 
      case 'pos': 
        destination = const PosScreen(); 
        break;
      case 'quotes': 
        destination = const QuoteListScreen(); 
        break;
      case 'orders-module': 
        destination = const ProviderOrdersScreen(); 
        break;
      case 'module_client_orders': 
        destination = const ClientOrdersScreen(); 
        break;
      case 'marketing-center-module': 
        destination = const MarketingCenterScreen(); 
        break;
    }
    
    if (destination != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => destination!));
    } else {
      debugPrint("Módulo no encontrado o sin ruta definida: $moduleId");
    }
  }

  void _explainModule(String moduleId) {
    HapticFeedback.selectionClick();
    String script = "";
    if (moduleId == "premium_error") { _voiceService.speak("Esta herramienta es exclusiva para socios premium."); return; }
    if (moduleId == "limit_error") { _voiceService.speak("Alcanzaste el límite de tu plan actual."); return; }

    switch (moduleId) {
      case 'store_template': script = "Tu Vidriera Digital."; break;
      case 'catalog_template': script = "Tu Portafolio Profesional."; break;
      case 'agenda': script = "Agenda y turnos."; break;
      case 'clients':
      case 'crm':
      case 'client-management': script = "Gestión de clientes."; break;
      case 'advanced-finance': script = "Finanzas."; break;
      case 'inventory': script = "Control de stock."; break;
      case 'fast_sales':
      case 'fast-sales':
      case 'pos': script = "Punto de venta."; break;
      case 'quotes': script = "Presupuestos PDF."; break;
      case 'cost_structure': script = "Estructura de costos."; break;
      case 'orders-module': script = "Pedidos."; break;
      case 'marketing-center-module': script = "Marketing Center."; break;
      default: script = "Herramienta Servicly.";
    }
    _voiceService.speak(script);
  }

  void _showUpgradeDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mejorar Plan'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Entendido")),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $msg"), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final sortedModules = List<ModuleModel>.from(widget.allModules);
    sortedModules.sort((a, b) {
      final aActive = widget.user.activeModules.contains(a.moduleId);
      final bActive = widget.user.activeModules.contains(b.moduleId);
      if (aActive && !bActive) return -1;
      if (!aActive && bActive) return 1;
      return a.defaultOrder.compareTo(b.defaultOrder);
    });

    return StreamBuilder<List<OrderModel>>(
      stream: widget.user.uid.isNotEmpty 
          ? context.read<OrderService>().getPendingOrders(widget.user.uid)
          : const Stream.empty(),
      builder: (context, snapshot) {
        int pendingCount = snapshot.hasData ? snapshot.data!.length : 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, "Mi presencia online"),
            if (widget.user.publicProfileTemplate == 'store') 
              _buildLargeTile(
                title: 'Mi Tienda Digital',
                subtitle: 'Tu vidriera abierta 24/7',
                icon: _iconMap['storefront_outlined']!,
                color: theme.primaryColor,
                // --- FIX CRÍTICO: CONEXIÓN DE DATOS ---
                onTap: () {
                  // 1. Intentamos obtener el perfil activo del Dashboard
                  ProviderProfileModel? activeProfile;
                  try {
                    activeProfile = context.read<DashboardContext>().selectedProfile;
                  } catch (_) {
                    // Si falla (ej. fuera del dashboard), seguimos con null
                  }

                  // 2. Navegamos pasando user (para fetch) y profile (si ya lo tenemos)
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ManageStoreScreen(
                      user: widget.user,
                      profile: activeProfile,
                    ),
                  ));
                },
                onLongPress: () => _explainModule('store_template'),
              ),
            if (widget.user.publicProfileTemplate == 'catalog')
              _buildLargeTile(
                title: 'Catálogo Pro',
                subtitle: 'Servicios de alto impacto',
                icon: _iconMap['auto_stories_outlined']!,
                color: Colors.deepPurpleAccent,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CatalogEditorScreen(providerId: widget.user.uid))),
                onLongPress: () => _explainModule('catalog_template'),
              ),

            const SizedBox(height: 24),
            _buildSectionHeader(context, "Herramientas"),
            
            if (widget.enableListView) 
              _buildVerticalList(sortedModules, pendingCount)
            else
              _buildGridView(sortedModules, pendingCount),
          ],
        );
      },
    );
  }

  // Grid para Móvil
  Widget _buildGridView(List<ModuleModel> modules, int pendingCount) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 130, 
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) => _buildItem(modules[index], index, pendingCount, isList: false),
    );
  }

  // Lista para Web
  Widget _buildVerticalList(List<ModuleModel> modules, int pendingCount) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: modules.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildItem(modules[index], index, pendingCount, isList: true),
    );
  }

  Widget _buildItem(ModuleModel module, int index, int pendingCount, {required bool isList}) {
      final isActive = widget.user.activeModules.contains(module.moduleId);
      int badge = (module.moduleId == 'orders-module' && isActive) ? pendingCount : 0;
      Color categoryColor = _getCategoryColor(module.moduleId);

      return AnimatedBuilder(
        animation: _listController,
        builder: (context, child) {
          final start = index * 0.05;
          final end = (start + 0.5).clamp(0.0, 1.0);
          final curve = CurvedAnimation(parent: _listController, curve: Interval(start, end, curve: Curves.easeOutBack));
          return Transform.scale(scale: curve.value, child: Opacity(opacity: curve.value.clamp(0.0, 1.0), child: child));
        },
        child: _InnovationCard(
          title: module.name,
          subtitle: isActive ? _getModuleSubtitle(module.moduleId) : "Desactivado",
          icon: _iconMap[module.icon] ?? Icons.extension_outlined,
          accentColor: categoryColor,
          isLarge: false,
          isActive: isActive,
          isListStyle: isList, 
          isLoading: _loadingModuleId == module.moduleId,
          isPremium: module.isPremium,
          badge: badge,
          onTap: () => _handleCardTap(module, isActive),
          onSwitchChanged: (val) => _toggleModuleState(module, val),
          onLongPress: () => _explainModule(module.moduleId),
        ),
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

  Widget _buildLargeTile({
    required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap, required VoidCallback onLongPress,
  }) {
    return _InnovationCard(
      title: title, subtitle: subtitle, icon: icon, accentColor: color,
      isLarge: true, isActive: true, onTap: onTap, onLongPress: onLongPress, onSwitchChanged: null, isListStyle: true,
    );
  }

  Color _getCategoryColor(String id) {
    switch (id) {
      case 'fast_sales':
      case 'fast-sales':
      case 'pos':
      case 'orders-module': return Colors.orangeAccent;
      case 'advanced-finance':
      case 'cost_structure': return Colors.tealAccent;
      case 'agenda':
      case 'clients':
      case 'crm':
      case 'client-management': return Colors.blueAccent;
      case 'inventory': return Colors.purpleAccent;
      case 'marketing-center-module': return Colors.cyanAccent;
      default: return Colors.blueGrey;
    }
  }

  String _getModuleSubtitle(String id) {
    switch (id) {
      case 'agenda': return 'Turnos';
      case 'clients':
      case 'crm':
      case 'client-management': return 'Base CRM';
      case 'advanced-finance': return 'Finanzas';
      case 'inventory': return 'Stock';
      case 'fast_sales':
      case 'fast-sales':
      case 'pos': return 'Caja';
      case 'quotes': return 'PDFs';
      case 'cost_structure': return 'Costos';
      case 'orders-module': return 'Pedidos';
      case 'marketing-center-module': return 'Promos e IA';
      default: return 'Gestión';
    }
  }
}

class _InnovationCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool isLarge;
  final bool isActive;
  final bool isListStyle;
  final bool isLoading;
  final bool isPremium;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<bool>? onSwitchChanged;
  final int badge;

  const _InnovationCard({
    required this.title, required this.subtitle, required this.icon, required this.accentColor, required this.isLarge, required this.isActive,
    this.isListStyle = false,
    this.isLoading = false, this.isPremium = false, required this.onTap, required this.onLongPress, this.onSwitchChanged, this.badge = 0,
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
    final displayColor = widget.isActive ? widget.accentColor : Colors.grey;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapDown = true),
      onTapUp: (_) => setState(() => _isTapDown = false),
      onTapCancel: () => setState(() => _isTapDown = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _isTapDown ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [
                if (widget.isActive) ...[
                   isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                   isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
                ] else ...[
                   isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                   isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade200,
                ]
              ],
            ),
            boxShadow: [
              if (widget.isActive)
                BoxShadow(color: displayColor.withValues(alpha: isDark ? 0.1 : 0.05), blurRadius: 12, offset: const Offset(0, 4)),
            ],
            border: Border.all(
              color: _isTapDown ? displayColor : (widget.isActive ? displayColor.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.3)),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.all(widget.isLarge ? 16 : 12),
                    child: (widget.isListStyle || widget.isLarge) 
                        ? _buildListLayout(isDark, displayColor) 
                        : _buildGridLayout(isDark, displayColor),
                  ),
                  
                  if (widget.isLoading)
                    Container(color: Colors.black45, child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))),
                  
                  if (widget.isPremium)
                     Positioned(top: 8, left: 8, child: Icon(Icons.star_rounded, size: 16, color: Colors.amber)),

                  if (!widget.isListStyle && !widget.isLarge && widget.onSwitchChanged != null && !widget.isLoading)
                    Positioned(
                      top: 0, right: 0,
                      child: Transform.scale(scale: 0.65, child: Switch(value: widget.isActive, onChanged: widget.onSwitchChanged, activeTrackColor: const Color(0xFF00FF7F))),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListLayout(bool isDark, Color color) {
    return Row(
      children: [
        _buildIconContainer(42, 42, 22, color),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _titleStyle(isDark, 13).copyWith(color: widget.isActive ? null : Colors.grey)),
              Text(widget.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: _subtitleStyle(isDark, 10)),
            ],
          ),
        ),
        if (widget.onSwitchChanged != null)
           Transform.scale(
             scale: 0.7,
             child: Switch(value: widget.isActive, onChanged: widget.onSwitchChanged, activeTrackColor: const Color(0xFF00FF7F)),
           )
        else
           const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
      ],
    );
  }

  Widget _buildGridLayout(bool isDark, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIconContainer(36, 36, 20, color),
        const SizedBox(height: 8),
        Flexible(
          child: Text(widget.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: _titleStyle(isDark, 11).copyWith(color: widget.isActive ? null : Colors.grey)),
        ),
        const SizedBox(height: 4),
        Text(widget.subtitle, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: _subtitleStyle(isDark, 9)),
      ],
    );
  }

  Widget _buildIconContainer(double w, double h, double iconSize, Color color) {
    return Container(
      width: w, height: h,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(widget.icon, color: color, size: iconSize),
          if (widget.badge > 0)
            Positioned(top: 0, right: 0, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle), constraints: const BoxConstraints(minWidth: 14, minHeight: 14), child: Text('${widget.badge}', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center))),
        ],
      ),
    );
  }

  TextStyle _titleStyle(bool isDark, double size) => TextStyle(fontWeight: FontWeight.w900, fontSize: size, letterSpacing: 0.5, color: isDark ? Colors.white : Colors.black87);
  TextStyle _subtitleStyle(bool isDark, [double size = 11]) => TextStyle(fontSize: size, color: isDark ? Colors.white54 : Colors.black45, fontStyle: FontStyle.italic);
}