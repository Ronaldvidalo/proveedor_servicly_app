import 'package:flutter/material.dart';

class MentorCard extends StatelessWidget {
  final String message;
  final String title;
  final VoidCallback? onDismiss;

  const MentorCard({
    super.key, 
    required this.message, 
    this.title = "Tip del Experto",
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // QA FIX: Obtener tema del contexto
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Color de acento (Cian / Azul Neón)
    // Este color se ve bien tanto en oscuro como en claro para destacar
    const borderColor = Color(0xFF00BFFF);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        // QA FIX: Fondo dinámico
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        
        // Borde: Neón en oscuro, Sutil en claro
        border: Border.all(
          color: isDark 
              ? borderColor.withValues(alpha: 0.5) 
              : theme.dividerColor,
        ),
        
        // Sombra: Glow en oscuro, Suave en claro
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? borderColor.withValues(alpha: 0.2) 
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            spreadRadius: 1,
            offset: isDark ? Offset.zero : const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Fondo del icono: Oscuro semi-transparente en dark, gris claro en light
              color: isDark ? Colors.black26 : theme.scaffoldBackgroundColor,
              border: Border.all(color: borderColor),
            ),
            child: const Icon(Icons.psychology_alt, color: borderColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: borderColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  // QA FIX: Texto adaptable (Negro/Blanco)
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.9),
                    fontSize: 14, 
                    height: 1.4
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(Icons.close, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.5)),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
        ],
      ),
    );
  }
}