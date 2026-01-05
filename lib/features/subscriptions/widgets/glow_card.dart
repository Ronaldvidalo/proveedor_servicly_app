// lib/features/subscriptions/presentation/widgets/glow_card.dart
import 'package:flutter/material.dart';
import '../../../../shared/theme/cyber_theme.dart'; // Asegúrate de importar la ruta correcta

class GlowCard extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback? onTap;

  const GlowCard({
    super.key,
    required this.child,
    this.isSelected = false,
    this.isRecommended = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    
    // Usamos nuestro helper actualizado para obtener el efecto correcto
    final boxShadows = CyberStyles.getGlow(
      context, 
      color: primaryColor, 
      isFocused: isSelected || isRecommended
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: theme.cardColor, // Usa _darkSurface o _lightSurface automáticamente
          borderRadius: BorderRadius.circular(16),
          border: CyberStyles.getBorder(context, isSelected: isSelected),
          boxShadow: boxShadows,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: child,
            ),
            if (isRecommended)
              Positioned(
                top: 0,
                right: 0,
                child: _RecommendedBadge(color: primaryColor),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedBadge extends StatelessWidget {
  final Color color;
  const _RecommendedBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        // Fondo más sólido en light mode para que se lea el texto blanco
        color: isDark ? color.withValues(alpha: 0.2) : color,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Text(
        "RECOMENDADO",
        style: TextStyle(
          // En dark: color del tema. En light: blanco sobre fondo de color.
          color: isDark ? color : Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}