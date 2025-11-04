import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; 

// Importaciones corregidas a rutas de paquete para evitar problemas de resolución de tipos
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart'; // NECESARIO para Provider
import 'package:proveedor_servicly_app/features/crm/data/models/cliente_model.dart';
import 'package:proveedor_servicly_app/features/crm/presentation/providers/client_list_viewmodel.dart';
import 'package:proveedor_servicly_app/features/crm/presentation/screens/client_detail_screen.dart';



// Las importaciones de crm_enums y flutter/foundation.dart se eliminan por ser unused

// --- WIDGETS AUXILIARES (simulando archivos separados) ---

// Widget para el ítem de la lista, mostrando la distinción Free/Pro
class ClientListItem extends StatelessWidget {
  final Cliente cliente;
  final bool isProUser;

  const ClientListItem({required this.cliente, required this.isProUser, super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_ES', symbol: '\$');
    
    // Icono para la última interacción
    final ultimaInteraccion = isProUser 
      ? DateFormat('dd MMM').format(cliente.ultimaInteraccion) 
      : DateFormat('yyyy/MM/dd').format(cliente.fechaAlta);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Text(cliente.nombreCompleto.substring(0, 1), style: const TextStyle(color: Colors.white)),
        ),
        title: Text(
          cliente.nombreCompleto,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cliente.email.isNotEmpty ? cliente.email : cliente.telefono),
            // KPIs Pro
            if (isProUser)
              Row(
                children: [
                  const Icon(Icons.monetization_on, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text('LTV: ${currencyFormat.format(cliente.montoTotalFacturado)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const Spacer(),
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Última: $ultimaInteraccion', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        // --- NAVEGACIÓN A LA PANTALLA DE DETALLE ---
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ClientDetailScreen(cliente: cliente),
            ),
          );
        },
        // --- FIN NAVEGACIÓN ---
      ),
    );
  }
}

// Widget para la barra de progreso del límite Free
class FreeLimitBar extends StatelessWidget {
  final double percentage;
  final int count;
  final int limit;
  
  const FreeLimitBar({required this.percentage, required this.count, required this.limit, super.key});

  @override
  Widget build(BuildContext context) {
    if (percentage == 0.0) return const SizedBox.shrink(); // No mostrar si es Pro
    
    final color = percentage > 0.9 ? Colors.red.shade600 : Colors.orange.shade400;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Límite Free: $count / $limit contactos', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: color.withOpacity(0.2),
            color: color,
          ),
          const SizedBox(height: 4),
          if (percentage >= 1.0)
            const Text('¡Límite alcanzado! Mejora a Pro para seguir añadiendo clientes.', style: TextStyle(color: Colors.red, fontSize: 12)),
        ],
      ),
    );
  }
}

// Pestaña 1: Clientes (ClientsTab)
class ClientsTab extends StatelessWidget {
  const ClientsTab({super.key});

  @override
  Widget build(BuildContext context) {
    // El tipo T en Consumer<T> ahora se resuelve correctamente
    return Consumer<ClientListViewModel>(
      builder: (context, viewModel, child) {
        // Campo de búsqueda siempre visible
        final searchBar = Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            // viewModel ahora es no-nulo (gracias a la inyección y el tipo resuelto)
            onChanged: viewModel.setSearchTerm, 
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, email o teléfono...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
          ),
        );

        // Barra de límite solo para usuarios Free
        final limitBar = FreeLimitBar(
          // viewModel ahora es no-nulo
          percentage: viewModel.limitPercentage, 
          count: viewModel.clienteCount, 
          limit: viewModel.freeLimit,
        );

        return Column(
          children: [
            searchBar,
            // viewModel ahora es no-nulo
            if (!viewModel.isProUser) limitBar,
            Expanded(
              // StreamBuilder para manejar los datos en tiempo real
              child: StreamBuilder<List<Cliente>>(
                // viewModel ahora es no-nulo
                stream: viewModel.filteredClientesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error al cargar clientes: ${snapshot.error}'));
                  }
                  final clientes = snapshot.data ?? [];
                  if (clientes.isEmpty) {
                    return const Center(
                      child: Text('No hay clientes activos. Convierte un Lead para empezar.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: clientes.length,
                    itemBuilder: (context, index) {
                      final cliente = clientes[index];
                      return ClientListItem(
                        cliente: cliente,
                        // viewModel ahora es no-nulo
                        isProUser: viewModel.isProUser,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// Pestaña 2: Leads y Seguimiento (LeadsTab - Simplificado)
class LeadsTab extends StatelessWidget {
  const LeadsTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Acceso seguro al ViewModel (el tipo T ahora está resuelto)
    final viewModel = Provider.of<ClientListViewModel>(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_add, size: 80, color: Colors.blueGrey),
          const SizedBox(height: 20),
          const Text(
            'Gestión de Leads',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'Esta sección permite capturar y gestionar contactos nuevos. En la versión Pro, se habilita el embudo de ventas avanzado (Nuevo, Contactado, Cotizado) y la captura automática.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Abriendo formulario de creación manual de Lead...')),
              );
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Crear Lead Manualmente'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
          ),
          const SizedBox(height: 20),
          // viewModel ahora es no-nulo
          if (!viewModel.isProUser)
            const Chip(
              label: Text('Funcionalidad Pro: Captura automática de Leads y estados avanzados'),
              backgroundColor: Colors.amber,
            ),
        ],
      ),
    );
  }
}

// PANTALLA PRINCIPAL
class ClientManagementScreen extends StatelessWidget {
  static const String routeName = '/client-management';
  
  const ClientManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inyectamos el Repositorio y el ViewModel en el árbol de widgets
    return MultiProvider(
      providers: [
        // Proveedor del Repositorio (Singleton)
        Provider(create: (_) => CrmRepository()),
        
        // Proveedor del ViewModel (ChangeNotifier)
        // El tipo ClientListViewModel ahora se resuelve correctamente
        ChangeNotifierProvider(
          create: (context) => ClientListViewModel(context.read<CrmRepository>()),
        ),
      ],
      child: DefaultTabController(
        length: 2, // Clientes y Leads
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Módulo CRM - Gestión de Clientes', style: TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            elevation: 4,
            bottom: const TabBar(
              indicatorColor: Colors.white,
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
              tabs: [
                Tab(text: 'Clientes', icon: Icon(Icons.people_alt)), 
                Tab(text: 'Leads y Seguimiento', icon: Icon(Icons.trending_up)), 
              ],
            ),
          ),
          // El cuerpo del Scaffold es el TabBarView
          body: const TabBarView(
            children: [
              ClientsTab(), 
              LeadsTab(), 
            ],
          ),
          // Botón flotante para la creación rápida de leads (Web/Mobile)
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Iniciando flujo de adición de nuevo contacto...')),
              );
            },
            label: const Text('Añadir Contacto'),
            icon: const Icon(Icons.add),
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
