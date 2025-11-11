import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Importamos para formatear precios grandes
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart'; 
// import 'package:proveedor_servicly_app/core/viewmodels/cart_provider.dart'; 


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

  // --- FUNCIÓN DE UTILIDAD PARA FORMATO DE PRECIO (Maneja millones) ---
  String _formatPrice(double price) {
    // Usamos NumberFormat para manejar grandes cantidades con separador de miles.
    // Locale 'es_AR' para formato argentino (punto para miles, coma para decimales)
    final format = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '\$',
      decimalDigits: 2, // 2 decimales
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

  // WIDGET AUXILIAR: ETIQUETA DE STOCK/CANTIDAD (Esquina superior izquierda)
  Widget _buildQuantityBadge() {
    if (product.isOutOfStock) {
      return const _StatusBadge(text: 'AGOTADO', color: Color(0xFFC62828), icon: Icons.block);
    }
    
    if (product.quantity != null && product.quantity! > 0 && product.quantity! <= 5) {
      return _StatusBadge(
        text: 'Sólo ${product.quantity}', 
        color: Colors.orange.shade700,
        icon: Icons.inventory_2_outlined,
      );
    }
    return const SizedBox.shrink();
  }

  // WIDGET AUXILIAR: ETIQUETA DE DESCUENTO (Esquina superior derecha en diagonal)
  Widget _buildPromoBadge() {
    if (product.isOnSale && product.promoPrice != null && product.promoPrice! < product.price) {
      final discount = (1 - (product.promoPrice! / product.price)) * 100;
      
      // La clave está en el Clipper y el tamaño del Container
      return Transform.translate(
        offset: const Offset(4, -4), // Mover un poco hacia la esquina para que no se oculte
        child: ClipPath(
          clipper: _DiscountClipper(), 
          child: Container(
            width:50, // Aumentamos el ancho para que el clipper sea más grande
            height: 50, 
            color: Colors.redAccent,
            alignment: Alignment.topCenter,
            child: Transform.rotate(
              angle: 0.785, // 45 grados
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 10.0), // Ajuste visual
                child: Text(
                  '-${discount.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14, // Aumentamos un poco la fuente
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
                            loadingBuilder: (context, child, progress) =>
                                progress == null ? child : Center(child: CircularProgressIndicator(strokeWidth: 2, color: brandColor)),
                            errorBuilder: (context, error, stack) =>
                                const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.white38, size: 40)),
                          )
                        : Container(
                            color: Colors.black.withAlpha(51),
                            child: const Center(child: Icon(Icons.shopping_bag_outlined, color: Colors.white38, size: 40)),
                          ),
                    
                    if (isAgotado) Container(color: Colors.black54),

                    // Badge de Cantidad/Agotado (Esquina superior izquierda)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildQuantityBadge(),
                    ),
                    
                    // Badge de Descuento (Esquina superior derecha, diagonal)
                    // Se posiciona en top: 0, right: 0 y se ajusta con Transform.translate en _buildPromoBadge
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _buildPromoBadge(),
                    ),
                  ],
                ),
              ),

              // --- 2. Detalles (Optimizado para el Overflow) ---
              Expanded(
               flex: 2,
               child: Padding(
    
               padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0), 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                     mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      // --- Título (Permite 2 líneas, mismo tamaño) ---
                      Text(
                        product.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // --- PRECIOS (Optimizado para grandes números) ---
                      if (product.isOnSale && product.promoPrice != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatPrice(product.price), // Usamos el formateador
                              style: TextStyle(
                                  color: Colors.red.shade400,
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 12, // Fuente pequeña para el precio tachado
                                  fontWeight: FontWeight.normal),
                            ),
                            const SizedBox(height: 2),
                            // Precio de Oferta (Ligeramente más pequeño para evitar overflow vertical)
                            Text(
                              _formatPrice(product.promoPrice!), // Usamos el formateador
                              style: TextStyle(
                                  color: brandColor, 
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16), // Reducido de 18 a 16
                            ),
                          ],
                        )
                      else
                        // Solo el precio si no hay oferta
                        Text(
                          _formatPrice(product.price), // Usamos el formateador
                          style: TextStyle(
                              color: brandColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16), // Reducido de 18 a 16
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
// WIDGETS AUXILIARES Y CLIPPER (Sin cambios significativos)
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
        boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// CLIPPER AJUSTADO para la Etiqueta Diagonal
class _DiscountClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width, 0);       // Esquina superior derecha
    path.lineTo(size.width, size.height * 0.5); // Punto medio derecho
    path.lineTo(size.width * 0.5, size.height); // Punto medio inferior
    path.lineTo(0, size.height);       // Esquina inferior izquierda (ajustado para la visualización)
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}