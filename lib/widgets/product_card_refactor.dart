import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';

class ProductCardRefactor extends StatefulWidget {
  final ProductModel product;
  final Color brandColor;
  final VoidCallback? onTap;
  final bool isEditable; // TRUE = Modo Gestor, FALSE = Modo Tienda Pública
  final VoidCallback? onLikeToggle; // Solo para modo público
  final bool isLiked; // Solo para modo público

  const ProductCardRefactor({
    super.key,
    required this.product,
    this.brandColor = const Color(0xFF00BFFF),
    this.onTap,
    this.isEditable = true,
    this.onLikeToggle,
    this.isLiked = false,
  });

  @override
  State<ProductCardRefactor> createState() => _ProductCardRefactorState();
}

class _ProductCardRefactorState extends State<ProductCardRefactor> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // 1. LÓGICA DE IMAGEN
    String displayImage = widget.product.imageUrl;
    
    if ((displayImage.isEmpty) && widget.product.mediaGallery.isNotEmpty) {
       final firstMedia = widget.product.mediaGallery.firstWhere(
         (m) => m['url'] != null && m['url'].toString().isNotEmpty,
         orElse: () => {},
       );
       if (firstMedia.isNotEmpty) displayImage = firstMedia['url'];
    } else if (widget.product.imageUrl.isEmpty && widget.product.mediaGallery.isEmpty) {
      displayImage = ''; 
    }

    // Lógica de Stock
    final bool isLowStock = widget.product.quantity != null && widget.product.quantity! > 0 && widget.product.quantity! < 5;
    final bool isOutOfStock = widget.product.quantity == 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          // CORRECCIÓN 1: Usamos Matrix4.translationValues en lugar de .identity()..translate
          transform: Matrix4.translationValues(0.0, _isHovered ? -5.0 : 0.0, 0.0), 
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered 
                  ? widget.brandColor 
                  : theme.dividerColor.withValues(alpha: 0.1),
              width: _isHovered ? 2 : 1
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered 
                    ? widget.brandColor.withValues(alpha: 0.2) 
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: _isHovered ? 12 : 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. IMAGEN (Parte Superior) ---
              Expanded(
                flex: 3, 
                child: Stack(
                  children: [
                    // Imagen
                    SizedBox.expand(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                        child: displayImage.isNotEmpty
                            ? Image.network(
                                displayImage,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildPlaceholder(widget.brandColor),
                              )
                            : _buildPlaceholder(widget.brandColor),
                      ),
                    ),
                    
                    // Overlay oscuro si no hay stock
                    if (isOutOfStock)
                      Container(
                        color: Colors.black.withValues(alpha: 0.5),
                        alignment: Alignment.center,
                        child: const Text(
                          "AGOTADO",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                      ),

                    // Badges (Stock)
                    if (isLowStock && !isOutOfStock)
                       Positioned(
                        top: 8, left: 8,
                        child: _buildTag('Últimas u.', Colors.orange),
                      ),

                    // Botón Like / Edit (Flotante)
                    Positioned(
                      top: 8, right: 8,
                      child: widget.isEditable
                          ? _buildIconBtn(Icons.edit, Colors.white, Colors.black54, () {}) 
                          : _buildLikeButton(),
                    ),
                  ],
                ),
              ),

              // --- 2. INFORMACIÓN (Parte Inferior) ---
              Expanded(
                flex: 2, 
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Ver detalles", 
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5)
                            ),
                          ),
                        ],
                      ),
                      
                      // Precio y Acción
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        // CORRECCIÓN 2: Cambiado 'items' por 'children'
                        children: [
                          Text(
                            '\$${widget.product.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: widget.brandColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          // Icono de carrito pequeño
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _isHovered ? widget.brandColor : theme.canvasColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _isHovered ? widget.brandColor : theme.dividerColor),
                            ),
                            child: Icon(
                              Icons.add_shopping_cart, 
                              size: 16, 
                              color: _isHovered ? Colors.white : theme.iconTheme.color,
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS INTERNOS ---

  Widget _buildPlaceholder(Color color) {
    return Container(
      color: color.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 32,
          color: color.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, Color iconColor, Color bgColor, VoidCallback onTap) {
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: iconColor, size: 16),
    );
  }

  Widget _buildLikeButton() {
    return GestureDetector(
      onTap: widget.onLikeToggle,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]
        ),
        child: Icon(
          widget.isLiked ? Icons.favorite : Icons.favorite_border,
          color: widget.isLiked ? Colors.redAccent : Colors.grey,
          size: 18,
        ),
      ),
    );
  }
}