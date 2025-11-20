import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

class GeocodingService {
  
  /// Convierte una dirección de texto (ej: "Av Bragado 5985, Wilde") 
  /// en coordenadas (Lat, Lng).
  /// 
  /// Retorna null si no encuentra la dirección.
  Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
    try {
      // Intentamos buscar la dirección. 
      // Recomendación: Concatenar el país o ciudad si no lo tiene para mayor precisión.
      // Ej: "$address, Argentina"
      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        Location location = locations.first;
        if (kDebugMode) {
          print("Dirección encontrada: ${location.latitude}, ${location.longitude}");
        }
        return {
          'latitude': location.latitude,
          'longitude': location.longitude,
        };
      }
    } catch (e) {
      print("Error al geocodificar dirección '$address': $e");
    }
    return null;
  }

  /// (Opcional) Obtiene la dirección legible desde coordenadas GPS
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return "${place.street}, ${place.locality}";
      }
    } catch (e) {
      print("Error obteniendo dirección: $e");
    }
    return null;
  }
}