// Archivo: lib/core/services/firestore_service_web.dart

class Platform {
  // Cuando estemos en web, devolvemos "web" o lo que necesites
  static String get operatingSystem => 'web';
  
  // Agrega estos si los usas en otras partes de tu app
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static bool get isMacOS => false;
  static bool get isWindows => false;
  static bool get isLinux => false;
  static bool get isFuchsia => false;
}