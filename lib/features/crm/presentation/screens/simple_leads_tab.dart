import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:ui'; 

// Modelos
import 'package:proveedor_servicly_app/features/crm/data/models/cliente_model.dart';
import 'package:proveedor_servicly_app/features/crm/core/crm_enums.dart';
import 'package:proveedor_servicly_app/features/crm/core/lead_access_helper.dart';

// Pantallas
import 'package:proveedor_servicly_app/features/crm/presentation/screens/lead_detail_screen.dart';

class SimpleLeadsTab extends StatefulWidget {
  const SimpleLeadsTab({super.key});

  @override
  State<SimpleLeadsTab> createState() => _SimpleLeadsTabState();
}

class _SimpleLeadsTabState extends State<SimpleLeadsTab> {
  int _currentLimit = 10;
  // ignore: unused_field
  bool _isLoadingMore = false; // Mantenemos por si la usas luego en _loadMore

  void _loadMore() {
    setState(() {
      _currentLimit += 10; 
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);
    const String userPlan = 'free'; 

    if (userId == null) return const Center(child: Text('Error: No usuario'));

    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    return Scaffold(
      backgroundColor: backgroundColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('clientes')
            .where('fechaAlta', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
            .orderBy('fechaAlta', descending: true)
            .limit(_currentLimit)
            .snapshots(),
        builder: (context, snapshot) {
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: accentColor));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
              ),
            );
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
                    'No hay leads recientes',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length + 1, 
            itemBuilder: (context, index) {
              
              if (index == docs.length) {
                if (docs.length >= _currentLimit) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: TextButton(
                      onPressed: _loadMore,
                      child: const Text("Ver más antiguos...", style: TextStyle(color: Colors.white54)),
                    ),
                  );
                } else {
                  return const SizedBox.shrink(); 
                }
              }

              final cliente = Cliente.fromFirestore(docs[index]);
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
    super.key,
    required this.lead, 
    required this.hasAccess,
    required this.userPlan,
  });

  String _getFriendlySource(String? source) {
    if (source == null) return 'Consulta';
    final s = source.toLowerCase();
    if (s.contains('whatsapp')) return 'WhatsApp';
    if (s.contains('view_product')) return 'Vio Producto';
    if (s.contains('cart')) return 'Carrito Abandonado';
    if (s.contains('like')) return 'Le gustó un Producto'; // ❤️
    if (s.contains('telefono')) return 'Llamada';
    if (s.contains('email')) return 'Email';
    if (s.contains('presupuesto')) return 'Presupuesto';
    return 'Consulta';
  }

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Color(0xFF2D2D5A);
    
    final displayName = hasAccess ? lead.nombreCompleto : 'Oportunidad Detectada'; 
    final displaySource = hasAccess ? _getFriendlySource(lead.source) : "Carrito/Interés (Solo PRO)";

    Color statusColor = Colors.blueGrey;
    
    // CORRECCIÓN 1: Usar .name para obtener el string del Enum
    String statusText = lead.estadoCRM.name; 

    // CORRECCIÓN 2: Comparar Enum con Enum
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

    // CORRECCIÓN 3: fechaAlta ya es DateTime?, no usar .toDate()
    final dateStr = lead.fechaAlta != null 
        ? DateFormat('dd MMM - HH:mm').format(lead.fechaAlta!) 
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
                           ? Text(displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))
                           : ImageFiltered(
                               imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                               child: Text(displayName, style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 16)),
                             ),
                         const SizedBox(height: 4),
                         Text(
                           displaySource,
                           style: TextStyle(
                               color: hasAccess ? Colors.white70 : Colors.amber, 
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
                                  color: statusColor.withAlpha(50),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: statusColor.withAlpha(100)),
                                ),
                                child: Text(statusText.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
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
        title: const Row(children: [Icon(Icons.star, color: Colors.amber), SizedBox(width: 8), Text('Oportunidad Perdida', style: TextStyle(color: Colors.white))]),
        content: const Text(
          'Un cliente mostró interés pero no te contactó directamente.\n\nLos usuarios PRO pueden ver estos datos y contactar al cliente proactivamente.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(child: const Text('Cerrar', style: TextStyle(color: Colors.white38)), onPressed: () => Navigator.pop(ctx)),
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