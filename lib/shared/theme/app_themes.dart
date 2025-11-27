import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Paleta de Colores "Cyber Glow" (Oscuro) ---
const Color _darkBackground = Color(0xFF1A1A2E);
const Color _darkSurface = Color(0xFF2D2D5A);
const Color _darkTextPrimary = Colors.white;
const Color _darkTextSecondary = Color.fromARGB(179, 234, 195, 195);

// --- Paleta "Cyber Light" (Claro) ---
const Color _lightBackground = Color(0xFFF8F8F8);
const Color _lightSurface = Color(0xFFFFFFFF);
const Color _lightTextPrimary = Color(0xFF0A0A0A);
const Color _lightTextSecondary = Color(0xFF6B7280);

// --- Paletas de Acento ---
const Color _accentBlue = Color(0xFF0066CC);
const Color _accentGreen = Color(0xFF00FF7F);
const Color _accentPink = Color(0xFFFF00FF);
const Color _accentOrange = Color(0xFFFFA500);

enum AppPalette {
  blue,
  green,
  pink,
  orange,
}

class AppThemes {
  
  // --- TEMA OSCURO ---
  static ThemeData _buildDarkTheme(Color accentColor) {
    final baseTheme = ThemeData.dark();
    final textTheme = GoogleFonts.interTextTheme(baseTheme.textTheme).apply(
      bodyColor: _darkTextSecondary,
      displayColor: _darkTextPrimary,
    );

    return baseTheme.copyWith(
      brightness: Brightness.dark,
      primaryColor: accentColor,
      scaffoldBackgroundColor: _darkBackground,
      cardColor: _darkSurface,
      dividerColor: Colors.white.withValues(alpha: 0.2),
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.dark,
        primary: accentColor,
        onPrimary: Colors.black, 
        secondary: _accentPink,
        surface: _darkSurface,
        onSurface: _darkTextPrimary,
        error: Colors.redAccent,
      ).copyWith(
        surface: _darkSurface,
      ),
      
      textTheme: textTheme,
      
      appBarTheme: AppBarTheme(
        backgroundColor: _darkBackground,
        elevation: 0,
        foregroundColor: _darkTextPrimary,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: _darkTextPrimary
        ),
      ),
      
      // CORRECCIÓN AQUÍ: Usamos CardThemeData en lugar de CardTheme
      cardTheme: CardThemeData(
        color: _darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.transparent),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _darkBackground,
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: _darkSurface,
        selectedIconTheme: IconThemeData(color: accentColor),
        unselectedIconTheme: const IconThemeData(color: Colors.white60),
        indicatorColor: accentColor.withValues(alpha: 0.2),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface,
        prefixIconColor: accentColor,
        labelStyle: const TextStyle(color: Colors.white60),
        hintStyle: const TextStyle(color: Colors.white24),
        border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
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

  // --- TEMA CLARO ---
  static ThemeData _buildLightTheme(Color accentColor) {
    final baseTheme = ThemeData.light();
    final textTheme = GoogleFonts.interTextTheme(baseTheme.textTheme).apply(
      bodyColor: _lightTextPrimary,      
      displayColor: _lightTextPrimary,   
    );
    
    return baseTheme.copyWith(
      brightness: Brightness.light,
      primaryColor: accentColor,
      scaffoldBackgroundColor: _lightBackground,
      cardColor: _lightSurface,
      dividerColor: Colors.black.withValues(alpha: 0.06), 
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.light,
        primary: accentColor,
        onPrimary: Colors.white, 
        secondary: _accentPink, 
        onSecondary: Colors.white,
        surface: _lightSurface, 
        onSurface: _lightTextPrimary,
        error: Colors.red.shade600,
        outline: _lightTextSecondary,
      ).copyWith(
        surface: _lightSurface, 
      ),
      
      textTheme: textTheme,
      
      appBarTheme: AppBarTheme(
        backgroundColor: _lightBackground,
        elevation: 0,
        foregroundColor: _lightTextPrimary,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold, 
          color: _lightTextPrimary
        ),
        iconTheme: IconThemeData(color: _lightTextPrimary),
      ),
      
      // CORRECCIÓN AQUÍ: Usamos CardThemeData en lugar de CardTheme
      cardTheme: CardThemeData(
        color: _lightSurface,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _lightSurface,
        selectedItemColor: accentColor,
        unselectedItemColor: _lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: _lightSurface,
        selectedIconTheme: IconThemeData(color: accentColor),
        unselectedIconTheme: const IconThemeData(color: Colors.black54),
        indicatorColor: accentColor.withValues(alpha: 0.2), 
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface,
        prefixIconColor: accentColor,
        labelStyle: const TextStyle(color: _lightTextSecondary),
        hintStyle: TextStyle(color: _lightTextPrimary.withValues(alpha: 0.4)),
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
      
      iconTheme: IconThemeData(color: _lightTextSecondary),
      
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: _darkSurface, 
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

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