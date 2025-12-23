import 'package:flutter/material.dart';

// Definimos los colores base de tu tema "Cyber Glow"
const Color _cyberPrimary = Color(0xFF00BFFF); // Azul eléctrico brillante
const Color _cyberBackground = Color(0xFF1A1A2E); // Azul oscuro casi negro
const Color _cyberSurface = Color(0xFF2D2D5A); // Superficie ligeramente más clara

class ThemeProvider with ChangeNotifier {
  // Por defecto, empezamos en modo oscuro (puedes cambiarlo a 'false' si prefieres)
  bool _isDarkMode = true;

  // Getter para que el resto de la app sepa el estado actual
  bool get isDarkMode => _isDarkMode;

  // Método para obtener el tema actual
  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;

  // Método para alternar el tema
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners(); // Notifica a todos los 'listeners' (como el Consumer) que el estado cambió
  }

  // --- Definición del Tema Oscuro (Cyber Glow) ---
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: _cyberPrimary,
    scaffoldBackgroundColor: _cyberBackground,
    colorScheme: const ColorScheme.dark(
      primary: _cyberPrimary,
      secondary: _cyberPrimary,
      surface: _cyberSurface,
      onPrimary: Colors.black, // Color del texto sobre 'primary'
      onSecondary: Colors.black,
      onSurface: Colors.white,
      error: Colors.redAccent,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _cyberBackground, // AppBar transparente o del color de fondo
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
          color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _cyberSurface,
      selectedItemColor: _cyberPrimary,
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _cyberPrimary,
        foregroundColor: Colors.black, // Texto de los botones
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _cyberPrimary,
        side: const BorderSide(color: _cyberPrimary, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _cyberPrimary,
      ),
    ),
    iconTheme: const IconThemeData(
      color: _cyberPrimary,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: _cyberSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white),
    ),
    // ... puedes añadir más personalizaciones aquí (textTheme, cardTheme, etc.)
  );

  // --- Definición del Tema Claro (Básico) ---
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: _cyberPrimary, // Mantenemos el azul como acento
    scaffoldBackgroundColor: const Color(0xFFF4F6F8), // Un gris muy claro
    colorScheme: ColorScheme.light(
      primary: _cyberPrimary,
      secondary: _cyberPrimary,
      surface: Colors.white, // Tarjetas y superficies blancas
      onPrimary: Colors.white, // Texto sobre el color primario
      onSecondary: Colors.black,
      onSurface: Colors.black87,
      error: Colors.red,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white, // AppBar blanco
      elevation: 1,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(
          color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: _cyberPrimary,
      unselectedItemColor: Colors.grey.shade600,
      type: BottomNavigationBarType.fixed,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _cyberPrimary,
        foregroundColor: Colors.white, // Texto blanco sobre azul
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _cyberPrimary,
        side: const BorderSide(color: _cyberPrimary, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _cyberPrimary,
      ),
    ),
    iconTheme: const IconThemeData(
      color: _cyberPrimary,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white),
    ),
    // ...
  );
}