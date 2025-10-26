// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 14/10/2025
// Style: Cyber Glow
// This screen was refactored into a "Discovery Hub" implementing the defined UX
// principles. It features a responsive layout with search, profile type tabs,
// category filters, and redesigned provider cards, all styled with the
// "Cyber Glow" aesthetic. Includes a placeholder for featured profiles.
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/category_model.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/services/auth_service.dart';
import 'package:proveedor_servicly_app/core/services/marketplace_service.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/public_profile_screen.dart';

/// La pantalla principal para los usuarios con rol 'cliente'.
/// Actúa como el "Hub de Descubrimiento" para explorar perfiles.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Proveemos el MarketplaceService aquí
    return Provider<MarketplaceService>(
      create: (_) => MarketplaceService(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

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
        setState(() {}); // Actualiza la UI cuando cambia la pestaña
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

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final marketplaceService = context.read<MarketplaceService>();
    final selectedProfileType = _getSelectedProfileType();

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
            tooltip: 'Cerrar Sesión',
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
            shadowColor: accentColor.withAlpha((255 * 0.3).round()),
            titleSpacing: 0,
            // Barra de Búsqueda Estilizada
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar servicio o proveedor...',
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
            // Pestañas Estilizadas
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: accentColor,
              labelColor: accentColor,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
              tabs: _profileTypes
                  .map((type) => Tab(text: type['label']))
                  .toList(),
            ),
          ),
          
          // --- CORRECCIÓN: Sección de Destacados Reincorporada ---
          _buildSectionTitle(context, 'Destacados'),
          _buildFeaturedSection(context, marketplaceService),

          // --- Filtro por Categoría (Chips) ---
          _buildSectionTitle(context, 'Filtrar por Rubro'),
          _buildCategoryFilter(context, marketplaceService),
          
          // --- Grilla de Perfiles ---
          StreamBuilder<List<ProviderProfileModel>>(
            stream: marketplaceService.getProviders(
              profileType: selectedProfileType == 'all' ? null : selectedProfileType,
              categoryName: _selectedCategory,
              // searchTerm: _searchTerm.trim().toLowerCase(), // Descomentar cuando el servicio lo soporte
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

              final providers = snapshot.data!;

              return SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final provider = providers[index];
                      return _ProviderCard(provider: provider);
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

  /// --- CORRECCIÓN: Widget para la sección (Opcional) "Destacados" ---
  Widget _buildFeaturedSection(BuildContext context, MarketplaceService service) {
    const surfaceColor = Color(0xFF2D2D5A);
    const accentColor = Color(0xFF00BFFF);
    
    // Placeholder - Idealmente, usarías un StreamBuilder aquí con 'getFeaturedProviders'
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 180, // Altura de las tarjetas destacadas
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: 3, // Número de placeholders
          itemBuilder: (context, index) {
            return Container(
              width: 280, // Ancho de las tarjetas destacadas
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accentColor.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(
                  'Destacado ${index + 1}',
                   style: const TextStyle(color: Colors.white70)
                )
              ), // Placeholder
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context, MarketplaceService service) {
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);
    
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 50,
        child: StreamBuilder<List<CategoryModel>>(
          stream: service.getMainCategories(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                  child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: accentColor)));
            }

            final categories = snapshot.data ?? [];

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length + 1,
              itemBuilder: (context, index) {
                bool isSelected;
                String label;
                VoidCallback onSelected;

                if (index == 0) {
                  label = 'Todos';
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
                    selectedColor: accentColor,
                    backgroundColor: surfaceColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
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
    );
  }
}

/// Tarjeta de proveedor rediseñada con estilo "Cyber Glow".
class _ProviderCard extends StatelessWidget {
  final ProviderProfileModel provider;

  const _ProviderCard({required this.provider});

  Widget _buildProfileTypeChip(BuildContext context) {
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
          border: Border.all(color: brandColor.withAlpha((255 * 0.5).round()), width: 1),
          boxShadow: [
            BoxShadow(color: brandColor.withAlpha((255 * 0.2).round()), blurRadius: 10, spreadRadius: 1)
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
                    // Imagen o Placeholder
                    provider.logoUrl.isNotEmpty
                        ? Image.network(
                            provider.logoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: brandColor.withAlpha(50),
                              child: const Center(
                                  child: Icon(Icons.error_outline, size: 40, color: Colors.white38)),
                            ),
                          )
                        : Container(
                            color: brandColor.withAlpha(128),
                            child: const Center(
                                child: Icon(Icons.storefront, size: 40, color: Colors.white)),
                          ),
                    // Chip de Tipo de Perfil
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildProfileTypeChip(context),
                    ),
                  ],
                ),
              ),
              // Nombre del Negocio
              Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 10.0),
                child: Text(
                  provider.businessName,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGETS DE ESTADO (ESTILIZADOS) ---

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.9,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => Container(
             decoration: BoxDecoration(
              color: const Color(0xFF2D2D5A).withAlpha((255 * 0.5).round()),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          childCount: 6, // Mostrar más placeholders
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 80, color: Colors.white24),
              SizedBox(height: 24),
              Text(
                'No se encontraron perfiles',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Intenta ajustar los filtros o el término de búsqueda.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white60),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});
  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      child: Center(child: Text('Error al cargar:\n$error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent))),
    );
  }
}

