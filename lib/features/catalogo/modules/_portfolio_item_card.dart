import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/portfolio_item_model.dart'; // Asegúrate que la ruta sea correcta
// Puedes usar 'cached_network_image' para mejor rendimiento
// import 'package:cached_network_image/cached_network_image.dart'; 

class PortfolioItemCard extends StatelessWidget {
  final PortfolioItemModel item;
  final bool isEditable;
  final VoidCallback? onDelete; // Callback para borrar (solo en modo edición)

  const PortfolioItemCard({
    super.key,
    required this.item,
    required this.isEditable,
    this.onDelete,
  }) : assert(!isEditable || onDelete != null, 'onDelete callback is required when isEditable is true'); // Asegura que onDelete se pase si es editable

  @override
  Widget build(BuildContext context) {
    Widget content;

    // Decide qué mostrar basado en el tipo de ítem
    if (item.type == PortfolioItemType.image) {
      // Usamos Image.network simple. Considera usar cached_network_image
      content = Image.network(
        item.url,
        fit: BoxFit.cover,
        // Indicador de carga mientras baja la imagen
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child; // Imagen cargada
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null, // Progreso indeterminado si no se sabe el total
            ),
          );
        },
        // Widget a mostrar si la URL falla
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40),
        ),
      );
    } else { // Si es video
      // Placeholder simple para video. Podrías usar 'video_thumbnail'
      // para generar una miniatura real si lo necesitas.
      content = Container(
        color: Colors.black87,
        child: const Center(
          child: Icon(Icons.play_circle_outline_rounded, color: Colors.white, size: 50),
        ),
      );
    }

    // Envolvemos el contenido en un Card y añadimos botón si es editable
    return Card(
      clipBehavior: Clip.antiAlias, // Para que la imagen/contenido respete los bordes
      elevation: isEditable ? 2.0 : 1.0, // Sombra sutil
      child: Stack(
        fit: StackFit.expand, // Para que la imagen/contenido llene el Card
        children: [
          // Contenido (Imagen o Video Placeholder)
          content,

          // Botón de eliminar (solo si es editable)
          if (isEditable)
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.black.withAlpha((255 * 0.6).round()), // Fondo semitransparente
                type: MaterialType.circle, // Botón circular
                child: InkWell(
                  onTap: onDelete, // Llama al callback pasado
                  customBorder: const CircleBorder(),
                  splashColor: Colors.red.withAlpha(100),
                  child: const Padding(
                    padding: EdgeInsets.all(5.0),
                    child: Icon(
                      Icons.close_rounded, // Icono 'x'
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}