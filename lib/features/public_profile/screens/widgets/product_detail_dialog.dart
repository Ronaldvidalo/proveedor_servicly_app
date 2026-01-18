import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- Modelos y Servicios ---
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/viewmodels/cart_provider.dart';
// import 'package:proveedor_servicly_app/core/services/analytics_service.dart'; // Opcional
// import 'package:proveedor_servicly_app/core/services/auth_service.dart'; // Opcional

class ProductDetailDialog extends StatefulWidget {
  final ProductModel product;
  final Color brandColor;

  const ProductDetailDialog({
    super.key,
    required this.product,
    required this.brandColor,
  });

  // Método estático seguro para mostrar el diálogo
  static void show(BuildContext context, ProductModel product, Color brandColor) {
    // Intentamos obtener el perfil del proveedor de forma segura
    ProviderProfileModel? profile;
    try {
      profile = Provider.of<ProviderProfileModel>(context, listen: false);
    } catch (e) {
      debugPrint("Advertencia: No se encontró ProviderProfileModel en el contexto.");
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (ctx) {
        // Si tenemos perfil, lo re-inyectamos. Si no, mostramos el diálogo sin él.
        if (profile != null) {
          return Provider.value(
            value: profile,
            child: ProductDetailDialog(product: product, brandColor: brandColor),
          );
        } else {
          return ProductDetailDialog(product: product, brandColor: brandColor);
        }
      },
    );
  }

  @override
  State<ProductDetailDialog> createState() => _ProductDetailDialogState();
}

class _ProductDetailDialogState extends State<ProductDetailDialog> {
  int _quantity = 1;
  late PageController _pageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _addToCart() {
    // Verificación de seguridad para el CartProvider
    try {
      final cart = context.read<CartProvider>();
      cart.addItem(widget.product, _quantity);
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Se añadieron $_quantity "${widget.product.name}" al carrito.', 
            style: const TextStyle(fontWeight: FontWeight.bold)
          ),
          backgroundColor: widget.brandColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          width: 400,
        ),
      );
    } catch (e) {
      debugPrint("Error al agregar al carrito: $e");
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isWebLarge = size.width > 900; 

    return Dialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: isWebLarge ? 1000 : double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: size.height * 0.9, 
          maxWidth: 1000,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: isWebLarge 
              ? _buildWebLayout(context, theme)
              : _buildMobileLayout(context, theme),
        ),
      ),
    );
  }

  // ===========================================================================
  // LAYOUT WEB (DOS COLUMNAS)
  // ===========================================================================
  Widget _buildWebLayout(BuildContext context, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // COLUMNA IZQUIERDA: CARRUSEL
        Expanded(
          flex: 5,
          child: Container(
            color: theme.colorScheme.surface, 
            child: Stack(
              children: [
                _buildMediaGallery(BoxFit.contain),
                // Botón cerrar flotante (Izquierda arriba)
                Positioned(
                  top: 16,
                  left: 16,
                  child: CircleAvatar(
                    backgroundColor: theme.cardColor.withValues(alpha: 0.8),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: theme.iconTheme.color),
                      tooltip: 'Cerrar',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // COLUMNA DERECHA: INFO
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderInfo(theme),
                      const SizedBox(height: 24),
                      _buildDescription(theme),
                      const SizedBox(height: 24),
                      _buildPriceSection(theme),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: _buildActionButtons(context, theme),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // LAYOUT MÓVIL (VERTICAL)
  // ===========================================================================
  Widget _buildMobileLayout(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        // ZONA SUPERIOR: CARRUSEL + CERRAR
        SizedBox(
          height: 350,
          child: Stack(
            children: [
              Container(
                color: theme.colorScheme.surface,
                child: _buildMediaGallery(BoxFit.cover),
              ),
              Positioned(
                top: 16, right: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.3),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ZONA INFERIOR: INFO SCROLLABLE
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderInfo(theme),
                const SizedBox(height: 16),
                _buildPriceSection(theme),
                const SizedBox(height: 20),
                _buildDescription(theme),
                const SizedBox(height: 80), // Espacio para botones fijos
              ],
            ),
          ),
        ),

        // BARRA DE ACCIÓN FLOTANTE
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5))],
            border: Border(top: BorderSide(color: theme.dividerColor)),
          ),
          child: _buildActionButtons(context, theme),
        ),
      ],
    );
  }

  // ===========================================================================
  // LOGICA DE IMÁGENES / GALERÍA
  // ===========================================================================
  Widget _buildMediaGallery(BoxFit fit) {
    // 1. Recopilar todas las imágenes válidas
    final List<String> images = [];
    
    if (widget.product.imageUrl.isNotEmpty) {
      images.add(widget.product.imageUrl);
    }
    
    if (widget.product.mediaGallery.isNotEmpty) {
      for (var media in widget.product.mediaGallery) {
        if (media['url'] != null && media['url'].toString().isNotEmpty && media['url'] != widget.product.imageUrl) {
          images.add(media['url']);
        }
      }
    }

    // 2. Si no hay imágenes, mostrar placeholder
    if (images.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text("Sin imagen", style: TextStyle(color: Colors.grey.withValues(alpha: 0.5))),
          ],
        ),
      );
    }

    // 3. Renderizar PageView (Carrusel Nativo)
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: images.length,
          onPageChanged: (index) => setState(() => _currentImageIndex = index),
          itemBuilder: (context, index) {
            return Image.network(
              images[index],
              fit: fit,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => 
                const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(child: CircularProgressIndicator(color: widget.brandColor));
              },
            );
          },
        ),
        // Indicadores de página (Puntos)
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: images.asMap().entries.map((entry) {
                return Container(
                  width: 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == entry.key
                        ? widget.brandColor
                        : Colors.grey.withValues(alpha: 0.5),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // COMPONENTES DE UI
  // ===========================================================================

  Widget _buildHeaderInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.product.name,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Botón Compartir Simple
            IconButton(
              icon: Icon(Icons.share, color: widget.brandColor),
              onPressed: () {
                // Lógica de compartir simple o placeholder
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enlace copiado al portapapeles (Simulado)')),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.product.quantity != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: widget.product.quantity! > 0 ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: widget.product.quantity! > 0 ? Colors.green : Colors.red,
                width: 0.5
              )
            ),
            child: Text(
              widget.product.quantity! > 0 ? 'Stock Disponible: ${widget.product.quantity}' : 'Agotado',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: widget.product.quantity! > 0 ? Colors.green : Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPriceSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.product.isOnSale) ...[
          Text(
            '\$${widget.product.price.toStringAsFixed(2)}',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              decoration: TextDecoration.lineThrough,
              fontSize: 16,
            ),
          ),
          Text(
            '\$${widget.product.promoPrice!.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 32,
              color: widget.brandColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ] else
          Text(
            '\$${widget.product.price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 32,
              color: widget.brandColor,
              fontWeight: FontWeight.w900,
            ),
          ),
      ],
    );
  }

  Widget _buildDescription(ThemeData theme) {
    if (widget.product.description.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Descripción",
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          widget.product.description,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // CONTADOR
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove, size: 20, color: theme.iconTheme.color),
                    onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                  ),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '$_quantity',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, size: 20, color: widget.brandColor),
                    onPressed: () => setState(() => _quantity++),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // BOTÓN CARRITO
            Expanded(
              child: SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: _addToCart,
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: const Text("Agregar al Carrito", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.brandColor,
                    foregroundColor: Colors.white, // Siempre blanco para contraste
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    shadowColor: widget.brandColor.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Fila Secundaria (Consultar)
        TextButton.icon(
          onPressed: () {}, 
          icon: Icon(Icons.chat_bubble_outline, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          label: Text("Consultar al vendedor", style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        ),
      ],
    );
  }
}