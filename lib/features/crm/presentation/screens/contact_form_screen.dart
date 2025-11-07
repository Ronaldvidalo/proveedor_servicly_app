import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importaciones de paquete:
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart';
import 'package:proveedor_servicly_app/features/crm/presentation/providers/contact_form_viewmodel.dart';
import 'package:proveedor_servicly_app/features/crm/core/crm_enums.dart';

// Pantalla modal para la creación manual de Leads o Clientes.
class ContactFormScreen extends StatelessWidget {
  // ELIMINAMOS LA LECTURA DEL REPOSITORIO DESDE EL MÉTODO CREATE
  // Y LO ACEPTAMOS COMO PARÁMETRO REQUERIDO.
  final CrmRepository crmRepository;

  const ContactFormScreen({required this.crmRepository, super.key});

  @override
  Widget build(BuildContext context) {
    // Inyectamos el ViewModel del formulario, pasando el Repositorio ACEPTADO
    return ChangeNotifierProvider(
      create: (context) => ContactFormViewModel(crmRepository), // <-- Repositorio inyectado aquí
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Añadir Nuevo Contacto', style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
        body: Consumer<ContactFormViewModel>(
          builder: (context, viewModel, child) {
            // ... (resto del cuerpo del formulario, que es funcionalmente correcto)
            // CÓDIGO DEL CUERPO DEL FORMULARIO:
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información Esencial',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                  const Divider(),
                  
                  // Campo Nombre Completo
                  _buildTextField(
                    context,
                    label: 'Nombre Completo (*)',
                    hint: 'Ej: Ana Torres',
                    onChanged: viewModel.setNombre,
                    initialValue: viewModel.nombre,
                    keyboardType: TextInputType.name,
                  ),

                  // Campo Email
                  _buildTextField(
                    context,
                    label: 'Email',
                    hint: 'ejemplo@contacto.com',
                    onChanged: viewModel.setEmail,
                    initialValue: viewModel.email,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  // Campo Teléfono
                  _buildTextField(
                    context,
                    label: 'Teléfono',
                    hint: '+54 9 11 XXXX-XXXX',
                    onChanged: viewModel.setTelefono,
                    initialValue: viewModel.telefono,
                    keyboardType: TextInputType.phone,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Selector de Estado (Lead o Cliente Activo)
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
                    initialValue: viewModel.estadoSeleccionado,
                    items: viewModel.availableStates.map((CrmEstado estado) {
                      return DropdownMenuItem<CrmEstado>(
                        value: estado,
                        child: Text(_getEstadoLabel(estado)),
                      );
                    }).toList(),
                    onChanged: viewModel.setEstadoSeleccionado,
                  ),

                  const SizedBox(height: 40),

                  // Botón de Guardar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: viewModel.isLoading
                          ? null
                          : () => viewModel.createContact(context),
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
            );
          },
        ),
      ),
    );
  }

  // Helper para construir campos de texto
  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required String hint,
    required ValueChanged<String> onChanged,
    required String initialValue,
    required TextInputType keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        onChanged: onChanged,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // Helper para obtener la etiqueta visible del estado
  String _getEstadoLabel(CrmEstado estado) {
    if (estado == CrmEstado.lead) {
      return 'Lead (Contacto Potencial)';
    } else if (estado == CrmEstado.clienteActivo) {
      return 'Cliente Activo (Ya pagó)';
    }
    return estado.name;
  }
}