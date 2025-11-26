// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 26/10/2025
// Style: Cyber Glow
// QA FIX 26/11/2025: Implementación de Smart Currency Formatting
// para manejar "Big Numbers" (Trillones/Cuatrillones) sin romper la UI.
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

  // --- QA FIX: Formateador Estándar (para montos pequeños) ---
  final _standardFormatter = NumberFormat.currency(
    locale: 'es_CL',
    symbol: '\$',
    decimalDigits: 0,
  );

  // --- QA FIX: Formateador Compacto (para montos > 1 Millón) ---
  // Convierte 1.000.000 en "1M", 1.000.000.000 en "1B", etc.
  final _compactFormatter = NumberFormat.compactCurrency(
    locale: 'es_US', // Usamos US para que use K, M, B, T que son más cortos visualmente
    symbol: '\$',
    decimalDigits: 1, 
  );

  /// Helper para decidir qué formato usar dinámicamente
  String _formatSmartMoney(double amount) {
    if (amount.abs() >= 1000000) {
      return _compactFormatter.format(amount);
    }
    return _standardFormatter.format(amount);
  }

  // --- Paleta de Colores "Cyber Glow" ---
  static const Color accentColor = Color(0xFF00BFFF);
  static const Color surfaceColor = Color(0xFF2D2D5A);
  static const Color successColor = Color(0xFF00FF7F);
  static const Color errorColor = Colors.redAccent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gastosAsync = ref.watch(gastosStreamProvider);
    final cobrosAsync = ref.watch(cobrosStreamProvider);
    final presupuestosAsync = ref.watch(presupuestosStreamProvider);

    if (gastosAsync.isLoading || cobrosAsync.isLoading || presupuestosAsync.isLoading) {
      return const Center(child: CircularProgressIndicator(color: accentColor));
    }

    if (gastosAsync.hasError || cobrosAsync.hasError || presupuestosAsync.hasError) {
      return Center(child: Text(
        "Error al cargar datos: ${gastosAsync.error ?? cobrosAsync.error ?? presupuestosAsync.error}",
        style: const TextStyle(color: errorColor),
      ));
    }

    final gastos = gastosAsync.value!;
    final cobros = cobrosAsync.value!;
    final presupuestos = presupuestosAsync.value!;

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Sección 1: Gráficos de Tendencias ---
              Text(
                "Tendencias de Crecimiento",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white, 
                    ),
              ),
              const SizedBox(height: 16),
              
              // --- Gráfico 1: Envuelta con Showcase ---
              Showcase(
                key: analysisChartKey,
                title: 'Análisis Comparativo',
                description: 'Compara tus ingresos (verde) contra tus gastos (rojo) mes a mes.',
                child: SizedBox(
                  height: 250,
                  child: _buildIngresoVsGastoChart(context, cobros, gastos),
                ),
              ),
              const SizedBox(height: 24),

              // --- Gráfico 2: Facturación (12 Meses) ---
              SizedBox(
                height: 250,
                child: _buildFacturacion12MesesChart(context, cobros),
              ),
              const SizedBox(height: 32),

              // --- Sección 2: Gestión de Presupuestos ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Presupuestos de Gastos",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: accentColor, size: 28), 
                    onPressed: () {
                      _showAddBudgetModal(context);
                    },
                    tooltip: "Añadir Presupuesto",
                  ),
                ],
              ),
              const SizedBox(height: 8),

              _buildPresupuestosList(context, presupuestos, gastos),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la lista de tarjetas de progreso de presupuesto
  Widget _buildPresupuestosList(BuildContext context, 
      List<PresupuestoFinancieroModel> presupuestos, List<GastoModel> gastos) {
    
    final String mesActual = DateFormat('yyyy-MM').format(DateTime.now());
    final presupuestosMesActual = presupuestos.where((p) => p.mes == mesActual && p.activo).toList();

    if (presupuestosMesActual.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: surfaceColor.withAlpha(150),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            "No has definido presupuestos para este mes. \nToca el botón (+) para empezar.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: presupuestosMesActual.length,
      shrinkWrap: true, 
      physics: const NeverScrollableScrollPhysics(), 
      itemBuilder: (context, index) {
        final presupuesto = presupuestosMesActual[index];
        
        final double gastoActual = gastos
            .where((g) =>
                g.categoria == presupuesto.categoria &&
                DateFormat('yyyy-MM').format(g.fecha) == presupuesto.mes)
            .fold(0.0, (sum, g) => sum + g.monto);

        // NOTA DE QA: El widget BudgetProgressCard recibe el dato crudo.
        // Asegúrate de aplicar las correcciones visuales dentro de ese archivo también.
        return BudgetProgressCard(
          presupuesto: presupuesto,
          gastoActual: gastoActual,
        );
      },
    );
  }

  void _showAddBudgetModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceColor,
      barrierColor: Colors.black.withAlpha(128),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const AddBudgetModal(), 
      ),
    );
  }

  /// GRÁFICO 1: Comparativa Ingresos vs Gastos (Estilo Cyber Glow)
  Widget _buildIngresoVsGastoChart(BuildContext context, List<CobroModel> cobros, List<GastoModel> gastos) {
    final now = DateTime.now();
    final Map<int, double> ingresosPorMes = {};
    final Map<int, double> gastosPorMes = {};

    // 1. Calcular Ingresos
    final cobrosPagados = cobros.where((c) => c.estado == 'COBRADO');
    for (final cobro in cobrosPagados) {
      if (cobro.fechaCobro == null) continue;
      final int monthDiff = (now.year - cobro.fechaCobro!.year) * 12 + (now.month - cobro.fechaCobro!.month);
      if (monthDiff >= 0 && monthDiff < 6) {
        ingresosPorMes.update(monthDiff, (v) => v + cobro.monto, ifAbsent: () => cobro.monto);
      }
    }

    // 2. Calcular Gastos
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
            color: successColor, 
            width: 12,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: gasto,
            color: errorColor, 
            width: 12,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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
            getTooltipColor: (_) => surfaceColor.withAlpha(240),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final String label = (rodIndex == 0) ? 'Ingreso' : 'Gasto';
              // QA FIX: Usamos _formatSmartMoney para evitar overflow en el tooltip
              return BarTooltipItem(
                '$label\n${_formatSmartMoney(rod.toY)}',
                TextStyle(color: rodIndex == 0 ? successColor : errorColor, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final int index = value.toInt();
                if (index >= 0 && index < reversedMeses.length) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4,
                    child: Text(reversedMeses[index], style: const TextStyle(fontSize: 10, color: Colors.white70)),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), 
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withAlpha(50), 
            strokeWidth: 1,
            dashArray: [3, 3],
          ),
        ),
        barGroups: barGroups.reversed.toList(), 
      ),
    );
  }

  /// GRÁFICO 2: Facturación Total (Estilo Cyber Glow)
  Widget _buildFacturacion12MesesChart(BuildContext context, List<CobroModel> cobros) {
    final now = DateTime.now();
    final Map<int, double> ingresosPorMes = {};
    final List<String> meses = [];

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
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withAlpha(50),
            strokeWidth: 1,
            dashArray: [3, 3],
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final int index = value.toInt();
                if (index % 2 != 0) return const Text(''); 
                if (index >= 0 && index < reversedMeses.length) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4,
                    child: Text(reversedMeses[index], style: const TextStyle(fontSize: 10, color: Colors.white70)),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
              interval: 1,
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 11,
        minY: 0,
        maxY: maxY * 1.2, 
        lineBarsData: [
          LineChartBarData(
            spots: spots.reversed.toList(),
            isCurved: true,
            color: accentColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [accentColor.withAlpha(80), accentColor.withAlpha(0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => surfaceColor.withAlpha(240),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                // QA FIX: Smart formatting aquí también
                return LineTooltipItem(
                  _formatSmartMoney(spot.y),
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}