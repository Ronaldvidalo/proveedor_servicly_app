import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:proveedor_servicly_app/features/cost_structure/data/models/fixed_cost_model.dart';
import 'package:proveedor_servicly_app/features/finance/presentation/providers/finance_providers.dart';

const List<String> _categoriasFijas = ['Administrativo', 'Operativo', 'Ventas', 'Financiero'];
const List<String> _frecuencias = ['Semanal', 'Quincenal', 'Mensual', 'Trimestral', 'Semestral', 'Anual'];

class FixedCostModal extends ConsumerStatefulWidget {
  final FixedCostModel? cost;

  const FixedCostModal({super.key, this.cost});

  @override
  ConsumerState<FixedCostModal> createState() => _FixedCostModalState();
}

class _FixedCostModalState extends ConsumerState<FixedCostModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _conceptoController;
  late TextEditingController _montoController; 
  
  String? _selectedCategoria;
  String _selectedFrecuencia = 'Mensual'; 
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _conceptoController = TextEditingController(text: widget.cost?.concepto ?? '');
    
    // Si el modelo guarda el monto mensual, al editar lo dejamos tal cual por ahora,
    // o aplicamos la inversa visual si se desea.
    _montoController = TextEditingController(text: widget.cost?.montoMensual.toStringAsFixed(0) ?? '');
    
    _selectedCategoria = widget.cost?.categoria;
    if (widget.cost != null) {
      _selectedFrecuencia = widget.cost!.frecuencia;
      
      double montoOriginal = widget.cost!.montoMensual;
      if (_selectedFrecuencia == 'Anual') _montoController.text = (montoOriginal * 12).toStringAsFixed(0);
      if (_selectedFrecuencia == 'Semestral') _montoController.text = (montoOriginal * 6).toStringAsFixed(0);
      if (_selectedFrecuencia == 'Trimestral') _montoController.text = (montoOriginal * 3).toStringAsFixed(0);
      if (_selectedFrecuencia == 'Quincenal') _montoController.text = (montoOriginal / 2).toStringAsFixed(0);
      if (_selectedFrecuencia == 'Semanal') _montoController.text = (montoOriginal / 4).toStringAsFixed(0);
    }
  }

  // LA MAGIA MATEMÁTICA 🧮
  double _calcularMontoMensualNormalizado(double montoInput) {
    switch (_selectedFrecuencia) {
      case 'Semanal':
        return montoInput * 4; 
      case 'Quincenal':
        return montoInput * 2;
      case 'Mensual':
        return montoInput;
      case 'Trimestral':
        return montoInput / 3;
      case 'Semestral':
        return montoInput / 6;
      case 'Anual':
        return montoInput / 12;
      default:
        return montoInput;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCategoria == null) return;

    setState(() => _isLoading = true);
    final repo = ref.read(financeRepositoryProvider);

    try {
      final double montoIngresado = double.parse(_montoController.text);
      final double montoFinalMensual = _calcularMontoMensualNormalizado(montoIngresado);

      final newCost = FixedCostModel(
        id: widget.cost?.id ?? const Uuid().v4(),
        concepto: _conceptoController.text,
        montoMensual: montoFinalMensual, 
        categoria: _selectedCategoria!,
        frecuencia: _selectedFrecuencia, 
        activo: true,
      );

      await repo.saveFixedCost(newCost);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // QA FIX: Obtener tema del contexto
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = colorScheme.primary;

    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Nuevo Costo Fijo", 
              // QA FIX: Texto de título dinámico
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface
              )
            ),
            const SizedBox(height: 20),
            
            TextFormField(
              controller: _conceptoController,
              // QA FIX: Estilo de texto input dinámico
              style: TextStyle(color: colorScheme.onSurface),
              decoration: _inputDecoration(theme, "Concepto (Ej: Seguro Local)", Icons.label_outline),
              validator: (v) => v!.isEmpty ? "Requerido" : null,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                // Input Monto
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _montoController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(theme, "Monto", Icons.attach_money),
                    validator: (v) => v!.isEmpty ? "Requerido" : null,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Dropdown Frecuencia
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedFrecuencia,
                    // QA FIX: Fondo del dropdown dinámico
                    dropdownColor: theme.cardTheme.color,
                    style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
                    decoration: _inputDecoration(theme, "Frecuencia", Icons.repeat),
                    items: _frecuencias.map((f) => DropdownMenuItem(
                      value: f, 
                      child: Text(f, overflow: TextOverflow.ellipsis)
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedFrecuencia = v!),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              initialValue: _selectedCategoria,
              dropdownColor: theme.cardTheme.color,
              style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
              decoration: _inputDecoration(theme, "Categoría", Icons.category_outlined),
              items: _categoriasFijas.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCategoria = v),
            ),
            const SizedBox(height: 24),
            
            // Aviso visual de conversión
            if (_montoController.text.isNotEmpty && _selectedFrecuencia != 'Mensual')
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    // QA FIX: Fondo del aviso adaptable
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor.withValues(alpha: 0.3))
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: accentColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Se registrará como \$${_calcularMontoMensualNormalizado(double.tryParse(_montoController.text) ?? 0).toStringAsFixed(2)} / mes en tus costos.",
                          // QA FIX: Texto secundario adaptable
                          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor, 
                  // QA FIX: Texto botón legible (Negro sobre neón, o blanco sobre oscuro)
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.all(16)
                ),
                child: _isLoading 
                  ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2)) 
                  : const Text("Guardar", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  // QA FIX: Input Decoration Adaptable
  InputDecoration _inputDecoration(ThemeData theme, String label, IconData icon) {
    final colorScheme = theme.colorScheme;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
      prefixIcon: Icon(icon, color: colorScheme.primary),
      filled: true,
      // Fondo del input: Usamos el color de input definido en el tema o el de tarjeta
      fillColor: theme.inputDecorationTheme.fillColor ?? theme.cardTheme.color,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      // Borde activo usa el color primario
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), 
        borderSide: BorderSide(color: colorScheme.primary, width: 2)
      ),
    );
  }
}