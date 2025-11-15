// --- UX/UI Enhancement Comment ---
// ... (comentarios omitidos por brevedad) ...
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

// --- NUEVAS IMPORTACIONES PARA EL PERFIL PÚBLICO ---
import 'package:proveedor_servicly_app/core/viewmodels/cart_provider.dart';
import 'package:proveedor_servicly_app/features/cart/screens/cart_screen.dart';
import 'package:proveedor_servicly_app/widgets/public_brand_header_1.dart';
import 'package:proveedor_servicly_app/widgets/partners_carousel.dart';
import 'package:proveedor_servicly_app/core/services/follow_service.dart';

// --- Asumo que tienes un AuthService para obtener el cliente actual ---
import 'package:proveedor_servicly_app/core/services/auth_service.dart'; 


// --- CORRECCIÓN 1: Ruta de importación DEFINITIVA ---
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart';

class TiendaLayout extends StatefulWidget {
  final String providerId;
  final ProviderProfileModel profile;
  // TODO: Necesitaremos el ID del cliente actual para la lógica de "Seguir"
  // final String currentClientId; // <-- ¡LO OBTENDREMOS DEL AUTH_SERVICE!

  const TiendaLayout({
    super.key,
    required this.providerId,
    required this.profile,
    // required this.currentClientId,
  });

  @override
  State<TiendaLayout> createState() => _TiendaLayoutState();
}

/// Un widget de layout que muestra el perfil de un proveedor con un estilo de "tienda".
class _TiendaLayoutState extends State<TiendaLayout> {

  // --- LÓGICA DE SEGUIMIENTO ELIMINADA ---
  // Toda la lógica de _isFollowing, _isLoadingFollow, _followService y _onFollowTap
  // se ha movido al widget 'FollowButton', tal como lo definiste.
  
  // Solo necesitamos el ID del cliente actual para pasarlo al header.
  late final String? _currentClientId;
  // --- FIN DE LA MODIFICACIÓN ---


  // --- Conectar los servicios en initState ---
  @override
  void initState() {
    super.initState();
    // 1. Obtenemos el AuthService
    final authService = context.read<AuthService>();
    
    // 2. Obtenemos el ID del cliente (el usuario logueado)
    // (Tu AuthService usa 'currentUser.uid', así que esto es correcto)
    _currentClientId = authService.currentUser?.uid; 

    // 3. Lógica de suscripción eliminada.
  }

  // --- Limpiar la suscripción ---
  @override
  void dispose() {
    // Suscripción eliminada.
    super.dispose();
  }

  // --- Función _onFollowTap eliminada ---
  // (Ahora está encapsulada en FollowButton)


  /// Para lanzar URLs
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
    const backgroundColor = Color(0xFF1A1A2E);
    final brandColor = widget.profile.brandColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      // AppBar Pública
      appBar: AppBar(
        title: Text(widget.profile.businessName),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          _CartBadge(brandColor: brandColor), // Ícono del carrito
          const SizedBox(width: 16),
        ],
      ),

      body: Provider.value(
        value: widget.profile, // Aquí inyectamos el modelo
        child: CustomScrollView(
          slivers: [
            // --- SECCIÓN 1: Identidad de Marca (PÚBLICA) ---
            SliverToBoxAdapter(
              child: PublicBrandHeader1(
                profile: widget.profile,
                onLaunchUrl: _launchURL,
                
                // --- MODIFICACIÓN CLAVE ---
                // Ya no pasamos 'isFollowing' ni 'onFollowTap'
                // Solo pasamos el ID del cliente
                clientId: _currentClientId,
                // --- FIN DE LA MODIFICACIÓN ---
              ),
            ),
            
            // --- ¡NUEVA SECCIÓN 2: PARTNERS! ---
            SliverToBoxAdapter(
              child: PartnersCarousel(
                partners: widget.profile.partners,
              ),
            ),

            
            // --- SECCIÓN 2: Gestor de Promoción (Videos) ---
            _buildSectionTitle('Videos del Proveedor', false),
            _buildVideoPromoSection(context, widget.profile.providerId),

            // --- SECCIÓN 3: Productos de la Tienda ---
            _buildSectionTitle('Nuestros Productos', false),

            // _buildProductsByCategoriesSection ES el contenido de la Sección 4
            _buildProductsByCategoriesSection(context, widget.profile.providerId),

            // --- SECCIÓN 5: Calificaciones (¡NUEVO!) ---
            _buildSectionTitle('Calificaciones y Comentarios', false),
            SliverToBoxAdapter(
              child: Container(
                height: 120,
                alignment: Alignment.center,
                child: const Text(
                  '(Próximamente: Módulo de Reseñas)',
                  style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                ),
              )
            ),


            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }


  // --- WIDGET PARA SECCIÓN 3 (Videos) ---
  Widget _buildVideoPromoSection(BuildContext context, String providerId) {
    final videoService = context.read<VideoService>();
    const accentColor = Color(0xFF00BFFF);

    return StreamBuilder<List<VideoShowcaseModel>>(
      stream: videoService.getVideoShowcasesByProvider(providerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: CircularProgressIndicator(color: accentColor),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
              child: Center(
                  child: Text('Error al cargar videos: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent))));
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
              itemCount: videos.length, // Sin botones de gestión
              itemBuilder: (context, index) {
                final video = videos[index];
                // Usamos el VideoCard REUTILIZABLE
                return VideoCard(
                  video: video,
                  brandColor: accentColor, 
                  onPlayTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => VideoPlayerScreen(videoShowcase: video),
                    ));
                  },
                  // NO pasamos onEditTap, así que no es editable
                );
              },
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET PARA SECCIÓN 5 (Productos por Categoría) ---
  Widget _buildProductsByCategoriesSection(BuildContext context, String providerId) {
    final categoryService = context.read<CategoryService>();
    final productService = context.read<ProductService>();

    return StreamBuilder<List<CategoryModel>>(
      stream: categoryService.getCategories(providerId),
      builder: (context, categorySnapshot) {
        if (categorySnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingSkeleton(); // Widget que SÍ se usa
        }
        if (categorySnapshot.hasError) {
          return SliverToBoxAdapter(
              child: Center(
                  child: Text('Error: ${categorySnapshot.error}',
                      style: const TextStyle(color: Colors.redAccent))));
        }
        
        final categories = categorySnapshot.data ?? [];

        if (categories.isEmpty) {
          return const SliverToBoxAdapter(child: _EmptyState()); // Widget que SÍ se usa
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

  // --- WIDGET AUXILIAR PARA TÍTULOS DE SECCIÓN ---
  Widget _buildSectionTitle(String title, bool isFirst) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, isFirst ? 16 : 32, 16, 16),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
} 
// --- FIN DE LA CLASE _TiendaLayoutState ---

// ===================================================================
// --- WIDGETS AUXILIARES (AHORA FUERA DE LA CLASE) ---
// ===================================================================

/// Fila de Productos para una Categoría Específica
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
    final brandColor = context.watch<ProviderProfileModel>().brandColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Título de la Categoría
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              category.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // 2. Fila Horizontal de Productos
          SizedBox(
            height: 220, // Altura fija para el carrusel
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
                        color: const Color(0xFF2D2D5A).withAlpha(128),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  );
                }
                
                final products = productSnapshot.data ?? [];

                // Si no hay productos, no muestra nada
                if (products.isEmpty) {
                  return const SizedBox.shrink();
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: products.length, // ¡SIN BOTONES + y Ver Más!
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: SizedBox(
                        width: 160,
                        child: _ProductCard(
                          product: product,
                          brandColor: brandColor,
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

// --- Tarjeta de Producto (Copiada del tienda_layout original) ---
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final Color brandColor;

  const _ProductCard({required this.product, required this.brandColor});

  @override
  Widget build(BuildContext context) {
    final crmRepository = context.read<CrmRepository>();
    final providerId = context.watch<ProviderProfileModel>().providerId;
    
    // Función de contacto
    void onContact(String contactType) async {
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
        color: const Color(0xFF2D2D5A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brandColor.withAlpha(128), width: 1),
        boxShadow: [
          BoxShadow(color: brandColor.withAlpha(51), blurRadius: 10, spreadRadius: 1)
        ]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () => _showProductDetailDialog(context, product, brandColor, onContact),
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
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
                            style: const TextStyle( color: Colors.white54, decoration: TextDecoration.lineThrough, fontSize: 14 ),
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

// Función para mostrar el detalle del producto (Se mantiene fuera de las clases para reuso)
void _showProductDetailDialog(BuildContext context, ProductModel product, Color brandColor, ValueChanged<String> onContact) {
  int quantity = 1;

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      final cart = dialogContext.read<CartProvider>();
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2D2D5A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                          Text(product.description, style: const TextStyle(color: Colors.white70)),
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
                                  style: const TextStyle(color: Colors.white54, decoration: TextDecoration.lineThrough, fontSize: 16),
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
                            const Text('Cantidad:', style: TextStyle(fontSize: 16, color: Colors.white)),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A2E),
                                borderRadius: BorderRadius.circular(30)
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, color: Colors.white70),
                                    onPressed: () {
                                      if (quantity > 1) setState(() => quantity--);
                                    },
                                  ),
                                  Text('$quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
                        // --- BOTÓN DE CONTACTO ESPECÍFICO ---
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(dialogContext).pop(); // Cerrar diálogo primero
                              onContact('whatsapp'); 
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
                    border: Border.all(color: const Color(0xFF1A1A2E), width: 2),
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

// --- WIDGETS DE ESTADO (Loading, Empty, Error) ---

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.storefront_outlined, size: 80, color: Colors.white24),
              SizedBox(height: 24),
              Text(
                'Tienda en Construcción',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Este proveedor aún no ha añadido productos a su tienda.',
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


// --- CLASES AUXILIARES COPIADAS DE MANAGE_STORE_SCREEN ---

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate(
          [
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D5A).withAlpha(128),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}