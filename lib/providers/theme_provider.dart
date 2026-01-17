import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// 1. DEFINICIONES VISUALES (TU CÓDIGO ORIGINAL MEJORADO)
// =============================================================================

// --- COLORES BASE ---
const Color _darkBackground = Color(0xFF1A1A2E);
const Color _darkSurface = Color(0xFF2D2D5A);
const Color _darkTextPrimary = Colors.white;
const Color _darkTextSecondary = Color.fromARGB(179, 234, 195, 195);

const Color _lightBackground = Color(0xFFF0F2F5);
const Color _lightSurface = Color(0xFFFFFFFF);
const Color _lightTextPrimary = Color(0xFF1A1A2E);
const Color _lightTextSecondary = Color(0xFF6B7280);

// --- PALETAS DE ACENTO ---
const Color _darkAccentBlue = Color(0xFF00BFFF);
const Color _darkAccentGreen = Color(0xFF00FF7F);
const Color _darkAccentPink = Color(0xFFFF00FF);
const Color _darkAccentOrange = Color(0xFFFFA500);

const Color _lightAccentBlue = Color(0xFF0056D2);
const Color _lightAccentGreen = Color(0xFF007A33);
const Color _lightAccentPink = Color(0xFFB0003A);
const Color _lightAccentOrange = Color(0xFFC63F00);

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

  // --- BUILDER TEMA OSCURO ---
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
        secondary: _darkAccentPink,
        surface: _darkSurface,
        onSurface: _darkTextPrimary,
        error: Colors.redAccent,
      ).copyWith(surface: _darkSurface),
      
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
        margin: EdgeInsets.zero, // Importante para layouts web
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _darkBackground,
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Agregamos esto para el Sidebar y Agenda
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface,
        prefixIconColor: accentColor,
        labelStyle: const TextStyle(color: Colors.white60),
        hintStyle: const TextStyle(color: Colors.white24),
        border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
      ),

      iconTheme: const IconThemeData(color: Colors.white70),
      
      // Agregado para los botones de Agenda
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

 // --- BUILDER TEMA CLARO (MEJORADO) ---
  static ThemeData _buildLightTheme(Color accentColor) {
    final baseTheme = ThemeData.light();
    final textTheme = GoogleFonts.interTextTheme(baseTheme.textTheme).apply(
      bodyColor: _lightTextPrimary,      
      displayColor: _lightTextPrimary,   
    );
    
    return baseTheme.copyWith(
      brightness: Brightness.light,
      primaryColor: accentColor,
      // Usamos el fondo grisáceo para mejor contraste
      scaffoldBackgroundColor: _lightBackground, 
      cardColor: _lightSurface,
      dividerColor: Colors.black.withValues(alpha: 0.06),
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.light,
        primary: accentColor,
        onPrimary: Colors.white,
        secondary: _lightAccentPink, 
        surface: _lightSurface, 
        onSurface: _lightTextPrimary,
        error: Colors.red.shade700,
        outline: _lightTextSecondary,
      ).copyWith(surface: _lightSurface),
      
      textTheme: textTheme,
      
      appBarTheme: AppBarTheme(
        backgroundColor: _lightSurface, // AppBar blanco
        elevation: 0,
        foregroundColor: _lightTextPrimary,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold, 
          color: _lightTextPrimary
        ),
        iconTheme: IconThemeData(color: _lightTextPrimary),
        shape: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
      ),
      
      cardTheme: CardThemeData(
        color: _lightSurface,
        elevation: 0, 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          // Borde sutil para separar del fondo gris
          side: BorderSide(color: Colors.black.withValues(alpha: 0.08), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _lightSurface,
        selectedItemColor: accentColor,
        unselectedItemColor: _lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        prefixIconColor: accentColor,
        labelStyle: TextStyle(color: _lightTextSecondary),
        hintStyle: TextStyle(color: _lightTextPrimary.withValues(alpha: 0.4)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
      ),
      
      iconTheme: IconThemeData(color: _lightTextSecondary),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          elevation: 2,
        ),
      ),
    );
  }
} 

// =============================================================================
// 2. GESTIÓN DE ESTADO (PROVIDER + PERSISTENCIA)
// =============================================================================

class ThemeProvider with ChangeNotifier {
  // Estado privado
  bool _isDarkMode = true;
  AppPalette _currentPalette = AppPalette.blue;

  // Constructor: Carga preferencias al iniciar
  ThemeProvider() {
    _loadFromPrefs();
  }

  // Getters públicos
  bool get isDarkMode => _isDarkMode;
  AppPalette get currentPalette => _currentPalette;

  // Obtener el ThemeData actual basado en el estado
  ThemeData get currentTheme {
    final themeMap = _isDarkMode ? AppThemes.darkThemes : AppThemes.lightThemes;
    return themeMap[_currentPalette] ?? themeMap[AppPalette.blue]!;
  }

  // --- ACCIONES ---

  // Alternar modo Oscuro/Claro
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveToPrefs();
    notifyListeners();
  }

  // Cambiar paleta de colores (Por si quieres implementar un selector de colores luego)
  void changePalette(AppPalette palette) {
    _currentPalette = palette;
    _saveToPrefs();
    notifyListeners();
  }

  // --- PERSISTENCIA (SharedPreferences) ---

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    
    // Cargar paleta guardada (por índice)
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