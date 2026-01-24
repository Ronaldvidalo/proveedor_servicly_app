import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Imports de Tabs ---
import '../tabs/summary_tab.dart';
import '../tabs/expenses_tab.dart';
import '../tabs/analysis_tab.dart';

// --- Import del Sidebar ---
import 'package:proveedor_servicly_app/widgets/navigation/servicly_sidebar.dart';

class AdvancedFinanceScreen extends ConsumerStatefulWidget {
  const AdvancedFinanceScreen({super.key});

  @override
  ConsumerState<AdvancedFinanceScreen> createState() => _AdvancedFinanceScreenState();
}

class _AdvancedFinanceScreenState extends ConsumerState<AdvancedFinanceScreen> with TickerProviderStateMixin {
  
  late TabController _tabController;
  
  // --- Claves Globales para el Tour ---
  final GlobalKey _keyResumenTab = GlobalKey();
  final GlobalKey _keyGastosTab = GlobalKey();
  final GlobalKey _keyAnalisisTab = GlobalKey();
  final GlobalKey _keyKpiCards = GlobalKey();
  final GlobalKey _keyIncomeChart = GlobalKey();
  final GlobalKey _keyAddExpenseButton = GlobalKey();
  final GlobalKey _keyAnalysisChart = GlobalKey();

  BuildContext? _showCaseContext;
  int _sidebarIndex = 2; // Índice de Finanzas

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkIfFirstTime();
  }

  Future<void> _checkIfFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenTour = prefs.getBool('hasSeenFinanceTour_v2') ?? false; // Clave v2 para reiniciar si quieres

    if (!hasSeenTour) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTour();
        prefs.setBool('hasSeenFinanceTour_v2', true);
      });
    }
  }

  void _startTour() {
    if (_showCaseContext != null) {
      ShowCaseWidget.of(_showCaseContext!).startShowCase([
        _keyResumenTab,
        _keyKpiCards,
        _keyIncomeChart,
        _keyGastosTab,
        _keyAddExpenseButton,
        _keyAnalisisTab,
      ]);
    }
  }

  void _onSidebarDestinationSelected(int index) {
    setState(() => _sidebarIndex = index);
    // Aquí iría tu lógica de navegación (go_router, Navigator, etc.)
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final primaryColor = colorScheme.primary;
    final onSurface = colorScheme.onSurface;

    return ShowCaseWidget(
      onFinish: () => _tabController.animateTo(0),
      builder: (context) { 
        _showCaseContext = context; 
        
        return LayoutBuilder(
          builder: (context, constraints) {
            // Detección de Web (> 900px)
            final isWeb = constraints.maxWidth > 900;

            if (isWeb) {
              // ==========================================
              // 💻 DISEÑO WEB (Sidebar + Full Width Content)
              // ==========================================
              return Scaffold(
                backgroundColor: backgroundColor,
                body: Row(
                  children: [
                    // 1. Sidebar Fijo a la Izquierda
                    ServiclySidebar(
                      selectedIndex: _sidebarIndex,
                      onDestinationSelected: _onSidebarDestinationSelected,
                    ),
                    // 2. Contenido Principal (Ocupa todo el resto)
                    Expanded(
                      child: Scaffold(
                        backgroundColor: backgroundColor,
                        // AppBar simplificado para Web
                        appBar: AppBar(
                          title: const Text('Copiloto Financiero'),
                          backgroundColor: backgroundColor,
                          elevation: 0,
                          centerTitle: false, // Alineado a la izquierda
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.help_outline_rounded),
                              tooltip: 'Ver Tutorial',
                              onPressed: _startTour,
                            ),
                            const SizedBox(width: 16),
                          ],
                          bottom: PreferredSize(
                            preferredSize: const Size.fromHeight(50),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TabBar(
                                controller: _tabController,
                                isScrollable: true, // Tabs compactos a la izquierda
                                tabAlignment: TabAlignment.start,
                                indicatorColor: primaryColor,
                                labelColor: primaryColor,
                                unselectedLabelColor: onSurface.withValues(alpha: 0.5),
                                tabs: [
                                  _buildTab(_keyResumenTab, Icons.dashboard_rounded, 'Resumen'),
                                  _buildTab(_keyGastosTab, Icons.payment_rounded, 'Gastos'),
                                  _buildTab(_keyAnalisisTab, Icons.analytics_rounded, 'Análisis'),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // El cuerpo ocupa el 100% del espacio restante
                        body: TabBarView(
                          controller: _tabController,
                          children: [
                            SummaryTab(
                              kpiCardsKey: _keyKpiCards,
                              incomeChartKey: _keyIncomeChart,
                            ),
                            ExpensesTab(
                              addExpenseButtonKey: _keyAddExpenseButton,
                            ),
                            AnalysisTab(
                              analysisChartKey: _keyAnalysisChart,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // ==========================================
              // 📱 DISEÑO MOBILE (Clásico)
              // ==========================================
              return Scaffold(
                backgroundColor: backgroundColor,
                appBar: AppBar(
                  title: const Text('Copiloto Financiero'),
                  backgroundColor: backgroundColor,
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.help_outline_rounded),
                      onPressed: _startTour,
                    ),
                  ],
                  bottom: TabBar(
                    controller: _tabController,
                    indicatorColor: primaryColor,
                    labelColor: primaryColor,
                    tabs: [
                      _buildTab(_keyResumenTab, Icons.dashboard_rounded, 'Resumen'),
                      _buildTab(_keyGastosTab, Icons.payment_rounded, 'Gastos'),
                      _buildTab(_keyAnalisisTab, Icons.analytics_rounded, 'Análisis'),
                    ],
                  ),
                ),
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    SummaryTab(
                      kpiCardsKey: _keyKpiCards,
                      incomeChartKey: _keyIncomeChart,
                    ),
                    ExpensesTab(
                      addExpenseButtonKey: _keyAddExpenseButton,
                    ),
                    AnalysisTab(
                      analysisChartKey: _keyAnalysisChart,
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

  Widget _buildTab(GlobalKey key, IconData icon, String text) {
    return Showcase(
      key: key,
      title: text,
      description: 'Accede a la sección de $text.',
      child: Tab(icon: Icon(icon), text: text),
    );
  }
}