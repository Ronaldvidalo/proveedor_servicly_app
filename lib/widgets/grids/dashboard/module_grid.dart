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
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart'; 

// --- Importaciones de Servicios y Providers ---
import 'package:proveedor_servicly_app/core/services/order_service.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
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
      duration: const Duration(milliseconds: 800), // Animación más rápida para grid
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
      // Si está inactivo, al tocarlo se activa automáticamente
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
    final colors = theme.colorScheme;
    
    final sortedModules = List<ModuleModel>.from(widget.allModules);
    sortedModules.sort((a, b) {
      final aActive = widget.user.activeModules.contains(a.moduleId);
      final bActive = widget.user.activeModules.contains(b.moduleId);
      // Priorizar activos, luego orden default
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
            // Sección: Presencia Online (Estilo destacado "Hero")
            if (widget.user.publicProfileTemplate == 'store' || widget.user.publicProfileTemplate == 'catalog')
               Padding(
                 padding: const EdgeInsets.only(bottom: 12.0),
                 child: Text("MI PRESENCIA ONLINE", style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: colors.onSurface.withValues(alpha: 0.6))),
               ),
            
            if (widget.user.publicProfileTemplate == 'store') 
              _buildLargeTile(
                title: 'Mi Tienda Digital',
                subtitle: 'Tu vidriera abierta 24/7',
                icon: _iconMap['storefront_outlined']!,
                color: colors.primary,
                onTap: () {
                  ProviderProfileModel? activeProfile;
                  try {
                    activeProfile = context.read<DashboardContext>().selectedProfile;
                  } catch (_) {}

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

            // Espacio entre secciones
            if (widget.user.publicProfileTemplate == 'store' || widget.user.publicProfileTemplate == 'catalog')
                const SizedBox(height: 24),
            
            // Sección: Herramientas (Grid Denso 3x3)
            // No ponemos título aquí porque el contenedor padre (_WebDashboardCard) ya suele tenerlo
            
            if (widget.enableListView) 
              _buildVerticalList(sortedModules, pendingCount)
            else
              _buildDenseGrid(sortedModules, pendingCount),
          ],
        );
      },
    );
  }

  // --- NUEVO GRID DENSO (3 Columnas, Estilo Botón) ---
  Widget _buildDenseGrid(List<ModuleModel> modules, int pendingCount) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 Columnas para mayor densidad
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0, // Cuadrados perfectos
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) => _buildItem(modules[index], index, pendingCount, isList: false),
    );
  }

  // Lista para compatibilidad (Legacy)
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
          subtitle: isActive ? "ON" : "OFF", // Texto corto para grid denso
          icon: _iconMap[module.icon] ?? Icons.extension_outlined,
          accentColor: categoryColor,
          isLarge: false,
          isActive: isActive,
          isListStyle: isList, 
          isLoading: _loadingModuleId == module.moduleId,
          isPremium: module.isPremium,
          badge: badge,
          onTap: () => _handleCardTap(module, isActive),
          onSwitchChanged: null, // Sin switch en grid denso, el tap controla todo
          onLongPress: () {
             // Long press para desactivar o explicar
             if (isActive) {
               _toggleModuleState(module, false);
             } else {
               _explainModule(module.moduleId);
             }
          },
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
      case 'orders-module': return Colors.orange;
      case 'advanced-finance':
      case 'cost_structure': return Colors.teal;
      case 'agenda':
      case 'clients':
      case 'crm':
      case 'client-management': return Colors.blue;
      case 'inventory': return Colors.purple;
      case 'marketing-center-module': return Colors.cyan;
      default: return Colors.blueGrey;
    }
  }
}

// --- INNOVATION CARD (DISEÑO "CYBER-KEY") ---
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
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    // Si activo: color vibrante. Si inactivo: gris apagado.
    final displayColor = widget.isActive ? widget.accentColor : theme.colorScheme.onSurface.withValues(alpha: 0.3);
    
    // Fondo: Tinte de color si activo, casi transparente si inactivo.
    final backgroundColor = isDark 
        ? (widget.isActive ? widget.accentColor.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03))
        : (widget.isActive ? widget.accentColor.withValues(alpha: 0.08) : Colors.grey.shade100);

    // Borde: Brillante si activo en dark mode (efecto neón)
    final borderColor = isDark
        ? (widget.isActive ? widget.accentColor.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1))
        : (widget.isActive ? widget.accentColor.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05));

    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapDown = true),
      onTapUp: (_) => setState(() => _isTapDown = false),
      onTapCancel: () => setState(() => _isTapDown = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _isTapDown ? 0.92 : 1.0, // Efecto de pulsación más táctil
        duration: const Duration(milliseconds: 100),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Efecto Glass
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: [
                  // Glow Effect si está activo
                  if (widget.isActive && isDark)
                    BoxShadow(color: widget.accentColor.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 0)),
                  // Sombra normal si está inactivo o en light mode
                  if (!isDark && widget.isActive)
                     BoxShadow(color: widget.accentColor.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Stack(
                children: [
                  // Contenido
                  Padding(
                    padding: EdgeInsets.all(widget.isLarge ? 16 : 8),
                    child: (widget.isListStyle || widget.isLarge) 
                        ? _buildListLayout(theme, displayColor) 
                        : _buildCompactLayout(theme, displayColor),
                  ),
                  
                  // Indicador de Carga
                  if (widget.isLoading)
                    Positioned.fill(
                      child: Container(
                        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.6), 
                        child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                      )
                    ),
                  
                  // Badge Premium (Estrella pequeña)
                  if (widget.isPremium)
                     const Positioned(top: 6, left: 6, child: Icon(Icons.star_rounded, size: 14, color: Colors.amber)),

                  // Badge de Notificación (Pedidos, etc)
                  if (widget.badge > 0)
                     Positioned(
                       top: 6, right: 6,
                       child: Container(
                         padding: const EdgeInsets.all(3),
                         decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                         constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                         child: Text('${widget.badge}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
                       )
                     ),
                     
                  // Switch (Solo visible en modo lista o tarjeta grande)
                  if ((widget.isListStyle || widget.isLarge) && widget.onSwitchChanged != null && !widget.isLoading)
                    Positioned(
                      top: 0, right: 0,
                      child: Transform.scale(
                        scale: 0.65, 
                        child: Switch(
                          value: widget.isActive, 
                          onChanged: widget.onSwitchChanged, 
                          activeColor: widget.accentColor
                        )
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListLayout(ThemeData theme, Color color) {
    return Row(
      children: [
        _buildIconContainer(48, 48, 26, color), 
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  widget.title, 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis, 
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: widget.isActive ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.5))
              ),
              Text(
                  widget.subtitle, 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis, 
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))
              ),
            ],
          ),
        ),
        if (widget.onSwitchChanged == null)
           Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.3), size: 24),
      ],
    );
  }

  // Layout para el Grid Denso (Botones Cuadrados)
  Widget _buildCompactLayout(ThemeData theme, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icono
        Icon(widget.icon, size: 28, color: color),
        
        const SizedBox(height: 8),
        
        // Título
        Text(
            widget.title, 
            textAlign: TextAlign.center,
            maxLines: 2, 
            overflow: TextOverflow.ellipsis, 
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold, 
              fontSize: 10, 
              height: 1.1,
              color: widget.isActive ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.5)
            )
        ),
      ],
    );
  }

  Widget _buildIconContainer(double w, double h, double iconSize, Color color) {
    return Container(
      width: w, height: h,
      decoration: BoxDecoration(
        color: widget.isActive ? color.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1), 
        borderRadius: BorderRadius.circular(12)
      ),
      child: Center(
        child: Icon(widget.icon, color: color, size: iconSize),
      ),
    );
  }
}