import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/features/crm/data/models/cliente_model.dart';
import 'package:proveedor_servicly_app/features/crm/presentation/providers/lead_list_viewmodel.dart';

// El widget LeadsTab implementa la interfaz de usuario para la gestión de Leads.
class LeadsTab extends StatelessWidget {
  const LeadsTab({super.key});

  // Widget auxiliar para mostrar el bloqueo Pro en la parte inferior
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

  @override
  Widget build(BuildContext context) {
    // Usamos Consumer para acceder al LeadListViewModel
    return Consumer<LeadListViewModel>(
      builder: (context, viewModel, child) {
        // StreamBuilder para manejar los datos en tiempo real (Leads)
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
                  // Los leads son clientes con estado LEAD, LEAD_NUEVO, CONTACTADO, etc.
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
                      trailing: ElevatedButton(
                        onPressed: () => viewModel.convertLeadToClient(lead.id, context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text('Convertir'),
                      ),
                      onTap: () {
                         // Aquí se navegaría a una pantalla de detalle de Lead, similar a ClientDetailScreen
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
                if (!viewModel.isProUser) _buildProLock(context),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }
}