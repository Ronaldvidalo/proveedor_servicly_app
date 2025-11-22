import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui'; 
// Modelos y Servicios
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/services/product_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/models/video_showcase_model.dart';
import 'package:proveedor_servicly_app/core/services/video_service.dart';
import 'package:proveedor_servicly_app/core/services/category_service.dart';
import 'package:proveedor_servicly_app/core/models/category_model.dart';
import 'package:proveedor_servicly_app/widgets/VideoCard.dart';
import 'package:proveedor_servicly_app/features/manage_store/presentation/screens/video_player_screen.dart';
// Widgets del Perfil Público
import 'package:proveedor_servicly_app/core/viewmodels/cart_provider.dart';
import 'package:proveedor_servicly_app/features/cart/screens/cart_screen.dart';
import 'package:proveedor_servicly_app/widgets/public_brand_header_1.dart';
import 'package:proveedor_servicly_app/widgets/partners_carousel.dart';
// --- CRM WIDGETS ---
import 'package:proveedor_servicly_app/features/crm/presentation/widget/lead_capture_button.dart'; // Contiene ContactAction enum
import 'package:proveedor_servicly_app/features/public_profile/screens/widgets/contact_action_row.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/widgets/social_media_row.dart';

// --- Servicios ---
import 'package:proveedor_servicly_app/core/services/auth_service.dart'; 

// --- DEFINICIÓN ÚNICA DE LA FUNCIÓN DE DIÁLOGO ---
void _showProductDetailDialog(BuildContext context, ProductModel product, Color brandColor) {
  int quantity = 1;
  final theme = Theme.of(context);
  final colors = theme.colorScheme;
  final profile = context.read<ProviderProfileModel>();
  final providerId = profile.providerId;

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      final cart = dialogContext.read<CartProvider>();
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: colors.surface, 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(product.name, style: TextStyle(fontWeight: FontWeight.bold, color: colors.onSurface)),
            contentPadding: const EdgeInsets.all(0),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: product.imageUrl.isNotEmpty
                        ? Image.network(product.imageUrl, fit: BoxFit.cover)
                        : Icon(Icons.shopping_bag_outlined, size: 80, color: colors.onSurface.withAlpha(102)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if(product.description.isNotEmpty) ...[
                          Text(product.description, style: TextStyle(color: colors.onSurface.withAlpha(178))),
                          const SizedBox(height: 24),
                        ],
                        
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('Precio:', style: TextStyle(fontSize: 18, color: brandColor, fontWeight: FontWeight.bold)),
                              if (product.isOnSale) ...[
                                Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                  style: TextStyle(color: colors.onSurface.withAlpha(128), decoration: TextDecoration.lineThrough, fontSize: 16),
                                ),
                                Text(
                                  '\$${product.promoPrice!.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 22, color: brandColor, fontWeight: FontWeight.bold),
                                ),
                              ] else ...[
                                Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 22, color: brandColor, fontWeight: FontWeight.bold),
                                ),
                              ]
                            ],
                          ),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Cantidad:', style: TextStyle(fontSize: 16, color: colors.onSurface)),
                            Container(
                              decoration: BoxDecoration(
                                color: colors.background, 
                                borderRadius: BorderRadius.circular(30)
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.remove, color: colors.onSurface.withAlpha(178)),
                                    onPressed: () {
                                      if (quantity > 1) setState(() => quantity--);
                                    },
                                  ),
                                  Text('$quantity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.onSurface)),
                                  IconButton(
                                    icon: Icon(Icons.add, color: brandColor),
                                    onPressed: () => setState(() => quantity++),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // --- BOTÓN DE CONTACTO REUTILIZABLE ---
                        if (profile.whatsapp != null && profile.whatsapp!.isNotEmpty)
                          LeadCaptureButton(
                            actionType: ContactAction.whatsapp,
                            contactValue: profile.whatsapp!,
                            providerId: providerId,
                            label: 'Contactar por Producto',
                            brandColor: brandColor,
                            message: 'Hola, me gustaría comprar/cotizar el producto: ${product.name}',
                            isOutline: true, 
                          ),
                        // --- FIN BOTÓN DE CONTACTO ---
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('Cerrar', style: TextStyle(color: brandColor)),
              ),
              FilledButton.icon(
                onPressed: () {
                  cart.addItem(product, quantity);
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Se añadieron $quantity "${product.name}" al carrito.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: brandColor,
                  foregroundColor: ThemeData.estimateBrightnessForColor(brandColor) == Brightness.dark
                      ? Colors.white : Colors.black,
                ),
                icon: const Icon(Icons.add_shopping_cart_outlined),
                label: const Text('Añadir al Carrito'),
              ),
            ],
          );
        },
      );
    },
  );
}

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

  String? _selectedCategoryId; // Variable de estado para el filtro
  late final String? _currentClientId;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _currentClientId = authService.currentUser?.uid; 
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    // =======================================================
    // IMPRESIÓN DE DEPURACIÓN CRÍTICA (Punto de Falla 1)
    // Verificamos que los datos EXISTAN en el modelo antes de inyectarlo.
    // =======================================================
    debugPrint('--- DIAGNÓSTICO TIENDA LAYOUT (DATOS BASE) ---');
    debugPrint('Profile: ${widget.profile.businessName}');
    debugPrint('WhatsApp: ${widget.profile.whatsapp}');
    debugPrint('Phone: ${widget.profile.phone}');
    debugPrint('Instagram: ${widget.profile.instagram}');
    debugPrint('Facebook: ${widget.profile.facebook}');
    debugPrint('----------------------------------------------');


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

      body: Provider.value(
        value: widget.profile,
        child: CustomScrollView(
          slivers: [
            // --- SECCIÓN 1: Header (Identidad de Marca) ---
            SliverToBoxAdapter(
              child: PublicBrandHeader1(
                profile: widget.profile,
                onLaunchUrl: (url) {
                  debugPrint('Lanzando URL genérica: $url');
                },
                clientId: _currentClientId,
              ),
            ),
            
            // --- NUEVA FILA: REDES SOCIALES ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: SocialMediaRow(brandColor: colors.primary),
              ),
            ),
            
            // --- NUEVA FILA: Botones de Contacto CRM (WhatsApp/Teléfono/Cotizar) ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: ContactActionRow(
                  brandColor: colors.primary,
                  useOutlineStyle: true,
                ),
              ),
            ),

            // --- SECCIÓN 2: Partners ---
            SliverToBoxAdapter(
              child: PartnersCarousel(
                partners: widget.profile.partners,
              ),
            ),
            
            // --- SECCIÓN 3: Videos ---
            _buildSectionTitle('Videos del Proveedor', false, theme),
            _buildVideoPromoSection(context, widget.profile.providerId, theme),

            // --- SECCIÓN 4: Productos (Categorías) ---
            _buildSectionTitle('Nuestros Productos', false, theme),
            
            // Selector de Categorías 
            _CategorySelector(
              providerId: widget.profile.providerId,
              selectedCategoryId: _selectedCategoryId, 
              brandColor: colors.primary,
              onCategorySelected: (categoryId) {
                setState(() {
                  _selectedCategoryId = categoryId; 
                });
              },
            ),

            // Carrete de Productos Filtrados
            _buildProductsGridSection(context, widget.profile.providerId, _selectedCategoryId, colors.primary, theme),


            // --- SECCIÓN 5: Calificaciones ---
            _buildSectionTitle('Calificaciones y Comentarios', false, theme),
            SliverToBoxAdapter(
              child: Container(
                height: 120,
                alignment: Alignment.center,
                child: Text(
                  '(Próximamente: Módulo de Reseñas)',
                  style: TextStyle(
                    color: colors.onSurface.withOpacity(0.5), 
                    fontStyle: FontStyle.italic
                  ),
                ),
              )
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DE CONSTRUCCIÓN INTERNA ---

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
  
  // WIDGET que carga el Grid de Productos
  Widget _buildProductsGridSection(BuildContext context, String providerId, String? selectedCategoryId, Color brandColor, ThemeData theme) {
    final productService = context.read<ProductService>();

    return StreamBuilder<List<ProductModel>>(
      stream: productService.getProducts(providerId, categoryId: selectedCategoryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingSkeleton(); 
        }
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
              child: Center(
                  child: Text('Error al cargar productos: ${snapshot.error}',
                      style: TextStyle(color: theme.colorScheme.error))));
        }
        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return const _EmptyState();
        }

        return SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = products[index];
                return _ProductCard(
                  product: product, 
                  brandColor: brandColor,
                );
              },
              childCount: products.length,
            ),
          ),
        );
      },
    );
  }

  // WIDGET que construye la sección de videos (asumido)
  Widget _buildVideoPromoSection(BuildContext context, String providerId, ThemeData theme) {
    final videoService = context.read<VideoService>();
    final colors = theme.colorScheme;

    return StreamBuilder<List<VideoShowcaseModel>>(
      stream: videoService.getVideoShowcasesByProvider(providerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: CircularProgressIndicator(color: colors.primary),
              ),
            ),
          );
        }
        final videos = snapshot.data ?? [];
        
        if (videos.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverToBoxAdapter(
          child: SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];
                return VideoCard(
                  video: video,
                  brandColor: colors.primary, // Color dinámico
                  onPlayTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => VideoPlayerScreen(videoShowcase: video),
                    ));
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
} 

// ===================================================================
// --- WIDGETS AUXILIARES (DEFINICIONES ÚNICAS) ---
// ===================================================================

class _CartBadge extends StatelessWidget {
  const _CartBadge({required this.brandColor});
  final Color brandColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, size: 28),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const CartScreen(),
                ));
              },
            ),
            if (cart.totalItems > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: brandColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    '${cart.totalItems}',
                    style: TextStyle(
                      color: ThemeData.estimateBrightnessForColor(brandColor) == Brightness.dark
                          ? Colors.white : Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}


class _CategorySelector extends StatelessWidget {
  final String providerId;
  final String? selectedCategoryId;
  final Color brandColor;
  final ValueChanged<String?> onCategorySelected;

  const _CategorySelector({
    required this.providerId,
    required this.selectedCategoryId,
    required this.brandColor,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final categoryService = context.read<CategoryService>(); 
    final theme = Theme.of(context);
    final colors = theme.colorScheme;


    return StreamBuilder<List<CategoryModel>>(
      stream: categoryService.getCategories(providerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final categories = snapshot.data!;

        return SliverToBoxAdapter(
          child: SizedBox(
            height: 60,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length + 1,
              itemBuilder: (context, index) {
                // El primer chip siempre es "Todos"

                if (index == 0) {
                  final isSelected = selectedCategoryId == null;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: const Text('Ver Todos'),
                      selected: isSelected,
                      onSelected: (selected) => onCategorySelected(null),
                      selectedColor: brandColor,
                      labelStyle: TextStyle(color: isSelected ? (ThemeData.estimateBrightnessForColor(brandColor) == Brightness.dark ? Colors.white : Colors.black) : colors.onSurface),
                      backgroundColor: colors.surface,
                      shape: StadiumBorder(side: BorderSide(color: isSelected ? brandColor : colors.onSurface.withAlpha(77))), 
                    ),
                  );
                }

                final category = categories[index - 1];
                final isSelected = selectedCategoryId == category.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(category.name),
                    selected: isSelected,
                    onSelected: (selected) => onCategorySelected(category.id),
                    selectedColor: brandColor,
                    labelStyle: TextStyle(color: isSelected ? (ThemeData.estimateBrightnessForColor(brandColor) == Brightness.dark ? Colors.white : Colors.black) : colors.onSurface),
                    backgroundColor: colors.surface,
                    shape: StadiumBorder(side: BorderSide(color: isSelected ? brandColor : colors.onSurface.withAlpha(77))), 
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}


class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final Color brandColor;

  const _ProductCard({required this.product, required this.brandColor}); 

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface, 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brandColor.withAlpha(128), width: 1), 
        boxShadow: [
          BoxShadow(color: brandColor.withAlpha(51), blurRadius: 10, spreadRadius: 1)
        ]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () => _showProductDetailDialog(context, product, brandColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    product.imageUrl.isNotEmpty
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) => 
                            progress == null ? child : Center(child: CircularProgressIndicator(strokeWidth: 2, color: brandColor)),
                          errorBuilder: (context, error, stackTrace) => 
                            Center(child: Icon(Icons.image_not_supported_outlined, color: colors.onSurface.withAlpha(102), size: 40)), 
                        )
                      : Container(
                          color: colors.onSurface.withAlpha(25), 
                          child: Center(child: Icon(Icons.shopping_bag_outlined, size: 50, color: colors.onSurface.withAlpha(102))),
                        ),
                    if (product.promoText != null && product.promoText!.isNotEmpty)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.promoText!,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colors.onSurface), 
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8.0,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        if (product.isOnSale) ...[
                          Text(
                            '\$${product.promoPrice!.toStringAsFixed(2)}',
                            style: TextStyle( color: brandColor, fontWeight: FontWeight.bold, fontSize: 18 ),
                          ),
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: TextStyle( color: colors.onSurface.withAlpha(128), decoration: TextDecoration.lineThrough, fontSize: 14 ),
                          ),
                        ] else ...[
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: TextStyle( color: brandColor, fontWeight: FontWeight.bold, fontSize: 18 ),
                          ),
                        ]
                      ],
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


class _LoadingSkeleton extends StatelessWidget {
// ...
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate(
          [
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: colors.surface.withAlpha(128),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _EmptyState extends StatelessWidget {
// ...
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.storefront_outlined, size: 80, color: colors.onSurface.withAlpha(51)), 
              const SizedBox(height: 24),
              Text(
                'Tienda en Construcción',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, color: colors.onSurface, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Este proveedor aún no ha añadido productos a su tienda.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: colors.onSurface.withAlpha(153)),
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
      child: Center(child: Text('Error al cargar productos:\n$error', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error))),
    );
  }
}
