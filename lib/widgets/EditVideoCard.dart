import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/video_showcase_model.dart'; 
import 'package:proveedor_servicly_app/core/models/user_model.dart'; 
import 'package:proveedor_servicly_app/features/manage_store/presentation/screens/add_edit_video_screen.dart'; 


class EditVideoCard extends StatelessWidget {
  final VideoShowcaseModel video;
  final UserModel user;
  final Color brandColor; // Añadido para consistencia visual
  
  const EditVideoCard({
    super.key,
    required this.video,
    required this.user,
    required this.brandColor,
  });

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Color(0xFF2D2D5A);
    
    // Usamos el brandColor para darle un toque de neón al borde
    final borderColor = brandColor.withAlpha(150);

    return GestureDetector(
      // Acción: Navegar a la pantalla de edición
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AddEditVideoScreen(
            user: user,
            videoToEdit: video,
          ),
        ));
      },
      child: Container(
        width: 140, // Ancho consistente con el otro widget
        margin: const EdgeInsets.only(right: 12.0),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          // Borde estilizado
          border: Border.all(color: borderColor, width: 1.5), 
          boxShadow: [
            BoxShadow(
              color: borderColor.withAlpha(100),
              blurRadius: 10,
              spreadRadius: 1,
            )
          ],
          // Imagen de fondo (thumbnail)
          image: video.thumbnailUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(video.thumbnailUrl),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.5),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Overlay Gradiente (para legibilidad del texto)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    // Más oscuro en la parte inferior
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              
              // 2. Icono Central de Edición (Cambiamos el icono de Play por Edit)
              const Center(
                child: Icon(Icons.edit_note_rounded,
                    color: Colors.white70, size: 40),
              ),
              
              // 3. Título del Video
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
              
              // 4. Etiqueta Promocional
              if (video.isPromoted)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: brandColor, // Usamos brandColor para 'PROMO'
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
                
              // 5. Indicador Visual de Edición
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(Icons.settings, color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}