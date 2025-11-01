import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../data/models/financial_summary_model.dart';
import '../providers/finance_providers.dart';
import '../widgets/kpi_card.dart';

// ignore_for_file: avoid_print

/// Pestaña 1: Resumen Ejecutivo
/// Muestra los KPIs principales, gráficos de resumen y transacciones recientes.
class SummaryTab extends ConsumerWidget {
  // *** CORRECCIÓN ***
  // Usamos super.key para el constructor
  SummaryTab({super.key});

  // Formateador de moneda
  final currencyFormatter = NumberFormat.currency(
    locale: 'es_CL', // O tu locale (ej. 'es_MX', 'es_CO')
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observamos el provider principal que nos da el resumen completo
    final summaryAsync = ref.watch(financialSummaryProvider);

    return summaryAsync.when(
      // --- ESTADO DE CARGA ---
      loading: () => const Center(child: CircularProgressIndicator()),
      
      // --- ESTADO DE ERROR ---
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error al cargar el resumen:\n$error',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
      
      // --- ESTADO DE ÉXITO (DATOS) ---
      data: (summary) {
        return RefreshIndicator(
          // *** CORRECCIÓN ***
          // onRefresh debe devolver un Future<void>.
          // Invalidamos los providers de datos base (streams)
          // y el provider de resumen se actualizará automáticamente.
          onRefresh: () async {
            // Invalidamos los streams para que vuelvan a cargar
            ref.invalidate(gastosStreamProvider);
            ref.invalidate(cobrosStreamProvider);
            ref.invalidate(presupuestosStreamProvider);

            // Invalidamos el resumen para que se recalcule
            ref.invalidate(financialSummaryProvider);

            // Damos un pequeño delay para asegurar que el spinner se muestre
            // mientras los streams emiten sus nuevos valores.
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 600;
              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildKpiGrid(summary, isMobile),
                  const SizedBox(height: 24),
                  _buildAlerts(summary, context),
                  const SizedBox(height: 24),
                  Text(
                    'Ingresos Netos (Últimos 6 Meses)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildIncomeChart(summary.datosGraficoIngresos6Meses, context),
                  const SizedBox(height: 24),
                  Text(
                    'Transacciones Recientes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildRecentTransactions(summary.transaccionesRecientes),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Construye la cuadrícula de KPIs principales.
  Widget _buildKpiGrid(FinancialSummaryModel summary, bool isMobile) {
    // *** CORRECCIÓN ***
    // El KpiCard no acepta 'extraContent', así que construimos el
    // widget como una Columna que *contiene* el KpiCard y el gráfico.
    final kpiCrecimiento = Column(
      children: [
        KpiCard(
          title: 'Crecimiento (3M)',
          // *** CORRECCIÓN ***
          // El 'value' debe ser un double, no un String.
          value: (summary.porcentajeCrecimiento3Meses * 100),
          color: summary.porcentajeCrecimiento3Meses >= 0
              ? Colors.green.shade700
              : Colors.red.shade700,
          // *** CORRECCIÓN ***
          // Eliminados 'icon', 'backgroundColor' y 'extraContent'
          // porque no están definidos en tu KpiCard.
        ),
        // Movimos el gráfico (que estaba en extraContent)
        // para que se muestre *debajo* de la tarjeta.
        if (summary.datosCurvaCrecimiento3M.isNotEmpty)
          SizedBox(
            height: 40,
            child: _buildMiniGrowthChart(
              summary.datosCurvaCrecimiento3M,
              summary.porcentajeCrecimiento3Meses >= 0
                  ? Colors.green
                  : Colors.red,
            ),
          )
      ],
    );

    // Lista de KPIs
    final kpis = [
      // KPI 1: Ingresos Netos
      KpiCard(
        title: 'Ingresos Netos',
        // *** CORRECIÓN ***
        // El 'value' debe ser un double, no un String.
        value: summary.ingresosNetos,
        color: Colors.green.shade700,
        // *** CORRECCIÓN ***
        // Eliminados 'icon' y 'backgroundColor'.
      ),
      // KPI 2: Pendiente de Cobro
      KpiCard(
        title: 'Pendiente de Cobro',
        // *** CORRECIÓN ***
        // El 'value' debe ser un double, no un String.
        value: summary.montoPendienteDeCobro,
        color: Colors.orange.shade800,
        // *** CORRECCIÓN ***
        // Eliminados 'icon' y 'backgroundColor'.
        onTap: () {
          // TODO: Implementar navegación a lista de cobros pendientes
          print('Navegar a cobros pendientes');
        },
      ),
    ];

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...kpis,
          kpiCrecimiento,
        ].map((k) => Padding(padding: const EdgeInsets.only(bottom: 12.0), child: k)).toList(),
      );
    } else {
      // Web/Tablet: Grid
      return GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.0, // Más anchos que altos
        children: [
          ...kpis,
          kpiCrecimiento,
        ],
      );
    }
  }

  /// Construye las alertas de presupuesto si existen.
  Widget _buildAlerts(FinancialSummaryModel summary, BuildContext context) {
    if (summary.alertasPresupuesto.isEmpty) {
      // Si no hay alertas, mostramos un mensaje tranquilizador
      return Card(
        color: Colors.grey.shade50,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: const ListTile(
          leading: Icon(Icons.check_circle_outline, color: Colors.green),
          title: Text('¡Todo en orden!'),
          subtitle: Text('Tus presupuestos están bajo control este mes.'),
        ),
      );
    }

    // Si hay alertas
    return Card(
      color: Colors.amber.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.shade300),
      ),
      child: ListTile(
        leading: Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
        title: Text(
          'Alerta de Presupuesto',
          style: TextStyle(
              color: Colors.amber.shade900, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Has superado el 80% en: ${summary.alertasPresupuesto.map((a) => a.categoria).join(', ')}.',
          style: TextStyle(color: Colors.amber.shade800),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {
          // TODO: Navegar a la pestaña de Análisis
          print('Navegar a la pestaña de Análisis');
        },
      ),
    );
  }

  /// Construye el gráfico principal de ingresos de 6 meses.
  Widget _buildIncomeChart(
    // El tipo es 'MonthlyData'
    List<MonthlyData> data, 
    BuildContext context,
  ) {
    if (data.isEmpty) {
      return const Center(child: Text('No hay datos suficientes para el gráfico.'));
    }

    // Encontrar el valor máximo y mínimo para el eje Y
    final minY = data.map((d) => d.monto).reduce((a, b) => a < b ? a : b);
    final maxY = data.map((d) => d.monto).reduce((a, b) => a > b ? a : b);
    final buffer = (maxY - minY) * 0.2; // 20% de búfer

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          minY: (minY - buffer).floorToDouble(),
          maxY: (maxY + buffer).ceilToDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: (maxY - minY) / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade300,
                strokeWidth: 1,
                dashArray: [2, 2],
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.transparent,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            // Eje X (Meses)
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < data.length) {
                    final mes = DateFormat.MMM('es')
                        .format(data[index].mes); // 'es' para español
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8.0,
      
                      child: Text(mes,
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 10)),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            // Eje Y (Montos) - Oculto
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          // Datos de la línea
          lineBarsData: [
            LineChartBarData(
              spots: data
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.monto))
                  .toList(),
              isCurved: true,
              color: Theme.of(context).primaryColor,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                // 'withOpacity' está obsoleto
                color: Theme.of(context).primaryColor.withAlpha((255 * 0.1).round()), 
              ),
            ),
          ],
          // Tooltips
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final monto = spot.y;
                  return LineTooltipItem(
                    currencyFormatter.format(monto),
                    const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Construye el mini-gráfico para la tarjeta KPI.
  Widget _buildMiniGrowthChart(List<MonthlyData> data, Color color) {
    if (data.isEmpty) return const SizedBox.shrink();

    final minY = data.map((d) => d.monto).reduce((a, b) => a < b ? a : b);
    final maxY = data.map((d) => d.monto).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: data
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.monto))
                .toList(),
            isCurved: true,
            color: color,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
          ),
        ],
        lineTouchData: const LineTouchData(enabled: false),
      ),
    );
  }

  /// Construye la lista de transacciones recientes.
  /// Esta función ahora consume la lista pre-calculada del provider
  Widget _buildRecentTransactions(List<RecentTransaction> transacciones) {
    if (transacciones.isEmpty) {
      return const Card(
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('No hay transacciones recientes.')),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300)
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: transacciones.map((tx) {
          final esIngreso = tx.tipo == TransactionType.ingreso;
          final color = esIngreso ? Colors.green : Colors.red;
          final icon = esIngreso ? Icons.arrow_upward : Icons.arrow_downward;

          return ListTile(
            leading: Icon(icon, color: color),
            title: Text(tx.concepto, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(DateFormat.yMMMd('es').format(tx.fecha)),
            trailing: Text(
              currencyFormatter.format(tx.monto),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

