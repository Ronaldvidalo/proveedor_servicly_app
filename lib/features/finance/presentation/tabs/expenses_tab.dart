import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // Para groupBy

import '../../data/models/gasto_model.dart';
import '../../data/repositories/finance_repository.dart';
import '../providers/finance_providers.dart';
// Importamos el modal que acabamos de crear
import '../widgets/add_expense_modal.dart'; 

/// Provider local para mantener el estado de la categoría seleccionada en el gráfico.
/// `null` significa que "Todas" están seleccionadas.
final selectedExpenseCategoryProvider = StateProvider<String?>((ref) => null);

/// Pestaña 2: Gestión de Gastos
///
/// Muestra un gráfico de torta interactivo y una lista CRUD de gastos.
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

  @override
  Widget build(BuildContext context) {
    final gastosAsync = ref.watch(gastosStreamProvider);
    final selectedCategory = ref.watch(selectedExpenseCategoryProvider);

    return Scaffold(
      body: gastosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (gastosList) {
          if (gastosList.isEmpty) {
            return const Center(
              child: Text(
                "Aún no tienes gastos registrados.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // 1. Agrupar gastos para el PieChart (siempre usa la lista completa)
          final Map<String, double> gastosPorCategoria =
              _calcularGastosPorCategoria(gastosList);
          
          // 2. Filtrar la lista para mostrar (basado en la selección)
          final List<GastoModel> listaFiltrada = gastosList.where((gasto) {
            if (selectedCategory == null) return true; // Mostrar todos
            return gasto.categoria == selectedCategory;
          }).toList();

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
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Lista de Gastos",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (selectedCategory != null)
                      Chip(
                        label: Text(selectedCategory),
                        labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                        backgroundColor: Colors.blue.shade700,
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
        child: const Icon(Icons.add),
        tooltip: 'Añadir Gasto',
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
    final List<Color> colors = [
      Colors.blue.shade400, Colors.red.shade400, Colors.green.shade400,
      Colors.orange.shade400, Colors.purple.shade400, Colors.teal.shade400,
      Colors.pink.shade300, Colors.amber.shade600,
    ];

    int i = 0;
    data.forEach((categoria, monto) {
      final isTouched = (i == _touchedIndex);
      final double radius = isTouched ? 60.0 : 50.0;
      final double fontSize = isTouched ? 16.0 : 12.0;
      final double percentage = (monto / totalGastos) * 100;

      sections.add(PieChartSectionData(
        color: colors[i % colors.length],
        value: monto,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
        ),
        badgeWidget: _ChartBadge(categoria, color: colors[i % colors.length]),
        badgePositionPercentageOffset: 1.0,
      ));
      i++;
    });

    return PieChart(
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
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: sections,
      ),
    );
  }

  /// Construye la lista de gastos
  Widget _buildExpensesList(BuildContext context, List<GastoModel> gastos) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 80),
      itemCount: gastos.length,
      itemBuilder: (context, index) {
        final gasto = gastos[index];
        return Card(
          elevation: 1.0,
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            title: Text(gasto.concepto, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(gasto.categoria),
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dateFormatter.format(gasto.fecha).split(' ')[0], // "dd"
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  dateFormatter.format(gasto.fecha).split(' ')[1].toUpperCase(), // "MMM"
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currencyFormatter.format(gasto.monto),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontSize: 15,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
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
    );
  }

  /// Lógica para mostrar el modal de añadir/editar
  void _showAddExpenseModal(BuildContext context, GastoModel? gasto) {
    // Este es el código final que reemplaza el SnackBar de marcador.
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
        child: AddExpenseModal(gasto: gasto),
      ),
    );
  }

  /// Lógica para eliminar un gasto
  void _deleteGasto(BuildContext context, GastoModel gasto) {
    // Usamos 'ref.read' para llamar a una función del repositorio
    final repository = ref.read(financeRepositoryProvider);
    
    try {
      // Asumimos que el ID existe (deberíamos chequear por si acaso)
      if (gasto.id == null) throw Exception("ID de gasto nulo");

      repository.deleteGasto(gasto.id!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${gasto.concepto} eliminado."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al eliminar: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}


/// Widget privado para mostrar la "etiqueta" de la categoría en el gráfico.
class _ChartBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _ChartBadge(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.8), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

