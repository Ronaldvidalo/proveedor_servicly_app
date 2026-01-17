import 'package:flutter/material.dart';

class AdaptiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWebWidth;
  final AlignmentGeometry alignment;

  const AdaptiveCenter({
    super.key, 
    required this.child, 
    this.maxWebWidth = 600, // Un ancho cómodo para formularios/botones
    this.alignment = Alignment.center, // Por defecto centrado
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Si la pantalla es grande (Web/Tablet)
        if (constraints.maxWidth > maxWebWidth) {
          return Align(
            alignment: alignment,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWebWidth),
              child: child,
            ),
          );
        }
        // Si es móvil, deja que fluya normal (full width)
        return child;
      },
    );
  }
}