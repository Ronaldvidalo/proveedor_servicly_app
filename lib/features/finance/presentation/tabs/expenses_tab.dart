// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 26/10/2025
// Style: Cyber Glow
// WEB UPDATE: Responsive Layout (Split View for Web)
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; 
import 'package:showcaseview/showcaseview.dart'; 

import '../../data/models/gasto_model.dart';
import '../providers/finance_providers.dart';
import '../widgets/add_expense_modal.dart';

/// Provider local para mantener el estado de la categoría seleccionada en el gráfico.
final selectedExpenseCategoryProvider = StateProvider<String?>((ref) => null);

/// Pestaña 2: Gestión de Gastos
class ExpensesTab extends ConsumerStatefulWidget {
  final GlobalKey addExpenseButtonKey;

  const ExpensesTab({
    super.key,
    required this.addExpenseButtonKey,
  });

  @override
  ConsumerState<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends ConsumerState<ExpensesTab> {
  int _touchedIndex = -1;

  final currencyFormatter = NumberFormat.currency(
    locale: 'es_CL',
    symbol: '\$',
    decimalDigits: 0,
  );
  
  final dateFormatter = DateFormat('dd MMM yyyy', 'es_ES');

  // --- Paleta de Colores "Cyber Glow" ---
  static const Color accentColor = Color(0xFF00BFFF);
  static const Color successColor = Color(0xFF00FF7F);
  static const Color errorColor = Colors.redAccent;
  static const Color warningColor = Colors.orangeAccent;

  @override
  Widget build(BuildContext context) {
    final gastosAsync = ref.watch(gastosStreamProvider);
    final selectedCategory = ref.watch(selectedExpenseCategoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: gastosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: accentColor)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: errorColor))),
        data: (gastosList) {
          if (gastosList.isEmpty) {
            return const _EmptyState();
          }

          final Map<String, double> gastosPorCategoria = _calcularGastosPorCategoria(gastosList);
          
          final List<GastoModel> listaFiltrada = gastosList.where((gasto) {
            if (selectedCategory == null) return true;
            return gasto.categoria == selectedCategory;
          }).toList()
            ..sort((a, b) => b.fecha.compareTo(a.fecha));

          return LayoutBuilder(
            builder: (context, constraints) {
              // --- WEB LAYOUT (> 900px) ---
              if (constraints.maxWidth > 900) {
                return _buildWebLayout(context, gastosPorCategoria, listaFiltrada, selectedCategory, theme);
              }
              // --- MOBILE LAYOUT ---
              return _buildMobileLayout(context, gastosPorCategoria, listaFiltrada, selectedCategory, theme);
            },
          );
        },
      ),
      // --- Botón Flotante ---
      floatingActionButton: Showcase(
        key: widget.addExpenseButtonKey,
        title: 'Añadir Gasto',
        description: 'Registra un nuevo gasto.',
        child: FloatingActionButton(
          onPressed: () => _showAddExpenseModal(context, null),
          backgroundColor: accentColor,
          foregroundColor: Colors.black,
          tooltip: 'Añadir Gasto',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  // ===========================================================================
  // 💻 WEB LAYOUT: SPLIT VIEW (Gráfico Izq / Lista Der)
  // ===========================================================================
  Widget _buildWebLayout(BuildContext context, Map<String, double> gastosPorCategoria, List<GastoModel> listaFiltrada, String? selectedCategory, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // COLUMNA IZQUIERDA: Gráfico + Resumen (40%)
          Expanded(
            flex: 4,
            child: _WebCard(
              theme: theme,
              title: "Distribución de Gastos",
              child: Column(
                children: [
                  SizedBox(
                    height: 350, // Gráfico grande
                    child: _buildPieChart(context, gastosPorCategoria),
                  ),
                  const SizedBox(height: 24),
                  if (selectedCategory != null)
                    _buildFilterChip(context, selectedCategory),
                  if (selectedCategory == null)
                    Text("Toca una sección para filtrar.", style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 24),

          // COLUMNA DERECHA: Lista de Gastos (60%)
          Expanded(
            flex: 6,
            child: _WebCard(
              theme: theme,
              title: "Historial de Gastos",
              padding: EdgeInsets.zero, // Padding manual para lista
              child: Expanded( // Lista ocupa el resto
                child: _buildExpensesList(context, listaFiltrada, theme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 📱 MOBILE LAYOUT: SCROLL VERTICAL
  // ===========================================================================
  Widget _buildMobileLayout(BuildContext context, Map<String, double> gastosPorCategoria, List<GastoModel> listaFiltrada, String? selectedCategory, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 250,
          child: _buildPieChart(context, gastosPorCategoria),
        ),
        
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Lista de Gastos",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
              if (selectedCategory != null)
                _buildFilterChip(context, selectedCategory),
            ],
          ),
        ),
        
        Expanded(
          child: _buildExpensesList(context, listaFiltrada, theme),
        ),
      ],
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildFilterChip(BuildContext context, String category) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(category),
      labelStyle: const TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.bold),
      backgroundColor: theme.cardColor,
      deleteIconColor: accentColor.withValues(alpha: 180),
      side: BorderSide(color: accentColor.withValues(alpha: 100)),
      onDeleted: () {
        ref.read(selectedExpenseCategoryProvider.notifier).state = null;
      },
    );
  }

  Map<String, double> _calcularGastosPorCategoria(List<GastoModel> gastos) {
    return groupBy(gastos, (g) => g.categoria)
        .map((categoria, gastosCategoria) => MapEntry(
              categoria,
              gastosCategoria.fold(0.0, (sum, g) => sum + g.monto),
            ));
  }

  Widget _buildPieChart(BuildContext context, Map<String, double> data) {
    final double totalGastos = data.values.fold(0.0, (sum, v) => sum + v);
    final List<PieChartSectionData> sections = [];
    
    final List<Color> colors = [
      accentColor, successColor, warningColor,
      Colors.purpleAccent.shade100, Colors.redAccent.shade100,
      Colors.tealAccent.shade100, Colors.pinkAccent.shade100,
    ];

    int i = 0;
    data.forEach((categoria, monto) {
      final isTouched = (i == _touchedIndex);
      final double radius = isTouched ? 65.0 : 55.0;
      final double fontSize = isTouched ? 16.0 : 12.0;
      final double percentage = (monto / totalGastos) * 100;
      final sectionColor = colors[i % colors.length];

      sections.add(PieChartSectionData(
        color: sectionColor,
        value: monto,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.black,
          shadows: const [Shadow(color: Colors.white, blurRadius: 1)],
        ),
      ));
      i++;
    });

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                setState(() {
                  if (event is FlTapUpEvent) {
                    final int? touchedIndex = pieTouchResponse?.touchedSection?.touchedSectionIndex;
                    if (touchedIndex == null || touchedIndex == _touchedIndex) {
                      _touchedIndex = -1;
                      ref.read(selectedExpenseCategoryProvider.notifier).state = null;
                    } else {
                      _touchedIndex = touchedIndex;
                      final String selectedCategory = data.keys.elementAt(_touchedIndex);
                      ref.read(selectedExpenseCategoryProvider.notifier).state = selectedCategory;
                    }
                  }
                });
              },
            ),
            borderData: FlBorderData(show: false),
            sectionsSpace: 3,
            centerSpaceRadius: 60,
            sections: sections,
          ),
        ),
        SizedBox(
          width: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               const Text('Total', style: TextStyle(fontSize: 12, color: Colors.white60), textAlign: TextAlign.center),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  currencyFormatter.format(totalGastos),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpensesList(BuildContext context, List<GastoModel> gastos, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 80), 
      itemCount: gastos.length,
      itemBuilder: (context, index) {
        final gasto = gastos[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(gasto.concepto, style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(gasto.categoria, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
            leading: Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(8)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(dateFormatter.format(gasto.fecha).split(' ')[0], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                  Text(dateFormatter.format(gasto.fecha).split(' ')[1].toUpperCase(), style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            trailing: SizedBox(
              width: 145, 
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(currencyFormatter.format(gasto.monto), style: const TextStyle(fontWeight: FontWeight.bold, color: errorColor, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.delete_outline_rounded, color: errorColor.withValues(alpha: 180)),
                    onPressed: () => _deleteGasto(context, gasto),
                  ),
                ],
              ),
            ),
            onTap: () => _showAddExpenseModal(context, gasto),
          ),
        );
      },
    );
  }

  void _showAddExpenseModal(BuildContext context, GastoModel? gasto) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: theme.cardColor, 
      barrierColor: Colors.black.withValues(alpha: 128),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: AddExpenseModal(gasto: gasto),
        );
      },
    );
  }

  void _deleteGasto(BuildContext context, GastoModel gasto) {
    final repository = ref.read(financeRepositoryProvider);
    try {
      repository.deleteGasto(gasto.id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${gasto.concepto} eliminado."), backgroundColor: successColor));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: errorColor));
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.money_off_csred_rounded, size: 80, color: Colors.white24),
            SizedBox(height: 24),
            Text('Sin Gastos', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Toca el botón "+" para registrar tu primer gasto.', style: TextStyle(fontSize: 16, color: Colors.white60)),
          ],
        ),
      ),
    );
  }
}

class _WebCard extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _WebCard({required this.theme, required this.title, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
          // Expanded asegura que el hijo llene el alto del card (útil para listas o gráficos)
          Expanded(child: padding != null ? Padding(padding: padding!, child: child) : child),
        ],
      ),
    );
  }
}