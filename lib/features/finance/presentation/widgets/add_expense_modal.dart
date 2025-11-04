// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 26/10/2025
// Style: Cyber Glow
// This modal was fully refactored to align with the "Cyber Glow" design,
// reusing the same custom form widgets from AddExpenseModal for
// perfect visual consistency.
// CORRECCIÓN: Se eliminó el padding de viewInsets.bottom, que ahora es
// manejado por el builder de showModalBottomSheet en expenses_tab.dart.
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/gasto_model.dart';
// --- CORRECCIÓN DE IMPORT ---
// Importamos el archivo de providers, que ahora contiene el financeRepositoryProvider
import '../providers/finance_providers.dart'; 

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

  // --- Paleta de Colores "Cyber Glow" ---
  static const Color accentColor = Color(0xFF00BFFF);
  static const Color surfaceColor = Color(0xFF2D2D5A);
  static const Color backgroundColor = Color(0xFF1A1A2E);
  static const Color successColor = Color(0xFF00FF7F);
  static const Color errorColor = Colors.redAccent;

  @override
  void initState() {
    super.initState();
    _montoController = TextEditingController(
      text: widget.gasto?.monto.toStringAsFixed(0) ?? '',
    );
    _conceptoController = TextEditingController(
      text: widget.gasto?.concepto ?? '',
    );
    
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
      // --- Estilo Cyber Glow para DatePicker ---
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: accentColor,
              onPrimary: Colors.black,
              surface: surfaceColor,
              onSurface: Colors.white,
            ),
            // --- CORRECCIÓN DE LINTER ---
            // 'dialogBackgroundColor' obsoleto, usamos 'dialogTheme'
            // --- CORRECCIÓN DE SINTAXIS ---
            // Debe ser 'DialogThemeData'
            dialogTheme: const DialogThemeData(
              backgroundColor: backgroundColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  /// Valida y envía el formulario
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() ||
        _selectedCategoria == null ||
        _selectedTipo == null) {
      
      if (_selectedCategoria == null || _selectedTipo == null) {
        _showSnackbar('Por favor, completa todos los campos.', isError: true);
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(financeRepositoryProvider); // <-- Esto ahora funciona
      final monto = double.tryParse(_montoController.text);
      final concepto = _conceptoController.text;

      if (monto == null) {
        throw Exception('Monto inválido');
      }

      if (_isEditing) {
        final updatedGasto = widget.gasto!.copyWith(
          monto: monto,
          concepto: concepto,
          fecha: _selectedDate,
          categoria: _selectedCategoria!,
          tipo: _selectedTipo!,
        );
        await repository.updateGasto(updatedGasto);
      } else {
        final newGasto = GastoModel(
          id: const Uuid().v4(),
          monto: monto,
          concepto: concepto,
          fecha: _selectedDate,
          categoria: _selectedCategoria!,
          tipo: _selectedTipo!,
        );
        await repository.addGasto(newGasto);
      }

      if (!mounted) return;

      _showSnackbar(_isEditing ? 'Gasto actualizado' : 'Gasto añadido');
      Navigator.of(context).pop();

    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Error al guardar: $e', isError: true);
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
    // Se elimina el padding para 'viewInsets.bottom' de aquí,
    // ya que ahora se maneja en 'expenses_tab.dart' (quien lo llama).
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
              Text(
                _isEditing ? 'Editar Gasto' : 'Añadir Gasto',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 24),

              // --- Concepto ---
              _StyledTextFormField(
                controller: _conceptoController,
                labelText: 'Concepto',
                prefixIcon: Icons.description_outlined,
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              
              // --- Monto ---
              _StyledTextFormField(
                controller: _montoController,
                labelText: 'Monto',
                prefixIcon: Icons.attach_money_rounded,
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
                hint: 'Categoría',
                prefixIcon: Icons.category_outlined,
                items: _categoriasGasto,
                onChanged: (value) {
                  setState(() => _selectedCategoria = value);
                },
                validator: (value) => value == null ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              
              // --- Tipo (Fijo/Variable) ---
              _StyledDropdownField(
                value: _selectedTipo,
                hint: 'Tipo de Gasto',
                prefixIcon: Icons.swap_horiz_rounded,
                items: _tiposGasto,
                onChanged: (value) {
                  setState(() => _selectedTipo = value);
                },
                validator: (value) => value == null ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              // --- Selector de Fecha (Rediseñado) ---
              InputDecorator(
                decoration: _buildInputDecoration(
                  labelText: 'Fecha del Gasto',
                  prefixIcon: Icons.calendar_today_rounded,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy', 'es_ES').format(_selectedDate),
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
                  label: Text(_isLoading
                      ? 'Guardando...'
                      : _isEditing
                          ? 'Actualizar Gasto'
                          : 'Añadir Gasto'),
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // Padding inferior para que haya espacio al final del scroll
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
      // El linter reporta 'value' como obsoleto (severity 2),
      // pero es un falso positivo. Usar 'value' es CORRECTO
      // para un componente controlado por 'setState'.
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

