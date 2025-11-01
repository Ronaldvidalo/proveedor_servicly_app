import 'package:flutter/foundation.dart';
import '../models/provider_profile_model.dart';
// --- ¡IMPORTACIÓN CLAVE AÑADIDA! ---
import 'package:proveedor_servicly_app/core/services/firestore_service.dart'; 

/// Servicio responsable de las interacciones con Firestore
/// para obtener los datos del perfil público de un proveedor.
class ProviderService {
  // --- ¡CAMBIO! ---
  // Ya no usa FirebaseFirestore directamente, usa nuestro servicio
  final FirestoreService _firestoreService;

  // --- ¡CAMBIO! ---
  // El constructor ahora requiere el FirestoreService
  ProviderService({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  /// Obtiene el perfil público de un proveedor desde Firestore.
  Future<ProviderProfileModel?> getProviderProfile(String providerId) async {
    try {
      // --- ¡CAMBIO DE ARQUITECTURA! ---
      // Llama al método centralizado en FirestoreService que
      // ya sabe cómo leer desde la colección 'catalogs'.
      final profile = await _firestoreService.getCatalogData(providerId);

      if (profile != null) {
        return profile;
      } else {
        // Esto puede pasar si un proveedor NUNCA ha abierto el editor
        // y el documento de 'catalogs' aún no se ha creado.
        debugPrint('No se encontró un catálogo con el ID: $providerId');
        return null;
      }
    } catch (e) {
      debugPrint('Error al obtener el perfil del proveedor: $e');
      return null;
    }
  }
}