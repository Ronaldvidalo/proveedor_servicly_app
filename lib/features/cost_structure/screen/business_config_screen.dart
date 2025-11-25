// Ignoramos las advertencias de depreciación por versiones nuevas de Flutter
// para centrarnos en que el código funcione primero.
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// --- IMPORTS DE MODELOS ---
import 'package:proveedor_servicly_app/features/cost_structure/data/models/business_config_model.dart';
import 'package:proveedor_servicly_app/features/cost_structure/data/models/fixed_cost_model.dart';

// --- IMPORTS DE PROVIDERS (CORE) ---
import 'package:proveedor_servicly_app/features/cost_structure/core/providers/cost_providers.dart';

// --- IMPORTS DE WIDGETS (VISUALES) ---
// CORREGIDO: MentorCard está en la carpeta 'widgets', no en 'screen'
import 'package:proveedor_servicly_app/features/cost_structure/screen/mentor_card.dart';
// CORREGIDO: Faltaba importar el Modal para agregar costos
import 'package:proveedor_servicly_app/features/cost_structure/data/models/fixed_cost_model.dart';
// --- IMPORTS DE FINANZAS (REPO Y PROVIDER GENERAL) ---
import 'package:proveedor_servicly_app/features/finance/data/repositories/finance_repository.dart';
// CORREGIDO: Faltaba importar el provider del repositorio para usar ref.read(financeRepositoryProvider)
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
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Estructura de Negocio"),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentColor,
          labelColor: accentColor,
          unselectedLabelColor: Colors.white60,
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
            backgroundColor: accentColor,
            child: const Icon(Icons.add, color: Colors.black),
            onPressed: () {
               showModalBottomSheet(
                  context: context, 
                  isScrollControlled: true,
                  backgroundColor: const Color(0xFF2D2D5A),
                  // Ahora sí reconoce FixedCostModal gracias al import corregido
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const MentorCard(
            title: "Paso 1: La Realidad",
            message: "Antes de hablar de inventario, necesito saber cuánto te cuesta abrir la persiana cada mes (Alquiler, Luz, Internet).",
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue.shade900, const Color(0xFF2D2D5A)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              children: [
                const Text("Total Gastos Fijos Mensuales", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(_currencyFormatter.format(totalCosts), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: fixedCostsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text("Error: $err", style: const TextStyle(color: Colors.red)),
              data: (costs) {
                if (costs.isEmpty) return const Center(child: Text("Toca el + para agregar tu primer gasto fijo.", style: TextStyle(color: Colors.white54)));
                return ListView.builder(
                  itemCount: costs.length,
                  itemBuilder: (ctx, index) {
                    final cost = costs[index];
                    return Card(
                      color: const Color(0xFF2D2D5A),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.receipt, color: Color(0xFF00BFFF)),
                        ),
                        title: Text(cost.concepto, style: const TextStyle(color: Colors.white)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_currencyFormatter.format(cost.montoMensual), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              // Ahora reconoce financeRepositoryProvider gracias al import corregido
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

  // --- PESTAÑA 2: ESTRATEGIA (Lógica Híbrida V2) ---
  Widget _buildStrategyTab(BuildContext context) {
    final configAsync = ref.watch(businessConfigStreamProvider);
    final totalFixedCosts = ref.watch(totalFixedCostsProvider);

    return configAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Error: $e")),
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
  late double _margenDeseado; // Valor interno (0.0 a 1.0)
  late TextEditingController _unidadesProyectadasController;
  
  // NUEVO: Controlador para el input manual de margen
  late TextEditingController _margenController; 
  
  bool _isSaving = false;
  final int _mockInventarioTotal = 0; 

  @override
  void initState() {
    super.initState();
    _usarInventarioReal = widget.initialConfig.usarInventarioReal;
    _margenDeseado = widget.initialConfig.margenDeseado;
    _unidadesProyectadasController = TextEditingController(text: widget.initialConfig.unidadesProyectadasMes.toString());
    
    // Inicializamos el texto con el valor actual (ej. 0.3 -> "30")
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

  // Lógica para actualizar cuando se mueve el Slider
  void _onSliderChanged(double value) {
    setState(() {
      _margenDeseado = value;
      // Actualizamos el texto sin perder el foco si fuera necesario, 
      // pero aquí es simple asignación
      _margenController.text = (value * 100).toStringAsFixed(1).replaceAll('.0', '');
    });
  }

  // Lógica para actualizar cuando se escribe manual
  void _onManualMarginChanged(String value) {
    final double? parsed = double.tryParse(value);
    if (parsed != null) {
      setState(() {
        // Convertimos de 30 a 0.30 y limitamos entre 0 y 1
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
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Estrategia actualizada")));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);
    final currencyFormatter = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 2);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Método de Cálculo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              RadioListTile<bool>(
                title: const Text("Estimación Manual", style: TextStyle(color: Colors.white)),
                subtitle: const Text("Usar una meta de ventas.", style: TextStyle(color: Colors.white54, fontSize: 12)),
                value: false,
                groupValue: _usarInventarioReal,
                activeColor: accentColor,
                onChanged: (val) => setState(() => _usarInventarioReal = val!),
              ),
              Divider(color: Colors.white.withOpacity(0.1), height: 1),
              RadioListTile<bool>(
                title: const Text("Basado en Inventario", style: TextStyle(color: Colors.white)),
                subtitle: Text("Usar mi stock real ($_mockInventarioTotal items).", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                value: true,
                groupValue: _usarInventarioReal,
                activeColor: accentColor,
                onChanged: _mockInventarioTotal > 0 ? (val) => setState(() => _usarInventarioReal = val!) : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (!_usarInventarioReal) ...[
          const MentorCard(title: "Proyección", message: "¿Cuántas unidades crees vender al mes?"),
          const SizedBox(height: 12),
          TextFormField(
            controller: _unidadesProyectadasController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Unidades Estimadas",
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: surfaceColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],

        const SizedBox(height: 32),
        
        // --- SECCIÓN DE MARGEN (MEJORADA) ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Flexible(
              child: Text("Margen de Ganancia Deseado", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            // Input Manual Pequeño
            SizedBox(
              width: 80,
              child: TextField(
                controller: _margenController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 18),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  filled: true,
                  fillColor: surfaceColor,
                  suffixText: '%',
                  suffixStyle: TextStyle(color: accentColor.withOpacity(0.7)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: accentColor.withOpacity(0.5))
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: accentColor)
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
          divisions: 100, // Aumentado para más precisión
          activeColor: accentColor,
          onChanged: _onSliderChanged,
        ),
        // ------------------------------------

        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: accentColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
            color: accentColor.withOpacity(0.1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Costo Fijo Oculto", style: TextStyle(color: Colors.white70)),
                  Text("por cada producto", style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
              Text(
                currencyFormatter.format(_costoFijoUnitarioEstimado),
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
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
            style: FilledButton.styleFrom(backgroundColor: accentColor),
            icon: const Icon(Icons.save_as, color: Colors.black),
            label: _isSaving ? const CircularProgressIndicator(color: Colors.black) : const Text("Confirmar Estrategia", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}