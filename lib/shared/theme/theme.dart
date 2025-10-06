// lib/shared/theme/theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Paleta de Colores Profesional ---

/// Paleta de colores principal para el tema claro.
const Color _lightPrimaryColor = Color(0xFF005A9C);
const Color _lightOnPrimaryColor = Colors.white;
const Color _lightSecondaryColor = Color(0xFFF2A900);
const Color _lightBackgroundColor = Color(0xFFF7F9FC);
const Color _lightSurfaceColor = Colors.white;
const Color _lightTextColor = Color(0xFF333333);
const Color _lightErrorColor = Color(0xFFD32F2F);

/// Paleta de colores principal para el tema oscuro.
const Color _darkPrimaryColor = Color(0xFF4A90E2);
const Color _darkOnPrimaryColor = Colors.black;
const Color _darkSecondaryColor = Color(0xFFF5B82E);
const Color _darkBackgroundColor = Color(0xFF121212);
const Color _darkSurfaceColor = Color(0xFF1E1E1E);
const Color _darkTextColor = Color(0xFFE0E0E0);
const Color _darkErrorColor = Color(0xFFEF9A9A);

/// Define el tema claro para la aplicación Servicly.
///
/// Este tema utiliza una paleta de colores profesional y legible, con un fondo
/// claro para maximizar la visibilidad durante el día. La tipografía
/// principal es 'Inter' de Google Fonts para una apariencia moderna y limpia.
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: _lightPrimaryColor,
  scaffoldBackgroundColor: _lightBackgroundColor,
  colorScheme: const ColorScheme.light(
    primary: _lightPrimaryColor,
    onPrimary: _lightOnPrimaryColor,
    secondary: _lightSecondaryColor,
    // Se eliminan 'background' y 'onBackground' (obsoletos).
    // 'surface' y 'onSurface' son las propiedades correctas.
    surface: _lightSurfaceColor,
    error: _lightErrorColor,
    onSurface: _lightTextColor,
    onError: Colors.white,
  ),
  
  /// Define la tipografía base usando Google Fonts.
  textTheme: GoogleFonts.interTextTheme(
    ThemeData.light().textTheme,
  ).apply(
    bodyColor: _lightTextColor,
    displayColor: _lightTextColor,
  ),

  /// Estilo para las AppBars en el tema claro.
  appBarTheme: const AppBarTheme(
    // Se reemplaza 'color' (obsoleto) por 'backgroundColor'.
    backgroundColor: _lightSurfaceColor, 
    elevation: 1,
    iconTheme: IconThemeData(color: _lightPrimaryColor),
    titleTextStyle: TextStyle(
      color: _lightTextColor,
      fontSize: 20,
      fontWeight: FontWeight.w500,
    ),
  ),

  /// Estilo para los botones elevados.
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _lightPrimaryColor,
      foregroundColor: _lightOnPrimaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),

  /// Estilo para los campos de texto y formularios.
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: const BorderSide(color: _lightPrimaryColor, width: 2.0),
    ),
    labelStyle: const TextStyle(color: _lightTextColor),
  ),
);

/// Define el tema oscuro para la aplicación Servicly.
///
/// Este tema está diseñado para reducir la fatiga visual en condiciones de poca
/// luz. Utiliza una paleta de colores de alto contraste con un fondo oscuro.
/// La tipografía se mantiene consistente con el tema claro.
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: _darkPrimaryColor,
  scaffoldBackgroundColor: _darkBackgroundColor,
  colorScheme: const ColorScheme.dark(
    primary: _darkPrimaryColor,
    onPrimary: _darkOnPrimaryColor,
    secondary: _darkSecondaryColor,
    // Se eliminan 'background' y 'onBackground' (obsoletos).
    surface: _darkSurfaceColor,
    error: _darkErrorColor,
    onSurface: _darkTextColor,
    onError: Colors.black,
  ),

  /// Define la tipografía base usando Google Fonts para el tema oscuro.
  textTheme: GoogleFonts.interTextTheme(
    ThemeData.dark().textTheme,
  ).apply(
    bodyColor: _darkTextColor,
    displayColor: _darkTextColor,
  ),

  /// Estilo para las AppBars en el tema oscuro.
  appBarTheme: const AppBarTheme(
    // Se reemplaza 'color' (obsoleto) por 'backgroundColor'.
    backgroundColor: _darkSurfaceColor,
    elevation: 1,
    iconTheme: IconThemeData(color: _darkPrimaryColor),
    titleTextStyle: TextStyle(
      color: _darkTextColor,
      fontSize: 20,
      fontWeight: FontWeight.w500,
    ),
  ),

  /// Estilo para los botones elevados en el tema oscuro.
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _darkPrimaryColor,
      foregroundColor: _darkOnPrimaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),

  /// Estilo para los campos de texto y formularios en el tema oscuro.
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _darkSurfaceColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(color: Colors.grey[700]!),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(color: Colors.grey[700]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: const BorderSide(color: _darkPrimaryColor, width: 2.0),
    ),
    labelStyle: const TextStyle(color: _darkTextColor),
  ),
);