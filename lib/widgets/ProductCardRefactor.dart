import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';

class ProductCardRefactor extends StatelessWidget {
  final ProductModel product;
  final Color brandColor;
  final VoidCallback onDetailTap;

  const ProductCardRefactor({
    super.key,
    required this.product,
    required this.brandColor,
    required this.onDetailTap,
  });

  // --- FUNCIÓN DE UTILIDAD PARA FORMATO DE PRECIO ---
  String _formatPrice(double price) {
    final format = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '\$',
      decimalDigits: 2,
    );
    return format.format(price);
  }

  // Lógica de colores de estado (Borde)
  Color _getBorderColor() {
    if (product.isOutOfStock) return Colors.grey.shade700;
    if (product.isExpired) return Colors.redAccent.shade700;
    if (product.isExpiringSoon) return Colors.orangeAccent.shade700;
    return brandColor.withAlpha(150);
  }

  // WIDGET AUXILIAR: ETIQUETA DE STOCK
  Widget _buildQuantityBadge() {
    if (product.isOutOfStock) {
      return const _StatusBadge(text: 'AGOTADO', color: Color(0xFFC62828), icon: Icons.block);
    }
    
    if (product.quantity != null && product.quantity! > 0 && product.quantity! <= 5) {
      return _StatusBadge(
        text: 'Quedan ${product.quantity}', // Texto un poco más corto
        color: Colors.orange.shade700,
        icon: Icons.inventory_2_outlined,
      );
    }
    return const SizedBox.shrink();
  }

  // WIDGET AUXILIAR: ETIQUETA DE DESCUENTO
  Widget _buildPromoBadge() {
    if (product.isOnSale && product.promoPrice != null && product.promoPrice! < product.price) {
      // Calculamos porcentaje y evitamos división por cero
      if (product.price == 0) return const SizedBox.shrink();
      final discount = (1 - (product.promoPrice! / product.price)) * 100;
      
      return Transform.translate(
        offset: const Offset(4, -4),
        child: ClipPath(
          clipper: _DiscountClipper(), 
          child: Container(
            width: 50, 
            height: 50, 
            color: Colors.redAccent,
            alignment: Alignment.topCenter,
            child: Transform.rotate(
              angle: 0.785, // 45 grados
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 10.0),
                child: Text(
                  '-${discount.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Color(0xFF2D2D5A);
    final borderColor = _getBorderColor();
    final isAgotado = product.isOutOfStock;

    return GestureDetector(
      onTap: onDetailTap,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: borderColor.withAlpha(80),
              blurRadius: 12,
              spreadRadius: 1,
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. Imagen y Badges ---
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Imagen/Thumbnail
                    product.imageUrl.isNotEmpty
                        ? Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            // OPTIMIZACIÓN DE MEMORIA: Redimensiona la imagen en caché
                            cacheWidth: 400, 
                            loadingBuilder: (context, child, progress) =>
                                progress == null ? child : Center(child: CircularProgressIndicator(strokeWidth: 2, color: brandColor)),
                            errorBuilder: (context, error, stack) =>
                                const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.white38, size: 40)),
                          )
                        : Container(
                            color: Colors.black.withAlpha(51),
                            child: const Center(child: Icon(Icons.shopping_bag_outlined, color: Colors.white38, size: 40)),
                          ),
                    
                    // Overlay oscuro si está agotado
                    if (isAgotado) Container(color: Colors.black54),

                    // Badges
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildQuantityBadge(),
                    ),
                    
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _buildPromoBadge(),
                    ),
                  ],
                ),
              ),

              // --- 2. Detalles ---
              Expanded(
               flex: 2,
               child: Padding(
               padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0), 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                     mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      // Título
                      Text(
                        product.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15), // Ligero ajuste de fuente
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // Precios
                      if (product.isOnSale && product.promoPrice != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatPrice(product.price),
                              style: TextStyle(
                                  color: Colors.red.shade400,
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 11,
                                  fontWeight: FontWeight.normal),
                            ),
                            Text(
                              _formatPrice(product.promoPrice!),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: brandColor, 
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ],
                        )
                      else
                        Text(
                          _formatPrice(product.price),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: brandColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
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
}

// -------------------------------------------------------------------
// WIDGETS AUXILIARES
// -------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _StatusBadge({required this.text, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        // CORRECCIÓN: Usamos withAlpha para evitar warnings de deprecación
        boxShadow: [BoxShadow(color: color.withAlpha(128), blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 10),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _DiscountClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width, 0);       
    path.lineTo(size.width, size.height * 0.5); 
    path.lineTo(size.width * 0.5, size.height); 
    path.lineTo(0, size.height);       
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}