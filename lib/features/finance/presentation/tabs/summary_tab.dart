import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:showcaseview/showcaseview.dart'; 

import '../../data/models/financial_summary_model.dart';
import '../providers/finance_providers.dart';

// ignore_for_file: avoid_print

/// Pestaña 1: Resumen Ejecutivo
class SummaryTab extends ConsumerWidget {
  final GlobalKey kpiCardsKey;
  final GlobalKey incomeChartKey;

  SummaryTab({
    super.key,
    required this.kpiCardsKey,
    required this.incomeChartKey,
  });

  final currencyFormatter = NumberFormat.currency(
    locale: 'es_CL', 
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(financialSummaryProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return summaryAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: colorScheme.primary)),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (summary) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // --- WEB LAYOUT (> 900px) ---
            if (constraints.maxWidth > 900) {
              return _buildWebDashboard(context, summary, theme);
            }
            // --- MOBILE LAYOUT ---
            return _buildMobileLayout(context, summary, theme);
          },
        );
      },
    );
  }

  // ===========================================================================
  // 💻 WEB LAYOUT: DASHBOARD (NO SCROLL GLOBAL)
  // ===========================================================================
  Widget _buildWebDashboard(BuildContext context, FinancialSummaryModel summary, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          // 1. ZONA KPIs (Altura Fija)
          SizedBox(
            height: 110, 
            child: Showcase(
              key: kpiCardsKey,
              title: 'Tus Métricas Clave',
              description: 'Resumen rápido de ingresos y crecimiento.',
              child: _buildKpiRow(summary, currencyFormatter, theme),
            ),
          ),
          
          const SizedBox(height: 16),

          // 2. ZONA CONTENIDO (Gráfico + Lista)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // COLUMNA IZQUIERDA: GRÁFICO (65%)
                Expanded(
                  flex: 65,
                  child: _DashboardCard(
                    theme: theme,
                    title: 'Evolución de Ingresos (6 Meses)',
                    child: Expanded( // El gráfico llena el espacio disponible
                      child: Showcase(
                        key: incomeChartKey,
                        title: 'Gráfico de Ingresos',
                        description: 'Visualiza tus ingresos netos recientes.',
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 24, 24, 10),
                          child: _buildIncomeChart(summary.datosGraficoIngresos6Meses, context, currencyFormatter, theme),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),

                // COLUMNA DERECHA: TRANSACCIONES + ALERTAS (35%)
                Expanded(
                  flex: 35,
                  child: Column(
                    children: [
                      // Alerta (si existe)
                      if (summary.alertasPresupuesto.isNotEmpty) ...[
                         _buildAlertBanner(summary, theme),
                         const SizedBox(height: 16),
                      ],
                      // Lista de Transacciones
                      Expanded(
                        child: _DashboardCard(
                          theme: theme,
                          title: 'Últimos Movimientos',
                          padding: EdgeInsets.zero, // Padding manual para la lista
                          child: Expanded(
                            child: _buildRecentTransactionsList(summary.transaccionesRecientes, currencyFormatter, theme),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 📱 MOBILE LAYOUT (CON SCROLL)
  // ===========================================================================
  Widget _buildMobileLayout(BuildContext context, FinancialSummaryModel summary, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Showcase(
          key: kpiCardsKey,
          title: 'Tus Métricas Clave',
          description: 'Resumen rápido.',
          child: Column(
            children: [
              _KpiCardMobile(title: 'Ingresos Netos', value: currencyFormatter.format(summary.ingresosNetos), icon: Icons.attach_money, color: const Color(0xFF00FF7F)),
              const SizedBox(height: 12),
              _KpiCardMobile(title: 'Por Cobrar', value: currencyFormatter.format(summary.montoPendienteDeCobro), icon: Icons.account_balance_wallet_outlined, color: Colors.orangeAccent),
              const SizedBox(height: 12),
              _KpiCardMobile(title: 'Crecimiento (3M)', value: '${(summary.porcentajeCrecimiento3Meses * 100).toStringAsFixed(1)}%', icon: Icons.trending_up, color: Colors.blueAccent),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (summary.alertasPresupuesto.isNotEmpty) _buildAlertBanner(summary, theme),
        const SizedBox(height: 24),
        Text('Ingresos Netos', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Showcase(
          key: incomeChartKey,
          title: 'Gráfico',
          description: 'Evolución de ingresos.',
          child: SizedBox(
            height: 250,
            child: _buildIncomeChart(summary.datosGraficoIngresos6Meses, context, currencyFormatter, theme),
          ),
        ),
      ],
    );
  }

  // --- WIDGETS INTERNOS ---

  Widget _buildKpiRow(FinancialSummaryModel summary, NumberFormat formatter, ThemeData theme) {
    return Row(
      children: [
        Expanded(child: _KpiCardWeb(title: 'Ingresos Netos', value: formatter.format(summary.ingresosNetos), icon: Icons.attach_money, color: const Color(0xFF00FF7F))),
        const SizedBox(width: 16),
        Expanded(child: _KpiCardWeb(title: 'Por Cobrar', value: formatter.format(summary.montoPendienteDeCobro), icon: Icons.pending_actions, color: Colors.orangeAccent)),
        const SizedBox(width: 16),
        Expanded(child: _KpiCardWeb(title: 'Crecimiento', value: '${(summary.porcentajeCrecimiento3Meses * 100).toStringAsFixed(1)}%', icon: Icons.show_chart, color: Colors.blueAccent)),
      ],
    );
  }

  Widget _buildAlertBanner(FinancialSummaryModel summary, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        border: Border.all(color: Colors.orangeAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(child: Text('Alerta: ${summary.alertasPresupuesto.length} presupuestos excedidos.', style: const TextStyle(color: Colors.orangeAccent))),
        ],
      ),
    );
  }

  Widget _buildIncomeChart(List<MonthlyData> data, BuildContext context, NumberFormat formatter, ThemeData theme) {
    if (data.isEmpty) return const Center(child: Text('Sin datos.'));
    
    // Lógica simple para gráfico
    final spots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.monto)).toList();
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: theme.dividerColor.withOpacity(0.1))),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(), topTitles: const AxisTitles(),
          leftTitles: const AxisTitles(), // Ocultar eje Y para limpieza
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                if (val.toInt() >= 0 && val.toInt() < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(DateFormat.MMM('es').format(data[val.toInt()].mes).toUpperCase(), style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 10)),
                  );
                }
                return const Text('');
              },
              interval: 1
            )
          )
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: theme.colorScheme.primary.withOpacity(0.1)),
          )
        ]
      )
    );
  }

  Widget _buildRecentTransactionsList(List<RecentTransaction> transacciones, NumberFormat formatter, ThemeData theme) {
    if (transacciones.isEmpty) return const Center(child: Text("Sin movimientos recientes."));
    
    return ListView.separated(
      itemCount: transacciones.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
      itemBuilder: (_, index) {
        final tx = transacciones[index];
        final isIncome = tx.tipo == TransactionType.ingreso;
        return ListTile(
          dense: true,
          leading: Icon(isIncome ? Icons.arrow_upward : Icons.arrow_downward, color: isIncome ? Colors.green : Colors.red, size: 20),
          title: Text(tx.concepto, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Text(formatter.format(tx.monto), style: TextStyle(color: isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}

// --- Tarjetas Auxiliares ---

class _DashboardCard extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _DashboardCard({required this.theme, required this.title, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
          Expanded(child: padding != null ? Padding(padding: padding!, child: child) : child),
        ],
      ),
    );
  }
}

class _KpiCardWeb extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCardWeb({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
              Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          )
        ],
      ),
    );
  }
}

class _KpiCardMobile extends StatelessWidget {
  final String title; final String value; final IconData icon; final Color color;
  const _KpiCardMobile({required this.title, required this.value, required this.icon, required this.color});
  
  @override
  Widget build(BuildContext context) {
    // Versión simplificada para móvil
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 12)),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ])
        ],
      ),
    );
  }
}