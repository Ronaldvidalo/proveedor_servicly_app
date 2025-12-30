import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';

class ProviderRatingBadge extends StatelessWidget {
  final ProviderProfileModel? profile;
  
  // Opcionales para personalizar (si mandas esto, sobrescribes el tema automático)
  final TextStyle? textStyle;
  final Color? starColor;
  final Color? emptyStarColor;
  final double starSize;
  final bool showReviewCount;

  const ProviderRatingBadge({
    super.key,
    required this.profile,
    this.textStyle,
    this.starColor,      // Ahora es nullable para usar defaults inteligentes
    this.emptyStarColor, // Ahora es nullable para usar defaults inteligentes
    this.starSize = 18.0,
    this.showReviewCount = true,
  });

  @override
  Widget build(BuildContext context) {
    // 1. OBTENEMOS EL TEMA ACTUAL
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 2. Extraer datos seguros
    final double rating = profile?.averageRating ?? 0.0;
    final int count = profile?.reviewCount ?? 0;

    // --- CASO: NUEVO (0 reseñas) ---
    if (count == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          // Usamos un verde sutil que se vea bien en ambos modos
          color: Colors.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.green),
        ),
        child: const Text(
          "NUEVO",
          style: TextStyle(
            color: Colors.green, 
            fontWeight: FontWeight.bold, 
            fontSize: 10
          ),
        ),
      );
    }

    // --- COLORES DINÁMICOS ---
    
    // Si no pasas color de estrella, usa Amber (estándar).
    final effectiveStarColor = starColor ?? Colors.amber;
    
    // Si no pasas color de estrella vacía, usa el color del texto base con mucha transparencia.
    // Esto hace que sea gris claro en modo Light y gris oscuro en modo Dark automáticamente.
    final effectiveEmptyStarColor = emptyStarColor ?? colorScheme.onSurface.withValues(alpha: 0.2);

    // --- ESTILO DE TEXTO AUTOMÁTICO ---
    // Si no pasas estilo, usa el del tema actual (onSurface).
    final effectiveTextStyle = textStyle ?? TextStyle(
      color: colorScheme.onSurface, // <--- MAGIA AQUÍ: Blanco en Dark, Negro en Light
      fontWeight: FontWeight.bold, 
      fontSize: 16
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // A. Número (Ej: 4.8)
        Text(
          rating.toStringAsFixed(1),
          style: effectiveTextStyle,
        ),
        
        const SizedBox(width: 6),

        // B. Estrellas
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            IconData icon;
            if (index < rating.floor()) {
              icon = Icons.star; 
            } else if (index < rating) {
              icon = Icons.star_half; 
            } else {
              icon = Icons.star_border; 
            }
            
            return Icon(
              icon,
              color: index < rating.ceil() ? effectiveStarColor : effectiveEmptyStarColor,
              size: starSize,
            );
          }),
        ),

        // C. Cantidad de Reseñas
        if (showReviewCount) ...[
          const SizedBox(width: 6),
          Text(
            "($count)",
            style: effectiveTextStyle.copyWith(
              fontSize: (effectiveTextStyle.fontSize ?? 14) * 0.85, 
              fontWeight: FontWeight.normal,
              // Usa el mismo color del texto principal pero más transparente
              color: effectiveTextStyle.color?.withValues(alpha: 0.6), 
            ),
          ),
        ],
      ],
    );
  }
}