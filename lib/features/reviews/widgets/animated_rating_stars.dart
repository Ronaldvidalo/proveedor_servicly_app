// 📍 Ubicación: lib/features/reviews/widgets/animated_rating_stars.dart
import 'package:flutter/material.dart';
import '../../../shared/theme/cyber_theme.dart';

class AnimatedRatingStars extends StatelessWidget {
  final int currentRating;
  final Function(int) onRatingSelected;
  final double size;

  const AnimatedRatingStars({
    super.key, // Corrección Lint: 'key' converted to super parameter
    required this.currentRating,
    required this.onRatingSelected,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    // 1. CORRECCIÓN: Usamos CyberStyles.getRatingColor pasando el context
    Color activeColor = CyberStyles.getRatingColor(context, currentRating == 0 ? 5 : currentRating);
    
    // Obtenemos el tema para el color de la estrella inactiva
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        int starValue = index + 1;
        bool isActive = starValue <= currentRating;
        
        return GestureDetector(
          onTap: () => onRatingSelected(starValue),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              isActive ? Icons.star : Icons.star_border,
              // 2. CORRECCIÓN: Color inactivo adaptativo (no grey[700] fijo)
              color: isActive ? activeColor : theme.disabledColor,
              size: size,
              // 3. CORRECCIÓN: Usamos CyberStyles.getGlow pasando context y color
              shadows: isActive 
                  ? CyberStyles.getGlow(context, color: activeColor, isFocused: true) 
                  : [],
            ),
          ),
        );
      }),
    );
  }
}