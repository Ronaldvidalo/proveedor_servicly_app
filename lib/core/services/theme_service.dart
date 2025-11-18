import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/shared/theme/app_themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Definimos la clave para SharedPreferences
const String _kThemePaletteKey = 'theme_palette_v1';

class ThemeService extends ChangeNotifier {
  
  // Por defecto iniciamos en Azul
  AppPalette _palette = AppPalette.blue;

  // Getters públicos para que la UI los consuma
  ThemeData get darkTheme => AppThemes.darkThemes[_palette]!;
  ThemeData get lightTheme => AppThemes.lightThemes[_palette]!;
  AppPalette get currentPalette => _palette;

  /// Carga la paleta guardada por el usuario desde SharedPreferences.
  /// Debe llamarse al iniciar la app (en main.dart).
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final paletteName = prefs.getString(_kThemePaletteKey);
    
    // Busca la paleta por su nombre, si no, usa la azul por defecto
    _palette = AppPalette.values.firstWhere(
      (p) => p.name == paletteName,
      orElse: () => AppPalette.blue,
    );
    
    // No notificamos a los listeners aquí, ya que main.dart
    // usará el valor cargado antes de construir el MaterialApp.
  }

  /// Actualiza la paleta, la guarda y notifica a la app.
  void setPalette(AppPalette newPalette) {
    if (_palette == newPalette) return; // No hay cambios

    _palette = newPalette;
    _savePalette(newPalette.name); // Guarda la elección
    notifyListeners(); // Notifica a MaterialApp para que se repinte
  }

  /// Guarda la elección de paleta del usuario.
  Future<void> _savePalette(String paletteName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemePaletteKey, paletteName);
  }
}