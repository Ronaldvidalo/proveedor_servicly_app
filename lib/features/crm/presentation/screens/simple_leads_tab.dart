import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Modelos
import 'package:proveedor_servicly_app/features/crm/data/models/cliente_model.dart';
import 'package:proveedor_servicly_app/features/crm/core/crm_enums.dart';
import 'package:proveedor_servicly_app/features/crm/core/lead_access_helper.dart'; // Asegúrate de tener este archivo

// Pantallas
import 'package:proveedor_servicly_app/features/crm/presentation/screens/lead_detail_screen.dart';

class SimpleLeadsTab extends StatelessWidget {
  const SimpleLeadsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);

    // TODO: Conectar esto con tu Provider de Usuario real
    const String userPlan = 'free'; 

    if (userId == null) return const Center(child: Text('Error: No usuario'));

    return Scaffold(
      backgroundColor: backgroundColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('clientes')
            .orderBy('fechaAlta', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: accentColor));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white70)));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.white.withAlpha(25)),
                  const SizedBox(height: 16),
                  const Text(
                    'No tienes leads pendientes',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final cliente = Cliente.fromFirestore(docs[index]);
              
              // 1. Filtro de Retención
              // Usamos el '!' porque la lógica de isLeadExpired espera un Timestamp, 
              // pero tu modelo Cliente ya lo convirtió a DateTime.
              // Vamos a ajustar esto para que funcione:
              if (cliente.fechaAlta != null) {
                 // Convertimos de nuevo a Timestamp para el helper, o ajustamos el helper.
                 // Asumiendo que el helper espera Timestamp:
                 final timestamp = Timestamp.fromDate(cliente.fechaAlta!);
                 if (LeadAccessHelper.isLeadExpired(userPlan, timestamp)) {
                    return const SizedBox.shrink(); 
                 }
              }

              // 2. Verificación de Acceso
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

/// Tarjeta individual INTELIGENTE
class _LeadCard extends StatelessWidget {
  final Cliente lead;
  final bool hasAccess; 
  final String userPlan;
  
  const _LeadCard({
    super.key,
    required this.lead, 
    required this.hasAccess,
    required this.userPlan,
  });

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Color(0xFF2D2D5A);
    
    // Lógica de Visualización
    final displayName = hasAccess 
        ? lead.nombreCompleto 
        : 'Oportunidad Detectada'; 
        
    final displaySource = hasAccess
        ? (lead.source ?? "Desconocido")
        : "Carrito/Interés (Requiere Plan PRO)";

    // Colores de estado (Usando Enum.name para comparar con seguridad)
    Color statusColor = Colors.blueGrey;
    String statusText = lead.estadoCRM.name; // Usamos .name del Enum

    if (lead.estadoCRM == CrmEstado.leadNuevo) {
      statusColor = Colors.blueAccent;
      statusText = 'NUEVO';
    } else if (lead.estadoCRM == CrmEstado.contactado) {
      statusColor = Colors.orange;
      statusText = 'Contactado';
    }

    // --- CORRECCIÓN DEL ERROR ---
    // lead.fechaAlta ya es DateTime?, no hace falta .toDate()
    final dateStr = lead.fechaAlta != null 
        ? DateFormat('dd MMM - HH:mm').format(lead.fechaAlta!) // <-- CORREGIDO AQUÍ
        : '--/--';

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
             _showUpgradeDialog(context);
          }
        },
        child: Stack(
          children: [
            // CONTENIDO
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                   Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           displayName,
                           style: TextStyle(
                             color: hasAccess ? Colors.white : Colors.white38,
                             fontWeight: FontWeight.bold,
                             fontSize: 16,
                           ),
                         ),
                         const SizedBox(height: 4),
                         Text(
                           displaySource,
                           style: TextStyle(
                               color: hasAccess ? Colors.white38 : Colors.amber, 
                               fontSize: 12, 
                               fontWeight: hasAccess ? FontWeight.normal : FontWeight.bold
                           ),
                         ),
                         const SizedBox(height: 8),
                         Row(
                           children: [
                             Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withAlpha(50),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: statusColor.withAlpha(100)),
                                ),
                                child: Text(
                                  statusText.toUpperCase(),
                                  style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Spacer(),
                              Text(dateStr, style: const TextStyle(color: Colors.white24, fontSize: 10)),
                           ],
                         )
                       ],
                     ),
                   ),
                   if (hasAccess)
                    const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                ],
              ),
            ),
            
            // CAPA DE BLOQUEO
            if (!hasAccess)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(180),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.amber),
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.black.withAlpha(100)
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

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D5A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text('Oportunidad Perdida', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Un cliente mostró interés pero no te contactó directamente.\n\nLos usuarios PRO pueden ver estos datos y contactar al cliente proactivamente.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('Cerrar', style: TextStyle(color: Colors.white38)), 
            onPressed: () => Navigator.pop(ctx)
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            child: const Text('MEJORAR PLAN'),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navegando a planes...')));
            }, 
          ),
        ],
      ),
    );
  }
}