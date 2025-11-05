import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/features/crm/data/models/cliente_model.dart';
import 'package:proveedor_servicly_app/features/crm/presentation/providers/lead_list_viewmodel.dart';
import 'package:proveedor_servicly_app/features/crm/core/crm_enums.dart';

// El widget LeadsTab implementa la interfaz de usuario para la gestión de Leads.
class LeadsTab extends StatelessWidget {
  const LeadsTab({super.key});

  // Widget auxiliar para mostrar un bloqueo de característica Pro
  Widget _buildProLock(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 20, left: 16, right: 16),
      child: Chip(
        label: Text('Funcionalidad Pro: Embudo avanzado y captura automática de Leads.'),
        backgroundColor: Colors.amber,
        labelStyle: TextStyle(fontSize: 12),
      ),
    );
  }

  // Widget que muestra el menú contextual para cambiar el estado de un Lead (PRO)
  Widget _buildPipelineMenu(BuildContext context, LeadListViewModel viewModel, Cliente lead) {
    final availableStates = viewModel.availableLeadPipelineStates;

    return PopupMenuButton<CrmEstado>(
      onSelected: (CrmEstado newStatus) {
        viewModel.updateLeadStatus(lead.id, newStatus, context);
      },
      itemBuilder: (BuildContext context) {
        // --- CORRECCIÓN CLAVE ---
        // 1. Usamos .where para filtrar el estado actual.
        // 2. Usamos .toList() con un cast explícito para asegurar el tipo.
        return availableStates
            .where((estado) => estado != lead.estadoCRM) // Quita el estado actual
            .map((CrmEstado estado) {
              return PopupMenuItem<CrmEstado>(
                value: estado,
                child: Text(
                  'Mover a ${viewModel.getLeadStatusLabel(estado)}',
                  style: TextStyle(
                    color: (estado == CrmEstado.clienteActivo) ? Colors.green.shade700 : Colors.black,
                    fontWeight: (estado == CrmEstado.clienteActivo) ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(); // La inferencia es correcta aquí porque ya filtramos
        // ------------------------
      },
      icon: const Icon(Icons.more_vert, size: 20),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<LeadListViewModel>(
      builder: (context, viewModel, child) {
        final isProUser = viewModel.isProUser;
        
        return StreamBuilder<List<Cliente>>(
          stream: viewModel.filteredLeadsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error al cargar leads: ${snapshot.error}'));
            }

            final leads = snapshot.data ?? [];
            Widget content;

            if (leads.isEmpty) {
              content = const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add_disabled, size: 60, color: Colors.blueGrey),
                      SizedBox(height: 20),
                      Text('No hay Leads activos.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Crea un Lead manualmente para empezar el seguimiento.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              );
            } else {
              content = ListView.builder(
                itemCount: leads.length,
                itemBuilder: (context, index) {
                  final lead = leads[index];
                  
                  // Decide qué trailing widget usar basado en el plan (Pro vs. Free)
                  Widget trailingWidget = isProUser 
                    ? _buildPipelineMenu(context, viewModel, lead)
                    : ElevatedButton(
                        onPressed: () => viewModel.convertLeadToClient(lead.id, context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero, // Para reducir el tamaño mínimo
                        ),
                        child: const Text('Convertir'),
                      );

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: viewModel.getLeadStatusColor(lead.estadoCRM),
                        child: Text(viewModel.getLeadStatusInitial(lead.estadoCRM), style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(lead.nombreCompleto),
                      subtitle: Text(
                        'Estado: ${viewModel.getLeadStatusLabel(lead.estadoCRM)} - Teléfono: ${lead.telefono.isNotEmpty ? lead.telefono : 'N/A'}',
                      ),
                      trailing: trailingWidget,
                      onTap: () {
                          // Navegación a la pantalla de detalle del Lead (similar a ClientDetailScreen)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Abriendo detalle del Lead ${lead.nombreCompleto}')),
                          );
                      },
                    ),
                  );
                },
              );
            }

            // Diseño final: Lista de Leads y barra de Pro si es Free
            return Column(
              children: [
                Expanded(child: content),
                if (!isProUser) _buildProLock(context),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }
}