import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as provider_pkg;

// --- IMPORTS DE DATOS Y MODELOS ---
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/features/dashboard/models/dashboard_metrics_viewmodel.dart';
import 'package:proveedor_servicly_app/features/dashboard/providers/dashboard_context_provider.dart';

// --- IMPORTS DE PANTALLAS (Para navegación) ---
import 'package:proveedor_servicly_app/features/public_profile/screens/presentation/screens/select_profile_template_screen.dart';
import 'package:proveedor_servicly_app/features/subscriptions/screens/subscription_screen.dart';
// Nuevos imports para los slides:
import 'package:proveedor_servicly_app/features/agenda/presentation/screens/agenda_screen.dart';
import 'package:proveedor_servicly_app/features/finance/presentation/screens/advanced_finance_screen.dart';
import 'package:proveedor_servicly_app/features/inventory/screens/inventory_screen.dart';
import 'package:proveedor_servicly_app/features/sales/screens/pos_screen.dart'; // O provider_orders_screen.dart según prefieras

// --- IMPORTS VISUALES ---
import 'package:proveedor_servicly_app/shared/widgets/glow_avatar.dart';

// --- IMPORTS DE PROVIDERS (Métricas) ---
import 'package:proveedor_servicly_app/features/finance/presentation/providers/finance_providers.dart';
import 'package:proveedor_servicly_app/features/sales/providers/sales_providers.dart';
import 'package:proveedor_servicly_app/features/inventory/providers/inventory_providers.dart';
import 'package:proveedor_servicly_app/features/agenda/providers/agenda_providers.dart';
import 'package:proveedor_servicly_app/features/agenda/data/models/agenda_event_model.dart';

class UnifiedControlCenter extends ConsumerStatefulWidget {
  final UserModel userModel;
  final List<ProviderProfileModel> profiles; 

  const UnifiedControlCenter({
    super.key, 
    required this.userModel,
    required this.profiles,
  });

  @override
  ConsumerState<UnifiedControlCenter> createState() => _UnifiedControlCenterState();
}

class _UnifiedControlCenterState extends ConsumerState<UnifiedControlCenter> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 6), (Timer timer) {
      if (_pageController.hasClients) {
        int next = _currentPage + 1;
        if (next > 3) next = 0; 
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  // --- LÓGICA DE NEGOCIO DEL HEADER (Añadir Tienda / Upgrade) ---
  void _handleOnAddStoreTap(BuildContext context) {
    final int currentCount = widget.profiles.length;
    final isPro = widget.userModel.isPremium || 
                  widget.userModel.planType.toLowerCase() == 'pro' || 
                  widget.userModel.planType.toLowerCase() == 'corporate';
    
    if (!isPro && currentCount >= 1) {
      _showUpgradeDialog(context);
      return;
    } 

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectProfileTemplateScreen(
          user: widget.userModel,
          isNewProfile: true, 
        ),
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context, 
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.rocket_launch, color: Colors.orange), SizedBox(width: 10), Text("Límite Alcanzado")]),
        content: const Text("Tu plan actual permite gestionar solo 1 perfil. Pásate a PRO para crear tiendas ilimitadas."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cerrar")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            onPressed: () { 
              Navigator.pop(context); 
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
            }, 
            child: const Text("SER PRO")
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final metricsModel = provider_pkg.Provider.of<DashboardMetricsViewModel>(context); 
    final dashboardContext = provider_pkg.Provider.of<DashboardContext>(context);
    
    final profilesList = widget.profiles; 
    final selectedProfile = dashboardContext.selectedProfile;
    final selectedProfileId = selectedProfile?.id;
    final isGlobalSelected = selectedProfileId == null;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final glassColor = isDark 
        ? const Color(0xFF101018).withValues(alpha: 0.75) 
        : Colors.white.withValues(alpha: 0.85);

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 340), 
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.6), 
              width: 1
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
                blurRadius: 30,
                offset: const Offset(0, 10),
              )
            ]
          ),
          child: Stack(
            children: [
              if (isDark)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.1),
                          Colors.transparent,
                          colorScheme.secondary.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                             dashboardContext.selectGlobal();
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vista Global Activada"), duration: Duration(milliseconds: 800)));
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isGlobalSelected ? colorScheme.primary : Colors.transparent,
                                width: 2
                              ),
                              boxShadow: isGlobalSelected && isDark 
                                ? [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.4), blurRadius: 12)] 
                                : []
                            ),
                            child: GlowAvatar(user: widget.userModel, radius: 24),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isGlobalSelected 
                                    ? "Hola, ${widget.userModel.displayName?.split(' ')[0] ?? 'Socio'}"
                                    : (selectedProfile?.businessName ?? "Tienda"),
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, fontSize: 18),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                isGlobalSelected ? "Vista Global" : "Gestionando tienda",
                                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            widget.userModel.planType.toUpperCase(),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.primary, letterSpacing: 1),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Profile Selector
                    SizedBox(
                      height: 55,
                      child: Row(
                        children: [
                          Expanded(
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: profilesList.length + 1, 
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                if (index == profilesList.length) {
                                  return _AddStoreButtonCompact(isDark: isDark, onTap: () => _handleOnAddStoreTap(context));
                                }
                                final profile = profilesList[index];
                                final isSelected = selectedProfileId == profile.id;
                                return _StoreItemCompact(
                                  profile: profile, 
                                  isSelected: isSelected, 
                                  isDark: isDark,
                                  onTap: () {
                                    dashboardContext.selectProfile(profile);
                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Divider(color: theme.dividerColor.withValues(alpha: 0.1), height: 1),
                    const SizedBox(height: 24),

                    // Operative Dashboard
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          // Left Panel: Hexagons
                          Expanded(
                            flex: 55,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _HexagonMetric(icon: Icons.visibility, label: "VISITAS", value: "${metricsModel.visitCount}", color: const Color(0xFF29B6F6), isDark: isDark),
                                    _HexagonMetric(icon: Icons.bolt, label: "LEADS", value: "${metricsModel.leadCount}", color: const Color(0xFFFFA726), isDark: isDark),
                                    _HexagonMetric(icon: Icons.star_rounded, label: "RATING", value: "4.8", color: const Color(0xFF66BB6A), isDark: isDark),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          Container(
                            width: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                colors: [Colors.transparent, theme.dividerColor.withValues(alpha: 0.3), Colors.transparent]
                              )
                            ),
                          ),

                          // Right Panel: Live Carousel (Interactive)
                          Expanded(
                            flex: 45,
                            child: Container(
                              height: 130, 
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
                              ),
                              child: Stack(
                                children: [
                                  PageView(
                                    controller: _pageController,
                                    onPageChanged: (index) => setState(() => _currentPage = index),
                                    children: [
                                      // --- SLIDES CON NAVEGACIÓN ---
                                      _SalesSlide(isDark: isDark, user: widget.userModel),
                                      _FinanceSlide(isDark: isDark, colorScheme: colorScheme),
                                      _StockSlide(isDark: isDark),
                                      _AgendaSlide(isDark: isDark, colorScheme: colorScheme, user: widget.userModel),
                                    ],
                                  ),
                                  Positioned(
                                    bottom: 8, left: 0, right: 0,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(4, (index) => AnimatedContainer(
                                        duration: const Duration(milliseconds: 300), 
                                        margin: const EdgeInsets.symmetric(horizontal: 2), 
                                        height: 3, 
                                        width: _currentPage == index ? 10 : 3, 
                                        decoration: BoxDecoration(
                                          color: _currentPage == index ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.2), 
                                          borderRadius: BorderRadius.circular(2)
                                        )
                                      )),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SUB-WIDGETS COMPACTOS
// =============================================================================

class _StoreItemCompact extends StatelessWidget {
  final ProviderProfileModel profile;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _StoreItemCompact({required this.profile, required this.isSelected, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 55, height: 55,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1
          )
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: profile.logoUrl.isNotEmpty
              ? Image.network(
                  profile.logoUrl, 
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.store, size: 24, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                )
              : Icon(Icons.store, size: 24, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}

class _AddStoreButtonCompact extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _AddStoreButtonCompact({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 55, height: 55,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2), style: BorderStyle.solid),
        ),
        child: const Icon(Icons.add, size: 24),
      ),
    );
  }
}

// =============================================================================
// HEXAGONOS Y SLIDES (AHORA INTERACTIVOS)
// =============================================================================

class _HexagonMetric extends StatelessWidget {
  final IconData icon; final String label; final String value; final Color color; final bool isDark;
  const _HexagonMetric({required this.icon, required this.label, required this.value, required this.color, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 42, height: 48, child: Stack(alignment: Alignment.center, children: [
              ClipPath(clipper: _HexagonClipper(), child: Container(color: color.withValues(alpha: 0.15))),
              CustomPaint(size: const Size(42, 48), painter: _HexagonPainter(color: color.withValues(alpha: 0.5))),
              Icon(icon, color: color, size: 18),
            ])),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: isDark ? Colors.white54 : Colors.black45, letterSpacing: 0.5)),
      ]);
  }
}

// --- SLIDE 1: VENTAS (Tap para ir a POS) ---
class _SalesSlide extends ConsumerWidget {
  final bool isDark; 
  final UserModel? user; // Opcional si necesitas user para navegar
  const _SalesSlide({required this.isDark, this.user});
  
  @override 
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesStreamProvider);
    final color = const Color(0xFF00E676);
    return InkWell(
      onTap: () {
         // Navegar a Ventas/POS
         Navigator.push(context, MaterialPageRoute(builder: (_) => const PosScreen()));
      },
      borderRadius: BorderRadius.circular(20),
      child: salesAsync.when(
        loading: () => const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))), 
        error: (_,__) => const SizedBox(), 
        data: (orders) {
          final now = DateTime.now();
          final todayTotal = orders.where((o) { final d = o.createdAt.toDate(); return d.year == now.year && d.month == now.month && d.day == now.day; }).fold(0.0, (sum, item) => sum + item.total);
          final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);
          return _GenericSlideLayout(icon: Icons.point_of_sale, iconColor: color, title: "VENTAS HOY", content: Text(currencyFormat.format(todayTotal), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: -0.5)), subContent: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.trending_up, size: 12, color: color), const SizedBox(width: 4), Text("En vivo", style: TextStyle(fontSize: 9, color: color))]), isDark: isDark);
        }
      ),
    );
  }
}

// --- SLIDE 2: FINANZAS (Tap para ir a Finanzas) ---
class _FinanceSlide extends ConsumerWidget {
  final bool isDark; final ColorScheme colorScheme; 
  const _FinanceSlide({required this.isDark, required this.colorScheme});
  
  @override 
  Widget build(BuildContext context, WidgetRef ref) {
    final financeAsync = ref.watch(financialSummaryProvider);
    return InkWell(
      onTap: () {
         Navigator.push(context, MaterialPageRoute(builder: (_) => const AdvancedFinanceScreen()));
      },
      borderRadius: BorderRadius.circular(20),
      child: financeAsync.when(
        loading: () => const SizedBox(), 
        error: (_,__) => const SizedBox(), 
        data: (summary) {
          final bool isHealthy = summary.ingresosNetos > 0;
          final color = isHealthy ? const Color(0xFF00B0FF) : const Color(0xFFFF9100);
          return _GenericSlideLayout(icon: isHealthy ? Icons.thumb_up : Icons.warning, iconColor: color, title: "FINANZAS", content: Text(isHealthy ? "SANAS" : "REVISAR", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)), subContent: Text("Estado actual", style: TextStyle(fontSize: 9, color: isDark?Colors.white60:Colors.black54)), isDark: isDark);
        }
      ),
    );
  }
}

// --- SLIDE 3: STOCK (Tap para ir a Inventario) ---
class _StockSlide extends ConsumerWidget {
  final bool isDark; 
  const _StockSlide({required this.isDark});
  
  @override 
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);
    return InkWell(
      onTap: () {
         Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen()));
      },
      borderRadius: BorderRadius.circular(20),
      child: productsAsync.when(
        loading: () => const SizedBox(), 
        error: (_,__) => const SizedBox(), 
        data: (products) {
          final alertCount = products.where((p) => p.isLowStock || p.isOutOfStock).length;
          final color = alertCount > 0 ? const Color(0xFFFF3D00) : const Color(0xFF76FF03);
          return _GenericSlideLayout(icon: Icons.inventory_2, iconColor: color, title: "STOCK", content: Text(alertCount > 0 ? "$alertCount" : "OK", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)), subContent: Text(alertCount > 0 ? "Alertas" : "Óptimo", style: TextStyle(fontSize: 9, color: isDark?Colors.white60:Colors.black54)), isDark: isDark);
        }
      ),
    );
  }
}

// --- SLIDE 4: AGENDA (Tap para ir a Agenda) ---
class _AgendaSlide extends ConsumerWidget {
  final bool isDark; final ColorScheme colorScheme; final UserModel? user;
  const _AgendaSlide({required this.isDark, required this.colorScheme, this.user});
  
  @override 
  Widget build(BuildContext context, WidgetRef ref) {
    final agendaAsync = ref.watch(nextAppointmentProvider);
    final color = const Color(0xFFD500F9);
    return InkWell(
      onTap: () {
         if (user != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => AgendaScreen(user: user!)));
         }
      },
      borderRadius: BorderRadius.circular(20),
      child: agendaAsync.when(
        loading: () => const SizedBox(), 
        error: (_,__) => const SizedBox(), 
        data: (event) {
          final bool hasEvent = event != null;
          return _GenericSlideLayout(icon: Icons.calendar_month, iconColor: color, title: "AGENDA", content: hasEvent ? Text(DateFormat('HH:mm').format(event.startTime), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)) : const Text("LIBRE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), subContent: hasEvent ? Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9, color: color)) : const Text("Sin citas", style: TextStyle(fontSize: 9)), isDark: isDark);
        }
      ),
    );
  }
}

class _GenericSlideLayout extends StatelessWidget {
  final IconData icon; final Color iconColor; final String title; final Widget content; final Widget subContent; final bool isDark;
  const _GenericSlideLayout({required this.icon, required this.iconColor, required this.title, required this.content, required this.subContent, required this.isDark});
  @override Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 12, color: iconColor), const SizedBox(width: 4), Text(title, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: isDark ? Colors.white54 : Colors.black45, letterSpacing: 1))]), const Spacer(), content, const SizedBox(height: 4), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: subContent), const Spacer()]));
  }
}

class _HexagonClipper extends CustomClipper<Path> {
  @override Path getClip(Size size) { final path = Path(); final w = size.width; final h = size.height; final hw = w / 2; path.moveTo(hw, 0); path.lineTo(w, h * 0.25); path.lineTo(w, h * 0.75); path.lineTo(hw, h); path.lineTo(0, h * 0.75); path.lineTo(0, h * 0.25); path.close(); return path; }
  @override bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HexagonPainter extends CustomPainter {
  final Color color; _HexagonPainter({required this.color});
  @override void paint(Canvas canvas, Size size) { final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5; final path = Path(); final w = size.width; final h = size.height; final hw = w / 2; path.moveTo(hw, 0); path.lineTo(w, h * 0.25); path.lineTo(w, h * 0.75); path.lineTo(hw, h); path.lineTo(0, h * 0.75); path.lineTo(0, h * 0.25); path.close(); canvas.drawPath(path, paint); }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}