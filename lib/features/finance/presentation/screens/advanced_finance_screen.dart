// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 26/10/2025
// Style: Cyber Glow (Adaptive Light/Dark)
// QA FIX 26/11/2025:
// 1. Refactorización completa para soportar ThemeService (Modo Claro/Oscuro).
// 2. Lógica de Tour Virtual (ShowCase) mantenida y verificada.
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tabs/summary_tab.dart';
import '../tabs/expenses_tab.dart';
import '../tabs/analysis_tab.dart';

/// La pantalla principal del módulo de finanzas que contiene el TabBar
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

  // Clave para el contexto del ShowCase
  BuildContext? _showCaseContext;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Comprueba si es la primera vez que se abre esta pantalla.
    _checkIfFirstTime();
  }

  Future<void> _checkIfFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenTour = prefs.getBool('hasSeenFinanceTour_v1') ?? false;

    if (!hasSeenTour) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTour();
        prefs.setBool('hasSeenFinanceTour_v1', true);
      });
    }
  }

  void _startTour() {
    if (_showCaseContext != null) {
      ShowCaseWidget.of(_showCaseContext!).startShowCase([
        _keyResumenTab,     // 1. Pestaña Resumen
        _keyKpiCards,       // 2. Tarjetas KPI
        _keyIncomeChart,    // 3. Gráfico de Ingresos
        _keyGastosTab,      // 4. Pestaña Gastos
        _keyAddExpenseButton, // 5. Botón Añadir
        _keyAnalisisTab,    // 6. Pestaña Análisis
        _keyAnalysisChart,  // 7. Gráfico Análisis
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    // QA FIX: Obtener tema del contexto (Adiós colores hardcoded)
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Colores dinámicos
    final backgroundColor = theme.scaffoldBackgroundColor;
    final primaryColor = colorScheme.primary;
    final onSurface = colorScheme.onSurface;

    return ShowCaseWidget(
      onFinish: () {
         _tabController.animateTo(0);
      },
      // Lógica de navegación del Tour
      onStart: (index, globalKey) {
        if (globalKey == _keyGastosTab || globalKey == _keyAddExpenseButton) {
          _tabController.animateTo(1); // Ir a Gastos
        } else if (globalKey == _keyAnalisisTab || globalKey == _keyAnalysisChart) {
          _tabController.animateTo(2); // Ir a Análisis
        } else if (globalKey == _keyResumenTab || globalKey == _keyKpiCards || globalKey == _keyIncomeChart) {
          _tabController.animateTo(0); // Ir a Resumen
        }
      },
      builder: (context) { 
          _showCaseContext = context; 
          return Scaffold(
            // Fondo dinámico
            backgroundColor: backgroundColor, 
            appBar: AppBar(
              title: const Text('Copiloto Financiero'),
              backgroundColor: backgroundColor, 
              // Texto negro en claro, blanco en oscuro
              foregroundColor: onSurface, 
              elevation: 0, 
              actions: [
                IconButton(
                  icon: const Icon(Icons.help_outline_rounded),
                  tooltip: 'Iniciar Tour',
                  // Icono visible en ambos modos
                  color: onSurface.withValues(alpha: 0.7),
                  onPressed: _startTour, 
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                // Indicador del color de la marca (Neón)
                indicatorColor: primaryColor, 
                labelColor: primaryColor, 
                // Color inactivo visible
                unselectedLabelColor: onSurface.withValues(alpha: 0.5), 
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
                tabs: [
                  Showcase(
                    key: _keyResumenTab,
                    title: 'Pestaña Resumen',
                    description: 'Aquí encontrarás un resumen de tus métricas clave y transacciones recientes.',
                    child: const Tab(icon: Icon(Icons.dashboard_rounded), text: 'Resumen'),
                  ),
                  Showcase(
                    key: _keyGastosTab,
                    title: 'Pestaña Gastos',
                    description: 'Registra y visualiza todos tus gastos en detalle.',
                    child: const Tab(icon: Icon(Icons.payment_rounded), text: 'Gastos'),
                  ),
                  Showcase(
                    key: _keyAnalisisTab,
                    title: 'Pestaña Análisis',
                    description: 'Compara tus ingresos y gastos a lo largo del tiempo.',
                    child: const Tab(icon: Icon(Icons.analytics_rounded), text: 'Análisis'),
                  ),
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
      },
    );
  }
}