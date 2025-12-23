// 📍 Ubicación: lib/shared/theme/cyber_theme.dart
import 'package:flutter/material.dart';

class CyberColors {
  static const Color background = Color(0xFF12121A); // Fondo oscuro
  static const Color surface = Color(0xFF1E1E2C);    // Tarjetas
  static const Color neonCyan = Color(0xFF00E5FF);   // 4-5 Estrellas
  static const Color neonGreen = Color(0xFF39FF14);  // Éxito
  static const Color neonAmber = Color(0xFFFFD600);  // 3 Estrellas
  static const Color neonRed = Color(0xFFFF1744);    // 1-2 Estrellas
  static const Color textGlow = Colors.white;
}

// Helper para obtener color según rating
Color getRatingColor(int rating) {
  if (rating <= 2) return CyberColors.neonRed;
  if (rating == 3) return CyberColors.neonAmber;
  return CyberColors.neonCyan;
}

// Sombra para efecto Glow
List<BoxShadow> getGlow(Color color) {
  return [
    BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 1),
  ];
}