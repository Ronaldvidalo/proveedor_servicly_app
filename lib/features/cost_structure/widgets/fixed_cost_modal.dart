// ignore_for_file: deprecated_member_use
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
  late TextEditingController _montoController; // El monto que ingresa el usuario (ej. 1200 anual)
  
  String? _selectedCategoria;
  String _selectedFrecuencia = 'Mensual'; // Por defecto
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _conceptoController = TextEditingController(text: widget.cost?.concepto ?? '');
    
    // Si editamos, necesitamos ingeniería inversa: 
    // Si guardamos $100 (mensual) pero la frecuencia era Anual, mostramos $1200.
    // Pero para simplificar por ahora, mostraremos el monto mensual guardado si editamos.
    // O mejor: Si el modelo guarda el monto mensual, al editar lo dejamos tal cual.
    _montoController = TextEditingController(text: widget.cost?.montoMensual.toStringAsFixed(0) ?? '');
    
    _selectedCategoria = widget.cost?.categoria;
    if (widget.cost != null) {
      _selectedFrecuencia = widget.cost!.frecuencia;
      
      // AJUSTE VISUAL PARA EDICIÓN:
      // Si el usuario guardó "Anual" y el monto mensual es 100, 
      // queremos que al abrir el modal vea "1200" en el input.
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
        return montoInput * 4; // Aprox 4 semanas por mes
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
        montoMensual: montoFinalMensual, // Guardamos SIEMPRE el valor mensualizado
        categoria: _selectedCategoria!,
        frecuencia: _selectedFrecuencia, // Guardamos la preferencia del usuario
        activo: true,
      );

      await repo.saveFixedCost(newCost);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00BFFF);

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
            const Text("Nuevo Costo Fijo", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            TextFormField(
              controller: _conceptoController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Concepto (Ej: Seguro Local)", Icons.label_outline),
              validator: (v) => v!.isEmpty ? "Requerido" : null,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                // Input Monto (Flexible)
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _montoController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Monto", Icons.attach_money),
                    validator: (v) => v!.isEmpty ? "Requerido" : null,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Dropdown Frecuencia
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedFrecuencia,
                    dropdownColor: const Color(0xFF2D2D5A),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Frecuencia", Icons.repeat),
                    items: _frecuencias.map((f) => DropdownMenuItem(value: f, child: Text(f, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => setState(() => _selectedFrecuencia = v!),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _selectedCategoria,
              dropdownColor: const Color(0xFF2D2D5A),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Categoría", Icons.category_outlined),
              items: _categoriasFijas.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCategoria = v),
            ),
            const SizedBox(height: 24),
            
            // Aviso visual de conversión (Feedback inmediato)
            if (_montoController.text.isNotEmpty && _selectedFrecuencia != 'Mensual')
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor.withOpacity(0.3))
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: accentColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Se registrará como \$${_calcularMontoMensualNormalizado(double.tryParse(_montoController.text) ?? 0).toStringAsFixed(2)} / mes en tus costos.",
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                style: FilledButton.styleFrom(backgroundColor: accentColor, padding: const EdgeInsets.all(16)),
                child: _isLoading ? const CircularProgressIndicator() : const Text("Guardar", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: const Color(0xFF00BFFF)),
      filled: true,
      fillColor: const Color(0xFF1A1A2E),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}