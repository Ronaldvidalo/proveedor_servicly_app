// --- UX/UI Enhancement Comment ---
// UX/UI Refactor: 19/11/2025
// Style: Cyber Glow (Theme Implementation - Tienda)
//
// (FIX) Corregido error de RenderSliver.
// Se eliminó 'SliverToBoxAdapter' que envolvía a '_EmptyState',
// ya que '_EmptyState' es un 'SliverFillRemaining' por sí mismo.
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // Para StreamSubscription

// --- Modelos y Servicios ---
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

// --- Widgets del Perfil Público ---
import 'package:proveedor_servicly_app/core/viewmodels/cart_provider.dart';
import 'package:proveedor_servicly_app/features/cart/screens/cart_screen.dart';
import 'package:proveedor_servicly_app/widgets/public_brand_header_1.dart';
import 'package:proveedor_servicly_app/widgets/partners_carousel.dart';

// --- Servicios ---
import 'package:proveedor_servicly_app/core/services/auth_service.dart'; 
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart';

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

  Future<void> _launchURL(String url) async {
    String launchableUrl = url;
    if (!url.startsWith('http://') &&
        !url.startsWith('https://') &&
        !url.startsWith('tel:') &&
        !url.startsWith('mailto:') &&
        !url.startsWith('https://wa.me/')) {
      launchableUrl = 'https://$url';
    }
    final Uri uri = Uri.parse(launchableUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error al lanzar $url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- 1. LEEMOS EL TEMA INYECTADO ---
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Fondo dinámico
      
      // AppBar Pública
      appBar: AppBar(
        title: Text(widget.profile.businessName),
        backgroundColor: theme.appBarTheme.backgroundColor, // Fondo dinámico
        foregroundColor: theme.appBarTheme.foregroundColor, 
        elevation: 0,
        actions: [
          _CartBadge(brandColor: colors.primary), // Usamos el color de marca
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
                onLaunchUrl: _launchURL,
                clientId: _currentClientId,
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
            _buildProductsByCategoriesSection(context, widget.profile.providerId, theme),

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


  // --- WIDGET: Sección de Videos ---
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
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
              child: Center(
                  child: Text('Error al cargar videos: ${snapshot.error}',
                      style: TextStyle(color: colors.error))));
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

  // --- WIDGET: Sección de Productos por Categoría ---
  Widget _buildProductsByCategoriesSection(BuildContext context, String providerId, ThemeData theme) {
    final categoryService = context.read<CategoryService>();
    final productService = context.read<ProductService>();
    final colors = theme.colorScheme;

    return StreamBuilder<List<CategoryModel>>(
      stream: categoryService.getCategories(providerId),
      builder: (context, categorySnapshot) {
        if (categorySnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingSkeleton(); 
        }
        if (categorySnapshot.hasError) {
          return SliverToBoxAdapter(
              child: Center(
                  child: Text('Error: ${categorySnapshot.error}',
                      style: TextStyle(color: colors.error))));
        }
        
        final categories = categorySnapshot.data ?? [];

        if (categories.isEmpty) {
          // --- ¡CORRECCIÓN AQUÍ! ---
          // _EmptyState ya es un SliverFillRemaining, no necesita SliverToBoxAdapter.
          return const _EmptyState(); 
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final category = categories[index];
              return _ProductCarousel(
                category: category,
                providerId: providerId,
                productService: productService,
              );
            },
            childCount: categories.length,
          ),
        );
      },
    );
  }

  // --- WIDGET: Título de Sección ---
  Widget _buildSectionTitle(String title, bool isFirst, ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, isFirst ? 16 : 32, 16, 16),
        child: Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.onSurface, // Texto dinámico
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
} 

// ===================================================================
// --- WIDGETS AUXILIARES ---
// ===================================================================

/// Fila de Productos para una Categoría
class _ProductCarousel extends StatelessWidget {
  final CategoryModel category;
  final String providerId;
  final ProductService productService;

  const _ProductCarousel({
    required this.category,
    required this.providerId,
    required this.productService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de Categoría
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              category.name,
              style: TextStyle(
                color: colors.onSurface, // Dinámico
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Lista Horizontal
          SizedBox(
            height: 220,
            child: StreamBuilder<List<ProductModel>>(
              stream: productService.getProducts(providerId, categoryId: category.id, limit: 5),
              builder: (context, productSnapshot) {
                if (productSnapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: 3,
                    itemBuilder: (context, index) => Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        // Color de esqueleto dinámico
                        color: colors.surface.withAlpha(128), 
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  );
                }
                
                final products = productSnapshot.data ?? [];

                if (products.isEmpty) {
                  return const SizedBox.shrink();
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: SizedBox(
                        width: 160,
                        child: _ProductCard(
                          product: product,
                          brandColor: colors.primary, // Color de marca dinámico
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- Tarjeta de Producto ---
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final Color brandColor;

  const _ProductCard({required this.product, required this.brandColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    void onContact(String contactType) async {
      final crmRepository = context.read<CrmRepository>();
      final providerId = context.read<ProviderProfileModel>().providerId;
      final profile = context.read<ProviderProfileModel>();
      if (contactType == 'whatsapp' && profile.whatsapp != null && profile.whatsapp!.isNotEmpty) {
        
        final cleanNumber = profile.whatsapp!.replaceAll(RegExp(r'[^\d]'), '');
        final formattedNumber = cleanNumber.startsWith('+') ? cleanNumber : '+$cleanNumber'; 
        final Uri launchUri = Uri.parse('https://wa.me/$formattedNumber?text=Hola,%20estoy%20interesado%20en%20el%20producto:%20${product.name}');

        // Lanzar URL y Capturar Lead
        try {
          await crmRepository.captureLeadFromPublicProfile(
            email: null, 
            nombreCompleto: 'Visitante Tienda', 
            source: 'tienda_whatsapp_producto',
            providerId: providerId,
            telefono: null,
          );
        } catch (e) {
          debugPrint("Error al capturar Lead: $e");
        }

        if (await canLaunchUrl(launchUri)) {
          await launchUrl(launchUri, mode: LaunchMode.externalApplication);
        }

      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El proveedor no tiene configurado WhatsApp.')));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface, // <-- CLAVE: Color de tarjeta dinámico
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
                                const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.white38, size: 40)),
                          )
                        : Container(
                            color: Colors.black.withAlpha(51),
                            child: const Center(child: Icon(Icons.shopping_bag_outlined, size: 50, color: Colors.white38)),
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
                      // Texto dinámico
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
                            style: TextStyle( color: colors.onSurface.withOpacity(0.5), decoration: TextDecoration.lineThrough, fontSize: 14 ),
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

// --- Diálogo de Detalle de Producto ---
void _showProductDetailDialog(BuildContext context, ProductModel product, Color brandColor) {
  int quantity = 1;
  final theme = Theme.of(context);
  final colors = theme.colorScheme;
  final crmRepository = context.read<CrmRepository>();
  final providerId = context.read<ProviderProfileModel>().providerId;

  // Función de contacto local
  void onContact() async {
      final profile = context.read<ProviderProfileModel>();
      if (profile.whatsapp != null && profile.whatsapp!.isNotEmpty) {
        final cleanNumber = profile.whatsapp!.replaceAll(RegExp(r'[^\d]'), '');
        final formattedNumber = cleanNumber.startsWith('+') ? cleanNumber : '+$cleanNumber'; 
        final Uri launchUri = Uri.parse('https://wa.me/$formattedNumber?text=Hola,%20estoy%20interesado%20en%20el%20producto:%20${product.name}');

        try {
          await crmRepository.captureLeadFromPublicProfile(
            email: null, 
            nombreCompleto: 'Visitante Tienda', 
            source: 'tienda_whatsapp_producto',
            providerId: providerId,
            telefono: null,
          );
        } catch (e) {
          debugPrint("Error CRM: $e");
        }

        if (await canLaunchUrl(launchUri)) {
          await launchUrl(launchUri, mode: LaunchMode.externalApplication);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El proveedor no tiene WhatsApp.')));
      }
  }

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      final cart = dialogContext.read<CartProvider>();
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: colors.surface, // <-- Fondo dinámico
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
                        : const Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.white38),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if(product.description.isNotEmpty) ...[
                          Text(product.description, style: TextStyle(color: colors.onSurface.withOpacity(0.7))),
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
                                  style: TextStyle(color: colors.onSurface.withOpacity(0.5), decoration: TextDecoration.lineThrough, fontSize: 16),
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
                                color: colors.background, // <-- Input bg dinámico
                                borderRadius: BorderRadius.circular(30)
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.remove, color: colors.onSurface.withOpacity(0.7)),
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
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(dialogContext).pop(); 
                              onContact(); 
                            },
                            icon: const Icon(Icons.chat_bubble_outline), 
                            label: const Text('Contactar por WhatsApp'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: brandColor,
                              side: BorderSide(color: brandColor, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
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

class _EmptyState extends StatelessWidget {
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
              Icon(Icons.storefront_outlined, size: 80, color: colors.onSurface.withOpacity(0.2)),
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
                style: TextStyle(fontSize: 16, color: colors.onSurface.withOpacity(0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
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