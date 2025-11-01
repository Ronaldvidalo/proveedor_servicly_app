import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../tabs/summary_tab.dart';
import '../tabs/expenses_tab.dart';
import '../tabs/analysis_tab.dart';

/// La pantalla principal del módulo de finanzas que contiene el TabBar
class AdvancedFinanceScreen extends ConsumerWidget {
  const AdvancedFinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Copiloto Financiero'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Resumen'),
              Tab(icon: Icon(Icons.payment), text: 'Gastos'),
              Tab(icon: Icon(Icons.analytics), text: 'Análisis'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // *** CORRECCIÓN ***
            // Hemos quitado 'const' de las siguientes 3 líneas,
            // ya que sus constructores no son constantes.
            SummaryTab(),
            ExpensesTab(),
            AnalysisTab(),
          ],
        ),
      ),
    );
  }
}

