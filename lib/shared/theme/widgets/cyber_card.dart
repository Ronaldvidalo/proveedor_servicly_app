import 'package:flutter/material.dart';

class CyberCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double? height;
  final double? width;
  final bool hasGlow; // Para activar el efecto neón extra

  const CyberCard({
    super.key,
    required this.child,
    this.onTap,
    this.height,
    this.width,
    this.hasGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colores dinámicos
    final backgroundColor = theme.colorScheme.surface; // Blanco en Light, Azul Oscuro en Dark
    final borderColor = hasGlow 
        ? theme.colorScheme.primary 
        : (isDark ? Colors.white10 : Colors.grey.shade200);

    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
        boxShadow: [
          // Sombra diferente para cada modo
          if (isDark && hasGlow)
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 1,
            )
          else if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05), // Sombra suave material design
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: child,
          ),
        ),
      ),
    );
  }
}