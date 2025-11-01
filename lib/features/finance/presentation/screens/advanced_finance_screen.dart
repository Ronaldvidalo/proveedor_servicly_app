// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 26/10/2025
// Style: Cyber Glow
// This screen was refactored to align with the "Cyber Glow" design philosophy.
// The Scaffold, AppBar, and TabBar are now styled with the app's dark theme
// and neon accents for a cohesive user experience.
// Screen title updated to "Focus Financiero" for a more modern feel.
// ---------------------------------

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
    
    // --- Paleta "Cyber Glow" ---
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: backgroundColor, // Fondo oscuro
        appBar: AppBar(
          title: const Text('Focus Financiero'), // --- CAMBIO DE NOMBRE ---
          backgroundColor: backgroundColor, // Fondo de AppBar
          foregroundColor: Colors.white, // Color de texto y botón de retroceso
          elevation: 0, // Sin sombra, para un look moderno
          bottom: TabBar(
            // --- Estilo Cyber Glow ---
            indicatorColor: accentColor, // Línea indicadora neón
            labelColor: accentColor, // Color de la pestaña activa
            unselectedLabelColor: Colors.white60, // Color de pestañas inactivas
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
            tabs: const [
              // --- Iconos Rediseñados ---
              Tab(icon: Icon(Icons.dashboard_rounded), text: 'Resumen'),
              Tab(icon: Icon(Icons.payment_rounded), text: 'Gastos'),
              Tab(icon: Icon(Icons.analytics_rounded), text: 'Análisis'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // El 'const' se quita si los widgets hijos no son const
            SummaryTab(),
            ExpensesTab(),
            AnalysisTab(),
          ],
        ),
      ),
    );
  }
}

