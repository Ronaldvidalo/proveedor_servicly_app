// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 26/10/2025
// Style: Cyber Glow (Adaptive Light/Dark)
// QA FIX: Adaptive Colors using ThemeProvider logic
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:showcaseview/showcaseview.dart'; 

import '../../data/models/cobro_model.dart';
import '../../data/models/gasto_model.dart';
import '../../data/models/presupuesto_financiero_model.dart';
import '../providers/finance_providers.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/add_budget_modal.dart';

/// Pestaña 3: Análisis y Proyección
class AnalysisTab extends ConsumerWidget {
  final GlobalKey analysisChartKey;
  
  AnalysisTab({
    super.key,
    required this.analysisChartKey,
  });

  // Formateadores
  final _standardFormatter = NumberFormat.currency(
    locale: 'es_CL',
    symbol: '\$',
    decimalDigits: 0,
  );

  final _compactFormatter = NumberFormat.compactCurrency(
    locale: 'es_US', 
    symbol: '\$',
    decimalDigits: 1, 
  );

  String _formatSmartMoney(double amount) {
    if (amount.abs() >= 1000000) {
      return _compactFormatter.format(amount);
    }
    return _standardFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gastosAsync = ref.watch(gastosStreamProvider);
    final cobrosAsync = ref.watch(cobrosStreamProvider);
    final presupuestosAsync = ref.watch(presupuestosStreamProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (gastosAsync.isLoading || cobrosAsync.isLoading || presupuestosAsync.isLoading) {
      return Center(child: CircularProgressIndicator(color: colorScheme.primary));
    }

    if (gastosAsync.hasError || cobrosAsync.hasError || presupuestosAsync.hasError) {
      return Center(child: Text(
        "Error al cargar datos",
        style: TextStyle(color: colorScheme.error),
      ));
    }

    final gastos = gastosAsync.value!;
    final cobros = cobrosAsync.value!;
    final presupuestos = presupuestosAsync.value!;

    return LayoutBuilder(
      builder: (context, constraints) {
        // --- WEB LAYOUT (> 900px) ---
        if (constraints.maxWidth > 900) {
          return _buildWebDashboard(context, cobros, gastos, presupuestos, theme);
        }
        
        // --- MOBILE LAYOUT ---
        return _buildMobileLayout(context, cobros, gastos, presupuestos, theme);
      },
    );
  }

  // ===========================================================================
  // 💻 WEB LAYOUT: DASHBOARD ANALÍTICO (Full Screen)
  // ===========================================================================
  Widget _buildWebDashboard(BuildContext context, List<CobroModel> cobros, List<GastoModel> gastos, List<PresupuestoFinancieroModel> presupuestos, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          // 1. ZONA SUPERIOR: Gráficos (60% Alto)
          Expanded(
            flex: 6,
            child: Row(
              children: [
                // Gráfico Principal (Ingresos vs Gastos)
                Expanded(
                  flex: 6,
                  child: _WebCard(
                    theme: theme,
                    title: "Tendencias de Crecimiento",
                    child: Showcase(
                      key: analysisChartKey,
                      title: 'Análisis Comparativo',
                      description: 'Compara ingresos vs gastos.',
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildIngresoVsGastoChart(context, cobros, gastos, theme),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Gráfico Secundario (Facturación Anual)
                Expanded(
                  flex: 4,
                  child: _WebCard(
                    theme: theme,
                    title: "Facturación Anual",
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildFacturacion12MesesChart(context, cobros, theme),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          // 2. ZONA INFERIOR: Presupuestos (40% Alto)
          Expanded(
            flex: 4,
            child: _WebCard(
              theme: theme,
              title: "Gestión de Presupuestos",
              padding: EdgeInsets.zero, 
              headerAction: IconButton(
                icon: Icon(Icons.add_circle, color: theme.colorScheme.primary, size: 28), 
                onPressed: () => _showAddBudgetModal(context, theme),
                tooltip: "Añadir Presupuesto",
              ),
              child: _buildPresupuestosList(context, presupuestos, gastos, theme, isWeb: true),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 📱 MOBILE LAYOUT
  // ===========================================================================
  Widget _buildMobileLayout(BuildContext context, List<CobroModel> cobros, List<GastoModel> gastos, List<PresupuestoFinancieroModel> presupuestos, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tendencias de Crecimiento",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            
            Showcase(
              key: analysisChartKey,
              title: 'Análisis Comparativo',
              description: 'Compara tus ingresos (verde) contra tus gastos (rojo) mes a mes.',
              child: SizedBox(
                height: 250,
                child: _buildIngresoVsGastoChart(context, cobros, gastos, theme),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 250,
              child: _buildFacturacion12MesesChart(context, cobros, theme),
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Presupuestos",
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, color: colorScheme.primary, size: 28), 
                  onPressed: () => _showAddBudgetModal(context, theme),
                ),
              ],
            ),
            const SizedBox(height: 8),

            _buildPresupuestosList(context, presupuestos, gastos, theme, isWeb: false),
          ],
        ),
      ),
    );
  }

  // --- Widgets Comunes ---

  Widget _buildPresupuestosList(BuildContext context, 
      List<PresupuestoFinancieroModel> presupuestos, List<GastoModel> gastos, ThemeData theme, {required bool isWeb}) {
    
    final String mesActual = DateFormat('yyyy-MM').format(DateTime.now());
    final presupuestosMesActual = presupuestos.where((p) => p.mes == mesActual && p.activo).toList();

    if (presupuestosMesActual.isEmpty) {
      return Center(
        child: Text(
          "No has definido presupuestos para este mes.",
          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 15),
        ),
      );
    }

    if (isWeb) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 400,
          childAspectRatio: 2.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: presupuestosMesActual.length,
        itemBuilder: (context, index) => _buildBudgetItem(presupuestosMesActual[index], gastos),
      );
    }

    return ListView.builder(
      itemCount: presupuestosMesActual.length,
      shrinkWrap: true, 
      physics: const NeverScrollableScrollPhysics(), 
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: _buildBudgetItem(presupuestosMesActual[index], gastos),
      ),
    );
  }

  Widget _buildBudgetItem(PresupuestoFinancieroModel presupuesto, List<GastoModel> gastos) {
    final double gastoActual = gastos
        .where((g) =>
            g.categoria == presupuesto.categoria &&
            DateFormat('yyyy-MM').format(g.fecha) == presupuesto.mes)
        .fold(0.0, (sum, g) => sum + g.monto);

    return BudgetProgressCard(
      presupuesto: presupuesto,
      gastoActual: gastoActual,
    );
  }

  void _showAddBudgetModal(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor, // Uso de tema dinámico
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const AddBudgetModal(), 
      ),
    );
  }

  // --- GRÁFICOS ---

  Widget _buildIngresoVsGastoChart(BuildContext context, List<CobroModel> cobros, List<GastoModel> gastos, ThemeData theme) {
    final now = DateTime.now();
    final Map<int, double> ingresosPorMes = {};
    final Map<int, double> gastosPorMes = {};
    
    final colorScheme = theme.colorScheme;
    final successColor = colorScheme.secondary; // Uso de color secundario (o custom)
    final errorColor = colorScheme.error;

    // Lógica de cálculo (sin cambios)
    final cobrosPagados = cobros.where((c) => c.estado == 'COBRADO');
    for (final cobro in cobrosPagados) {
      if (cobro.fechaCobro == null) continue;
      final int monthDiff = (now.year - cobro.fechaCobro!.year) * 12 + (now.month - cobro.fechaCobro!.month);
      if (monthDiff >= 0 && monthDiff < 6) {
        ingresosPorMes.update(monthDiff, (v) => v + cobro.monto, ifAbsent: () => cobro.monto);
      }
    }
    for (final gasto in gastos) {
      final int monthDiff = (now.year - gasto.fecha.year) * 12 + (now.month - gasto.fecha.month);
      if (monthDiff >= 0 && monthDiff < 6) {
        gastosPorMes.update(monthDiff, (v) => v + gasto.monto, ifAbsent: () => gasto.monto);
      }
    }

    final List<BarChartGroupData> barGroups = [];
    final List<String> meses = [];
    double maxY = 0.0; 

    for (int i = 0; i < 6; i++) {
      final mes = DateTime(now.year, now.month - i, 1);
      meses.add(DateFormat('MMM', 'es_ES').format(mes).toUpperCase());

      final double ingreso = ingresosPorMes[i] ?? 0.0;
      final double gasto = gastosPorMes[i] ?? 0.0;
      if (ingreso > maxY) maxY = ingreso;
      if (gasto > maxY) maxY = gasto;
      
      barGroups.add(BarChartGroupData(
        x: 5 - i, 
        barRods: [
          BarChartRodData(
            toY: ingreso, 
            // Color fijo verde o dinámico según prefieras, aquí uso un verde estático visible en ambos modos
            color: const Color(0xFF00C853), 
            width: 12, 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4))
          ),
          BarChartRodData(
            toY: gasto, 
            color: errorColor, 
            width: 12, 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4))
          ),
        ],
      ));
    }
    final reversedMeses = meses.reversed.toList();
    if (maxY == 0) maxY = 1; 

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => theme.cardColor.withValues(alpha: 0.9), // Fondo del tooltip según tema
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final String label = (rodIndex == 0) ? 'Ingreso' : 'Gasto';
              return BarTooltipItem(
                '$label\n${_formatSmartMoney(rod.toY)}',
                TextStyle(color: rodIndex == 0 ? const Color(0xFF00C853) : errorColor, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(), topTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final int index = val.toInt();
                if (index >= 0 && index < reversedMeses.length) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide, 
                    child: Text(
                      reversedMeses[index], 
                      style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withValues(alpha: 0.7))
                    )
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: const AxisTitles(), 
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true, 
          drawVerticalLine: false, 
          horizontalInterval: maxY / 4, 
          getDrawingHorizontalLine: (_) => FlLine(color: theme.dividerColor.withValues(alpha: 0.1))
        ),
        barGroups: barGroups.reversed.toList(), 
      ),
    );
  }

  Widget _buildFacturacion12MesesChart(BuildContext context, List<CobroModel> cobros, ThemeData theme) {
    final now = DateTime.now();
    final Map<int, double> ingresosPorMes = {};
    final List<String> meses = [];
    final colorScheme = theme.colorScheme;

    final cobrosPagados = cobros.where((c) => c.estado == 'COBRADO');
    for (final cobro in cobrosPagados) {
      if (cobro.fechaCobro == null) continue;
      final int monthDiff = (now.year - cobro.fechaCobro!.year) * 12 + (now.month - cobro.fechaCobro!.month);
      if (monthDiff >= 0 && monthDiff < 12) {
        ingresosPorMes.update(monthDiff, (v) => v + cobro.monto, ifAbsent: () => cobro.monto);
      }
    }

    final List<FlSpot> spots = [];
    double maxY = 0.0;
    for (int i = 0; i < 12; i++) {
      final mes = DateTime(now.year, now.month - i, 1);
      meses.add(DateFormat('MMM', 'es_ES').format(mes).toUpperCase());
      final double ingreso = ingresosPorMes[i] ?? 0.0;
      if (ingreso > maxY) maxY = ingreso;
      spots.add(FlSpot(11 - i.toDouble(), ingreso));
    }
    final reversedMeses = meses.reversed.toList();
    if (maxY == 0.0) maxY = 1.0; 

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true, 
          drawVerticalLine: false, 
          horizontalInterval: maxY / 4, 
          getDrawingHorizontalLine: (_) => FlLine(color: theme.dividerColor.withValues(alpha: 0.1))
        ),
        titlesData: FlTitlesData(
          show: true, rightTitles: const AxisTitles(), topTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final int index = val.toInt();
                if (index % 2 != 0) return const Text(''); 
                if (index >= 0 && index < reversedMeses.length) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide, 
                    child: Text(
                      reversedMeses[index], 
                      style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withValues(alpha: 0.7))
                    )
                  );
                }
                return const Text('');
              },
              reservedSize: 30, interval: 1,
            ),
          ),
          leftTitles: const AxisTitles(),
        ),
        borderData: FlBorderData(show: false),
        minX: 0, maxX: 11, minY: 0, maxY: maxY * 1.2, 
        lineBarsData: [
          LineChartBarData(
            spots: spots.reversed.toList(),
            isCurved: true,
            color: colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true, 
              color: colorScheme.primary.withValues(alpha: 0.1) // Gradiente suave
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => theme.cardColor.withValues(alpha: 0.9),
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) => LineTooltipItem(
              _formatSmartMoney(spot.y), 
              TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)
            )).toList(),
          ),
        ),
      ),
    );
  }
}

// Widget auxiliar para tarjetas en Web
class _WebCard extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Widget? headerAction;

  const _WebCard({required this.theme, required this.title, required this.child, this.padding, this.headerAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor, // Uso de tema dinámico
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), // Sombra sutil en modo claro
            blurRadius: 10, 
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              if (headerAction != null) headerAction!,
            ],
          ),
          const SizedBox(height: 24),
          Expanded(child: padding != null ? Padding(padding: padding!, child: child) : child),
        ],
      ),
    );
  }
}