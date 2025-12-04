// Ignoramos las advertencias de depreciación por versiones nuevas de Flutter
// para centrarnos en que el código funcione primero.
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// --- IMPORTS DE MODELOS ---
import 'package:proveedor_servicly_app/features/cost_structure/data/models/business_config_model.dart';
// import 'package:proveedor_servicly_app/features/cost_structure/data/models/fixed_cost_model.dart'; // Import duplicado eliminado

// --- IMPORTS DE PROVIDERS (CORE) ---
import 'package:proveedor_servicly_app/features/cost_structure/core/providers/cost_providers.dart';

// --- IMPORTS DE WIDGETS (VISUALES) ---
import 'package:proveedor_servicly_app/features/cost_structure/screen/mentor_card.dart'; // Ajustar ruta si es necesario
// import 'package:proveedor_servicly_app/features/cost_structure/data/models/fixed_cost_model.dart'; // Duplicado
// --- IMPORTS DE FINANZAS (REPO Y PROVIDER GENERAL) ---
import 'package:proveedor_servicly_app/features/finance/presentation/providers/finance_providers.dart';
import 'package:proveedor_servicly_app/features/cost_structure/widgets/fixed_cost_modal.dart';

class BusinessConfigScreen extends ConsumerStatefulWidget {
  const BusinessConfigScreen({super.key});

  @override
  ConsumerState<BusinessConfigScreen> createState() => _BusinessConfigScreenState();
}

class _BusinessConfigScreenState extends ConsumerState<BusinessConfigScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currencyFormatter = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Listener para redibujar el FAB al cambiar de tab
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // QA FIX: Obtener tema
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // Fondo dinámico
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Estructura de Negocio"),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
          tabs: const [
            Tab(text: "1. Mis Gastos Fijos", icon: Icon(Icons.account_balance_wallet)),
            Tab(text: "2. Estrategia", icon: Icon(Icons.psychology)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFixedCostsTab(context),
          _buildStrategyTab(context),
        ],
      ),
      floatingActionButton: _tabController.index == 0 
        ? FloatingActionButton(
            backgroundColor: colorScheme.primary,
            // Texto/Icono sobre botón primario (Negro/Blanco)
            child: Icon(Icons.add, color: colorScheme.onPrimary),
            onPressed: () {
               showModalBottomSheet(
                  context: context, 
                  isScrollControlled: true,
                  // QA FIX: Fondo modal dinámico
                  backgroundColor: theme.cardTheme.color,
                  builder: (ctx) => const FixedCostModal()
               );
            },
          )
        : null,
    );
  }

  // --- PESTAÑA 1: GASTOS FIJOS ---
  Widget _buildFixedCostsTab(BuildContext context) {
    final fixedCostsAsync = ref.watch(fixedCostsStreamProvider);
    final totalCosts = ref.watch(totalFixedCostsProvider);
    
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Asumimos que MentorCard ya está adaptada o usa colores neutros
          const MentorCard(
            title: "Paso 1: La Realidad",
            message: "Antes de hablar de inventario, necesito saber cuánto te cuesta abrir la persiana cada mes (Alquiler, Luz, Internet).",
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              // QA FIX: Gradiente solo en modo oscuro o adaptable
              gradient: LinearGradient(
                colors: theme.brightness == Brightness.dark 
                  ? [Colors.blue.shade900, const Color(0xFF2D2D5A)]
                  : [colorScheme.primary, colorScheme.secondary],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                 BoxShadow(
                  color: Colors.black.withOpacity(0.1), 
                  blurRadius: 10, 
                  offset: const Offset(0, 4)
                )
              ],
            ),
            child: Column(
              children: [
                const Text("Total Gastos Fijos Mensuales", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                // El texto sobre el gradiente siempre será blanco
                Text(
                  _currencyFormatter.format(totalCosts), 
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: fixedCostsAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: colorScheme.primary)),
              error: (err, _) => Text("Error: $err", style: TextStyle(color: colorScheme.error)),
              data: (costs) {
                if (costs.isEmpty) return Center(child: Text("Toca el + para agregar tu primer gasto fijo.", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))));
                return ListView.builder(
                  itemCount: costs.length,
                  itemBuilder: (ctx, index) {
                    final cost = costs[index];
                    return Card(
                      // QA FIX: Color de tarjeta del tema
                      color: theme.cardTheme.color,
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1), 
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: Icon(Icons.receipt, color: colorScheme.primary),
                        ),
                        title: Text(cost.concepto, style: TextStyle(color: colorScheme.onSurface)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currencyFormatter.format(cost.montoMensual), 
                              style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => ref.read(financeRepositoryProvider).deleteFixedCost(cost.id),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- PESTAÑA 2: ESTRATEGIA ---
  Widget _buildStrategyTab(BuildContext context) {
    final configAsync = ref.watch(businessConfigStreamProvider);
    final totalFixedCosts = ref.watch(totalFixedCostsProvider);
    
    final colorScheme = Theme.of(context).colorScheme;

    return configAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: colorScheme.primary)),
      error: (e, _) => Center(child: Text("Error: $e", style: TextStyle(color: colorScheme.error))),
      data: (config) => _StrategyForm(initialConfig: config, totalFixedCosts: totalFixedCosts),
    );
  }
}

class _StrategyForm extends ConsumerStatefulWidget {
  final BusinessConfigModel initialConfig;
  final double totalFixedCosts;

  const _StrategyForm({required this.initialConfig, required this.totalFixedCosts});

  @override
  ConsumerState<_StrategyForm> createState() => _StrategyFormState();
}

class _StrategyFormState extends ConsumerState<_StrategyForm> {
  late bool _usarInventarioReal;
  late double _margenDeseado; 
  late TextEditingController _unidadesProyectadasController;
  late TextEditingController _margenController; 
  
  bool _isSaving = false;
  final int _mockInventarioTotal = 0; 

  @override
  void initState() {
    super.initState();
    _usarInventarioReal = widget.initialConfig.usarInventarioReal;
    _margenDeseado = widget.initialConfig.margenDeseado;
    _unidadesProyectadasController = TextEditingController(text: widget.initialConfig.unidadesProyectadasMes.toString());
    
    _margenController = TextEditingController(
      text: (widget.initialConfig.margenDeseado * 100).toStringAsFixed(1).replaceAll('.0', '')
    );
  }

  @override
  void dispose() {
    _unidadesProyectadasController.dispose();
    _margenController.dispose();
    super.dispose();
  }

  void _onSliderChanged(double value) {
    setState(() {
      _margenDeseado = value;
      _margenController.text = (value * 100).toStringAsFixed(1).replaceAll('.0', '');
    });
  }

  void _onManualMarginChanged(String value) {
    final double? parsed = double.tryParse(value);
    if (parsed != null) {
      setState(() {
        _margenDeseado = (parsed / 100).clamp(0.0, 1.0);
      });
    }
  }

  double get _costoFijoUnitarioEstimado {
    double divisor;
    if (_usarInventarioReal) {
      divisor = _mockInventarioTotal > 0 ? _mockInventarioTotal.toDouble() : 1.0;
    } else {
      divisor = double.tryParse(_unidadesProyectadasController.text) ?? 1.0;
    }
    if (divisor == 0) divisor = 1.0;
    return widget.totalFixedCosts / divisor;
  }

  Future<void> _saveStrategy() async {
    setState(() => _isSaving = true);
    final repo = ref.read(financeRepositoryProvider);
    try {
      final newConfig = widget.initialConfig.copyWith(
        margenDeseado: _margenDeseado,
        unidadesProyectadasMes: int.tryParse(_unidadesProyectadasController.text) ?? 0,
        usarInventarioReal: _usarInventarioReal,
        costoFijoUnitarioCalculado: _costoFijoUnitarioEstimado,
      );
      await repo.updateBusinessConfig(newConfig);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Estrategia actualizada"), backgroundColor: Colors.green));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // QA FIX: Obtener tema
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final currencyFormatter = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 2);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("Método de Cálculo", style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          // QA FIX: Fondo tarjeta dinámico
          decoration: BoxDecoration(
            color: theme.cardTheme.color, 
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor.withOpacity(0.5))
          ),
          child: Column(
            children: [
              RadioListTile<bool>(
                title: Text("Estimación Manual", style: TextStyle(color: colorScheme.onSurface)),
                subtitle: Text("Usar una meta de ventas.", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
                value: false,
                groupValue: _usarInventarioReal,
                activeColor: colorScheme.primary,
                onChanged: (val) => setState(() => _usarInventarioReal = val!),
              ),
              Divider(color: theme.dividerColor, height: 1),
              RadioListTile<bool>(
                title: Text("Basado en Inventario", style: TextStyle(color: colorScheme.onSurface)),
                subtitle: Text("Usar mi stock real ($_mockInventarioTotal items).", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
                value: true,
                groupValue: _usarInventarioReal,
                activeColor: colorScheme.primary,
                onChanged: _mockInventarioTotal > 0 ? (val) => setState(() => _usarInventarioReal = val!) : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (!_usarInventarioReal) ...[
          // Asumimos MentorCard adaptable
          const MentorCard(title: "Proyección", message: "¿Cuántas unidades crees vender al mes?"),
          const SizedBox(height: 12),
          TextFormField(
            controller: _unidadesProyectadasController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: "Unidades Estimadas",
              labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
              filled: true,
              fillColor: theme.cardTheme.color,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],

        const SizedBox(height: 32),
        
        // --- SECCIÓN DE MARGEN ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text("Margen de Ganancia Deseado", style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _margenController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  filled: true,
                  fillColor: theme.cardTheme.color,
                  suffixText: '%',
                  suffixStyle: TextStyle(color: colorScheme.primary.withOpacity(0.7)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.5))
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colorScheme.primary)
                  ),
                ),
                onChanged: _onManualMarginChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _margenDeseado,
          min: 0.0, 
          max: 1.0, 
          divisions: 100, 
          activeColor: colorScheme.primary,
          onChanged: _onSliderChanged,
        ),

        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
            color: colorScheme.primary.withOpacity(0.1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Costo Fijo Oculto", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.8))),
                  Text("por cada producto", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
                ],
              ),
              Text(
                currencyFormatter.format(_costoFijoUnitarioEstimado),
                // QA FIX: Texto visible en ambos modos
                style: TextStyle(color: colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _saveStrategy,
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              // Texto botón legible (Negro/Blanco)
              foregroundColor: colorScheme.onPrimary
            ),
            icon: const Icon(Icons.save_as),
            label: _isSaving 
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2)) 
              : const Text("Confirmar Estrategia", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}