import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:proveedor_servicly_app/features/crm/data/models/cliente_model.dart';
import 'package:proveedor_servicly_app/features/crm/core/crm_enums.dart';
import '../providers/client_list_viewmodel.dart'; // Para obtener isProUser


// Widget que muestra un candado y un mensaje de 'Mejora a Pro'
class ProFeatureLock extends StatelessWidget {
  final String featureName;

  const ProFeatureLock({required this.featureName, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.lock, color: Colors.amber.shade700, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Función Pro: $featureName', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                const SizedBox(height: 4),
                const Text('Desbloquea esta función y muchas más al mejorar tu plan.',
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          // Botón opcional de upsell
          TextButton(
            onPressed: () {
              // Simulación de navegación a pantalla de pago
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navegando a la página de planes Pro...')),
              );
            }, 
            child: const Text('Mejorar'),
          ),
        ],
      ),
    );
  }
}

// Widget para las secciones de detalle (KPIs, Notas, Etiquetas)
class DetailSection extends StatelessWidget {
  final String title;
  final Widget content;
  final bool isProFeature;

  const DetailSection({
    required this.title,
    required this.content,
    this.isProFeature = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Si es una función Pro y el usuario no es Pro, mostrar el candado
    if (isProFeature && !Provider.of<ClientListViewModel>(context).isProUser) {
      return ProFeatureLock(featureName: title);
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, 
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const Divider(color: Colors.blueGrey),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }
}

class ClientDetailScreen extends StatelessWidget {
  static const String routeName = '/client-detail';
  final Cliente cliente;

  const ClientDetailScreen({required this.cliente, super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ClientListViewModel>(context);
    final isProUser = viewModel.isProUser;
    final currencyFormat = NumberFormat.currency(locale: 'es_ES', symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Cliente', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          // Opción para editar el cliente
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Abriendo formulario de edición...')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Encabezado Básico del Cliente ---
            _buildHeader(context, cliente),

            const SizedBox(height: 30),

            // --- Sección de Estadísticas de Valor (Pro) ---
            DetailSection(
              title: 'Estadísticas de Valor',
              isProFeature: true,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatRow(
                    'LTV (Monto Total Facturado)', 
                    isProUser ? currencyFormat.format(cliente.montoTotalFacturado) : 'Oculto',
                    Icons.account_balance_wallet_outlined,
                    isProUser,
                  ),
                  _buildStatRow(
                    'Última Interacción', 
                    isProUser ? DateFormat('dd/MM/yyyy HH:mm').format(cliente.ultimaInteraccion) : 'Oculto',
                    Icons.access_time,
                    isProUser,
                  ),
                  _buildStatRow(
                    'Total de Pedidos', 
                    // Asumimos un campo "totalPedidos" o se calcula, aquí mostramos un mockup
                    '4 pedidos',
                    Icons.shopping_cart_outlined,
                    true,
                  ),
                ],
              ),
            ),
            
            // --- Sección de Notas Privadas (Pro) ---
            DetailSection(
              title: 'Notas Internas',
              isProFeature: true,
              content: Text(
                isProUser && cliente.notasInternas.isNotEmpty 
                  ? cliente.notasInternas 
                  : 'Aún no hay notas. Las notas privadas solo están disponibles para usuarios Pro.',
                style: TextStyle(fontStyle: isProUser ? FontStyle.normal : FontStyle.italic, color: Colors.black87),
              ),
            ),

            // --- Sección de Etiquetas Personalizadas (Pro) ---
            DetailSection(
              title: 'Etiquetas de Segmentación',
              isProFeature: true,
              content: Wrap(
                spacing: 8.0,
                children: isProUser && cliente.etiquetas.isNotEmpty
                  ? cliente.etiquetas.map((tag) => Chip(
                      label: Text(tag.toUpperCase(), style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.lightBlue.shade50,
                    )).toList()
                  : [
                      const Text('Asigna etiquetas como "VIP" o "Zona Norte" para segmentar (Solo Pro).', 
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                    ],
              ),
            ),

            // --- Historial de Pedidos/Cobros (No implementado - Simulación) ---
             DetailSection(
              title: 'Historial de Servicios y Cobros',
              content: Text(
                'Aquí se listaría el historial detallado de cobros proveniente de la colección /cobros (Integración con Módulo de Finanzas).'
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget helper para el encabezado de la pantalla
  Widget _buildHeader(BuildContext context, Cliente cliente) {
    return Row(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: Colors.blueAccent,
          child: Text(cliente.nombreCompleto.substring(0, 1), style: const TextStyle(fontSize: 30, color: Colors.white)),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cliente.nombreCompleto, 
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(cliente.email, 
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
            Text('Tel: ${cliente.telefono}', 
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 5),
            Chip(
              label: Text(
                cliente.estadoCRM == CrmEstado.clienteActivo ? 'CLIENTE ACTIVO' : 'LEAD',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
              ),
              backgroundColor: cliente.estadoCRM == CrmEstado.clienteActivo ? Colors.green : Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
            )
          ],
        ),
      ],
    );
  }

  // Widget helper para mostrar estadísticas
  Widget _buildStatRow(String label, String value, IconData icon, bool isPro) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isPro ? Colors.blue.shade400 : Colors.grey),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Text(value, style: TextStyle(color: isPro ? Colors.black : Colors.grey.shade400, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
