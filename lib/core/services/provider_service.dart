import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/provider_profile_model.dart';

/// Servicio responsable de las interacciones con la colección de usuarios en Firestore
/// para obtener los datos del perfil público de un proveedor.
class ProviderService {
  final FirebaseFirestore _firestore;

  /// Crea una instancia de [ProviderService].
  ///
  /// Requiere una instancia de [FirebaseFirestore], que normalmente se inyecta
  /// a través de un sistema de inyección de dependencias como `Provider`.
  ProviderService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Obtiene el perfil público de un proveedor desde Firestore.
  ///
  /// Dado un [providerId], este método recupera el documento correspondiente
  /// de la colección `users` y lo mapea a un [ProviderProfileModel].
  ///
  /// Devuelve el [ProviderProfileModel] si tiene éxito.
  /// Devuelve `null` si el documento no existe o si ocurre un error.
  Future<ProviderProfileModel?> getProviderProfile(String providerId) async {
    try {
      // Apuntamos a la colección 'users' para obtener los datos del proveedor.
      final docSnapshot = await _firestore.collection('users').doc(providerId).get();

      if (docSnapshot.exists) {
        // Si el documento existe, lo convertimos a nuestro modelo.
        return ProviderProfileModel.fromFirestore(docSnapshot);
      } else {
        // El proveedor con el ID dado no existe.
        // En una app real, podrías registrar este evento.
        debugPrint('No se encontró un proveedor con el ID: $providerId');
        return null;
      }
    } catch (e) {
      // En una app real, es crucial registrar este error en un servicio de monitoreo.
      debugPrint('Error al obtener el perfil del proveedor: $e');
      return null;
    }
  }
}

