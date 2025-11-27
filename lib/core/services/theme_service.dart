import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme/app_themes.dart'; // Asegúrate que la ruta sea correcta

class ThemeService extends ChangeNotifier {
  // Paleta por defecto: Azul Neón
  AppPalette _currentPalette = AppPalette.blue;
  
  // Clave para guardar en persistencia
  static const String _paletteKey = 'selected_palette';

  AppPalette get currentPalette => _currentPalette;

  // --- GETTERS MAESTROS ---
  // Estos conectan directamente con los mapas estáticos de AppThemes
  ThemeData get lightTheme => AppThemes.lightThemes[_currentPalette] ?? AppThemes.lightThemes[AppPalette.blue]!;
  ThemeData get darkTheme => AppThemes.darkThemes[_currentPalette] ?? AppThemes.darkThemes[AppPalette.blue]!;

  /// Carga el tema guardado al iniciar la app
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final String? paletteName = prefs.getString(_paletteKey);

    if (paletteName != null) {
      // Convertimos el String guardado (ej: "AppPalette.green") de vuelta al enum
      try {
        _currentPalette = AppPalette.values.firstWhere(
          (e) => e.toString() == paletteName,
          orElse: () => AppPalette.blue,
        );
      } catch (e) {
        _currentPalette = AppPalette.blue;
      }
      notifyListeners();
    }
  }

  /// Cambia la paleta de colores y la guarda
  Future<void> updatePalette(AppPalette newPalette) async {
    if (_currentPalette == newPalette) return;

    _currentPalette = newPalette;
    notifyListeners(); // Esto actualiza toda la UI inmediatamente

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_paletteKey, newPalette.toString());
  }
}