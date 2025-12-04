// (Nota: Asegúrate de guardar este archivo con el nombre correcto,
// parece que antes lo tenías en un archivo aparte o dentro de otro.
// Este código es para el archivo que contiene la clase ProductDetailDialog)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:share_plus/share_plus.dart';

// --- Modelos y Servicios ---
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/viewmodels/cart_provider.dart';
import 'package:proveedor_servicly_app/core/services/analytics_service.dart';
import 'package:proveedor_servicly_app/core/services/auth_service.dart';
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart';
import 'package:proveedor_servicly_app/features/crm/presentation/widget/lead_capture_button.dart';

class ProductDetailDialog extends StatefulWidget {
  final ProductModel product;
  final Color brandColor;

  const ProductDetailDialog({
    super.key,
    required this.product,
    required this.brandColor,
  });

  static void show(BuildContext context, ProductModel product, Color brandColor) {
    final profile = context.read<ProviderProfileModel>();
    final cart = context.read<CartProvider>();

    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(200), // Fondo más oscuro para enfoque
      builder: (_) => MultiProvider(
        providers: [
          Provider.value(value: profile),
          ChangeNotifierProvider.value(value: cart),
        ],
        child: ProductDetailDialog(product: product, brandColor: brandColor),
      ),
    );
  }

  @override
  State<ProductDetailDialog> createState() => _ProductDetailDialogState();
}

class _ProductDetailDialogState extends State<ProductDetailDialog> {
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _trackViewAndCaptureLead());
  }

  void _trackViewAndCaptureLead() {
    try {
      final profile = context.read<ProviderProfileModel>();
      final analytics = context.read<AnalyticsService>();
      final authService = context.read<AuthService>();
      final crmRepository = context.read<CrmRepository>();

      analytics.trackProductView(
        providerId: widget.product.providerId,
        planType: profile.planType,
        productName: widget.product.name,
      );

      final currentUser = authService.currentUser;
      if (currentUser != null) {
        crmRepository.captureLeadFromPublicProfile(
          providerId: widget.product.providerId,
          source: 'view_product',
          email: currentUser.email,
          nombreCompleto: currentUser.displayName ?? 'Visitante Registrado',
          logoUrl: currentUser.photoURL,
        );
      }
    } catch (e) {
      debugPrint("Error silencioso en ProductDetailDialog: $e");
    }
  }

  void _shareProduct() {
    const String appDownloadLink = "https://servicly.app/download"; 
    final String message = 
        "¡Mira lo que encontré en Servicly! 🚀\n\n"
        "*${widget.product.name}* a solo \$${widget.product.price.toStringAsFixed(2)}\n\n"
        "${widget.product.description.length > 50 ? widget.product.description.substring(0, 50) + '...' : widget.product.description}\n\n"
        "📲 Descárgalo aquí: $appDownloadLink";

    Share.share(message, subject: "Mira este producto: ${widget.product.name}");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final profile = context.watch<ProviderProfileModel>();
    final cart = context.read<CartProvider>();
    
    // Usamos Dialog en lugar de AlertDialog para control total del layout
    return Dialog(
      backgroundColor: Colors.transparent, // Hacemos transparente el fondo del Dialog
      insetPadding: const EdgeInsets.all(16), // Margen externo
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 500), // Ancho máximo en tablets
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D5A), // Surface Color Cyber Glow
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: widget.brandColor.withAlpha(100), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(100),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- 1. CABECERA (Título y Compartir) ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: _shareProduct,
                    icon: const Icon(Icons.share_rounded),
                    color: widget.brandColor,
                    tooltip: 'Compartir',
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.white54,
                    tooltip: 'Cerrar',
                  ),
                ],
              ),
            ),
            
            const Divider(color: Colors.white10, height: 1),

            // --- 2. CONTENIDO SCROLLEABLE ---
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Carrusel de Imágenes
                    if (widget.product.imageUrl.isNotEmpty || widget.product.mediaGallery.isNotEmpty)
                      _DetailMediaCarousel(product: widget.product),
                    
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Precios
                          Wrap(
                            spacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.end,
                            children: [
                              if (widget.product.isOnSale) ...[
                                Text(
                                  '\$${widget.product.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    decoration: TextDecoration.lineThrough,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '\$${widget.product.promoPrice!.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 28,
                                    color: widget.brandColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  '\$${widget.product.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 28,
                                    color: widget.brandColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ]
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Descripción
                          if (widget.product.description.isNotEmpty)
                            Text(
                              widget.product.description,
                              style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                            ),
                            
                          const SizedBox(height: 24),
                          
                          // WhatsApp Button (Si existe)
                          if (profile.whatsapp != null && profile.whatsapp!.isNotEmpty)
                            LeadCaptureButton(
                              actionType: ContactAction.whatsapp,
                              contactValue: profile.whatsapp!,
                              providerId: profile.providerId,
                              label: 'Consultar por WhatsApp',
                              brandColor: const Color(0xFF25D366), // Color oficial WhatsApp
                              message: 'Hola, estoy interesado en el producto: ${widget.product.name}',
                              isOutline: true,
                              onPressedOverride: () => Navigator.pop(context),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(color: Colors.white10, height: 1),

            // --- 3. BARRA DE ACCIÓN INFERIOR (Fija) ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF222244), // Ligeramente más oscuro
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  // Selector de Cantidad Compacto
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18, color: Colors.white),
                          onPressed: () {
                            if (_quantity > 1) setState(() => _quantity--);
                          },
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          padding: EdgeInsets.zero,
                        ),
                        Text(
                          '$_quantity',
                          style: const TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.white
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18, color: Colors.white),
                          onPressed: () => setState(() => _quantity++),
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Botón Añadir Grande
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: () {
                          cart.addItem(widget.product, _quantity);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Se añadieron $_quantity "${widget.product.name}" al carrito.', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              backgroundColor: const Color(0xFF00FF7F), // Verde Éxito
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: widget.brandColor,
                          foregroundColor: ThemeData.estimateBrightnessForColor(widget.brandColor) == Brightness.dark
                              ? Colors.white : Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.add_shopping_cart_rounded),
                        label: const Text('AÑADIR AL CARRITO', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET PRIVADO: Carrusel (Mejorado) ---
class _DetailMediaCarousel extends StatelessWidget {
  final ProductModel product;

  const _DetailMediaCarousel({required this.product});

  @override
  Widget build(BuildContext context) {
    List<Widget> mediaWidgets = [];

    if (product.imageUrl.isNotEmpty) {
      mediaWidgets.add(_buildImage(product.imageUrl));
    }

    if (product.mediaGallery.isNotEmpty) {
      for (var media in product.mediaGallery) {
        final String url = media['url'] ?? '';
        final String type = media['type'] ?? 'image';
        final String thumb = media['thumbnailUrl'] ?? '';

        if (url.isNotEmpty) {
          if (type == 'video') {
            mediaWidgets.add(Stack(
              fit: StackFit.expand,
              children: [
                if (thumb.isNotEmpty) 
                  _buildImage(thumb) 
                else 
                  Container(color: Colors.black87),
                const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 50)),
              ],
            ));
          } else {
            mediaWidgets.add(_buildImage(url));
          }
        }
      }
    }

    if (mediaWidgets.isEmpty) {
      return Container(
        height: 200,
        color: Colors.white.withAlpha(10),
        child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 50, color: Colors.white24)),
      );
    }

    if (mediaWidgets.length == 1) {
      return SizedBox(height: 250, width: double.infinity, child: mediaWidgets.first);
    }

    return CarouselSlider(
      items: mediaWidgets,
      options: CarouselOptions(
        height: 250,
        viewportFraction: 1.0,
        enableInfiniteScroll: mediaWidgets.length > 1,
        autoPlay: false, // Mejor false para que el usuario explore
      ),
    );
  }

  Widget _buildImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(child: CircularProgressIndicator(value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null));
      },
      errorBuilder: (context, error, stackTrace) => 
        Container(color: Colors.grey.shade900, child: const Icon(Icons.broken_image, color: Colors.white54)),
    );
  }
}