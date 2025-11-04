// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 26/10/2025
// Style: Cyber Glow
// This modal was refactored to align with the "Cyber Glow" design,
// reusing the same custom form widgets from AddExpenseModal for
// perfect visual consistency.
// CORRECCIÓN: Se eliminó el padding de viewInsets.bottom, que ahora es
// manejado por el builder de showModalBottomSheet en analysis_tab.dart.
// ---------------------------------

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

  // --- Paleta de Colores "Cyber Glow" ---
  static const Color accentColor = Color(0xFF00BFFF);
  static const Color surfaceColor = Color(0xFF2D2D5A);
  static const Color backgroundColor = Color(0xFF1A1A2E);
  static const Color successColor = Color(0xFF00FF7F);
  static const Color errorColor = Colors.redAccent;

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

  /// Muestra el DatePicker para seleccionar la fecha
  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 2),
      // --- Estilo Cyber Glow para DatePicker ---
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: accentColor,
              onPrimary: Colors.black,
              surface: surfaceColor,
              onSurface: Colors.white,
            ), dialogTheme: DialogThemeData(backgroundColor: backgroundColor),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }


  /// Valida y envía el formulario
  Future<void> _submitForm() async {
    // Validar que el formulario esté completo
    if (!_formKey.currentState!.validate() || _selectedCategoria == null) {
      if (_selectedCategoria == null) {
        _showSnackbar('Por favor, selecciona una categoría.', isError: true);
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
      
      await repository.addPresupuesto(newPresupuesto);

      if (!mounted) return;

      // Éxito
      _showSnackbar('Presupuesto añadido con éxito');
      Navigator.of(context).pop();

    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Error al guardar: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
     if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        message, 
        style: TextStyle(
          color: isError ? Colors.white : Colors.black, // Contraste
          fontWeight: FontWeight.bold
        )
      ),
      backgroundColor: isError ? errorColor : successColor,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    // --- CORRECCIÓN DE TECLADO ---
    // Se elimina el padding para 'viewInsets.bottom' de aquí.
    return Padding(
      padding: const EdgeInsets.only(
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
              const Text(
                'Añadir Presupuesto',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 24),
              
              // --- Monto Meta ---
              _StyledTextFormField(
                controller: _montoController,
                labelText: 'Monto Meta',
                prefixIcon: Icons.track_changes_rounded,
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
              _StyledDropdownField(
                value: _selectedCategoria,
                hint: 'Categoría del Presupuesto',
                prefixIcon: Icons.category_outlined,
                items: _categoriasGasto,
                onChanged: (value) {
                  setState(() => _selectedCategoria = value);
                },
                validator: (value) => value == null ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              
              // --- Selector de Mes (Rediseñado) ---
              InputDecorator(
                decoration: _buildInputDecoration(
                  labelText: 'Mes del Presupuesto',
                  prefixIcon: Icons.calendar_today_rounded,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy', 'es_ES').format(_selectedDate),
                      style: const TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 16
                      ),
                    ),
                    TextButton(
                      onPressed: _pickDate,
                      style: TextButton.styleFrom(foregroundColor: accentColor),
                      child: const Row(
                         children: [
                           Icon(Icons.edit_calendar_outlined, size: 20),
                           SizedBox(width: 8),
                           Text('Cambiar'),
                         ],
                       ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Botón de Guardar (Rediseñado) ---
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _submitForm,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_isLoading ? 'Guardando...' : 'Añadir Presupuesto'),
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.black,
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

// --- WIDGETS DE FORMULARIO ESTILIZADOS ---

/// Un TextFormField con el estilo "Cyber Glow".
class _StyledTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;

  const _StyledTextFormField({
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: _buildInputDecoration(
        labelText: labelText,
        prefixIcon: prefixIcon,
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}

/// Un DropdownButtonFormField con el estilo "Cyber Glow".
class _StyledDropdownField extends StatelessWidget {
  final String? value;
  final String hint;
  final IconData prefixIcon;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String>? validator;

  const _StyledDropdownField({
    required this.value,
    required this.hint,
    required this.prefixIcon,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      hint: Text(hint, style: const TextStyle(color: Colors.white70)),
      isExpanded: true,
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(item, overflow: TextOverflow.ellipsis),
      )).toList(),
      onChanged: onChanged,
      validator: validator,
      // --- Estilo "Cyber Glow" ---
      style: const TextStyle(color: Colors.white),
      iconEnabledColor: const Color(0xFF00BFFF),
      decoration: _buildInputDecoration(
        labelText: hint,
        prefixIcon: prefixIcon,
      ),
      dropdownColor: const Color(0xFF2D2D5A), // Color del menú
    );
  }
}

/// Helper centralizado para la decoración de inputs.
InputDecoration _buildInputDecoration({required String labelText, IconData? prefixIcon}) {
  const accentColor = Color(0xFF00BFFF);
  const formFieldColor = Color(0xFF1A1A2E); // Fondo más oscuro para contraste

  return InputDecoration(
    labelText: labelText,
    labelStyle: const TextStyle(color: Colors.white70),
    prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: accentColor, size: 20) : null,
    filled: true,
    fillColor: formFieldColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: accentColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.redAccent.shade100, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
    ),
  );
}

