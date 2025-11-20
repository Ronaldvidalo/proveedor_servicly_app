import 'package:geolocator/geolocator.dart';

class DistanceUtils {
  /// Calcula la distancia en KM entre dos puntos.
  /// Retorna un string formateado (ej: "2.5 km" o "800 m").
  static String formatDistance(double startLat, double startLng, double endLat, double endLng) {
    double distanceInMeters = Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
    
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Obtiene el valor numérico en metros para ordenar listas via sort()
  static double getDistanceInMeters(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}
