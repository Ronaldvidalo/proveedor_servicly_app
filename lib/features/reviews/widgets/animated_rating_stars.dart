// 📍 Ubicación: lib/features/reviews/widgets/animated_rating_stars.dart
import 'package:flutter/material.dart';
import '../../../shared/theme/cyber_theme.dart';

class AnimatedRatingStars extends StatelessWidget {
  final int currentRating;
  final Function(int) onRatingSelected;
  final double size;

  const AnimatedRatingStars({
    Key? key,
    required this.currentRating,
    required this.onRatingSelected,
    this.size = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color activeColor = getRatingColor(currentRating == 0 ? 5 : currentRating);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        int starValue = index + 1;
        bool isActive = starValue <= currentRating;
        
        return GestureDetector(
          onTap: () => onRatingSelected(starValue),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              isActive ? Icons.star : Icons.star_border,
              color: isActive ? activeColor : Colors.grey[700],
              size: size,
              shadows: isActive ? getGlow(activeColor) : [],
            ),
          ),
        );
      }),
    );
  }
}