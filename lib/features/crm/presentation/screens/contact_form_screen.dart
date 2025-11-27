import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Importaciones de paquete:
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart';
import 'package:proveedor_servicly_app/features/crm/presentation/providers/contact_form_viewmodel.dart';
import 'package:proveedor_servicly_app/features/crm/core/crm_enums.dart';

// QA FIX: Convertido a StatefulWidget para manejar la GlobalKey del formulario correctamente.
class ContactFormScreen extends StatefulWidget {
  final CrmRepository crmRepository;

  const ContactFormScreen({required this.crmRepository, super.key});

  @override
  State<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends State<ContactFormScreen> {
  // QA FIX: Clave global para identificar y validar el formulario.
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    // QA FIX: Obtener tema
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Decoración base adaptable
    final inputDecorationTheme = theme.inputDecorationTheme;
    final baseInputDecoration = InputDecoration(
      filled: true,
      fillColor: inputDecorationTheme.fillColor,
      labelStyle: inputDecorationTheme.labelStyle,
      border: inputDecorationTheme.border,
      focusedBorder: inputDecorationTheme.focusedBorder,
      enabledBorder: inputDecorationTheme.enabledBorder,
      errorBorder: inputDecorationTheme.errorBorder,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
    );

    return ChangeNotifierProvider(
      create: (context) => ContactFormViewModel(widget.crmRepository),
      child: Scaffold(
        // Fondo dinámico
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Añadir Nuevo Contacto', style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: theme.scaffoldBackgroundColor, // Adaptable
          foregroundColor: colorScheme.onSurface, // Texto negro/blanco
          elevation: 0,
        ),
        body: Consumer<ContactFormViewModel>(
          builder: (context, viewModel, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction, 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información Esencial',
                      // Título secundario adaptable
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold, 
                        color: colorScheme.onSurface.withValues(alpha: 0.8)
                      ),
                    ),
                    Divider(color: theme.dividerColor),
                    
                    _buildTextField(
                      context,
                      decoration: baseInputDecoration,
                      label: 'Nombre Completo (*)',
                      hint: 'Ej: Ana Torres',
                      initialValue: viewModel.nombre,
                      keyboardType: TextInputType.name,
                      onChanged: viewModel.setNombre,
                      style: TextStyle(color: colorScheme.onSurface),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'El nombre es obligatorio';
                        if (value.trim().length < 3) return 'El nombre es muy corto';
                        return null;
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                      ],
                    ),

                    _buildTextField(
                      context,
                      decoration: baseInputDecoration,
                      label: 'Email (*)',
                      hint: 'ejemplo@contacto.com',
                      initialValue: viewModel.email,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: viewModel.setEmail,
                      style: TextStyle(color: colorScheme.onSurface),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'El email es obligatorio';
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value)) return 'Ingresa un email válido';
                        return null;
                      },
                    ),

                    _buildTextField(
                      context,
                      decoration: baseInputDecoration,
                      label: 'Teléfono (*)',
                      hint: '+54 9 11 XXXX-XXXX',
                      initialValue: viewModel.telefono,
                      keyboardType: TextInputType.phone,
                      onChanged: viewModel.setTelefono,
                      style: TextStyle(color: colorScheme.onSurface),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'El teléfono es obligatorio';
                        if (value.length < 8) return 'El número es muy corto';
                        return null;
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    Text(
                      'Tipo de Contacto',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold, 
                        color: colorScheme.onSurface.withValues(alpha: 0.8)
                      ),
                    ),
                    Divider(color: theme.dividerColor),

                    DropdownButtonFormField<CrmEstado>(
                      decoration: baseInputDecoration.copyWith(labelText: 'Estado CRM Inicial'),
                      // QA FIX: Dropdown fondo tarjeta
                      dropdownColor: theme.cardTheme.color,
                      style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
                      value: viewModel.estadoSeleccionado,
                      items: viewModel.availableStates.map((CrmEstado estado) {
                        return DropdownMenuItem<CrmEstado>(
                          value: estado,
                          child: Text(_getEstadoLabel(estado)),
                        );
                      }).toList(),
                      onChanged: (val) {
                          if(val != null) viewModel.setEstadoSeleccionado(val);
                      },
                      validator: (value) => value == null ? 'Selecciona un estado' : null,
                    ),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: viewModel.isLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save(); 
                                  viewModel.createContact(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Por favor corrige los errores en rojo.'),
                                      backgroundColor: Colors.red.shade700,
                                    ),
                                  );
                                }
                              },
                        icon: viewModel.isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save, color: Colors.white),
                        label: Text(
                          viewModel.isLoading ? 'Guardando...' : 'Guardar Contacto',
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600, // Verde éxito consistente
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper method refactorizado para aceptar validadores y formatters
  Widget _buildTextField(
    BuildContext context, {
    required InputDecoration decoration,
    required String label,
    required String hint,
    required ValueChanged<String> onChanged,
    required String initialValue,
    required TextInputType keyboardType,
    required TextStyle style,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        onChanged: onChanged,
        keyboardType: keyboardType,
        style: style, // Estilo dinámico
        validator: validator, 
        inputFormatters: inputFormatters, 
        decoration: decoration.copyWith(
          labelText: label,
          hintText: hint,
        ),
      ),
    );
  }

  String _getEstadoLabel(CrmEstado estado) {
    if (estado == CrmEstado.lead) {
      return 'Lead (Contacto Potencial)';
    } else if (estado == CrmEstado.clienteActivo) {
      return 'Cliente Activo (Ya pagó)';
    }
    return estado.name;
  }
}