// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 14/10/2025
// Style: Cyber Glow + GeoLocation + Address Fallback + Availability Filter + Video Showcases
// Refactor: Usa Widgets Reutilizables (VideoCard, ProviderCard, VideoShowcaseSection)
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_pkg; 
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import 'package:geolocator/geolocator.dart'; 

import 'package:proveedor_servicly_app/core/models/category_model.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/services/auth_service.dart';
import 'package:proveedor_servicly_app/core/services/marketplace_service.dart';
import 'package:proveedor_servicly_app/core/services/video_service.dart';

// --- IMPORTACIONES DE UBICACIÓN ---
import 'package:proveedor_servicly_app/providers/location_provider.dart';
import 'package:proveedor_servicly_app/core/utils/distance_utils.dart';

// --- IMPORTACIÓN DE WIDGETS REUTILIZABLES ---
import 'package:proveedor_servicly_app/widgets/cards/provider_card.dart'; // <-- Widget reutilizable de Tienda
import 'package:proveedor_servicly_app/widgets/video_showcase_section.dart'; // <-- Widget reutilizable de Videos

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
    final authService = context.read<AuthService>();
    final marketplaceService = context.read<MarketplaceService>();
    // final videoService = context.read<VideoService>(); // Ya no es necesario instanciarlo aquí, el widget interno lo hace
    
    final selectedProfileType = _getSelectedProfileType();
    final locationState = ref.watch(userLocationProvider);

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
                  hintText: 'Busca nombre, servicio o dirección...',
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
          
          // --- USO DEL WIDGET REUTILIZABLE (VIDEOS) ---
          // Al ser un Widget normal, lo envolvemos en SliverToBoxAdapter
          const SliverToBoxAdapter(
            child: VideoShowcaseSection(),
          ),

          _buildSectionTitle(context, 'Filtrar resultados'),
          _buildFilterRow(context, marketplaceService, locationState),
          
          StreamBuilder<List<ProviderProfileModel>>(
            stream: marketplaceService.getProviders(
              profileType: selectedProfileType == 'all' ? null : selectedProfileType,
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
                return const _EmptyState();
              }

              var providers = snapshot.data!;

              // --- 0. FILTRO DE DISPONIBILIDAD ---
              providers = providers.where((p) => p.isAvailable).toList();

              // --- 1. BÚSQUEDA HÍBRIDA ---
              if (_searchTerm.isNotEmpty) {
                final term = _searchTerm.toLowerCase();
                providers = providers.where((p) {
                  final nameMatch = p.businessName.toLowerCase().contains(term);
                  final addressMatch = (p.address?.toLowerCase() ?? '').contains(term);
                  return nameMatch || addressMatch;
                }).toList();
              }

              // --- 2. ORDENAMIENTO GEO ---
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
                  if (latA != -999 && latB == -999) return -1;
                  if (latA == -999 && latB != -999) return 1;
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

                      // --- USO DEL WIDGET REUTILIZABLE (TIENDA) ---
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

  Widget _buildFilterRow(BuildContext context, MarketplaceService service, AsyncValue<Position?> locationState) {
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);
    
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            const SizedBox(width: 16),
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