// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 26/10/2025
// Style: Cyber Glow
// This summary tab was fully refactored to align with the "Cyber Glow" design.
// CORRECCIÓN: Añadidos parámetros GlobalKey para el tour virtual (ShowCaseView).
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:showcaseview/showcaseview.dart'; // Importar showcaseview

import '../../data/models/financial_summary_model.dart';
import '../providers/finance_providers.dart';

// ignore_for_file: avoid_print

/// Pestaña 1: Resumen Ejecutivo
class SummaryTab extends ConsumerWidget {
  // --- NUEVO: Aceptar las keys del tour ---
  final GlobalKey kpiCardsKey;
  final GlobalKey incomeChartKey;

  SummaryTab({
    super.key,
    required this.kpiCardsKey,
    required this.incomeChartKey,
  });

  // Formateador de moneda
  final currencyFormatter = NumberFormat.currency(
    locale: 'es_CL', // O tu locale (ej. 'es_MX', 'es_CO')
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(financialSummaryProvider);

    // --- Paleta "Cyber Glow" ---
    const accentColor = Color(0xFF00BFFF);
    const backgroundColor = Color(0xFF1A1A2E);
    
    return summaryAsync.when(
      // --- ESTADO DE CARGA ---
      loading: () => const Center(child: CircularProgressIndicator(color: accentColor)),
      
      // --- ESTADO DE ERROR ---
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error al cargar el resumen:\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
      
      // --- ESTADO DE ÉXITO (DATOS) ---
      data: (summary) {
        return RefreshIndicator(
          color: accentColor,
          backgroundColor: backgroundColor,
          onRefresh: () async {
            // Invalidamos los streams base para forzar un recálculo
            ref.invalidate(gastosStreamProvider);
            ref.invalidate(cobrosStreamProvider);
            ref.invalidate(presupuestosStreamProvider);
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 600;
              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // --- 5. Envolver el widget con Showcase ---
                  Showcase(
                    key: kpiCardsKey,
                    title: 'Tus Métricas Clave',
                    description: 'Aquí ves un resumen rápido de tus ingresos, deudas y crecimiento.',
                    child: _buildKpiGrid(summary, isMobile, currencyFormatter),
                  ),
                  const SizedBox(height: 24),
                  _buildAlerts(summary, context),
                  const SizedBox(height: 24),
                  Text(
                    'Ingresos Netos (Últimos 6 Meses)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // --- 6. Envolver el widget con Showcase ---
                  Showcase(
                    key: incomeChartKey,
                    title: 'Gráfico de Ingresos',
                    description: 'Visualiza tus ingresos netos (ingresos menos gastos) de los últimos 6 meses.',
                    child: _buildIncomeChart(summary.datosGraficoIngresos6Meses, context, currencyFormatter),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Transacciones Recientes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRecentTransactions(summary.transaccionesRecientes, currencyFormatter),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Construye la cuadrícula de KPIs principales.
  Widget _buildKpiGrid(FinancialSummaryModel summary, bool isMobile, NumberFormat formatter) {
    
    final kpiCrecimientoColor = summary.porcentajeCrecimiento3Meses >= 0
        ? const Color(0xFF00FF7F) // Verde Neón
        : Colors.redAccent;
    final kpiCrecimientoIcon = summary.porcentajeCrecimiento3Meses >= 0
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;

    final kpiCrecimiento = _KpiCard(
      title: 'Crecimiento (vs 3M)',
      value: '${(summary.porcentajeCrecimiento3Meses * 100).toStringAsFixed(1)}%',
      icon: kpiCrecimientoIcon,
      color: kpiCrecimientoColor,
    );

    final kpis = [
      _KpiCard(
        title: 'Ingresos Netos',
        value: formatter.format(summary.ingresosNetos),
        icon: Icons.attach_money_rounded,
        color: const Color(0xFF00FF7F),
      ),
      _KpiCard(
        title: 'Pendiente de Cobro',
        value: formatter.format(summary.montoPendienteDeCobro),
        icon: Icons.account_balance_wallet_outlined,
        color: Colors.orangeAccent,
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
        ].map((k) => Padding(padding: const EdgeInsets.only(bottom: 16.0), child: k)).toList(),
      );
    } else {
      return GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.2,
        children: [
          ...kpis,
          kpiCrecimiento,
        ],
      );
    }
  }

  /// Construye las alertas de presupuesto si existen.
  Widget _buildAlerts(FinancialSummaryModel summary, BuildContext context) {
    const surfaceColor = Color(0xFF2D2D5A);
    const successColor = Color(0xFF00FF7F);
    const warningColor = Colors.orangeAccent;

    if (summary.alertasPresupuesto.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: surfaceColor.withAlpha(150),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: successColor.withAlpha(150)),
        ),
        child: const ListTile(
          leading: Icon(Icons.check_circle_outline, color: successColor),
          title: Text('¡Todo en orden!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text('Tus presupuestos están bajo control este mes.', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor.withAlpha(150),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warningColor.withAlpha(200), width: 1.5),
         boxShadow: [
          BoxShadow(color: warningColor.withAlpha(70), blurRadius: 10)
        ]
      ),
      child: ListTile(
        leading: Icon(Icons.warning_amber_rounded, color: warningColor),
        title: const Text(
          'Alerta de Presupuesto',
          style: TextStyle(
              color: warningColor, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Has superado el 80% en: ${summary.alertasPresupuesto.map((a) => a.categoria).join(', ')}.',
          style: TextStyle(color: warningColor.withAlpha( (255 * 0.9).round() )),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white70),
        onTap: () {
           final controller = DefaultTabController.of(context);
           controller.animateTo(2);
        },
      ),
    );
  }

  /// Construye el gráfico principal de ingresos de 6 meses.
  Widget _buildIncomeChart(
    List<MonthlyData> data, 
    BuildContext context,
    NumberFormat formatter,
  ) {
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);

    if (data.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(child: Text('No hay datos suficientes para el gráfico.', style: TextStyle(color: Colors.white70)))
      );
    }

    final minY = data.map((d) => d.monto).reduce((a, b) => a < b ? a : b);
    final maxY = data.map((d) => d.monto).reduce((a, b) => a > b ? a : b);
    final buffer = (maxY - minY).abs() * 0.2;

    double horizontalInterval = (maxY.toDouble() - minY.toDouble()) / 4.0;
    if (horizontalInterval == 0 || horizontalInterval.isNaN) {
      horizontalInterval = maxY > 0 ? (maxY.toDouble() / 4.0) : 1.0;
    }
    
    double finalMinY = (minY - buffer).floorToDouble();
    double finalMaxY = (maxY + buffer).ceilToDouble();
    if (finalMinY == finalMaxY) {
      finalMaxY += 100;
    }

    if (finalMinY >= 0) { 
      finalMinY = - (finalMaxY * 0.1).clamp(1, 10).toDouble(); 
    }

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          minY: finalMinY,
          maxY: finalMaxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: horizontalInterval,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white.withAlpha(50),
                strokeWidth: 1,
                dashArray: [3, 3],
              );
            },
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < data.length) {
                    final mes = DateFormat.MMM('es')
                        .format(data[index].mes);
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8.0,
                      child: Text(mes.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: data
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.monto))
                  .toList(),
              isCurved: true,
              color: accentColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    accentColor.withAlpha(80),
                    accentColor.withAlpha(0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (LineBarSpot spot) => surfaceColor,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final monto = spot.y;
                  return LineTooltipItem(
                    formatter.format(monto),
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

  /// Construye la lista de transacciones recientes.
  Widget _buildRecentTransactions(List<RecentTransaction> transacciones, NumberFormat formatter) {
    const surfaceColor = Color(0xFF2D2D5A);
    const successColor = Color(0xFF00FF7F);
    const errorColor = Colors.redAccent;

    if (transacciones.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: surfaceColor.withAlpha(150),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('No hay transacciones recientes.', style: TextStyle(color: Colors.white70))),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor.withAlpha(150),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: transacciones.map((tx) {
          final esIngreso = tx.tipo == TransactionType.ingreso;
          final color = esIngreso ? successColor : errorColor;
          final icon = esIngreso ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

          return ListTile(
            leading: Icon(icon, color: color, size: 28),
            title: Text(tx.concepto, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
            subtitle: Text(DateFormat.yMMMd('es').format(tx.fecha), style: const TextStyle(color: Colors.white60)),
            trailing: Text(
              formatter.format(tx.monto),
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

// ===================================================================
// --- WIDGET KPI REDISEÑADO ---
// ===================================================================

/// Un widget de tarjeta KPI rediseñado para el estilo "Cyber Glow".
class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Color(0xFF2D2D5A);
    
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(100)),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(70),
            blurRadius: 12,
            spreadRadius: 1,
          )
        ]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withAlpha(50),
          highlightColor: color.withAlpha(30),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, size: 36, color: color),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                           shadows: [Shadow(color: color, blurRadius: 10)]
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

