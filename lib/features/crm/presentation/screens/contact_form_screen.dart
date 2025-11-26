import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para InputFormatters
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
    return ChangeNotifierProvider(
      create: (context) => ContactFormViewModel(widget.crmRepository),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Añadir Nuevo Contacto', style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
        body: Consumer<ContactFormViewModel>(
          builder: (context, viewModel, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              // QA FIX: Envolvemos todo en un widget Form vinculado a la _formKey
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction, // Feedback inmediato
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información Esencial',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                    const Divider(),
                    
                    _buildTextField(
                      context,
                      label: 'Nombre Completo (*)',
                      hint: 'Ej: Ana Torres',
                      initialValue: viewModel.nombre,
                      keyboardType: TextInputType.name,
                      onChanged: viewModel.setNombre,
                      // QA FIX: Validación de nombre (no vacío, min 3 letras)
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'El nombre es obligatorio';
                        if (value.trim().length < 3) return 'El nombre es muy corto';
                        return null;
                      },
                      // QA FIX: Solo permitir letras y espacios (no números ni símbolos raros)
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                      ],
                    ),

                    _buildTextField(
                      context,
                      label: 'Email (*)',
                      hint: 'ejemplo@contacto.com',
                      initialValue: viewModel.email,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: viewModel.setEmail,
                      // QA FIX: Regex estricto para email
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'El email es obligatorio';
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value)) return 'Ingresa un email válido';
                        return null;
                      },
                    ),

                    _buildTextField(
                      context,
                      label: 'Teléfono (*)',
                      hint: '+54 9 11 XXXX-XXXX',
                      initialValue: viewModel.telefono,
                      keyboardType: TextInputType.phone,
                      onChanged: viewModel.setTelefono,
                      // QA FIX: Validación de longitud mínima y caracteres
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'El teléfono es obligatorio';
                        if (value.length < 8) return 'El número es muy corto';
                        return null;
                      },
                      // QA FIX: Solo permitir números, espacios, guiones y el signo +
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    const Text(
                      'Tipo de Contacto',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                    const Divider(),

                    DropdownButtonFormField<CrmEstado>(
                      decoration: const InputDecoration(
                        labelText: 'Estado CRM Inicial',
                        border: OutlineInputBorder(),
                      ),
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
                      // QA FIX: Asegurar que no sea nulo (aunque tenga default, es buena práctica)
                      validator: (value) => value == null ? 'Selecciona un estado' : null,
                    ),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: viewModel.isLoading
                            ? null
                            : () {
                                // QA FIX: La barrera de seguridad final.
                                // Si el formulario no es válido, NO llamamos a createContact.
                                if (_formKey.currentState!.validate()) {
                                  // Opcional: Guardar el estado actual de los campos si usas controladores
                                  _formKey.currentState!.save(); 
                                  viewModel.createContact(context);
                                } else {
                                  // Feedback visual si intentan guardar con errores
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Por favor corrige los errores en rojo.'),
                                      backgroundColor: Colors.red.shade700,
                                    ),
                                  );
                                }
                              },
                        icon: viewModel.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save, color: Colors.white),
                        label: Text(
                          viewModel.isLoading ? 'Guardando...' : 'Guardar Contacto',
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
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
    required String label,
    required String hint,
    required ValueChanged<String> onChanged,
    required String initialValue,
    required TextInputType keyboardType,
    // Nuevos parámetros para QA
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        onChanged: onChanged,
        keyboardType: keyboardType,
        validator: validator, // Inyección de lógica de validación
        inputFormatters: inputFormatters, // Inyección de restricciones de teclado
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          // Mejora visual: Icono de error si falla la validación
          errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
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