import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/portfolio_item_model.dart'; 

class PortfolioItemCard extends StatelessWidget {
  final PortfolioItemModel item;
  final bool isEditable;
  final VoidCallback? onDelete; 

  const PortfolioItemCard({
    super.key,
    required this.item,
    required this.isEditable,
    this.onDelete,
  }) : assert(!isEditable || onDelete != null, 'onDelete callback is required when isEditable is true');

  @override
  Widget build(BuildContext context) {
    // QA FIX: Obtener tema del contexto
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget content;

    if (item.type == PortfolioItemType.image) {
      content = Image.network(
        item.url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              // QA FIX: Color de carga de marca (Neón)
              color: colorScheme.primary,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_outlined, color: colorScheme.error, size: 32),
              const SizedBox(height: 4),
              Text(
                "Error", 
                style: TextStyle(color: colorScheme.error, fontSize: 10)
              )
            ],
          ),
        ),
      );
    } else { 
      // Placeholder de Video
      content = Container(
        // QA FIX: Fondo dinámico (Gris muy oscuro en dark, Gris medio en light)
        color: theme.brightness == Brightness.dark 
            ? Colors.black26 
            : Colors.grey.shade200,
        child: Center(
          child: Icon(
            Icons.play_circle_outline_rounded, 
            // QA FIX: Icono de video con color primario
            color: colorScheme.primary, 
            size: 50
          ),
        ),
      );
    }

    return Container(
      // QA FIX: Usamos Container con decoración manual en lugar de Card
      // para igualar el estilo de las otras tarjetas Cyber Glow
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        // Borde sutil
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
           BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      // ClipRRect fuerza a la imagen a respetar los bordes redondeados del container
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11), // 1px menos que el borde para que no se monte
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Contenido (Imagen o Video)
            content,

            // Botón de eliminar (solo si es editable)
            if (isEditable)
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  // QA FIX: Fondo semitransparente negro SIEMPRE para contraste sobre imágenes
                  // No usamos el tema aquí porque la imagen puede ser de cualquier color.
                  color: Colors.black.withValues(alpha: 0.6),
                  type: MaterialType.circle,
                  child: InkWell(
                    onTap: onDelete,
                    customBorder: const CircleBorder(),
                    splashColor: Colors.red.withValues(alpha: 0.4),
                    child: const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white, // Blanco siempre visible sobre fondo negro
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}