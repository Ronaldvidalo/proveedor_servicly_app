import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Paleta de Colores "Cyber Glow" (Oscuro) ---
const Color _darkBackground = Color(0xFF1A1A2E);
const Color _darkSurface = Color(0xFF2D2D5A);
const Color _darkTextPrimary = Colors.white;
const Color _darkTextSecondary = Colors.white70;

// --- Paleta "Cyber Light" (Claro) ---
const Color _lightBackground = Color(0xFFF2F2F7);
const Color _lightSurface = Color(0xFFFFFFFF);
const Color _lightTextPrimary = Color(0xFF1C1C1E);
const Color _lightTextSecondary = Color(0xFF3A3A3C);


// --- Paletas de Acento (Personalizables por el usuario) ---
const Color _accentBlue = Color(0xFF00BFFF);
const Color _accentGreen = Color(0xFF00FF7F);
const Color _accentPink = Color(0xFFF000B0); // Rosa Neón
const Color _accentOrange = Color(0xFFFFA500); // Naranja Neón

/// Un enum para identificar las paletas de forma segura
enum AppPalette {
  blue,
  green,
  pink,
  orange,
}

/// Contiene la lógica para construir los temas claros y oscuros
/// basados en la paleta de colores seleccionada.
class AppThemes {
  
  /// Construye un tema OSCURO (Cyber Glow) con un color de acento
  static ThemeData _buildDarkTheme(Color accentColor) {
    final baseTheme = ThemeData.dark();
    // Usamos 'Inter' como nos gustaba
    final textTheme = GoogleFonts.interTextTheme(baseTheme.textTheme).apply(
      bodyColor: _darkTextSecondary,
      displayColor: _darkTextPrimary,
    );

    return baseTheme.copyWith(
      brightness: Brightness.dark,
      primaryColor: accentColor,
      scaffoldBackgroundColor: _darkBackground,
      cardColor: _darkSurface,
      dividerColor: Colors.white.withAlpha(50),
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.dark,
        primary: accentColor,
        surface: _darkSurface,
        background: _darkBackground,
        error: Colors.redAccent,
        onSurface: _darkTextSecondary, 
        onBackground: _darkTextPrimary, 
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: _darkBackground, // Fondo consistente
        elevation: 0,
        foregroundColor: Colors.white,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _darkSurface,
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.white60,
        type: BottomNavigationBarType.fixed,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: _darkSurface,
        selectedIconTheme: IconThemeData(color: accentColor),
        unselectedIconTheme: const IconThemeData(color: Colors.white60),
        indicatorColor: accentColor.withAlpha(50),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.black, // Alto contraste
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: BorderSide(color: accentColor, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accentColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface,
        prefixIconColor: accentColor,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
        border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        errorStyle: TextStyle(color: Colors.redAccent.shade100),
      ),
      iconTheme: const IconThemeData(color: Colors.white70),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: _darkSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  /// Construye un tema CLARO (Cyber Light) con un color de acento
  static ThemeData _buildLightTheme(Color accentColor) {
    final baseTheme = ThemeData.light();
    final textTheme = GoogleFonts.interTextTheme(baseTheme.textTheme).apply(
      bodyColor: _lightTextSecondary,
      displayColor: _lightTextPrimary,
    );
    
    return baseTheme.copyWith(
      brightness: Brightness.light,
      primaryColor: accentColor,
      scaffoldBackgroundColor: _lightBackground,
      cardColor: _lightSurface,
      dividerColor: Colors.black.withAlpha(30),
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.light,
        primary: accentColor,
        surface: _lightSurface,
        background: _lightBackground,
        error: Colors.red.shade700,
        onSurface: _lightTextSecondary,
        onBackground: _lightTextPrimary,
      ),
      textTheme: textTheme,
       appBarTheme: AppBarTheme(
        backgroundColor: _lightBackground, // Fondo claro
        elevation: 0,
        foregroundColor: _lightTextPrimary, // Texto oscuro
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: _lightTextPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _lightSurface,
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: _lightSurface,
        selectedIconTheme: IconThemeData(color: accentColor),
        unselectedIconTheme: const IconThemeData(color: Colors.black54),
        indicatorColor: accentColor.withAlpha(50),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white, // Alto contraste
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: BorderSide(color: accentColor, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accentColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface,
        prefixIconColor: accentColor,
        labelStyle: const TextStyle(color: _lightTextSecondary),
        hintStyle: const TextStyle(color: Colors.black38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.black54),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: _darkSurface, // Usamos un tooltip oscuro incluso en modo claro
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  // --- Mapas de Temas ---
  // El "motor" que conecta el enum con el tema
  
  static final Map<AppPalette, ThemeData> darkThemes = {
    AppPalette.blue: _buildDarkTheme(_accentBlue),
    AppPalette.green: _buildDarkTheme(_accentGreen),
    AppPalette.pink: _buildDarkTheme(_accentPink),
    AppPalette.orange: _buildDarkTheme(_accentOrange),
  };

  static final Map<AppPalette, ThemeData> lightThemes = {
    AppPalette.blue: _buildLightTheme(_accentBlue),
    AppPalette.green: _buildLightTheme(_accentGreen),
    AppPalette.pink: _buildLightTheme(_accentPink),
    AppPalette.orange: _buildLightTheme(_accentOrange),
  };
}