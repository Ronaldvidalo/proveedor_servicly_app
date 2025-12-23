import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- Modelos y Servicios ---
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/services/product_service.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/models/video_showcase_model.dart';
import 'package:proveedor_servicly_app/core/services/video_service.dart';
import 'package:proveedor_servicly_app/core/services/category_service.dart';
import 'package:proveedor_servicly_app/core/models/category_model.dart';
import 'package:proveedor_servicly_app/core/services/auth_service.dart';

// --- Widgets Reutilizables ---
import 'package:proveedor_servicly_app/widgets/video_card.dart';
import 'package:proveedor_servicly_app/features/manage_store/presentation/screens/video_player_screen.dart';
import 'package:proveedor_servicly_app/core/viewmodels/cart_provider.dart';
import 'package:proveedor_servicly_app/features/cart/screens/cart_screen.dart';
import 'package:proveedor_servicly_app/widgets/public_brand_header_1.dart';
import 'package:proveedor_servicly_app/widgets/product_card_refactor.dart';

// --- NUEVO WIDGET DE DETALLE ---
import 'package:proveedor_servicly_app/features/public_profile/screens/widgets/product_detail_dialog.dart'; // <--- IMPORTA ESTO

class TiendaLayout extends StatefulWidget {
  final String providerId;
  final ProviderProfileModel profile;

  const TiendaLayout({
    super.key,
    required this.providerId,
    required this.profile,
  });

  @override
  State<TiendaLayout> createState() => _TiendaLayoutState();
}

class _TiendaLayoutState extends State<TiendaLayout> {
  String? _selectedCategoryId; 
  late final String? _currentClientId;
  final Set<String> _likedProductIds = {};

  @override
  void initState() {
    super.initState();
    _currentClientId = context.read<AuthService>().currentUser?.uid; 
  }

  void _toggleLike(String productId) {
    setState(() {
      if (_likedProductIds.contains(productId)) {
        _likedProductIds.remove(productId);
      } else {
        _likedProductIds.add(productId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, 
      appBar: AppBar(
        title: Text(widget.profile.businessName),
        backgroundColor: theme.appBarTheme.backgroundColor, 
        foregroundColor: theme.appBarTheme.foregroundColor, 
        elevation: 0,
        actions: [
          _CartBadge(brandColor: colors.primary),
          const SizedBox(width: 16),
        ],
      ),
      // Proveemos el perfil para que ProductDetailDialog lo encuentre fácilmente
      body: Provider.value(
        value: widget.profile,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PublicBrandHeader1(
                profile: widget.profile,
                onLaunchUrl: (url) => debugPrint('Launch: $url'), 
                clientId: _currentClientId,
              ),
            ),        

            _buildSectionTitle('Videos del Proveedor', false, theme),
            _buildVideoPromoSection(context, widget.profile.providerId, theme),

            _buildSectionTitle('Nuestros Productos', false, theme),
            _CategorySelector(
              providerId: widget.profile.providerId,
              selectedCategoryId: _selectedCategoryId, 
              brandColor: colors.primary,
              onCategorySelected: (id) => setState(() => _selectedCategoryId = id),
            ),

            _buildProductsGridSection(context, widget.profile.providerId, _selectedCategoryId, colors.primary, theme),

            _buildSectionTitle('Calificaciones y Comentarios', false, theme),
            SliverToBoxAdapter(
              child: Container(
                height: 120,
                alignment: Alignment.center,
                child: Text(
                  '(Próximamente: Módulo de Reseñas)',
                  style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5), fontStyle: FontStyle.italic),
                ),
              )
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildSectionTitle(String title, bool isFirst, ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, isFirst ? 16 : 32, 16, 16),
        child: Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.onSurface, 
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  Widget _buildProductsGridSection(BuildContext context, String providerId, String? selectedCategoryId, Color brandColor, ThemeData theme) {
    return StreamBuilder<List<ProductModel>>(
      stream: context.read<ProductService>().getProducts(providerId, categoryId: selectedCategoryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SliverToBoxAdapter(child: SizedBox(height: 200)); 
        if (snapshot.hasError) return SliverToBoxAdapter(child: Center(child: Text('Error: ${snapshot.error}')));
        
        final products = snapshot.data ?? [];
        if (products.isEmpty) return const SliverFillRemaining(child: Center(child: Text('Sin productos')));

        return SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75, 
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = products[index];
                return ProductCardRefactor(
                  product: product, 
                  brandColor: brandColor,
                  isEditable: false, 
                  isLiked: _likedProductIds.contains(product.id),
                  onLikeToggle: () => _toggleLike(product.id),
                  // AQUÍ USAMOS EL NUEVO WIDGET REUTILIZABLE
                  onTap: () => ProductDetailDialog.show(context, product, brandColor),
                );
              },
              childCount: products.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoPromoSection(BuildContext context, String providerId, ThemeData theme) {
    return StreamBuilder<List<VideoShowcaseModel>>(
      stream: context.read<VideoService>().getVideoShowcasesByProvider(providerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
        
        return SliverToBoxAdapter(
          child: SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final video = snapshot.data![index];
                return VideoCard(
                  video: video,
                  brandColor: theme.colorScheme.primary, 
                  onPlayTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(videoShowcase: video))),
                );
              },
            ),
          ),
        );
      },
    );
  }
} 

// --- Widgets Auxiliares Locales (Badge y Selector) ---
class _CartBadge extends StatelessWidget {
  final Color brandColor;
  const _CartBadge({required this.brandColor});
  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(builder: (context, cart, child) {
      return Stack(alignment: Alignment.center, children: [
        IconButton(icon: const Icon(Icons.shopping_cart_outlined, size: 28), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()))),
        if (cart.totalItems > 0) Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: brandColor, shape: BoxShape.circle, border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2)), constraints: const BoxConstraints(minWidth: 18, minHeight: 18), child: Text('${cart.totalItems}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center)))
      ]);
    });
  }
}

class _CategorySelector extends StatelessWidget {
  final String providerId; final String? selectedCategoryId; final Color brandColor; final ValueChanged<String?> onCategorySelected;
  const _CategorySelector({required this.providerId, required this.selectedCategoryId, required this.brandColor, required this.onCategorySelected});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CategoryModel>>(
      stream: context.read<CategoryService>().getCategories(providerId), 
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
        final categories = snapshot.data!;
        // ✅ CORRECCIÓN: Variable 'theme' no utilizada eliminada.
        return SliverToBoxAdapter(child: SizedBox(height: 60, child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), scrollDirection: Axis.horizontal, itemCount: categories.length + 1, itemBuilder: (context, index) {
          if (index == 0) return _buildChip(context, 'Ver Todos', selectedCategoryId == null, () => onCategorySelected(null));
          return _buildChip(context, categories[index - 1].name, selectedCategoryId == categories[index - 1].id, () => onCategorySelected(categories[index - 1].id));
        })));
    });
  }
  
  Widget _buildChip(BuildContext context, String label, bool isSelected, VoidCallback onTap) {
    final colors = Theme.of(context).colorScheme;
    return Padding(padding: const EdgeInsets.only(right: 8.0), child: ChoiceChip(
      label: Text(label), selected: isSelected, onSelected: (_) => onTap(),
      selectedColor: brandColor,
      labelStyle: TextStyle(color: isSelected ? Colors.white : colors.onSurface),
      backgroundColor: colors.surface,
      shape: StadiumBorder(side: BorderSide(color: isSelected ? brandColor : colors.onSurface.withValues(alpha: 0.3))),
    ));
  }
}