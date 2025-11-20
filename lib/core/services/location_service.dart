import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Determina la posición actual del dispositivo.
  /// 
  /// Lanza excepciones si los servicios están deshabilitados o los permisos denegados.
  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Verificar si el GPS está encendido
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('El GPS está desactivado. Por favor enciéndelo.');
    }

    permission = await Geolocator.checkPermission();
    
    // 2. Verificar estado actual de permisos
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Los permisos de ubicación fueron denegados.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Los permisos de ubicación están permanentemente denegados. Habilítalos en Configuración.'
      );
    } 

    // 3. Obtener posición con alta precisión
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}