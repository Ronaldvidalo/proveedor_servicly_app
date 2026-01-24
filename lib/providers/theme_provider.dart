import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// 1. DEFINICIONES VISUALES (DUAL IDENTITY: CYBER vs PROFESSIONAL)
// =============================================================================

// --- COLORES DARK MODE (Estilo: Cyber Glow) ---
const Color _darkBackground = Color(0xFF1A1A2E); // Tu azul profundo original
const Color _darkSurface = Color(0xFF2D2D5A);    // Tu superficie original
const Color _darkTextPrimary = Colors.white;
const Color _darkTextSecondary = Color(0xFFB0B0C3); // Gris azulado claro
const Color _darkBorderColor = Color(0xFF40407A);   // Borde sutil para dark

// --- COLORES LIGHT MODE (Estilo: Clean Professional) ---
// Usamos un gris muy suave (Off-White) para evitar el brillo excesivo del blanco puro en el fondo
const Color _lightBackground = Color(0xFFF4F6F8); 
// Las tarjetas sí son blancas puras para destacar sobre el fondo grisáceo
const Color _lightSurface = Color(0xFFFFFFFF); 
// Textos oscuros (Gris Carbón) para máximo contraste y legibilidad
const Color _lightTextPrimary = Color(0xFF1F2937); 
const Color _lightTextSecondary = Color(0xFF6B7280); 
// Bordes grises suaves para delimitar áreas
const Color _lightBorderColor = Color(0xFFE5E7EB);
// Fondo de inputs un poco más oscuro que la tarjeta para denotar interactividad
const Color _lightInputFill = Color(0xFFF9FAFB);

// --- PALETAS DE ACENTO (MAPPING INTELIGENTE) ---

// DARK: Neones Brillantes (Emiten luz)
const Color _darkAccentBlue = Color(0xFF00BFFF); 
const Color _darkAccentGreen = Color(0xFF00FF7F); 
const Color _darkAccentPink = Color(0xFFFF00FF); 
const Color _darkAccentOrange = Color(0xFFFFA500);

// LIGHT: Colores Sólidos/Profesionales (Reflejan luz, alto contraste)
// Aquí "oscurecemos" los neones para que se vean bien sobre blanco
const Color _lightAccentBlue = Color(0xFF0056D2); // Azul Royal (Facebook/LinkedIn style)
const Color _lightAccentGreen = Color(0xFF008751); // Verde Esmeralda (Whatsapp/Excel style)
const Color _lightAccentPink = Color(0xFFC2185B); // Magenta Profundo
const Color _lightAccentOrange = Color(0xFFE65100); // Naranja Quemado

enum AppPalette {
  blue,
  green,
  pink,
  orange,
}

class AppThemes {
  static final Map<AppPalette, ThemeData> darkThemes = {
    AppPalette.blue: _buildDarkTheme(_darkAccentBlue),
    AppPalette.green: _buildDarkTheme(_darkAccentGreen),
    AppPalette.pink: _buildDarkTheme(_darkAccentPink),
    AppPalette.orange: _buildDarkTheme(_darkAccentOrange),
  };

  static final Map<AppPalette, ThemeData> lightThemes = {
    AppPalette.blue: _buildLightTheme(_lightAccentBlue),
    AppPalette.green: _buildLightTheme(_lightAccentGreen),
    AppPalette.pink: _buildLightTheme(_lightAccentPink),
    AppPalette.orange: _buildLightTheme(_lightAccentOrange),
  };

  // --- BUILDER TEMA OSCURO (CYBER GLOW) ---
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
      dividerColor: _darkBorderColor,
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.dark,
        primary: accentColor,
        onPrimary: Colors.black, // Texto negro sobre neón para legibilidad
        secondary: accentColor,
        surface: _darkSurface,
        onSurface: _darkTextPrimary,
        error: const Color(0xFFFF5252),
        outline: _darkBorderColor,
      ).copyWith(surface: _darkSurface),
      
      textTheme: textTheme,
      
      appBarTheme: AppBarTheme(
        backgroundColor: _darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _darkTextPrimary,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: _darkTextPrimary,
          fontSize: 20,
        ),
        iconTheme: const IconThemeData(color: _darkTextSecondary),
      ),
      
      cardTheme: CardThemeData(
        color: _darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.transparent), // Sin borde en dark, usamos contraste de color
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIconColor: accentColor,
        labelStyle: const TextStyle(color: _darkTextSecondary),
        hintStyle: TextStyle(color: _darkTextSecondary.withValues(alpha: 0.5)),
        
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _darkBackground,
        selectedItemColor: accentColor,
        unselectedItemColor: _darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      iconTheme: const IconThemeData(color: _darkTextSecondary),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.black, // Texto negro en botones oscuros
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
    );
  }

 // --- BUILDER TEMA CLARO (CLEAN PROFESSIONAL) ---
  static ThemeData _buildLightTheme(Color accentColor) {
    final baseTheme = ThemeData.light();
    // Forzamos la tipografía a colores oscuros (Gris grafito / Negro)
    final textTheme = GoogleFonts.interTextTheme(baseTheme.textTheme).apply(
      bodyColor: _lightTextPrimary,      
      displayColor: _lightTextPrimary,   
    );
    
    return baseTheme.copyWith(
      brightness: Brightness.light,
      primaryColor: accentColor,
      scaffoldBackgroundColor: _lightBackground,
      cardColor: _lightSurface,
      dividerColor: _lightBorderColor,
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.light,
        primary: accentColor,
        onPrimary: Colors.white, // Texto BLANCO sobre botones de color sólido
        secondary: accentColor, 
        surface: _lightSurface, 
        onSurface: _lightTextPrimary, // Texto NEGRO sobre superficies blancas
        error: const Color(0xFFD32F2F), // Rojo oscuro profesional
        outline: _lightBorderColor,
      ).copyWith(surface: _lightSurface),
      
      textTheme: textTheme,
      
      appBarTheme: AppBarTheme(
        backgroundColor: _lightSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        foregroundColor: _lightTextPrimary, // Iconos y texto negros
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: _lightTextPrimary,
          fontSize: 20,
        ),
        iconTheme: const IconThemeData(color: _lightTextSecondary),
      ),
      
      // En modo claro usamos SOMBRAS y BORDES para separar, no colores de fondo distintos
      cardTheme: CardThemeData(
        color: _lightSurface,
        elevation: 2, // Elevación suave
        shadowColor: Colors.black.withValues(alpha: 0.05), // Sombra muy difusa
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _lightBorderColor, width: 1), // Borde gris sutil
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightInputFill, // Gris muy pálido para diferenciar del fondo blanco
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIconColor: accentColor,
        suffixIconColor: _lightTextSecondary,
        labelStyle: TextStyle(color: _lightTextSecondary, fontWeight: FontWeight.w600),
        hintStyle: TextStyle(color: _lightTextSecondary.withValues(alpha: 0.5)),
        
        // Bordes visibles en gris
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
      ),
      
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _lightSurface,
        selectedItemColor: accentColor,
        unselectedItemColor: _lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 10, // Sombra fuerte en el bottom bar
      ),

      iconTheme: const IconThemeData(color: _lightTextSecondary),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white, // Texto blanco para contraste
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),

      // Botones outline con borde de color sólido
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
    );
  }
} 

// =============================================================================
// 2. GESTIÓN DE ESTADO (PROVIDER + PERSISTENCIA)
// =============================================================================

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true;
  AppPalette _currentPalette = AppPalette.blue;

  ThemeProvider() {
    _loadFromPrefs();
  }

  bool get isDarkMode => _isDarkMode;
  AppPalette get currentPalette => _currentPalette;

  ThemeData get currentTheme {
    final themeMap = _isDarkMode ? AppThemes.darkThemes : AppThemes.lightThemes;
    return themeMap[_currentPalette] ?? themeMap[AppPalette.blue]!;
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveToPrefs();
    notifyListeners();
  }

  void changePalette(AppPalette palette) {
    _currentPalette = palette;
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    final paletteIndex = prefs.getInt('paletteIndex') ?? 0;
    if (paletteIndex >= 0 && paletteIndex < AppPalette.values.length) {
      _currentPalette = AppPalette.values[paletteIndex];
    }
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setInt('paletteIndex', _currentPalette.index);
  }
}