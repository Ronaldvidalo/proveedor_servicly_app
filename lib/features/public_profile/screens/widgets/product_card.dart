import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Modelos
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';

// Servicios
import 'package:proveedor_servicly_app/core/services/auth_service.dart';
import 'package:proveedor_servicly_app/core/services/analytics_service.dart';
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart';
import 'package:proveedor_servicly_app/core/viewmodels/cart_provider.dart';

// Widgets
import 'package:proveedor_servicly_app/features/crm/presentation/widget/lead_capture_button.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final Color brandColor;

  const ProductCard({
    super.key,
    required this.product,
    required this.brandColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // --- 1. SELECCIÓN DE IMAGEN INTELIGENTE ---
    String? displayImage;
    if (product.imageUrl.isNotEmpty) {
      displayImage = product.imageUrl;
    } else if (product.mediaGallery.isNotEmpty) {
      // Si no hay principal, buscamos la primera de la galería
      final firstImage = product.mediaGallery.firstWhere(
        (m) => m['type'] == 'image',
        orElse: () => {},
      );
      if (firstImage.isNotEmpty) {
        displayImage = firstImage['url'];
      }
    }
    // ------------------------------------------

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brandColor.withAlpha(128), width: 1),
        boxShadow: [
          BoxShadow(color: brandColor.withAlpha(51), blurRadius: 10, spreadRadius: 1)
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () => _showProductDetailDialog(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- IMAGEN Y BADGES ---
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Imagen con manejo de errores
                    displayImage != null
                        ? Image.network(
                            displayImage,
                            fit: BoxFit.cover,
                            // EVITA PANTALLA ROJA SI FALLA (Error 403 o URL rota)
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Icon(Icons.broken_image_outlined, color: colors.onSurface.withAlpha(100), size: 40),
                            ),
                            loadingBuilder: (context, child, progress) => progress == null
                                ? child
                                : Center(child: CircularProgressIndicator(strokeWidth: 2, color: brandColor)),
                          )
                        : Container(
                            color: colors.onSurface.withAlpha(25),
                            child: Center(child: Icon(Icons.shopping_bag_outlined, size: 50, color: colors.onSurface.withAlpha(102))),
                          ),

                    // Etiqueta de Promo (Arriba Izquierda)
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

                    // Botón "Me Gusta" (Abajo Derecha)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 16,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.favorite_border, color: Colors.redAccent, size: 20),
                          onPressed: () => _handleLike(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- DETALLES ---
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
                            style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: TextStyle(color: colors.onSurface.withAlpha(128), decoration: TextDecoration.lineThrough, fontSize: 14),
                          ),
                        ] else ...[
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontSize: 18),
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

  // --- LÓGICA DEL LIKE ---
  void _handleLike(BuildContext context) {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    
    // Leemos el perfil del proveedor para saber a quién enviarle el lead
    final profile = context.read<ProviderProfileModel>(); 
    final repo = context.read<CrmRepository>();

    if (user != null) {
      repo.captureLeadFromPublicProfile(
        providerId: profile.providerId,
        source: 'product_like',
        email: user.email,
        nombreCompleto: user.displayName,
        logoUrl: user.photoURL,
        // location: user.personalization... (Si tuvieras el UserModel completo)
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❤️ Te gusta "${product.name}"'),
          backgroundColor: Colors.pinkAccent,
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para dar Me Gusta.')),
      );
    }
  }

  // --- LÓGICA DEL DIÁLOGO DETALLE ---
  void _showProductDetailDialog(BuildContext context) {
    int quantity = 1;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    // Contexto del proveedor dueño de la tienda
    final profile = context.read<ProviderProfileModel>();
    final providerId = profile.providerId;

    // 1. ANALÍTICA (Hitos)
    try {
      final analytics = context.read<AnalyticsService>();
      analytics.trackProductView(
        providerId: providerId,
        planType: profile.planType,
        productName: product.name,
      );
    } catch (_) {}

    // 2. CAPTURA "VISTO" (Lead Silencioso)
    try {
      final authService = context.read<AuthService>();
      final currentUser = authService.currentUser;

      if (currentUser != null) {
        final crmRepository = context.read<CrmRepository>();
        crmRepository.captureLeadFromPublicProfile(
          providerId: providerId,
          source: 'view_product',
          email: currentUser.email,
          nombreCompleto: currentUser.displayName ?? 'Visitante Registrado',
          logoUrl: currentUser.photoURL,
        );
      }
    } catch (_) {}

    // 3. MOSTRAR DIÁLOGO
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
                    // Imagen Grande
                    SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: product.imageUrl.isNotEmpty
                          ? Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 50, color: colors.onSurface.withAlpha(100)),
                            )
                          : Icon(Icons.shopping_bag_outlined, size: 80, color: colors.onSurface.withAlpha(102)),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (product.description.isNotEmpty) ...[
                            Text(product.description, style: TextStyle(color: colors.onSurface.withAlpha(178))),
                            const SizedBox(height: 24),
                          ],
                          
                          // Precio y Cantidad
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Precio:', style: TextStyle(fontSize: 18, color: brandColor, fontWeight: FontWeight.bold)),
                              Text('\$${(product.isOnSale ? product.promoPrice : product.price)?.toStringAsFixed(2)}', style: TextStyle(fontSize: 22, color: brandColor, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Cantidad:', style: TextStyle(fontSize: 16, color: colors.onSurface)),
                              Container(
                                decoration: BoxDecoration(color: colors.surface.withAlpha(50), borderRadius: BorderRadius.circular(30)),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.remove, color: colors.onSurface.withAlpha(178)),
                                      onPressed: () { if (quantity > 1) setState(() => quantity--); },
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
                          const SizedBox(height: 24),

                          // Botón Contactar WhatsApp
                          if (profile.whatsapp != null && profile.whatsapp!.isNotEmpty)
                            LeadCaptureButton(
                              actionType: ContactAction.whatsapp,
                              contactValue: profile.whatsapp!,
                              providerId: providerId,
                              label: 'Consultar por WhatsApp',
                              brandColor: brandColor,
                              message: 'Hola, estoy interesado en: ${product.name}',
                              isOutline: true,
                              onPressedOverride: () => Navigator.pop(dialogContext),
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
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Se añadieron $quantity al carrito.'), backgroundColor: Colors.green));
                  },
                  style: FilledButton.styleFrom(backgroundColor: brandColor, foregroundColor: Colors.white),
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
}