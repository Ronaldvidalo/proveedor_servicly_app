import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/video_showcase_model.dart'; 

class VideoCard extends StatelessWidget {
  final VideoShowcaseModel video;
  final Color brandColor;
  final VoidCallback onPlayTap;
  final VoidCallback? onEditTap;

  const VideoCard({
    super.key,
    required this.video,
    required this.brandColor,
    required this.onPlayTap,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Color(0xFF2D2D5A);
    // Uso de withValues(alpha: ...) para consistencia con nuevas versiones de Flutter
    // Si tu versión es anterior a 3.27, usa .withOpacity(0.6)
    final borderColor = brandColor.withOpacity(0.6); 

    return GestureDetector(
      onTap: onPlayTap,
      onLongPress: onEditTap, 
      child: Container(
        width: 140, 
        margin: const EdgeInsets.only(right: 12.0),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          // Borde y Sombra Neón
          border: Border.all(color: borderColor, width: 1.5), 
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 1,
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.5), 
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Thumbnail de Fondo
              if (video.thumbnailUrl.isNotEmpty)
                Image.network(
                  video.thumbnailUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) =>
                      progress == null ? child : Center(child: CircularProgressIndicator(strokeWidth: 2, color: brandColor)),
                  errorBuilder: (context, error, stack) =>
                      const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.white38, size: 40)),
                )
              else
                  Container(color: Colors.black.withOpacity(0.2)), 
              
              // 2. Overlay Gradiente (para legibilidad del texto)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.4), 
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
              
              // 3. Icono de Play
              Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white.withOpacity(0.85), 
                  size: 48,
                  shadows: [
                    BoxShadow(
                      color: brandColor.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ],
                ),
              ),
              
              // 4. Título
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  video.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13, 
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // 5. Etiqueta Promocional
              if (video.isPromoted)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: brandColor, 
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white, width: 0.5),
                    ),
                    child: Text(
                      'PROMO',
                      style: TextStyle(
                        color: surfaceColor, 
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              
              // 6. Botón de Edición (Solo si se pasa el callback)
              if (onEditTap != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                    onPressed: onEditTap,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}