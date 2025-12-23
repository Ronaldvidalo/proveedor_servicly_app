import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';

class ProductCardRefactor extends StatelessWidget {
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
    this.isEditable = true, // Por defecto es modo gestor
    this.onLikeToggle,
    this.isLiked = false,
  });

  @override
  Widget build(BuildContext context) {
    // 1. LÓGICA DE IMAGEN INTELIGENTE
    // Si imageUrl está vacía, buscamos la primera imagen en la galería
    String displayImage = product.imageUrl;
    
    if ((displayImage.isEmpty) && product.mediaGallery.isNotEmpty) {
       // Buscamos el primer elemento que sea imagen o video con thumbnail
       final firstMedia = product.mediaGallery.firstWhere(
         (m) => m['url'] != null && m['url'].toString().isNotEmpty,
         orElse: () => {},
       );
       if (firstMedia.isNotEmpty) {
         displayImage = firstMedia['url'];
       }
    } else if (product.imageUrl.isEmpty && product.mediaGallery.isEmpty) {
      // Si no hay nada de nada
      displayImage = ''; 
    }

    // Lógica de Stock Bajo (Menos de 5 unidades)
    final bool isLowStock = product.quantity != null && product.quantity! > 0 && product.quantity! < 5;
    final bool isOutOfStock = product.quantity == 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D5A),
          borderRadius: BorderRadius.circular(16),
          // ✅ CORRECCIÓN: withValues en lugar de withOpacity
          border: Border.all(color: brandColor.withValues(alpha: 0.5), width: 1),
          boxShadow: [
            BoxShadow(
              // ✅ CORRECCIÓN: withValues en lugar de withOpacity
              color: brandColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // --- FONDO DE IMAGEN ---
              Positioned.fill(
                child: displayImage.isNotEmpty
                    ? Image.network(
                        displayImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),

              // --- GRADIENTE PARA TEXTO ---
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        // ✅ CORRECCIÓN: withValues en lugar de withOpacity
                        const Color(0xFF1A1A2E).withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                ),
              ),

              // --- INFORMACIÓN DEL PRODUCTO ---
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: brandColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // --- ETIQUETAS DE STOCK (Arriba Izquierda) ---
              if (isOutOfStock)
                Positioned(
                  top: 8,
                  left: 8,
                  child: _buildTag('Agotado', Colors.red),
                )
              else if (isLowStock)
                Positioned(
                  top: 8,
                  left: 8,
                  child: _buildTag('Quedan ${product.quantity}', Colors.orange),
                ),

              // --- ACCIONES (Arriba Derecha) ---
              Positioned(
                top: 8,
                right: 8,
                child: isEditable
                    ? _buildEditButton() // Modo Gestor: Icono Editar
                    : _buildLikeButton(), // Modo Tienda: Corazón
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Placeholder (Bolsa de compras)
  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF2D2D5A),
      child: Center(
        child: Icon(
          Icons.shopping_bag_outlined,
          size: 40,
          // ✅ CORRECCIÓN: withValues en lugar de withOpacity
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  // Etiqueta (Tag)
  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Botón Editar (Solo Gestor)
  Widget _buildEditButton() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        // ✅ CORRECCIÓN: withValues en lugar de withOpacity
        color: const Color(0xFF1A1A2E).withValues(alpha: 0.7),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.edit, color: Colors.white, size: 16),
    );
  }

  // Botón Like (Solo Tienda Pública)
  Widget _buildLikeButton() {
    return GestureDetector(
      onTap: onLikeToggle,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          // ✅ CORRECCIÓN: withValues en lugar de withOpacity
          color: const Color(0xFF1A1A2E).withValues(alpha: 0.7),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isLiked ? Icons.favorite : Icons.favorite_border,
          color: isLiked ? Colors.redAccent : Colors.white,
          size: 18,
        ),
      ),
    );
  }
}