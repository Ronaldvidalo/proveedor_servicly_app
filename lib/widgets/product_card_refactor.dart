import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';

class ProductCardRefactor extends StatefulWidget {
  final ProductModel product;
  final Color brandColor;
  final VoidCallback? onTap;
  final bool isEditable;
  final VoidCallback? onLikeToggle;
  final bool isLiked;
  final VoidCallback? onAddToCart; // <--- NUEVO CALLBACK

  const ProductCardRefactor({
    super.key,
    required this.product,
    this.brandColor = const Color(0xFF00BFFF),
    this.onTap,
    this.isEditable = true,
    this.onLikeToggle,
    this.isLiked = false,
    this.onAddToCart, // <--- Recibimos la función
  });

  @override
  State<ProductCardRefactor> createState() => _ProductCardRefactorState();
}

class _ProductCardRefactorState extends State<ProductCardRefactor> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Lógica de Imagen
    String displayImage = widget.product.imageUrl;
    if ((displayImage.isEmpty) && widget.product.mediaGallery.isNotEmpty) {
      final firstMedia = widget.product.mediaGallery.firstWhere(
        (m) => m['url'] != null && m['url'].toString().isNotEmpty,
        orElse: () => {},
      );
      if (firstMedia.isNotEmpty) displayImage = firstMedia['url'];
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Si hay mucho ancho disponible, asumimos entorno de escritorio/web grid
        // y activamos el efecto "Reveal on Hover"
        final isWebGrid = constraints.maxWidth > 200; 

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16), 
                border: Border.all(
                  color: _isHovered ? widget.brandColor.withValues(alpha: 0.5) : theme.dividerColor.withValues(alpha: 0.1),
                  width: _isHovered ? 2 : 1
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isHovered 
                        ? widget.brandColor.withValues(alpha: 0.2) 
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: _isHovered ? 20 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    // --- FONDO: IMAGEN CON ZOOM ---
                    Positioned.fill(
                      child: AnimatedScale(
                        scale: _isHovered && isWebGrid ? 1.1 : 1.0, 
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        child: _buildImageArea(displayImage),
                      ),
                    ),

                    // --- CAPA SUPERIOR: BADGES & ACTIONS ---
                    if (isWebGrid) ...[
                       // Gradiente Oscuro siempre visible abajo para leer texto
                       Positioned(
                         bottom: 0, left: 0, right: 0,
                         height: 150,
                         child: Container(
                           decoration: BoxDecoration(
                             gradient: LinearGradient(
                               begin: Alignment.bottomCenter,
                               end: Alignment.topCenter,
                               colors: [
                                 Colors.black.withValues(alpha: 0.9),
                                 Colors.black.withValues(alpha: 0.0),
                               ],
                             ),
                           ),
                         ),
                       ),
                       
                       // Botón Like (Arriba Derecha)
                       Positioned(
                          top: 12, right: 12,
                          child: widget.isEditable
                              ? _buildIconBtn(Icons.edit, Colors.white, Colors.black54, () {}) 
                              : _buildLikeButton(),
                        ),
                    ],

                    // --- PANEL DE INFORMACIÓN (ANIMADO) ---
                    isWebGrid 
                      ? _buildWebRevealContent(theme)
                      : _buildMobileContent(theme),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- CONTENIDO WEB (REVEAL ANIMATION) ---
  Widget _buildWebRevealContent(ThemeData theme) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Precio siempre visible
            Text(
              '\$${widget.product.price.toStringAsFixed(2)}',
              style: TextStyle(
                color: widget.brandColor,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
            const SizedBox(height: 4),
            // Título
            Text(
              widget.product.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
              maxLines: _isHovered ? 3 : 1, 
              overflow: TextOverflow.ellipsis,
            ),

            // Elementos que aparecen SOLO al hover
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 8), 
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  if (widget.product.description != null)
                    Text(
                      widget.product.description!,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      // ✅ CORRECCIÓN: Conectado el callback
                      onPressed: widget.onAddToCart, 
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      label: const Text("Agregar"),
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.brandColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
              crossFadeState: _isHovered ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }

  // --- CONTENIDO MÓVIL (ESTÁTICO CLÁSICO) ---
  Widget _buildMobileContent(ThemeData theme) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        color: theme.cardColor.withValues(alpha: 0.95),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.product.name,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${widget.product.price.toStringAsFixed(2)}',
                  style: TextStyle(color: widget.brandColor, fontWeight: FontWeight.bold),
                ),
                // ✅ CORRECCIÓN: Botón "Más" para agregar al carrito en móvil
                InkWell(
                  onTap: widget.onAddToCart,
                  child: Icon(Icons.add_circle, color: widget.brandColor, size: 28),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---

  Widget _buildImageArea(String imageUrl) {
    final bool isLowStock = widget.product.quantity != null && widget.product.quantity! > 0 && widget.product.quantity! < 5;
    final bool isOutOfStock = widget.product.quantity == 0;

    return Stack(
      fit: StackFit.expand,
      children: [
        imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(widget.brandColor),
              )
            : _buildPlaceholder(widget.brandColor),
        
        if (isOutOfStock)
          Container(
            color: Colors.black.withValues(alpha: 0.6),
            alignment: Alignment.center,
            child: const Text("AGOTADO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),

        if (isLowStock && !isOutOfStock)
          Positioned(
            top: 12, left: 12,
            child: _buildTag('Últimas', Colors.orange),
          ),
      ],
    );
  }

  Widget _buildPlaceholder(Color color) {
    return Container(
      color: color.withValues(alpha: 0.05),
      child: Center(
        child: Icon(Icons.image_not_supported_outlined, size: 28, color: color.withValues(alpha: 0.3)),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildIconBtn(IconData icon, Color iconColor, Color bgColor, VoidCallback onTap) {
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)]
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