// 📍 Ubicación: lib/shared/theme/cyber_theme.dart
import 'package:flutter/material.dart';

/// Utilidad para centralizar los efectos visuales
class CyberStyles {
  
  /// Obtiene el color principal activo
  static Color getPrimaryGlow(BuildContext context) {
    return Theme.of(context).primaryColor;
  }

  /// Genera sombras (Neón en Dark, Sutil en Light)
  static List<BoxShadow> getGlow(BuildContext context, {Color? color, bool isFocused = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final targetColor = color ?? theme.primaryColor;

    if (isDark) {
      // MODO OSCURO: Neón
      return [
        BoxShadow(
          color: targetColor.withValues(alpha: isFocused ? 0.6 : 0.15),
          blurRadius: isFocused ? 20 : 8,
          spreadRadius: isFocused ? 2 : 0,
        ),
      ];
    } else {
      // MODO CLARO: Sombra suave
      return [
        BoxShadow(
          color: targetColor.withValues(alpha: isFocused ? 0.3 : 0.08),
          blurRadius: isFocused ? 15 : 10,
          spreadRadius: isFocused ? 1 : 0,
          offset: const Offset(0, 4),
        ),
      ];
    }
  }

  /// Helper inteligente para colores de Rating (Estrellas)
  static Color getRatingColor(BuildContext context, int rating) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (rating <= 2) {
      // Rojo/Error
      return isDark ? const Color(0xFFFF1744) : const Color(0xFFD32F2F); 
    }
    if (rating == 3) {
      // Ambar/Advertencia
      return isDark ? const Color(0xFFFFD600) : const Color(0xFFFFA000); 
    }
    // 4-5 Estrellas: Usa el color primario del tema seleccionado (Azul, Rosa, etc.)
    return Theme.of(context).primaryColor;
  }

  /// Borde condicional
  static Border getBorder(BuildContext context, {bool isSelected = false}) {
    final theme = Theme.of(context);
    if (isSelected) {
      return Border.all(color: theme.primaryColor, width: 2.0);
    } else {
      return Border.all(color: theme.dividerColor, width: 1.0);
    }
  }
}