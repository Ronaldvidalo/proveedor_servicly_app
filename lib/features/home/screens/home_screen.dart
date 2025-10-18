import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/category_model.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/services/auth_service.dart';
import 'package:proveedor_servicly_app/core/services/marketplace_service.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/public_profile_screen.dart';

/// La pantalla principal para los usuarios con rol 'cliente'.
/// Actuará como el marketplace para descubrir proveedores.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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

class _HomeViewState extends State<_HomeView> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final marketplaceService = context.read<MarketplaceService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Descubrir Servicios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 1,
            title: SizedBox(
              height: 50,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar por servicio o proveedor...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  contentPadding: EdgeInsets.zero,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant,
                ),
              ),
            ),
          ),
          
          // --- MODIFICACIÓN DE UX ---
          // La barra de filtros ahora es un Sliver que se puede desplazar horizontalmente.
          SliverToBoxAdapter(
            child: SizedBox(
              height: 60,
              child: StreamBuilder<List<CategoryModel>>(
                stream: marketplaceService.getMainCategories(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)));
                  
                  final categories = snapshot.data!;
                  
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: categories.length + 1, // +1 para el chip "Todos"
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = _selectedCategory == null;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: const Text('Todos'),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedCategory = null),
                          ),
                        );
                      }
                      final category = categories[index - 1];
                      final isSelected = _selectedCategory == category.name;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(category.name),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedCategory = category.name),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          StreamBuilder<List<ProviderProfileModel>>(
            stream: marketplaceService.getProviders(categoryName: _selectedCategory),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return SliverFillRemaining(child: Center(child: Text('Error: ${snapshot.error}')));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SliverFillRemaining(child: Center(child: Text('No hay proveedores para esta categoría.')));
              }

              final providers = snapshot.data!;

              return SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
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
}

class _ProviderCard extends StatelessWidget {
  final ProviderProfileModel provider;

  const _ProviderCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PublicProfileScreen(providerId: provider.providerId),
        ));
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: provider.logoUrl.isNotEmpty
                  ? Image.network(
                      provider.logoUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => 
                        Container(
                          color: provider.brandColor.withAlpha(50),
                          child: const Center(child: Icon(Icons.error_outline, size: 40, color: Colors.grey)),
                        ),
                    )
                  : Container(
                      color: provider.brandColor.withAlpha(128),
                      child: const Center(child: Icon(Icons.storefront, size: 40, color: Colors.white)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                provider.businessName,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

