import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
// Error 2 y 3: Eliminamos 'package:collection/collection.dart' que no se usa.

import '../../data/models/cobro_model.dart';
import '../../data/models/gasto_model.dart';
import '../../data/models/presupuesto_financiero_model.dart';
import '../providers/finance_providers.dart';
import '../widgets/budget_progress_card.dart';
// Error 4: Reemplazamos el TODO con el import correcto
import '../widgets/add_budget_modal.dart';

/// Pestaña 3: Análisis y Proyección
///
/// Muestra gráficos de tendencias a largo plazo y la gestión de presupuestos.
// Error 1: Eliminamos 'const' del constructor
class AnalysisTab extends ConsumerWidget {
  AnalysisTab({super.key});

  final currencyFormatter = NumberFormat.currency(
    locale: 'es_CL',
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observamos los 3 streams de datos que necesitamos
    final gastosAsync = ref.watch(gastosStreamProvider);
    final cobrosAsync = ref.watch(cobrosStreamProvider);
    final presupuestosAsync = ref.watch(presupuestosStreamProvider);

    // Patrón de carga múltiple:
    // Si CUALQUIERA está cargando, mostramos loading.
    if (gastosAsync.isLoading || cobrosAsync.isLoading || presupuestosAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Si CUALQUIERA tiene error, mostramos error.
    if (gastosAsync.hasError || cobrosAsync.hasError || presupuestosAsync.hasError) {
      return Center(child: Text(
        "Error al cargar datos: ${gastosAsync.error ?? cobrosAsync.error ?? presupuestosAsync.error}"
      ));
    }

    // Si llegamos aquí, todos los datos están disponibles.
    final gastos = gastosAsync.value!;
    final cobros = cobrosAsync.value!;
    final presupuestos = presupuestosAsync.value!;

    return Scaffold(
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
                    ),
              ),
              const SizedBox(height: 16),
              
              // --- Gráfico 1: Comparativa Ingreso vs Gasto (6 Meses) ---
              SizedBox(
                height: 250,
                child: _buildIngresoVsGastoChart(context, cobros, gastos),
              ),
              const SizedBox(height: 24),

              // --- Gráfico 2: Facturación (12 Meses) ---
              SizedBox(
                height: 250,
                child: _buildFacturacion12MesesChart(context, cobros),
              ),
              const SizedBox(height: 24),

              // --- Sección 2: Gestión de Presupuestos ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Presupuestos de Gastos",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle, color: Theme.of(context).primaryColor),
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
    
    // Filtramos presupuestos para el mes actual
    final String mesActual = DateFormat('yyyy-MM').format(DateTime.now());
    final presupuestosMesActual = presupuestos.where((p) => p.mes == mesActual && p.activo).toList();

    if (presupuestosMesActual.isEmpty) {
      return const Card(
        elevation: 0,
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              "No has definido presupuestos para este mes. \nToca el botón (+) para empezar.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: presupuestosMesActual.length,
      shrinkWrap: true, // Importante dentro de un SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(), // El scroll lo maneja el padre
      itemBuilder: (context, index) {
        final presupuesto = presupuestosMesActual[index];
        
        // Calcular el gasto actual para esta categoría y mes
        final double gastoActual = gastos
            .where((g) =>
                g.categoria == presupuesto.categoria &&
                DateFormat('yyyy-MM').format(g.fecha) == presupuesto.mes)
            .fold(0.0, (sum, g) => sum + g.monto);

        return BudgetProgressCard(
          presupuesto: presupuesto,
          gastoActual: gastoActual,
        );
      },
    );
  }

  /// Muestra el modal para añadir un nuevo presupuesto
  void _showAddBudgetModal(BuildContext context) {
    // Este código ya estaba correcto gracias a nuestra actualización anterior.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que el modal crezca
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        // Padding para que el teclado no tape el modal
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const AddBudgetModal(), // Llamamos al modal
      ),
    );
  }

  /// GRÁFICO 1: Comparativa Ingresos vs Gastos (Últimos 6 Meses)
  Widget _buildIngresoVsGastoChart(BuildContext context, List<CobroModel> cobros, List<GastoModel> gastos) {
    final now = DateTime.now();
    final Map<int, double> ingresosPorMes = {};
    final Map<int, double> gastosPorMes = {};

    // 1. Calcular Ingresos (Cobros COBRADOS)
    final cobrosPagados = cobros.where((c) => c.estado == 'COBRADO');
    for (final cobro in cobrosPagados) {
      // Manejar fecha de cobro nula (si aplica)
      if (cobro.fechaCobro == null) continue;
      final int monthDiff = (now.year - cobro.fechaCobro!.year) * 12 + (now.month - cobro.fechaCobro!.month);
      if (monthDiff >= 0 && monthDiff < 6) { // Últimos 6 meses
        ingresosPorMes.update(monthDiff, (v) => v + cobro.monto, ifAbsent: () => cobro.monto);
      }
    }

    // 2. Calcular Gastos
    for (final gasto in gastos) {
      final int monthDiff = (now.year - gasto.fecha.year) * 12 + (now.month - gasto.fecha.month);
      if (monthDiff >= 0 && monthDiff < 6) { // Últimos 6 meses
        gastosPorMes.update(monthDiff, (v) => v + gasto.monto, ifAbsent: () => gasto.monto);
      }
    }

    final List<BarChartGroupData> barGroups = [];
    final List<String> meses = [];

    // 3. Crear grupos de barras (de más reciente a más antiguo)
    for (int i = 0; i < 6; i++) {
      final mes = DateTime(now.year, now.month - i, 1);
      meses.add(DateFormat('MMM', 'es_ES').format(mes));

      final double ingreso = ingresosPorMes[i] ?? 0.0;
      final double gasto = gastosPorMes[i] ?? 0.0;
      
      barGroups.add(BarChartGroupData(
        x: 5 - i, // 0 = 5 meses atrás, 5 = mes actual
        barRods: [
          // Barra de Ingreso
          BarChartRodData(
            toY: ingreso,
            color: Colors.green.shade400,
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          // Barra de Gasto
          BarChartRodData(
            toY: gasto,
            color: Colors.red.shade400,
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      ));
    }
    
    // Invertimos las etiquetas de los meses para que coincidan con el eje X
    final reversedMeses = meses.reversed.toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final String label = (rodIndex == 0) ? 'Ingreso' : 'Gasto';
              return BarTooltipItem(
                '$label\n${currencyFormatter.format(rod.toY)}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                    child: Text(reversedMeses[index], style: const TextStyle(fontSize: 10)),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('0', style: TextStyle(fontSize: 9));
                // Ajustar la lógica para mostrar valores intermedios si es necesario
                if (value % 50000 == 0 && value > 0) {
                  return Text("${(value / 1000).toStringAsFixed(0)}k", style: const TextStyle(fontSize: 9));
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        barGroups: barGroups.reversed.toList(), // Mostrar de más antiguo a más reciente
      ),
    );
  }

  /// GRÁFICO 2: Facturación Total (Últimos 12 Meses)
  Widget _buildFacturacion12MesesChart(BuildContext context, List<CobroModel> cobros) {
    final now = DateTime.now();
    final Map<int, double> ingresosPorMes = {};
    final List<String> meses = [];

    // 1. Calcular Ingresos (Cobros COBRADOS)
    final cobrosPagados = cobros.where((c) => c.estado == 'COBRADO');
    for (final cobro in cobrosPagados) {
      if (cobro.fechaCobro == null) continue;
      final int monthDiff = (now.year - cobro.fechaCobro!.year) * 12 + (now.month - cobro.fechaCobro!.month);
      if (monthDiff >= 0 && monthDiff < 12) { // Últimos 12 meses
        ingresosPorMes.update(monthDiff, (v) => v + cobro.monto, ifAbsent: () => cobro.monto);
      }
    }

    final List<FlSpot> spots = [];
    double maxY = 0.0;

    // 2. Crear puntos (de más reciente a más antiguo)
    for (int i = 0; i < 12; i++) {
      final mes = DateTime(now.year, now.month - i, 1);
      meses.add(DateFormat('MMM', 'es_ES').format(mes));
      
      final double ingreso = ingresosPorMes[i] ?? 0.0;
      if (ingreso > maxY) maxY = ingreso;
      
      spots.add(FlSpot(11 - i.toDouble(), ingreso)); // 0 = 11 meses atrás, 11 = mes actual
    }
    
    // Invertimos las etiquetas de los meses para que coincidan con el eje X
    final reversedMeses = meses.reversed.toList();
    
    // Asegurarse de que maxY no sea 0 para evitar división por cero o gráficos planos
    if (maxY == 0.0) maxY = 1000.0; // Poner un valor por defecto si no hay datos

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
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
                    child: Text(reversedMeses[index], style: const TextStyle(fontSize: 10)),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
              interval: 1,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('0', style: TextStyle(fontSize: 9));
                if (value == maxY) {
                   return Text("${(value / 1000).toStringAsFixed(0)}k", style: const TextStyle(fontSize: 9));
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 11,
        minY: 0,
        maxY: maxY * 1.2, // Un 20% de padding superior
        lineBarsData: [
          LineChartBarData(
            spots: spots.reversed.toList(), // Mostrar de más antiguo a más reciente
            isCurved: true,
            color: Colors.blue,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              // Error 5: Corregido 'withOpacity' obsoleto
              color: Colors.blue.withAlpha((255 * 0.1).round()),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
             getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  currencyFormatter.format(spot.y),
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

