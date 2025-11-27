// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 14/10/2025
// Style: Cyber Glow (Adaptive Light/Dark)
// QA FIX 26/11/2025:
// 1. Refactorización completa para eliminar colores hardcoded.
// 2. Adaptación a Modo Claro/Oscuro usando ThemeService.
// 3. Widgets de búsqueda y filtros ahora usan el tema global.
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_pkg; 
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import 'package:geolocator/geolocator.dart'; 

import 'package:proveedor_servicly_app/core/models/category_model.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/services/auth_service.dart';
import 'package:proveedor_servicly_app/core/services/marketplace_service.dart';
// import 'package:proveedor_servicly_app/core/services/video_service.dart'; // No usado directamente

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
    
    final selectedProfileType = _getSelectedProfileType();
    final locationState = ref.watch(userLocationProvider);

    // QA FIX: Obtener tema del contexto
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // Fondo dinámico
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Explorar Servicios'),
        // Colores de AppBar dinámicos (se toman del theme global si no se especifican)
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
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
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 2,
            // Sombra sutil adaptativa
            shadowColor: theme.shadowColor.withValues(alpha: 0.1),
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                // QA FIX: Texto de input dinámico
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Busca nombre, servicio o dirección...',
                  // Hint text con opacidad
                  hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                  prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  filled: true,
                  // Fondo de input: Tarjeta o SurfaceVariant
                  fillColor: theme.cardTheme.color,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  // Borde activo con color primario
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
              // QA FIX: Color inactivo visible en ambos modos
              unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: _profileTypes.map((type) => Tab(text: type['label'])).toList(),
            ),
          ),
          
          _buildSectionTitle(context, 'Destacados', theme),
          
          // --- USO DEL WIDGET REUTILIZABLE (VIDEOS) ---
          // Asumimos que VideoShowcaseSection ya maneja sus propios temas internamente
          // o usa Theme.of(context)
          const SliverToBoxAdapter(
            child: VideoShowcaseSection(),
          ),

          _buildSectionTitle(context, 'Filtrar resultados', theme),
          _buildFilterRow(context, marketplaceService, locationState, theme),
          
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
                      // ProviderCard debería usar Theme.of(context) internamente
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
            // QA FIX: Texto dinámico
            color: theme.colorScheme.onSurface
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context, MarketplaceService service, AsyncValue<Position?> locationState, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    // QA FIX: Color de superficie para los chips
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
              // QA FIX: Colores de chip dinámicos
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
                            // QA FIX: Texto dinámico
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    // QA FIX: Color de carga dinámico
    return SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)));
  }
}
class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    // QA FIX: Texto dinámico
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