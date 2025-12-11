// --- UX/UI Component ---
// Name: CyberContainer
// Description: Contenedor inteligente que adapta su sombra (Glow vs Shadow)
// basado en el Brightness del tema actual definido en AppThemes.
// -----------------------

import 'package:flutter/material.dart';

class CyberContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool borderGlow; // Si true, fuerza el borde brillante activo

  const CyberContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.borderRadius = 16,
    this.onTap,
    this.borderGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Obtenemos los colores directamente de tu AppThemes
    final backgroundColor = theme.cardColor; // _darkSurface o _lightSurface
    final accentColor = theme.colorScheme.primary; 

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        // Lógica de Bordes y Sombras según el Tema
        border: isDark
            ? Border.all(
                // En modo oscuro: Borde sutil o brillante si está activo
                color: borderGlow 
                    ? accentColor 
                    : Colors.white.withOpacity(0.05),
                width: 1,
              )
            : Border.all(
                // En modo claro: Borde casi invisible para definición
                color: Colors.black.withOpacity(0.05),
                width: 1,
              ),
        boxShadow: [
          if (isDark)
            // --- MODO CYBER GLOW (Oscuro) ---
            BoxShadow(
              color: borderGlow 
                  ? accentColor.withOpacity(0.25) // Glow intenso si está activo
                  : Colors.black.withOpacity(0.3), // Sombra base
              blurRadius: borderGlow ? 12 : 8,
              offset: const Offset(0, 4),
            )
          else
            // --- MODO CLEAN (Claro) ---
            BoxShadow(
              color: Colors.black.withOpacity(0.06), // Sombra corporativa suave
              blurRadius: 10,
              offset: const Offset(0, 5),
              spreadRadius: -2, // Efecto "flotante" moderno
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          // El splash color también se adapta a tu paleta
          splashColor: accentColor.withOpacity(0.1),
          highlightColor: accentColor.withOpacity(0.05),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}