import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:ui'; 
import 'package:provider/provider.dart'; // NECESARIO PARA ACCEDER AL VIEWMODEL

// Modelos y ViewModels
import 'package:proveedor_servicly_app/features/crm/data/models/cliente_model.dart';
import 'package:proveedor_servicly_app/features/crm/core/crm_enums.dart';
import 'package:proveedor_servicly_app/features/crm/core/lead_access_helper.dart'; // Lógica de monetización
import 'package:proveedor_servicly_app/features/crm/presentation/providers/lead_list_viewmodel.dart'; // NUEVO

// Pantallas
import 'package:proveedor_servicly_app/features/crm/presentation/screens/lead_detail_screen.dart';

class SimpleLeadsTab extends StatefulWidget {
  const SimpleLeadsTab({super.key});

  @override
  State<SimpleLeadsTab> createState() => _SimpleLeadsTabState();
}

class _SimpleLeadsTabState extends State<SimpleLeadsTab> {
  
  // Eliminamos la paginación local (_currentLimit) ya que el ViewModel debe manejar la consulta filtrada.

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // 1. Obtener el ViewModel para acceder al Stream filtrado
    final leadViewModel = context.watch<LeadListViewModel>();
    
    // Nota: userPlan debe ser leído del ProviderProfileModel o del UserModel del usuario logueado
    // Por ahora, lo mantenemos como 'free' para simular el candado.
    const String userPlan = 'free'; 

    if (userId == null) return const Center(child: Text('Error: No usuario'));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // 2. El StreamBuilder consume el Stream pre-filtrado del ViewModel
      body: StreamBuilder<List<Cliente>>(
        stream: leadViewModel.filteredLeadsStream, // <- CRÍTICO: Usar el Stream del VM
        builder: (context, snapshot) {
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: colorScheme.primary));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                // Se usa snapshot.error directamente, ya que el VM lo maneja en el listen
                child: Text('Error: ${snapshot.error}', style: TextStyle(color: colorScheme.error), textAlign: TextAlign.center),
              ),
            );
          }

          // Los datos ya están mapeados a List<Cliente>
          final leads = snapshot.data ?? [];

          if (leads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: colorScheme.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(
                    'No hay leads recientes',
                    style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            // Usamos la longitud de la lista directamente
            itemCount: leads.length, 
            itemBuilder: (context, index) {
              
              final cliente = leads[index];
              // La lógica de acceso (monetización) se aplica aquí en la UI
              final bool hasAccess = LeadAccessHelper.canAccessLead(userPlan, cliente.source ?? '');

              return _LeadCard(
                lead: cliente, 
                hasAccess: hasAccess, 
                userPlan: userPlan
              );
            },
          );
        },
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final Cliente lead;
  final bool hasAccess; 
  final String userPlan;
  
  const _LeadCard({
    required this.lead, 
    required this.hasAccess,
    required this.userPlan,
  });

  String _getFriendlySource(String? source) {
    if (source == null) return 'Consulta';
    final s = source.toLowerCase();
    if (s.contains('whatsapp')) return 'WhatsApp';
    if (s.contains('view_product')) return 'Vio Producto';
    if (s.contains('cart')) return 'Carrito Abandonado'; // Fuente de alta intención
    if (s.contains('like')) return 'Le gustó un Producto'; 
    if (s.contains('telefono')) return 'Llamada';
    if (s.contains('email')) return 'Email';
    if (s.contains('presupuesto')) return 'Presupuesto';
    return 'Consulta';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceColor = theme.cardTheme.color;
    
    // Lógica de visualización de monetización:
    final displayName = hasAccess ? lead.nombreCompleto : 'Oportunidad Detectada'; 
    final displaySource = hasAccess ? _getFriendlySource(lead.source) : "Carrito/Interés (Solo PRO)";

    Color statusColor = Colors.blueGrey;
    String statusText = lead.estadoCRM.name; 

    if (lead.estadoCRM == CrmEstado.leadNuevo) {
      statusColor = Colors.blueAccent;
      statusText = 'NUEVO';
    } else if (lead.estadoCRM == CrmEstado.contactado) {
      statusColor = Colors.orange;
      statusText = 'Contactado';
    } else if (lead.estadoCRM == CrmEstado.clienteActivo) {
      statusColor = Colors.green;
      statusText = 'Cliente';
    }

    // Aseguramos que fechaAlta no sea nulo antes de formatear
    final dateStr = lead.fechaAlta != null 
      ? DateFormat('dd MMM - HH:mm').format(lead.fechaAlta!)
      : 'Fecha desconocida';

    return Card(
      color: surfaceColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (hasAccess) {
             Navigator.push(context, MaterialPageRoute(builder: (_) => LeadDetailScreen(lead: lead)));
          } else {
             _showUpgradeDialog(context, theme);
          }
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                   Container(
                    width: 4, height: 40,
                    decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2)),
                  ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         hasAccess 
                           ? Text(displayName, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16))
                           : ImageFiltered(
                               // Blur intencional para Leads 'Solo PRO'
                               imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                               child: Text(displayName, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.bold, fontSize: 16)),
                             ),
                         const SizedBox(height: 4),
                         Text(
                           displaySource,
                           style: TextStyle(
                              color: hasAccess ? colorScheme.onSurface.withValues(alpha: 0.7) : Colors.amber, 
                              fontSize: 13, 
                              fontWeight: hasAccess ? FontWeight.normal : FontWeight.bold
                           ),
                         ),
                         const SizedBox(height: 8),
                         Row(
                           children: [
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                               decoration: BoxDecoration(
                                 color: statusColor.withValues(alpha: 0.15),
                                 borderRadius: BorderRadius.circular(4),
                                 border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                               ),
                               child: Text(statusText.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
                             ),
                             const Spacer(),
                             Text(dateStr, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 10)),
                           ],
                         )
                       ],
                     ),
                   ),
                   if (hasAccess)
                    Icon(Icons.arrow_forward_ios, color: colorScheme.onSurface.withValues(alpha: 0.3), size: 16),
                ],
              ),
            ),
            
            // Candado "Solo PRO" para leads sin acceso
            if (!hasAccess)
              Positioned.fill(
                child: Container(
                  // Note: El filtro de desenfoque aplicado al texto arriba lo protege
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.amber),
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.black.withValues(alpha: 0.5)
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.lock, color: Colors.amber, size: 16),
                          SizedBox(width: 8),
                          Text("Solo PRO", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [const Icon(Icons.star, color: Colors.amber), const SizedBox(width: 8), Text('Oportunidad Perdida', style: TextStyle(color: theme.colorScheme.onSurface))]),
        content: Text(
          'Un cliente mostró interés pero no te contactó directamente.\n\nLos usuarios PRO pueden ver estos datos y contactar al cliente proactivamente.',
          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(child: Text('Cerrar', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))), onPressed: () => Navigator.pop(ctx)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            child: const Text('MEJORAR PLAN'),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Redirigiendo a planes...')));
            }, 
          ),
        ],
      ),
    );
  }
}
