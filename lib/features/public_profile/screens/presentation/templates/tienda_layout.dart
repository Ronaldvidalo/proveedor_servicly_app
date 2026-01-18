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
import 'package:proveedor_servicly_app/widgets/navigation/servicly_sidebar.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/widgets/product_detail_dialog.dart';

// Constantes de Diseño
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

  // Lógica para agregar al carrito con feedback visual
  void _addToCart(ProductModel product) {
    context.read<CartProvider>().addItem(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} agregado al carrito'),
        backgroundColor: widget.profile.brandColor,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        width: 300, // Ancho fijo para que se vea bien en web
      ),
    );
  }

  void _handleSidebarNavigation(int index) {
    if (index == 0) {
        Navigator.of(context).pop(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isWebLarge = kIsWeb && MediaQuery.of(context).size.width > kMobileBreakpoint;
    
    // --- ESTRUCTURA PRINCIPAL ---
    if (isWebLarge) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Row(
          children: [
            // 1. SIDEBAR GLOBAL
            ServiclySidebar(
              selectedIndex: 1, 
              onDestinationSelected: _handleSidebarNavigation,
            ),
            
            // 2. CONTENIDO DE LA TIENDA
            Expanded(
              child: Scaffold(
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
                floatingActionButton: _CartFloatingButton(brandColor: colors.primary),
              ),
            ),
          ],
        ),
      );
    } 
    
    // --- VERSIÓN MÓVIL ---
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
  // LAYOUT WEB (Estilo Mercado Libre / Amazon)
  // ===========================================================================
  Widget _buildWebLayout(BuildContext context, ThemeData theme, ColorScheme colors) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kMaxWebWidth),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // 1. HEADER DE TIENDA (BANNER)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: _WebCompactHeader(profile: widget.profile),
              ),
            ),

            // 2. CUERPO (SIDEBAR FILTROS + GRID PRODUCTOS)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- COLUMNA IZQUIERDA: FILTROS & CATEGORÍAS ---
                    SizedBox(
                      width: 260, 
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSidebarTitle("Categorías", theme),
                          _WebCategorySidebar(
                            providerId: widget.profile.providerId,
                            selectedCategoryId: _selectedCategoryId,
                            brandColor: widget.profile.brandColor,
                            onCategorySelected: (id) => setState(() => _selectedCategoryId = id),
                          ),
                          
                          const SizedBox(height: 32),
                          _buildSidebarTitle("Historias Destacadas", theme),
                          const SizedBox(height: 12),
                          _buildMiniVideoList(context, widget.profile.providerId, theme),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 32), 

                    // --- COLUMNA DERECHA: GRID DE PRODUCTOS ---
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título de la sección derecha
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedCategoryId == null ? "Catálogo Completo" : "Resultados de filtrado", 
                                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // GRID PRINCIPAL
                          _buildWebProductGrid(context, widget.profile.providerId, _selectedCategoryId, widget.profile.brandColor, theme),
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

        _buildSectionTitle('Historias', false, theme),
        _buildVideoPromoSection(context, widget.profile.providerId, theme),

        _buildSectionTitle('Productos', false, theme),
        _CategorySelector(
          providerId: widget.profile.providerId,
          selectedCategoryId: _selectedCategoryId, 
          brandColor: widget.profile.brandColor,
          onCategorySelected: (id) => setState(() => _selectedCategoryId = id),
        ),

        // Grid Móvil
        _buildProductsGridSection(context, widget.profile.providerId, _selectedCategoryId, widget.profile.brandColor, theme),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  // --- WIDGETS Y HELPERS ---

  Widget _buildSidebarTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildSectionTitle(String title, bool isFirst, ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, isFirst ? 16 : 32, 16, 8),
        child: Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.onSurface, 
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  // Grid Móvil (Ajustado a tamaño Dashboard)
  Widget _buildProductsGridSection(BuildContext context, String providerId, String? selectedCategoryId, Color brandColor, ThemeData theme) {
    return StreamBuilder<List<ProductModel>>(
      stream: context.read<ProductService>().getProducts(providerId, categoryId: selectedCategoryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SliverToBoxAdapter(child: SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))); 
        final products = snapshot.data ?? [];
        if (products.isEmpty) return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No hay productos disponibles'))));

        return SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              // TAMAÑO UNIFICADO CON DASHBOARD
              maxCrossAxisExtent: 300, 
              crossAxisSpacing: 12, 
              mainAxisSpacing: 12, 
              // RELACIÓN DE ASPECTO ESTÁNDAR
              childAspectRatio: 0.85, 
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = products[index];
                return ProductCardRefactor(
                  product: product, brandColor: brandColor, isEditable: false, 
                  isLiked: _likedProductIds.contains(product.id), 
                  onLikeToggle: () => _toggleLike(product.id),
                  onTap: () => ProductDetailDialog.show(context, product, brandColor),
                  onAddToCart: () => _addToCart(product),
                );
              },
              childCount: products.length,
            ),
          ),
        );
      },
    );
  }

  // Grid Web (Ajustado a tamaño Dashboard)
  Widget _buildWebProductGrid(BuildContext context, String providerId, String? selectedCategoryId, Color brandColor, ThemeData theme) {
    return StreamBuilder<List<ProductModel>>(
      stream: context.read<ProductService>().getProducts(providerId, categoryId: selectedCategoryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return Container(
            height: 300, 
            alignment: Alignment.center, 
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1))
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('No se encontraron productos en esta categoría', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          );
        }

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            // TAMAÑO UNIFICADO CON DASHBOARD
            maxCrossAxisExtent: 300,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            // RELACIÓN DE ASPECTO ESTÁNDAR
            childAspectRatio: 0.85, 
          ),
          itemCount: products.length,
          itemBuilder: (context, index) => ProductCardRefactor(
              product: products[index], brandColor: brandColor, isEditable: false,
              isLiked: _likedProductIds.contains(products[index].id), onLikeToggle: () => _toggleLike(products[index].id),
              onTap: () => ProductDetailDialog.show(context, products[index], brandColor),
              onAddToCart: () => _addToCart(products[index]),
          ),
        );
      },
    );
  }

  Widget _buildMiniVideoList(BuildContext context, String providerId, ThemeData theme) {
    return StreamBuilder<List<VideoShowcaseModel>>(
      stream: context.read<VideoService>().getVideoShowcasesByProvider(providerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text("Sin historias", style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontStyle: FontStyle.italic));
        }
        
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
            return VideoCard(
              video: video, 
              brandColor: widget.profile.brandColor, 
              onPlayTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(videoShowcase: video)))
            );
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
                padding: const EdgeInsets.only(right: 12.0),
                child: AspectRatio(
                  aspectRatio: 0.7,
                  child: VideoCard(
                    video: snapshot.data![index], 
                    brandColor: widget.profile.brandColor, 
                    onPlayTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(videoShowcase: snapshot.data![index])))
                  ),
                ),
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
      height: 180, 
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            profile.brandColor.withValues(alpha: 0.15),
            theme.cardColor,
          ]
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // LOGO
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: profile.brandColor, width: 3),
              color: theme.cardColor,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)]
            ),
            child: ClipOval(
              child: profile.logoUrl.isNotEmpty
                  ? Image.network(
                      profile.logoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildInitials(profile, colors),
                    )
                  : _buildInitials(profile, colors),
            ),
          ),
          const SizedBox(width: 32),
          
          // INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  profile.businessName, 
                  style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 28)
                ),
                if ((profile.slogan ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    profile.slogan!, 
                    style: TextStyle(fontStyle: FontStyle.italic, color: colors.onSurface.withValues(alpha: 0.7), fontSize: 16)
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    _IconText(icon: Icons.location_on, text: (profile.address ?? '').isNotEmpty ? profile.address! : "Online", color: colors.onSurface.withValues(alpha: 0.8)),
                    const SizedBox(width: 24),
                    const _IconText(icon: Icons.star, text: "4.8 (Nuevos)", color: Colors.amber),
                  ],
                )
              ],
            ),
          ),

          // ACCIONES
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FilledButton.icon(
                onPressed: () {}, 
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text("Contactar"),
                style: FilledButton.styleFrom(
                  backgroundColor: profile.brandColor, 
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold)
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if ((profile.whatsapp ?? '').isNotEmpty) _SocialIconBtn(icon: Icons.message, color: Colors.green, onTap: () => _launch("https://wa.me/${profile.whatsapp}")),
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

  Widget _buildInitials(ProviderProfileModel profile, ColorScheme colors) {
    return Container(
      color: colors.primary.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Text(
        profile.businessName.isNotEmpty ? profile.businessName[0].toUpperCase() : 'S',
        style: TextStyle(fontSize: 48, color: colors.primary, fontWeight: FontWeight.bold)
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _IconText({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8))),
      ],
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
      padding: const EdgeInsets.only(left: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1), 
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3))
          ),
          child: Icon(icon, size: 22, color: color),
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

// FAB personalizado para carrito en Web
class _CartFloatingButton extends StatelessWidget {
  final Color brandColor;
  const _CartFloatingButton({required this.brandColor});
  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(builder: (context, cart, child) {
       return FloatingActionButton.extended(
         backgroundColor: brandColor,
         icon: const Icon(Icons.shopping_cart, color: Colors.white),
         label: Text(cart.totalItems > 0 ? '${cart.totalItems} Items' : 'Carrito', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
         onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
       );
    });
  }
}

// SIDEBAR DE CATEGORÍAS (Estilo Amazon)
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
              _buildCategoryTile(context, "Ver Todos", selectedCategoryId == null, () => onCategorySelected(null)),
              const Divider(height: 1),
              ...categories.map((cat) => Column(
                children: [
                  _buildCategoryTile(context, cat.name, selectedCategoryId == cat.id, () => onCategorySelected(cat.id)),
                  if (cat != categories.last) const Divider(height: 1),
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
      leading: isSelected ? Icon(Icons.check_circle, color: brandColor, size: 20) : const SizedBox(width: 20),
      selected: isSelected,
      selectedTileColor: brandColor.withValues(alpha: 0.05),
      hoverColor: brandColor.withValues(alpha: 0.05),
      onTap: onTap,
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
    );
  }
}

// CHIPS DE CATEGORÍAS (Móvil)
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