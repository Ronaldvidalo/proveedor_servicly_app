import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/gasto_model.dart';
import '../../data/repositories/finance_repository.dart';

// Definición de categorías
const List<String> _categoriasGasto = [
  'Marketing',
  'Operaciones',
  'Software',
  'Transporte',
  'Materiales',
  'Oficina',
  'Impuestos',
  'Otros',
];

const List<String> _tiposGasto = ['FIJO', 'VARIABLE'];

/// Modal para crear o editar un Gasto.
///
/// Si [gasto] no es nulo, el modal se abre en modo "Editar".
/// Si [gasto] es nulo, se abre en modo "Crear".
class AddExpenseModal extends ConsumerStatefulWidget {
  final GastoModel? gasto;

  const AddExpenseModal({
    super.key,
    this.gasto,
  });

  @override
  ConsumerState<AddExpenseModal> createState() => _AddExpenseModalState();
}

class _AddExpenseModalState extends ConsumerState<AddExpenseModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _montoController;
  late TextEditingController _conceptoController;

  // Valores del estado del formulario
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoria;
  String? _selectedTipo;
  bool _isLoading = false;

  // Getter para saber si estamos editando
  bool get _isEditing => widget.gasto != null;

  @override
  void initState() {
    super.initState();
    _montoController = TextEditingController(
      text: widget.gasto?.monto.toStringAsFixed(0) ?? '',
    );
    _conceptoController = TextEditingController(
      text: widget.gasto?.concepto ?? '',
    );
    
    // Pre-llenar campos si estamos en modo "Editar"
    if (_isEditing) {
      _selectedDate = widget.gasto!.fecha;
      _selectedCategoria = widget.gasto!.categoria;
      _selectedTipo = widget.gasto!.tipo;
    }
  }

  @override
  void dispose() {
    _montoController.dispose();
    _conceptoController.dispose();
    super.dispose();
  }

  /// Muestra el DatePicker para seleccionar la fecha
  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  /// Valida y envía el formulario
  Future<void> _submitForm() async {
    // Validar que el formulario esté completo
    if (!_formKey.currentState!.validate() ||
        _selectedCategoria == null ||
        _selectedTipo == null) {
      
      // Mostrar SnackBar si falta categoría o tipo
      if (_selectedCategoria == null || _selectedTipo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, completa todos los campos.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return; // No continuar si el formulario no es válido
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(financeRepositoryProvider);
      final monto = double.tryParse(_montoController.text);
      final concepto = _conceptoController.text;

      if (monto == null) {
        throw Exception('Monto inválido');
      }

      if (_isEditing) {
        // --- Modo Editar ---
        // Aquí es donde necesitamos 'copyWith' (Error 1)
        final updatedGasto = widget.gasto!.copyWith(
          monto: monto,
          concepto: concepto,
          fecha: _selectedDate,
          categoria: _selectedCategoria!,
          tipo: _selectedTipo!,
        );
        await repository.updateGasto(updatedGasto);
      } else {
        // --- Modo Crear ---
        final newGasto = GastoModel(
          id: const Uuid().v4(), // Generar ID único
          monto: monto,
          concepto: concepto,
          fecha: _selectedDate,
          categoria: _selectedCategoria!,
          tipo: _selectedTipo!,
        );
        await repository.addGasto(newGasto);
      }

      // --- CORRECCIÓN (Error 2): Chequear 'mounted' ---
      if (!mounted) return; // Si el widget ya no está, no hacer nada.

      // Éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Gasto actualizado' : 'Gasto añadido'),
          backgroundColor: Colors.green,
        ),
      );
      // Cerrar el modal
      Navigator.of(context).pop();

    } catch (e) {
      setState(() => _isLoading = false);
      
      // --- CORRECCIÓN (Error 3): Chequear 'mounted' ---
      if (!mounted) return;
      
      // Error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Padding para que el teclado no tape el modal
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Título ---
              Text(
                _isEditing ? 'Editar Gasto' : 'Añadir Gasto',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),

              // --- Concepto ---
              TextFormField(
                controller: _conceptoController,
                decoration: const InputDecoration(
                  labelText: 'Concepto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              
              // --- Monto ---
              TextFormField(
                controller: _montoController,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Campo requerido';
                  if (double.tryParse(value) == null) return 'Monto inválido';
                  if (double.parse(value) <= 0) return 'El monto debe ser positivo';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // --- Categoría ---
              DropdownButtonFormField<String>(
                // Error 4: Ignoramos la advertencia de 'value'
                value: _selectedCategoria,
                hint: const Text('Categoría'),
                isExpanded: true,
                items: _categoriasGasto.map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat, overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategoria = value);
                },
                validator: (value) => value == null ? 'Requerido' : null,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              const SizedBox(height: 16),
              
              // --- Tipo (Fijo/Variable) ---
              DropdownButtonFormField<String>(
                // Error 5: Ignoramos la advertencia de 'value'
                value: _selectedTipo,
                hint: const Text('Tipo'),
                isExpanded: true,
                items: _tiposGasto.map((tipo) => DropdownMenuItem(
                  value: tipo,
                  child: Text(tipo),
                )).toList(),
                onChanged: (value) {
                  setState(() => _selectedTipo = value);
                },
                validator: (value) => value == null ? 'Requerido' : null,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Gasto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.swap_horiz),
                ),
              ),
              const SizedBox(height: 16),

              // --- Selector de Fecha ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Fecha del Gasto:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: _pickDate,
                    child: Text(
                      DateFormat('dd/MM/yyyy', 'es_ES').format(_selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Botón de Guardar ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitForm,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isLoading
                      ? 'Guardando...'
                      : _isEditing
                          ? 'Actualizar Gasto'
                          : 'Añadir Gasto'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

