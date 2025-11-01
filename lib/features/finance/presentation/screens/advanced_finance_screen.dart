// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 26/10/2025
// Style: Cyber Glow
// This screen was refactored to align with the "Cyber Glow" design.
// --- TOUR VIRTUAL (ShowCaseView) AÑADIDO ---
// Se ha añadido un tour virtual interactivo para guiar al usuario
// la primera vez que abre el módulo, con un botón para repetirlo.
// CORRECCIÓN: Se usa 'onStart' (en lugar de 'onBeforeShowCase')
// para manejar la navegación entre pestañas.
// CORRECCIÓN 2: Corregida la sintaxis del 'builder' de ShowCaseWidget.
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
  final GlobalKey _keyAnalysisChart = GlobalKey(); // Key para la pestaña de análisis

  // Clave para el widget ShowCase
  BuildContext? _showCaseContext;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // --- Lógica del Tour ---
    // Comprueba si es la primera vez que se abre esta pantalla.
    _checkIfFirstTime();
  }

  /// Comprueba SharedPreferences para ver si el tour ya se ha mostrado.
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

  /// Inicia el tour virtual
  void _startTour() {
    if (_showCaseContext != null) {
      ShowCaseWidget.of(_showCaseContext!).startShowCase([
        _keyResumenTab,     // 1. Pestaña Resumen
        _keyKpiCards,       // 2. Tarjetas KPI
        _keyIncomeChart,    // 3. Gráfico de Ingresos
        _keyGastosTab,      // 4. Pestaña Gastos (cambia de pestaña)
        _keyAddExpenseButton, // 5. Botón Añadir Gasto
        _keyAnalisisTab,    // 6. Pestaña Análisis (cambia de pestaña)
        _keyAnalysisChart,  // 7. Gráfico en Pestaña Análisis
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Paleta "Cyber Glow" ---
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);

    return ShowCaseWidget(
      onFinish: () {
         // Asegurarse de volver a la primera pestaña al finalizar
         _tabController.animateTo(0);
      },
      // --- Lógica de navegación del Tour ---
      onStart: (index, globalKey) {
        if (globalKey == _keyGastosTab || globalKey == _keyAddExpenseButton) {
          _tabController.animateTo(1); // Ir a pestaña Gastos
        } else if (globalKey == _keyAnalisisTab || globalKey == _keyAnalysisChart) {
          _tabController.animateTo(2); // Ir a pestaña Análisis
        } else if (globalKey == _keyResumenTab || globalKey == _keyKpiCards || globalKey == _keyIncomeChart) {
          _tabController.animateTo(0); // Ir a pestaña Resumen
        }
      },
      // --- CORRECCIÓN: 'builder' ahora es una función ---
      builder: (context) { 
          _showCaseContext = context; // Guardar el context para _startTour
          return Scaffold(
            backgroundColor: backgroundColor, 
            appBar: AppBar(
              title: const Text('Copiloto Financiero'),
              backgroundColor: backgroundColor, 
              foregroundColor: Colors.white, 
              elevation: 0, 
              actions: [
                // --- Botón para repetir el tour ---
                IconButton(
                  icon: const Icon(Icons.help_outline_rounded),
                  tooltip: 'Iniciar Tour',
                  onPressed: _startTour, // Llama al tour manualmente
                ),
              ],
              bottom: TabBar(
                controller: _tabController, // Usar el controlador
                indicatorColor: accentColor, 
                labelColor: accentColor, 
                unselectedLabelColor: Colors.white60, 
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
                    description: 'Registra y visualiza todos tus gastos en detalle. Toca el gráfico para filtrar la lista.',
                    child: const Tab(icon: Icon(Icons.payment_rounded), text: 'Gastos'),
                  ),
                  Showcase(
                    key: _keyAnalisisTab,
                    title: 'Pestaña Análisis',
                    description: 'Compara tus ingresos, gastos y presupuestos a lo largo del tiempo.',
                    child: const Tab(icon: Icon(Icons.analytics_rounded), text: 'Análisis'),
                  ),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController, // Usar el controlador
              children: [
                // --- 4. Pasar las GlobalKeys a las pestañas hijas ---
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

