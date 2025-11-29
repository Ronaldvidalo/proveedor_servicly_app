import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- COLORES BASE ---

// Neutros MODO OSCURO (Cyber Glow)
const Color _darkBackground = Color(0xFF1A1A2E);
const Color _darkSurface = Color(0xFF2D2D5A);
const Color _darkTextPrimary = Colors.white;
const Color _darkTextSecondary = Color.fromARGB(179, 234, 195, 195); // Tu color personalizado

// Neutros MODO CLARO (Cyber Clean - Ajustado)
// 1. Fondo más oscuro (Gris azulado suave) para reducir el brillo general
const Color _lightBackground = Color(0xFFF0F2F5); 
// 2. Superficie blanca pura para contraste limpio contra el fondo gris
const Color _lightSurface = Color(0xFFFFFFFF); 
const Color _lightTextPrimary = Color(0xFF1A1A2E); // Azul oscuro como negro
const Color _lightTextSecondary = Color(0xFF6B7280);

// --- PALETAS DE ACENTO (DUAL) ---

// 1. MODO OSCURO: Colores NEÓN (Brillantes)
const Color _darkAccentBlue = Color(0xFF00BFFF);
const Color _darkAccentGreen = Color(0xFF00FF7F);
const Color _darkAccentPink = Color(0xFFFF00FF);
const Color _darkAccentOrange = Color(0xFFFFA500);

// 2. MODO CLARO: Colores SÓLIDOS (Profesionales/Legibles)
// Ajustados para mayor contraste sobre blanco (WCAG 2.1 compliant)
const Color _lightAccentBlue = Color(0xFF0056D2);   // Azul más profundo e intenso
const Color _lightAccentGreen = Color(0xFF007A33);  // Verde bosque corporativo
const Color _lightAccentPink = Color(0xFFB0003A);   // Rojo-rosado fuerte
const Color _lightAccentOrange = Color(0xFFC63F00); // Teja/Ladrillo intenso

enum AppPalette {
  blue,
  green,
  pink,
  orange,
}

class AppThemes {
  
  // --- MAPA DE TEMAS OSCUROS (Usa acentos Neón) ---
  static final Map<AppPalette, ThemeData> darkThemes = {
    AppPalette.blue: _buildDarkTheme(_darkAccentBlue),
    AppPalette.green: _buildDarkTheme(_darkAccentGreen),
    AppPalette.pink: _buildDarkTheme(_darkAccentPink),
    AppPalette.orange: _buildDarkTheme(_darkAccentOrange),
  };

  // --- MAPA DE TEMAS CLAROS (Usa acentos Sólidos) ---
  static final Map<AppPalette, ThemeData> lightThemes = {
    AppPalette.blue: _buildLightTheme(_lightAccentBlue),
    AppPalette.green: _buildLightTheme(_lightAccentGreen),
    AppPalette.pink: _buildLightTheme(_lightAccentPink),
    AppPalette.orange: _buildLightTheme(_lightAccentOrange),
  };

  // ===========================================================================
  // CONSTRUCTORES DE TEMA
  // ===========================================================================

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
        onPrimary: Colors.black, // Texto negro sobre neón para contraste
        secondary: _darkAccentPink,
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
      dividerColor: Colors.black.withValues(alpha: 0.08), // Divisor un poco más visible
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.light,
        primary: accentColor,
        onPrimary: Colors.white, // Texto BLANCO sobre colores sólidos oscuros
        secondary: _lightAccentPink, 
        onSecondary: Colors.white,
        surface: _lightSurface, 
        onSurface: _lightTextPrimary,
        error: Colors.red.shade700, // Error más oscuro para leerse bien
        outline: _lightTextSecondary,
      ).copyWith(
        surface: _lightSurface, 
      ),
      
      textTheme: textTheme,
      
      appBarTheme: AppBarTheme(
        backgroundColor: _lightBackground, // AppBar del mismo color que el fondo para limpieza
        elevation: 0,
        foregroundColor: _lightTextPrimary,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold, 
          color: _lightTextPrimary
        ),
        iconTheme: IconThemeData(color: _lightTextPrimary),
      ),
      
      cardTheme: CardThemeData(
        color: _lightSurface,
        // Elevación sutil y borde imperceptible para separar del fondo gris
        elevation: 0, 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.05), width: 1),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _lightSurface,
        selectedItemColor: accentColor,
        unselectedItemColor: _lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 10, // Elevación para separar del contenido
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: _lightSurface,
        selectedIconTheme: IconThemeData(color: accentColor),
        unselectedIconTheme: const IconThemeData(color: Colors.black54),
        indicatorColor: accentColor.withValues(alpha: 0.1), 
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white, // Texto blanco para contraste
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          elevation: 2, // Sombra ligera en botones principales
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface,
        prefixIconColor: accentColor,
        labelStyle: TextStyle(color: _lightTextSecondary),
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
          color: _lightTextPrimary, 
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}