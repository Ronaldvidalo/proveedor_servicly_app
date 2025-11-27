import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; 

// Importaciones de paquete:
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart'; 
import 'package:proveedor_servicly_app/features/crm/data/models/cliente_model.dart';
import 'package:proveedor_servicly_app/features/crm/presentation/providers/client_list_viewmodel.dart';
import 'package:proveedor_servicly_app/features/crm/presentation/providers/lead_list_viewmodel.dart'; 
import 'package:proveedor_servicly_app/features/crm/presentation/screens/client_detail_screen.dart'; 
import 'package:proveedor_servicly_app/features/crm/presentation/screens/contact_form_screen.dart'; 
import 'package:proveedor_servicly_app/features/crm/presentation/screens/simple_leads_tab.dart';

// --- WIDGETS AUXILIARES ---

// Widget para el ítem de la lista, mostrando la distinción Free/Pro
class ClientListItem extends StatelessWidget {
  final Cliente cliente;
  final bool isProUser;

  const ClientListItem({required this.cliente, required this.isProUser, super.key});

  @override
  Widget build(BuildContext context) {
    // QA FIX: Tema dinámico
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormat = NumberFormat.currency(locale: 'es_ES', symbol: '\$');
    
    final ultimaInteraccion = isProUser 
      ? DateFormat('dd MMM').format(cliente.ultimaInteraccion) 
      : DateFormat('yyyy/MM/dd').format(cliente.fechaAlta);

    return Card(
      // QA FIX: Color de tarjeta dinámico
      color: theme.cardTheme.color,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary,
          child: Text(
            cliente.nombreCompleto.substring(0, 1).toUpperCase(), 
            style: TextStyle(color: colorScheme.onPrimary)
          ),
        ),
        title: Text(
          cliente.nombreCompleto,
          style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cliente.email.isNotEmpty ? cliente.email : cliente.telefono,
              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            if (isProUser)
              Row(
                children: [
                  const Icon(Icons.monetization_on, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text('LTV: ${currencyFormat.format(cliente.montoTotalFacturado)}',
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5))),
                  const Spacer(),
                  Icon(Icons.access_time, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text('Última: $ultimaInteraccion', style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5))),
                ],
              ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.3)),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ClientDetailScreen(cliente: cliente),
            ),
          );
        },
      ),
    );
  }
}

class FreeLimitBar extends StatelessWidget {
  final double percentage;
  final int count;
  final int limit;
  
  const FreeLimitBar({required this.percentage, required this.count, required this.limit, super.key});

  @override
  Widget build(BuildContext context) {
    if (percentage == 0.0) return const SizedBox.shrink(); 
    
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
            backgroundColor: color.withValues(alpha: 0.2), 
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

// Pestaña 1: Clientes
class ClientsTab extends StatelessWidget {
  const ClientsTab({super.key});

  @override
  Widget build(BuildContext context) {
    // QA FIX: Obtener tema
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<ClientListViewModel>(
      builder: (context, viewModel, child) {
        // Campo de búsqueda adaptable
        final searchBar = Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: viewModel.setSearchTerm, 
            // Texto dinámico
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, email o teléfono...',
              hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
              prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withValues(alpha: 0.6)),
              // Fondo de input dinámico
              filled: true,
              fillColor: theme.cardTheme.color,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
          ),
        );

        final limitBar = FreeLimitBar(
          percentage: viewModel.limitPercentage, 
          count: viewModel.clienteCount, 
          limit: viewModel.freeLimit,
        );

        return Column(
          children: [
            searchBar,
            if (!viewModel.isProUser) limitBar,
            Expanded(
              child: StreamBuilder<List<Cliente>>(
                stream: viewModel.filteredClientesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: colorScheme.primary));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error al cargar clientes: ${snapshot.error}', style: TextStyle(color: colorScheme.error)));
                  }
                  final clientes = snapshot.data ?? [];
                  if (clientes.isEmpty) {
                    return Center(
                      child: Text('No hay clientes activos.\nConvierte un Lead para empezar.', 
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5))),
                    );
                  }

                  return ListView.builder(
                    itemCount: clientes.length,
                    itemBuilder: (context, index) {
                      final cliente = clientes[index];
                      return ClientListItem(
                        cliente: cliente,
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

// PANTALLA PRINCIPAL
class ClientManagementScreen extends StatelessWidget {
  static const String routeName = '/client-management';
  
  const ClientManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // QA FIX: Obtener tema
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ClientListViewModel(context.read<CrmRepository>()), 
        ),
        ChangeNotifierProvider(
          create: (context) => LeadListViewModel(context.read<CrmRepository>()), 
        ),
      ],
      child: DefaultTabController(
        length: 2, 
        child: Scaffold(
          // Fondo dinámico
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('Módulo CRM', style: TextStyle(fontWeight: FontWeight.w600)),
            // AppBar adaptativa
            backgroundColor: theme.scaffoldBackgroundColor,
            foregroundColor: colorScheme.onSurface,
            elevation: 0,
            bottom: TabBar(
              // Indicador y texto adaptables
              indicatorColor: colorScheme.primary,
              labelColor: colorScheme.primary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
              tabs: const [
                Tab(text: 'Clientes', icon: Icon(Icons.people_alt)), 
                Tab(text: 'Leads', icon: Icon(Icons.trending_up)), 
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              ClientsTab(), 
              // Asumimos que SimpleLeadsTab ya es adaptable o usa colores neutros
              SimpleLeadsTab(),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
               final crmRepository = context.read<CrmRepository>();
               Navigator.of(context).push(
                 MaterialPageRoute(
                   builder: (context) => ContactFormScreen(crmRepository: crmRepository),
                 ),
               );
            },
            label: const Text('Añadir Contacto'),
            icon: const Icon(Icons.add),
            backgroundColor: Colors.green.shade600, // Verde éxito siempre visible
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}