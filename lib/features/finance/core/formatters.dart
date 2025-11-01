import 'package:flutter/material.dart';

/// Clase de utilidades para el módulo de finanzas.
/// Contiene helpers para dar formato, colores e íconos.
class AppFormatters {
  
  /// Asigna un color único a cada categoría de gasto.
  static Color getColorForCategory(String category) {
    // Usamos un hash del string de la categoría para generar un color.
    // Esto asegura que "Marketing" siempre sea del mismo color.
    final hash = category.hashCode;
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = (hash & 0x0000FF);
    
    // Devolvemos un color opaco. 
    // Usamos un HSL para asegurar que el color no sea demasiado oscuro.
    // Convertimos de RGB a HSL, ajustamos la luminosidad y volvemos a RGB.
    final hsl = HSLColor.fromColor(Color.fromRGBO(r, g, b, 1.0));
    // Nos aseguramos de que la luminosidad sea al menos 0.5 (no muy oscuro)
    // y la saturación al menos 0.6 (no muy gris)
    final adjustedHsl = hsl.withLightness((hsl.lightness + 0.3).clamp(0.4, 0.7))
                           .withSaturation((hsl.saturation + 0.5).clamp(0.6, 1.0));

    return adjustedHsl.toColor();
  }

  /// Asigna un ícono a cada categoría de gasto.
  static IconData getIconForCategory(String category) {
    // Convertimos a minúsculas para ser flexibles
    final lowerCategory = category.toLowerCase();

    // Mapeo de categorías conocidas
    if (lowerCategory.contains('comida') || lowerCategory.contains('restaurante')) {
      return Icons.restaurant;
    }
    if (lowerCategory.contains('transporte') || lowerCategory.contains('gasolina') || lowerCategory.contains('uber')) {
      return Icons.directions_car;
    }
    if (lowerCategory.contains('marketing') || lowerCategory.contains('publicidad')) {
      return Icons.campaign;
    }
    if (lowerCategory.contains('software') || lowerCategory.contains('suscripción') || lowerCategory.contains('saas')) {
      return Icons.cloud_queue;
    }
    if (lowerCategory.contains('oficina') || lowerCategory.contains('papelería')) {
      return Icons.inventory_2_outlined;
    }
    if (lowerCategory.contains('servicios') || lowerCategory.contains('luz') || lowerCategory.contains('agua') || lowerCategory.contains('internet')) {
      return Icons.receipt_long;
    }
    if (lowerCategory.contains('salud') || lowerCategory.contains('farmacia')) {
      return Icons.medical_services_outlined;
    }
     if (lowerCategory.contains('educación') || lowerCategory.contains('curso')) {
      return Icons.school_outlined;
    }
     if (lowerCategory.contains('ropa') || lowerCategory.contains('vestimenta')) {
      return Icons.checkroom;
    }

    // Ícono por defecto para categorías no conocidas
    return Icons.label_outline;
  }
}
