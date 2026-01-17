import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:url_launcher/url_launcher.dart'; 

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
// IMPORTANTE: Importamos el Sidebar que creamos antes
import 'package:proveedor_servicly_app/widgets/navigation/servicly_sidebar.dart';

// --- NUEVO WIDGET DE DETALLE ---
import 'package:proveedor_servicly_app/features/public_profile/screens/widgets/product_detail_dialog.dart';

// Constantes
const double kMaxWebWidth = 1280.0; 
const double kMobileBreakpoint = 900.0;

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
  
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentClientId = context.read<AuthService>().currentUser?.uid; 
  }

  @override
  void dispose() {
    _scrollController.dispose(); 
    super.dispose();
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

  // Lógica de navegación del sidebar (Placeholder)
  void _handleSidebarNavigation(int index) {
    if (index == 0) {
        // Volver al Dashboard
        Navigator.of(context).pop(); 
    }
    // Aquí puedes añadir más lógica de ruteo
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isWebLarge = kIsWeb && MediaQuery.of(context).size.width > kMobileBreakpoint;
    
    // --- ESTRUCTURA PRINCIPAL ---
    // Si es Web Grande, usamos un Row con Sidebar. Si es móvil, usamos Scaffold normal.
    if (isWebLarge) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Row(
          children: [
            // 1. SIDEBAR (Izquierda)
            ServiclySidebar(
              selectedIndex: 1, // Marcamos "Mi Catálogo" como activo
              onDestinationSelected: _handleSidebarNavigation,
            ),
            
            // 2. CONTENIDO (Derecha)
            Expanded(
              child: Scaffold(
                // Sin AppBar en Web para diseño limpio
                backgroundColor: theme.scaffoldBackgroundColor,
                body: Provider.value(
                  value: widget.profile,
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    child: _buildWebLayout(context, theme, colors),
                  ),
                ),
                // Floating Action Button del carrito para Web (opcional, o usar el del header)
                floatingActionButton: _CartFloatingButton(brandColor: colors.primary),
              ),
            ),
          ],
        ),
      );
    } 
    
    // --- VERSIÓN MÓVIL (Sin cambios, con AppBar) ---
    else {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor, 
        appBar: AppBar(
          title: Text(widget.profile.businessName, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: theme.appBarTheme.backgroundColor, 
          foregroundColor: theme.appBarTheme.foregroundColor, 
          elevation: 0,
          actions: [
            _CartBadge(brandColor: colors.primary),
            const SizedBox(width: 24),
          ],
        ),
        body: Provider.value(
          value: widget.profile,
          child: _buildMobileLayout(context, theme, colors),
        ),
      );
    }
  }

  // ===========================================================================
  // LAYOUT WEB
  // ===========================================================================
  Widget _buildWebLayout(BuildContext context, ThemeData theme, ColorScheme colors) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kMaxWebWidth),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // 1. HEADER COMPACTO HORIZONTAL
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24), // Un poco más de padding arriba
                child: _WebCompactHeader(profile: widget.profile),
              ),
            ),

            // 2. CUERPO PRINCIPAL
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- COLUMNA IZQUIERDA: CATEGORÍAS ---
                    SizedBox(
                      width: 240, 
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Explorar", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          _WebCategorySidebar(
                            providerId: widget.profile.providerId,
                            selectedCategoryId: _selectedCategoryId,
                            brandColor: colors.primary,
                            onCategorySelected: (id) => setState(() => _selectedCategoryId = id),
                          ),
                          const SizedBox(height: 32),
                          Text("Historias", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          _buildMiniVideoList(context, widget.profile.providerId, theme),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 32), 

                    // --- COLUMNA DERECHA: PRODUCTOS ---
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedCategoryId == null ? "Todos los Productos" : "Filtrado por categoría", 
                                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildWebProductGrid(context, widget.profile.providerId, _selectedCategoryId, colors.primary, theme),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // LAYOUT MÓVIL
  // ===========================================================================
  Widget _buildMobileLayout(BuildContext context, ThemeData theme, ColorScheme colors) {
    return CustomScrollView(
      controller: _scrollController,
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
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  // --- WIDGETS Y HELPERS ---

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
        final products = snapshot.data ?? [];
        if (products.isEmpty) return const SliverFillRemaining(child: Center(child: Text('Sin productos')));

        return SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 250, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.70, 
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = products[index];
                return ProductCardRefactor(
                  product: product, brandColor: brandColor, isEditable: false, 
                  isLiked: _likedProductIds.contains(product.id), onLikeToggle: () => _toggleLike(product.id),
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

  Widget _buildWebProductGrid(BuildContext context, String providerId, String? selectedCategoryId, Color brandColor, ThemeData theme) {
    return StreamBuilder<List<ProductModel>>(
      stream: context.read<ProductService>().getProducts(providerId, categoryId: selectedCategoryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        final products = snapshot.data ?? [];
        if (products.isEmpty) return Container(height: 200, alignment: Alignment.center, child: const Text('No hay productos en esta categoría'));

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 260,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 0.72,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) => ProductCardRefactor(
              product: products[index], brandColor: brandColor, isEditable: false,
              isLiked: _likedProductIds.contains(products[index].id), onLikeToggle: () => _toggleLike(products[index].id),
              onTap: () => ProductDetailDialog.show(context, products[index], brandColor),
          ),
        );
      },
    );
  }

  Widget _buildMiniVideoList(BuildContext context, String providerId, ThemeData theme) {
    return StreamBuilder<List<VideoShowcaseModel>>(
      stream: context.read<VideoService>().getVideoShowcasesByProvider(providerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text("Sin historias", style: TextStyle(color: Colors.grey));
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.7, 
          ),
          itemCount: snapshot.data!.length > 4 ? 4 : snapshot.data!.length, 
          itemBuilder: (context, index) {
            final video = snapshot.data![index];
            return VideoCard(video: video, brandColor: theme.colorScheme.primary, onPlayTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(videoShowcase: video))));
          },
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
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: VideoCard(video: snapshot.data![index], brandColor: theme.colorScheme.primary, onPlayTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(videoShowcase: snapshot.data![index])))),
              ),
            ),
          ),
        );
      },
    );
  }
} 

// ===========================================================================
// WIDGETS AUXILIARES
// ===========================================================================

class _WebCompactHeader extends StatelessWidget {
  final ProviderProfileModel profile;
  const _WebCompactHeader({required this.profile});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      height: 160,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            profile.brandColor.withValues(alpha: 0.05),
            theme.cardColor,
          ]
        )
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: profile.brandColor, width: 3),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)]
            ),
            child: ClipOval(
              child: profile.logoUrl.isNotEmpty
                  ? Image.network(
                      profile.logoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: colors.primary.withValues(alpha: 0.1),
                          alignment: Alignment.center,
                          child: Text(
                            profile.businessName.isNotEmpty ? profile.businessName[0].toUpperCase() : 'S',
                            style: TextStyle(fontSize: 40, color: colors.primary, fontWeight: FontWeight.bold)
                          ),
                        );
                      },
                    )
                  : Container(
                      color: colors.primary.withValues(alpha: 0.1),
                      alignment: Alignment.center,
                      child: Icon(Icons.store, size: 40, color: colors.primary),
                    ),
            ),
          ),
          const SizedBox(width: 24),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(profile.businessName, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if ((profile.slogan ?? '').isNotEmpty)
                  Text(profile.slogan!, style: TextStyle(fontStyle: FontStyle.italic, color: colors.onSurface.withValues(alpha: 0.7))),
                
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: colors.primary),
                    const SizedBox(width: 4),
                    Text((profile.address ?? '').isNotEmpty ? profile.address! : "Online", style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 16),
                    Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    const Text("4.8 (Nuevos)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FilledButton.icon(
                onPressed: () {}, 
                icon: const Icon(Icons.request_quote),
                label: const Text("Solicitar Cotización"),
                style: FilledButton.styleFrom(backgroundColor: profile.brandColor, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if ((profile.whatsapp ?? '').isNotEmpty) _SocialIconBtn(icon: Icons.chat, color: Colors.green, onTap: () => _launch("https://wa.me/${profile.whatsapp}")),
                  if ((profile.instagram ?? '').isNotEmpty) _SocialIconBtn(icon: Icons.camera_alt, color: Colors.purple, onTap: () => _launch("https://instagram.com/${profile.instagram}")),
                  _SocialIconBtn(icon: Icons.share, color: Colors.blue, onTap: () {}),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}

class _SocialIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SocialIconBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

class _CartBadge extends StatelessWidget {
  final Color brandColor;
  const _CartBadge({required this.brandColor});
  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(builder: (context, cart, child) {
      return Stack(alignment: Alignment.center, children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined, size: 28), 
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()))
        ),
        if (cart.totalItems > 0) Positioned(top: 4, right: 4, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: brandColor, shape: BoxShape.circle, border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2)), constraints: const BoxConstraints(minWidth: 20, minHeight: 20), child: Text('${cart.totalItems}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)))
      ]);
    });
  }
}

// FAB personalizado para carrito en Web (opcional)
class _CartFloatingButton extends StatelessWidget {
  final Color brandColor;
  const _CartFloatingButton({required this.brandColor});
  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(builder: (context, cart, child) {
       return FloatingActionButton(
         backgroundColor: brandColor,
         onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
         child: Stack(
           alignment: Alignment.center,
           children: [
             const Icon(Icons.shopping_cart, color: Colors.white),
             if (cart.totalItems > 0)
               Positioned(
                 right: 0, top: 0,
                 child: Container(
                   padding: const EdgeInsets.all(2),
                   decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                   constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                 ),
               )
           ],
         ),
       );
    });
  }
}

class _WebCategorySidebar extends StatelessWidget {
  final String providerId;
  final String? selectedCategoryId;
  final Color brandColor;
  final ValueChanged<String?> onCategorySelected;

  const _WebCategorySidebar({required this.providerId, required this.selectedCategoryId, required this.brandColor, required this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CategoryModel>>(
      stream: context.read<CategoryService>().getCategories(providerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final categories = snapshot.data!;
        
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              _buildCategoryTile(context, "Todas", selectedCategoryId == null, () => onCategorySelected(null)),
              const Divider(height: 1),
              ...categories.map((cat) => Column(
                children: [
                  _buildCategoryTile(context, cat.name, selectedCategoryId == cat.id, () => onCategorySelected(cat.id)),
                  const Divider(height: 1),
                ],
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryTile(BuildContext context, String label, bool isSelected, VoidCallback onTap) {
    return ListTile(
      title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? brandColor : null, fontSize: 14)),
      leading: isSelected ? Icon(Icons.check, color: brandColor, size: 18) : const SizedBox(width: 18),
      selected: isSelected,
      selectedTileColor: brandColor.withValues(alpha: 0.05),
      onTap: onTap,
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
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