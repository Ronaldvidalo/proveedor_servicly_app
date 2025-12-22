// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 14/10/2025
// Style: Cyber Glow (Adaptive Light/Dark)
// QA FIX 26/11/2025: Theme Integration
// UPDATE 21/12/2025: Integración Marketplace Real (BrandProfiles) - FULL CODE
// UPDATE: Integración Notificaciones Push (Cliente)
// ---------------------------------

import 'package:flutter/material.dart';

// --- MANEJO DE CONFLICTOS DE IMPORTS (Provider vs Riverpod) ---
// Importamos provider con alias para el Widget wrapper
import 'package:provider/provider.dart' as provider_pkg; 
// Importamos provider normal (ocultando conflictos) para usar context.read()
import 'package:provider/provider.dart' hide Provider, Consumer, StreamProvider, ChangeNotifierProvider, FutureProvider; 
import 'package:flutter_riverpod/flutter_riverpod.dart'; 

import 'package:geolocator/geolocator.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 

import 'package:proveedor_servicly_app/core/models/category_model.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/services/auth_service.dart';
import 'package:proveedor_servicly_app/core/services/marketplace_service.dart';
import 'package:proveedor_servicly_app/core/services/notification_service.dart'; // <--- NUEVO IMPORT

// --- IMPORTACIONES DE UBICACIÓN ---
import 'package:proveedor_servicly_app/providers/location_provider.dart';
import 'package:proveedor_servicly_app/core/utils/distance_utils.dart';

// --- IMPORTACIÓN DE WIDGETS REUTILIZABLES ---
import 'package:proveedor_servicly_app/widgets/cards/provider_card.dart'; 
import 'package:proveedor_servicly_app/widgets/video_showcase_section.dart';

// --- IMPORTACIONES DE NAVEGACIÓN ---
import 'package:proveedor_servicly_app/features/orders/screens/client_orders_screen.dart'; 

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return provider_pkg.Provider<MarketplaceService>(
      create: (_) => MarketplaceService(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends ConsumerStatefulWidget {
  const _HomeView();

  @override
  ConsumerState<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<_HomeView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  bool _isNearbyFilterActive = false;

  // DEFINICIÓN DE PESTAÑAS (Coinciden con publicProfileTemplate en BD)
  // IMPORTANTE: Estos IDs deben ser iguales a los que guardamos en BrandSettings
  final List<Map<String, String>> _profileTypes = [
    {'id': 'all', 'label': 'Descubrir'},
    {'id': 'store', 'label': 'Tiendas'},
    {'id': 'catalog', 'label': 'Catálogos'},
    {'id': 'booking', 'label': 'Reservas'},
    {'id': 'cv', 'label': 'Profesionales'}, 
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _profileTypes.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // Reconstruir al cambiar tab
      }
    });
    _searchController.addListener(() {
      setState(() => _searchTerm = _searchController.text);
    });

    // --- SOLICITUD DE NOTIFICACIONES (CLIENTE) ---
    // Esto asegura que el cliente reciba alertas de sus pedidos
    WidgetsBinding.instance.addPostFrameCallback((_) async {
       // Usamos context.read del paquete Provider (gracias al import oculto arriba)
       await context.read<NotificationService>().init();
       await context.read<NotificationService>().saveTokenToDatabase();
       debugPrint("🔔 Notificaciones configuradas para el Home de Cliente");
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _getSelectedProfileType() {
    return _profileTypes[_tabController.index]['id']!;
  }

  void _toggleNearbyFilter() {
    setState(() {
      _isNearbyFilterActive = !_isNearbyFilterActive;
    });
    if (_isNearbyFilterActive) {
      ref.read(userLocationProvider.notifier).captureUserLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final marketplaceService = context.read<MarketplaceService>();
    
    final selectedProfileType = _getSelectedProfileType();
    final locationState = ref.watch(userLocationProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Explorar Servicios'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
        actions: const [
          _UserAvatarMenu(), 
          SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 2,
            shadowColor: theme.shadowColor.withValues(alpha: 0.1),
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Busca nombre, servicio o dirección...',
                  hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                  prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: theme.cardTheme.color,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: colorScheme.primary,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: _profileTypes.map((type) => Tab(text: type['label'])).toList(),
            ),
          ),
          
          _buildSectionTitle(context, 'Destacados', theme),
          
          const SliverToBoxAdapter(
            child: VideoShowcaseSection(),
          ),

          _buildSectionTitle(context, 'Filtrar resultados', theme),
          _buildFilterRow(context, marketplaceService, locationState, theme),
          
          StreamBuilder<List<ProviderProfileModel>>(
            // Solicitamos TODOS y filtramos localmente para mayor control en debug
            stream: marketplaceService.getProviders(
              profileType: null, // Traemos todo para filtrar en cliente y ver qué pasa
              categoryName: _selectedCategory,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _LoadingState();
              }
              if (snapshot.hasError) {
                return _ErrorState(error: snapshot.error.toString());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                // debugPrint("Marketplace: La base de datos 'brandProfiles' parece vacía o sin permisos.");
                return const _EmptyState();
              }

              var providers = snapshot.data!;
              
              // --- FILTRO MANUAL (DEBUGGEABLE) ---
              final int totalCount = providers.length;
              
              // 1. Filtro por Pestaña (Store, Catalog, etc.)
              if (selectedProfileType != 'all') {
                providers = providers.where((p) {
                  // Comparamos contra publicProfileTemplate O profileType para asegurar compatibilidad
                  // Si es nulo, asumimos 'cv'
                  final template = p.publicProfileTemplate?.toLowerCase() ?? p.profileType.toLowerCase();
                  return template == selectedProfileType.toLowerCase();
                }).toList();
              }

              // 2. Filtro de Búsqueda
              if (_searchTerm.isNotEmpty) {
                final term = _searchTerm.toLowerCase();
                providers = providers.where((p) {
                  final nameMatch = p.businessName.toLowerCase().contains(term);
                  final addressMatch = (p.address?.toLowerCase() ?? '').contains(term);
                  return nameMatch || addressMatch;
                }).toList();
              }

              // 3. Ordenamiento por Distancia
              Position? userPosition = locationState.value;
              if (_isNearbyFilterActive && userPosition != null) {
                providers.sort((a, b) {
                  double latA = a.latitude ?? -999;
                  double lngA = a.longitude ?? -999;
                  double latB = b.latitude ?? -999;
                  double lngB = b.longitude ?? -999;

                  if (latA != -999 && latB != -999) {
                    double distA = DistanceUtils.getDistanceInMeters(userPosition.latitude, userPosition.longitude, latA, lngA);
                    double distB = DistanceUtils.getDistanceInMeters(userPosition.latitude, userPosition.longitude, latB, lngB);
                    return distA.compareTo(distB);
                  }
                  return 0; // Sin cambios si no tienen ubicación
                });
              }

              // debugPrint("Marketplace: Total en BD: $totalCount | Mostrando: ${providers.length} (Filtro: $selectedProfileType)");

              if (providers.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.search_off, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text(
                            "No hay resultados para '$selectedProfileType'",
                            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final provider = providers[index];
                      
                      String? distanceText;
                      if (userPosition != null && (provider.latitude != null && provider.longitude != null)) {
                        distanceText = DistanceUtils.formatDistance(
                          userPosition.latitude, userPosition.longitude, 
                          provider.latitude!, provider.longitude!
                        );
                      } else if (_isNearbyFilterActive && provider.address != null) {
                        distanceText = "Ver ubicación"; 
                      }

                      // Usamos tu tarjeta ProviderCard que ya tiene la navegación integrada
                      return ProviderCard(
                        provider: provider, 
                        distanceText: distanceText,
                      );
                    },
                    childCount: providers.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
        child: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context, MarketplaceService service, AsyncValue<Position?> locationState, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final chipBackgroundColor = theme.cardTheme.color;
    
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            const SizedBox(width: 16),
            FilterChip(
              avatar: _isNearbyFilterActive 
                ? (locationState.isLoading 
                    ? Padding(padding: const EdgeInsets.all(2), child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary)) 
                    : Icon(Icons.near_me, size: 16, color: colorScheme.onPrimary))
                : Icon(Icons.near_me_outlined, size: 16, color: colorScheme.primary),
              label: const Text("Cerca de mí"),
              selected: _isNearbyFilterActive,
              onSelected: (bool value) => _toggleNearbyFilter(),
              backgroundColor: chipBackgroundColor,
              selectedColor: colorScheme.primary,
              labelStyle: TextStyle(
                color: _isNearbyFilterActive ? colorScheme.onPrimary : colorScheme.onSurface,
                fontWeight: _isNearbyFilterActive ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: _isNearbyFilterActive ? BorderSide.none : BorderSide(color: colorScheme.primary, width: 1),
              ),
              showCheckmark: false,
            ),
            VerticalDivider(color: theme.dividerColor, indent: 10, endIndent: 10, width: 20),
            Expanded(
              child: StreamBuilder<List<CategoryModel>>(
                stream: service.getMainCategories(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  final categories = snapshot.data ?? [];
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length + 1,
                    itemBuilder: (context, index) {
                      bool isSelected;
                      String label;
                      VoidCallback onSelected;
                      if (index == 0) {
                        label = 'Todas';
                        isSelected = _selectedCategory == null;
                        onSelected = () => setState(() => _selectedCategory = null);
                      } else {
                        final category = categories[index - 1];
                        label = category.name;
                        isSelected = _selectedCategory == category.name;
                        onSelected = () => setState(() => _selectedCategory = category.name);
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (_) => onSelected(),
                          selectedColor: colorScheme.primary.withValues(alpha: 0.2),
                          backgroundColor: chipBackgroundColor,
                          labelStyle: TextStyle(
                            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          side: BorderSide.none,
                          showCheckmark: false,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================================================================
// --- WIDGETS AUXILIARES ---
// ===================================================================

class _UserAvatarMenu extends StatelessWidget {
  const _UserAvatarMenu();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final initials = user?.displayName?.isNotEmpty == true ? user!.displayName![0].toUpperCase() : 'U';

    return PopupMenuButton<String>(
      offset: const Offset(0, 50), // Desplazar el menú hacia abajo
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      icon: CircleAvatar(
        backgroundColor: colorScheme.primary,
        child: Text(initials, style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold)),
      ),
      onSelected: (value) {
        switch (value) {
          // --- AQUÍ ESTÁ LA NAVEGACIÓN A MIS COMPRAS ---
          case 'orders':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientOrdersScreen()));
            break;
          case 'profile':
            // TODO: Navegar a pantalla de perfil de cliente
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Próximamente: Perfil de Cliente")));
            break;
          case 'favorites':
            // TODO: Navegar a favoritos
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Próximamente: Favoritos")));
            break;
          case 'logout':
            context.read<AuthService>().signOut();
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        // Encabezado del menú
        PopupMenuItem<String>(
          enabled: false, // No seleccionable
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.displayName ?? "Usuario", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
              Text(user?.email ?? "", style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.6))),
              const Divider(),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'orders',
          child: ListTile(
            leading: Icon(Icons.shopping_bag_outlined),
            title: Text('Mis Compras'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'favorites',
          child: ListTile(
            leading: Icon(Icons.favorite_border),
            title: Text('Favoritos'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'profile',
          child: ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Mi Perfil'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: ListTile(
            leading: Icon(Icons.logout, color: Colors.redAccent),
            title: Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)));
  }
}
class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(child: Center(child: Text("Sin resultados", style: TextStyle(color: Theme.of(context).colorScheme.onSurface))));
  }
}
class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(child: Center(child: Text("Error: $error", style: const TextStyle(color: Colors.red))));
  }
}