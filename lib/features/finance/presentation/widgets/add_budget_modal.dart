import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/presupuesto_financiero_model.dart';
import '../../data/repositories/finance_repository.dart';
import '../providers/finance_providers.dart'; // Para leer los gastos existentes

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

/// Modal para crear un nuevo Presupuesto.
class AddBudgetModal extends ConsumerStatefulWidget {
  const AddBudgetModal({super.key});

  @override
  ConsumerState<AddBudgetModal> createState() => _AddBudgetModalState();
}

class _AddBudgetModalState extends ConsumerState<AddBudgetModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _montoController;

  // Valores del estado del formulario
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoria;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _montoController = TextEditingController();
  }

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  /// Valida y envía el formulario
  Future<void> _submitForm() async {
    // Validar que el formulario esté completo
    if (!_formKey.currentState!.validate() || _selectedCategoria == null) {
      if (_selectedCategoria == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, selecciona una categoría.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return; // No continuar
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(financeRepositoryProvider);
      final monto = double.tryParse(_montoController.text);
      final mes = DateFormat('yyyy-MM').format(_selectedDate);

      if (monto == null) {
        throw Exception('Monto inválido');
      }

      // --- Validación Anti-Duplicados ---
      // Obtenemos los presupuestos existentes ANTES de añadir uno nuevo
      final presupuestosExistentes = await ref.read(presupuestosStreamProvider.future);
      final yaExiste = presupuestosExistentes.any(
        (p) => p.mes == mes && p.categoria == _selectedCategoria!,
      );

      if (yaExiste) {
        throw Exception('Ya existe un presupuesto para esta categoría este mes.');
      }
      
      // --- Modo Crear ---
      final newPresupuesto = PresupuestoFinancieroModel(
        id: const Uuid().v4(), // Generar ID único
        mes: mes,
        categoria: _selectedCategoria!,
        montoMeta: monto,
        activo: true, // Siempre se crea como activo
      );
      
      // Aquí estaba el Error 1
      await repository.addPresupuesto(newPresupuesto);

      // --- CORRECCIÓN (Error 2): Chequear 'mounted' ---
      if (!mounted) return;

      // Éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Presupuesto añadido con éxito'),
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
          content: Text('Error al guardar: ${e.toString()}'),
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
                'Añadir Presupuesto',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              
              // --- Monto Meta ---
              TextFormField(
                controller: _montoController,
                decoration: const InputDecoration(
                  labelText: 'Monto Meta',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.track_changes),
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
                  labelText: 'Categoría del Presupuesto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              const SizedBox(height: 16),
              
              // --- Selector de Mes ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mes del Presupuesto:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    // Simple picker para el mes (simplificado)
                    // Para un picker de solo mes/año real, se necesitaría un paquete
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(DateTime.now().year - 1),
                        lastDate: DateTime(DateTime.now().year + 2),
                        // Opcional: Cambiar el modo inicial a solo mes/año
                        // initialDatePickerMode: DatePickerMode.year, 
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _selectedDate = pickedDate;
                        });
                      }
                    },
                    child: Text(
                      DateFormat('MMMM yyyy', 'es_ES').format(_selectedDate),
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
                  label: Text(_isLoading ? 'Guardando...' : 'Añadir Presupuesto'),
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

