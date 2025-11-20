// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 14/10/2025
// Style: Cyber Glow + GeoLocation + Address Fallback
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_pkg; // Alias para evitar conflictos
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod
import 'package:geolocator/geolocator.dart'; // Para tipos de datos (Position)

// --- TUS MODELOS Y SERVICIOS ---
import 'package:proveedor_servicly_app/core/models/category_model.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/services/auth_service.dart';
import 'package:proveedor_servicly_app/core/services/marketplace_service.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/public_profile_screen.dart';
import 'package:proveedor_servicly_app/core/models/video_showcase_model.dart';
import 'package:proveedor_servicly_app/core/services/video_service.dart';
import 'package:proveedor_servicly_app/features/manage_store/presentation/screens/video_player_screen.dart';

// --- IMPORTACIONES DE UBICACIÓN (NUEVO) ---
import 'package:proveedor_servicly_app/providers/location_provider.dart';
import 'package:proveedor_servicly_app/core/utils/distance_utils.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mantenemos el Provider clásico para servicios legacy
    return provider_pkg.Provider<MarketplaceService>(
      create: (_) => MarketplaceService(),
      child: const _HomeView(),
    );
  }
}

// Cambiamos a ConsumerStatefulWidget para usar Riverpod (ref)
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
  
  // Estado del filtro de cercanía
  bool _isNearbyFilterActive = false;

  final List<Map<String, String>> _profileTypes = [
    {'id': 'all', 'label': 'Descubrir'},
    {'id': 'store', 'label': 'Tiendas'},
    {'id': 'booking', 'label': 'Reservas'},
    {'id': 'social', 'label': 'Perfiles'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _profileTypes.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _searchController.addListener(() {
      setState(() => _searchTerm = _searchController.text);
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

  // --- Lógica para activar/desactivar filtro GEO ---
  void _toggleNearbyFilter() {
    setState(() {
      _isNearbyFilterActive = !_isNearbyFilterActive;
    });
    
    // Si se activa, pedimos la ubicación al Provider de Riverpod
    if (_isNearbyFilterActive) {
      ref.read(userLocationProvider.notifier).captureUserLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final marketplaceService = context.read<MarketplaceService>();
    final videoService = context.read<VideoService>();
    
    final selectedProfileType = _getSelectedProfileType();
    
    // Escuchamos la ubicación del usuario (Riverpod)
    final locationState = ref.watch(userLocationProvider);

    // --- Paleta "Cyber Glow" ---
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Explorar Servicios'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // --- Barra de Búsqueda y Pestañas ---
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: backgroundColor,
            elevation: 2,
            shadowColor: accentColor.withOpacity(0.3),
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Busca nombre, servicio o dirección...', // Hint actualizado
                  hintStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor: surfaceColor,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: accentColor, width: 2),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: accentColor,
              labelColor: accentColor,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: _profileTypes.map((type) => Tab(text: type['label'])).toList(),
            ),
          ),
          
          _buildSectionTitle(context, 'Destacados'),
          _buildVideoShowcasesSection(context, videoService),

          _buildSectionTitle(context, 'Filtrar resultados'),
          
          // Fila de filtros con botón "Cerca de mí"
          _buildFilterRow(context, marketplaceService, locationState),
          
          // --- Grilla de Perfiles ---
          StreamBuilder<List<ProviderProfileModel>>(
            stream: marketplaceService.getProviders(
              profileType: selectedProfileType == 'all' ? null : selectedProfileType,
              categoryName: _selectedCategory,
              // searchTerm: _searchTerm, // Lo manejamos localmente para la búsqueda híbrida
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _LoadingState();
              }
              if (snapshot.hasError) {
                return _ErrorState(error: snapshot.error.toString());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const _EmptyState();
              }

              var providers = snapshot.data!;

              // 1. BÚSQUEDA HÍBRIDA (Nombre + Dirección)
              if (_searchTerm.isNotEmpty) {
                final term = _searchTerm.toLowerCase();
                providers = providers.where((p) {
                  final nameMatch = p.businessName.toLowerCase().contains(term);
                  // Buscamos también en la dirección (manejando nulos)
                  final addressMatch = (p.address?.toLowerCase() ?? '').contains(term);
                  
                  return nameMatch || addressMatch;
                }).toList();
              }

              // 2. ORDENAMIENTO POR DISTANCIA
              Position? userPosition = locationState.value;
              
              if (_isNearbyFilterActive && userPosition != null) {
                providers.sort((a, b) {
                  // Si faltan coordenadas, usamos una distancia "infinita" (-999 flag)
                  double latA = a.latitude ?? -999;
                  double lngA = a.longitude ?? -999;
                  
                  double latB = b.latitude ?? -999;
                  double lngB = b.longitude ?? -999;

                  // Caso: Ambos tienen coordenadas -> Orden normal por metros
                  if (latA != -999 && latB != -999) {
                    double distA = DistanceUtils.getDistanceInMeters(userPosition.latitude, userPosition.longitude, latA, lngA);
                    double distB = DistanceUtils.getDistanceInMeters(userPosition.latitude, userPosition.longitude, latB, lngB);
                    return distA.compareTo(distB);
                  }
                  
                  // Caso: A tiene coordenadas, B no -> A va primero
                  if (latA != -999 && latB == -999) return -1;
                  
                  // Caso: A no tiene, B si -> B va primero
                  if (latA == -999 && latB != -999) return 1;
                  
                  // Caso: Ninguno tiene -> Se quedan igual
                  return 0;
                });
              }

              if (providers.isEmpty) return const _EmptyState();

              return SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85, // Ajustado para el chip de distancia
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final provider = providers[index];
                      
                      // Lógica de visualización de distancia en la tarjeta
                      String? distanceText;
                      
                      // A. Si tenemos GPS de ambos lados -> Calculamos KM
                      if (userPosition != null && (provider.latitude != null && provider.longitude != null)) {
                        distanceText = DistanceUtils.formatDistance(
                          userPosition.latitude, userPosition.longitude, 
                          provider.latitude!, provider.longitude!
                        );
                      } 
                      // B. Si activó "Cerca de mí" pero el proveedor solo tiene dirección texto
                      else if (_isNearbyFilterActive && provider.address != null) {
                        distanceText = "Ver ubicación"; 
                      }

                      return _ProviderCard(
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white
          ),
        ),
      ),
    );
  }

  // Placeholder para videos (reemplaza con tu implementación real si la tienes)
  Widget _buildVideoShowcasesSection(BuildContext context, VideoService service) {
    // Aquí deberías poner tu stream de videos destacados
    // Por ahora devolvemos espacio vacío para que compile limpio
    return const SliverToBoxAdapter(child: SizedBox.shrink()); 
  }

  // Fila de filtros combinada
  Widget _buildFilterRow(BuildContext context, MarketplaceService service, AsyncValue<Position?> locationState) {
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);
    
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            const SizedBox(width: 16),
            // --- Botón GEO ---
            FilterChip(
              avatar: _isNearbyFilterActive 
                ? (locationState.isLoading 
                    ? const Padding(padding: EdgeInsets.all(2), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) 
                    : const Icon(Icons.near_me, size: 16, color: Colors.black))
                : const Icon(Icons.near_me_outlined, size: 16, color: accentColor),
              label: const Text("Cerca de mí"),
              selected: _isNearbyFilterActive,
              onSelected: (bool value) => _toggleNearbyFilter(),
              backgroundColor: surfaceColor,
              selectedColor: accentColor,
              labelStyle: TextStyle(
                color: _isNearbyFilterActive ? Colors.black : Colors.white,
                fontWeight: _isNearbyFilterActive ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: _isNearbyFilterActive ? BorderSide.none : const BorderSide(color: accentColor, width: 1),
              ),
              showCheckmark: false,
            ),
            const VerticalDivider(color: Colors.white24, indent: 10, endIndent: 10, width: 20),
            
            // --- Lista de Categorías ---
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
                          selectedColor: accentColor.withOpacity(0.5),
                          backgroundColor: surfaceColor,
                          labelStyle: TextStyle(
                            color: Colors.white,
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

class _ProviderCard extends StatelessWidget {
  final ProviderProfileModel provider;
  final String? distanceText; 

  const _ProviderCard({required this.provider, this.distanceText});

  Widget _buildProfileTypeChip(BuildContext context) {
     // Lógica del chip de tipo (Tienda, Social, etc.)
     IconData iconData;
     String label;
     Color color;
     const accentColorChip = Color(0xFF00BFFF);

     switch (provider.profileType) {
       case 'store':
         iconData = Icons.storefront_outlined;
         label = 'Tienda';
         color = accentColorChip;
         break;
       case 'booking':
         iconData = Icons.calendar_month_outlined;
         label = 'Reservas';
         color = Colors.greenAccent;
         break;
       case 'social':
         iconData = Icons.person_outline_rounded;
         label = 'Perfil';
         color = Colors.purpleAccent;
         break;
       default:
         iconData = Icons.business_rounded;
         label = 'Servicio';
         color = Colors.white70;
     }

     return Chip(
       avatar: Icon(iconData, size: 16, color: color),
       label: Text(label),
       labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
       backgroundColor: const Color(0xFF2D2D5A).withAlpha((255 * 0.8).round()),
       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
       side: BorderSide.none,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
     );
  }

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Color(0xFF2D2D5A);
    final brandColor = provider.brandColor;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PublicProfileScreen(providerId: provider.providerId),
        ));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
          decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: brandColor.withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(color: brandColor.withOpacity(0.2), blurRadius: 10, spreadRadius: 1)
          ]
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    provider.logoUrl.isNotEmpty
                        ? Image.network(provider.logoUrl, fit: BoxFit.cover)
                        : Container(color: brandColor.withOpacity(0.5), child: const Icon(Icons.store, color: Colors.white)),
                    
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildProfileTypeChip(context),
                    ),
                    
                    // --- INDICADOR DE DISTANCIA ---
                    if (distanceText != null)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              // Verde si son Km exactos, Amarillo si es solo referencia
                              color: distanceText!.contains('km') || distanceText!.contains('m') 
                                ? Colors.greenAccent 
                                : Colors.amberAccent, 
                              width: 1
                            )
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on, 
                                size: 12, 
                                color: distanceText!.contains('km') || distanceText!.contains('m') 
                                  ? Colors.greenAccent 
                                  : Colors.amberAccent
                              ),
                              const SizedBox(width: 4),
                              Text(
                                distanceText!,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.businessName,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // Mostramos la dirección si existe, sino la categoría
                      provider.address ?? provider.category ?? 'Servicio', 
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
  }
}
class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(child: Center(child: Text("Sin resultados", style: TextStyle(color: Colors.white))));
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