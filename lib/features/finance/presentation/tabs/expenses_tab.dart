// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 26/10/2025
// Style: Cyber Glow
// This expenses tab was fully refactored to align with the "Cyber Glow" design.
// The PieChart was redesigned with a center value metric and neon color palette.
// List items, modals, and snackbars are all styled for a cohesive experience.
// CORRECCIÓN (Definitiva): Se asignó un width/height fijo al 'leading' (widget de fecha)
// en _buildExpensesList para solucionar el RenderFlex overflow de 2.0 pixels.
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // Para groupBy

import '../../data/models/gasto_model.dart';
import '../../data/repositories/finance_repository.dart';
import '../providers/finance_providers.dart';
// Importamos el modal
import '../widgets/add_expense_modal.dart';

/// Provider local para mantener el estado de la categoría seleccionada en el gráfico.
/// `null` significa que "Todas" están seleccionadas.
final selectedExpenseCategoryProvider = StateProvider<String?>((ref) => null);

/// Pestaña 2: Gestión de Gastos
class ExpensesTab extends ConsumerStatefulWidget {
  const ExpensesTab({super.key});

  @override
  ConsumerState<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends ConsumerState<ExpensesTab> {
  /// Índice de la sección del gráfico que fue tocada.
  int _touchedIndex = -1;

  final currencyFormatter = NumberFormat.currency(
    locale: 'es_CL',
    symbol: '\$',
    decimalDigits: 0,
  );
  
  final dateFormatter = DateFormat('dd MMM yyyy', 'es_ES');

  // --- Paleta de Colores "Cyber Glow" ---
  static const Color backgroundColor = Color(0xFF1A1A2E);
  static const Color accentColor = Color(0xFF00BFFF);
  static const Color surfaceColor = Color(0xFF2D2D5A);
  static const Color successColor = Color(0xFF00FF7F);
  static const Color errorColor = Colors.redAccent;
  static const Color warningColor = Colors.orangeAccent;

  @override
  Widget build(BuildContext context) {
    final gastosAsync = ref.watch(gastosStreamProvider);
    final selectedCategory = ref.watch(selectedExpenseCategoryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // El fondo lo da el TabBarView
      body: gastosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: accentColor)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: errorColor))),
        data: (gastosList) {
          if (gastosList.isEmpty) {
            return const _EmptyState(); // --- Estado Vacío Estilizado ---
          }

          // 1. Agrupar gastos para el PieChart
          final Map<String, double> gastosPorCategoria =
              _calcularGastosPorCategoria(gastosList);
          
          // 2. Filtrar la lista para mostrar (basado en la selección)
          final List<GastoModel> listaFiltrada = gastosList.where((gasto) {
            if (selectedCategory == null) return true; // Mostrar todos
            return gasto.categoria == selectedCategory;
          }).toList()
            ..sort((a, b) => b.fecha.compareTo(a.fecha)); // Ordenar por fecha

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Gráfico de Torta (Pie Chart) ---
              SizedBox(
                height: 250,
                child: _buildPieChart(context, gastosPorCategoria),
              ),
              
              // --- Título y Chip de Filtro ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0), // Padding ajustado
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Lista de Gastos",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                    if (selectedCategory != null)
                      Chip(
                        label: Text(selectedCategory),
                        labelStyle: const TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.bold),
                        backgroundColor: surfaceColor,
                        deleteIconColor: accentColor.withAlpha(180),
                        side: BorderSide(color: accentColor.withAlpha(100)),
                        onDeleted: () {
                          // Limpiar filtro
                          ref.read(selectedExpenseCategoryProvider.notifier).state = null;
                        },
                      ),
                  ],
                ),
              ),
              
              // --- Lista de Gastos (Filtrada) ---
              Expanded(
                child: _buildExpensesList(context, listaFiltrada),
              ),
            ],
          );
        },
      ),
      // --- Botón para Añadir Gasto ---
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Llamamos al modal para AÑADIR (gasto = null)
          _showAddExpenseModal(context, null);
        },
        backgroundColor: accentColor,
        foregroundColor: Colors.black, // Color del icono
        tooltip: 'Añadir Gasto',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Calcula la suma de gastos por cada categoría
  Map<String, double> _calcularGastosPorCategoria(List<GastoModel> gastos) {
    return groupBy(gastos, (g) => g.categoria)
        .map((categoria, gastosCategoria) => MapEntry(
              categoria,
              gastosCategoria.fold(0.0, (sum, g) => sum + g.monto),
            ));
  }

  /// Construye el widget de Gráfico de Torta
  Widget _buildPieChart(BuildContext context, Map<String, double> data) {
    final double totalGastos = data.values.fold(0.0, (sum, v) => sum + v);
    final List<PieChartSectionData> sections = [];
    
    // --- Paleta de Colores Cyber Glow ---
    final List<Color> colors = [
      accentColor,
      successColor,
      warningColor,
      Colors.purpleAccent.shade100,
      Colors.redAccent.shade100,
      Colors.tealAccent.shade100,
      Colors.pinkAccent.shade100,
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
          color: Colors.black, // Texto negro para mejor contraste sobre colores neón
          shadows: const [Shadow(color: Colors.white, blurRadius: 1)],
        ),
      ));
      i++;
    });

    // --- Usamos un Stack para mostrar el centro (solución robusta) ---
    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                setState(() {
                  if (event is FlTapUpEvent) {
                    final int? touchedIndex =
                        pieTouchResponse?.touchedSection?.touchedSectionIndex;
                    
                    if (touchedIndex == null || touchedIndex == _touchedIndex) {
                      // Si toca fuera o toca el mismo de nuevo
                      _touchedIndex = -1;
                      ref.read(selectedExpenseCategoryProvider.notifier).state = null;
                    } else {
                      // Si toca una nueva sección
                      _touchedIndex = touchedIndex;
                      final String selectedCategory = data.keys.elementAt(_touchedIndex);
                      ref.read(selectedExpenseCategoryProvider.notifier).state = selectedCategory;
                    }
                  }
                });
              },
            ),
            borderData: FlBorderData(show: false),
            sectionsSpace: 3, // Espacio entre secciones
            centerSpaceRadius: 60, // Radio del agujero central
            sections: sections,
          ),
        ),
        // --- Texto central superpuesto ---
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             const Text(
              'Total Gastos',
              style: TextStyle(fontSize: 12, color: Colors.white60)
            ),
             Text(
              currencyFormatter.format(totalGastos),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }

  /// Construye la lista de gastos
  Widget _buildExpensesList(BuildContext context, List<GastoModel> gastos) {
    return Padding(
      // Padding exterior para la lista
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 80), 
      child: ListView.builder(
        itemCount: gastos.length,
        itemBuilder: (context, index) {
          final gasto = gastos[index];
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              // --- CORRECCIÓN DE OVERFLOW (Definitiva) ---
              // Se asigna un tamaño fijo al 'leading' y se ajusta el padding.
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(gasto.concepto, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(gasto.categoria, style: const TextStyle(color: Colors.white70)),
              leading: Container(
                // Se asigna un tamaño fijo para estabilizar el layout del ListTile
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8)
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dateFormatter.format(gasto.fecha).split(' ')[0], // "dd"
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      dateFormatter.format(gasto.fecha).split(' ')[1].toUpperCase(), // "MMM"
                      style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      currencyFormatter.format(gasto.monto),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: errorColor,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: errorColor.withAlpha(180)),
                    onPressed: () => _deleteGasto(context, gasto),
                  ),
                ],
              ),
              onTap: () {
                // Llamamos al modal para EDITAR (pasando el gasto)
                _showAddExpenseModal(context, gasto);
              },
            ),
          );
        },
      ),
    );
  }

  /// Lógica para mostrar el modal de añadir/editar
  void _showAddExpenseModal(BuildContext context, GastoModel? gasto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: surfaceColor, 
      barrierColor: Colors.black.withAlpha(128),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        // --- El Padding para el teclado se aplica aquí ---
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: AddExpenseModal(gasto: gasto),
        );
      },
    );
  }

  /// Lógica para eliminar un gasto
  void _deleteGasto(BuildContext context, GastoModel gasto) {
    final repository = ref.read(financeRepositoryProvider);
    
    try {
      repository.deleteGasto(gasto.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${gasto.concepto} eliminado.", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: successColor, // Verde neón
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al eliminar: $e"),
          backgroundColor: errorColor, // Rojo
        ),
      );
    }
  }
}

/// Estado vacío rediseñado
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
            Text(
              'Sin Gastos',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Toca el botón "+" para registrar tu primer gasto.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}

