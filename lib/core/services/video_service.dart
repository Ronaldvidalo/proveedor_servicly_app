import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:proveedor_servicly_app/core/models/video_showcase_model.dart';

/// Un servicio dedicado a gestionar todas las operaciones CRUD
/// para la colección 'videoShowcases'.
class VideoService {
  final FirebaseFirestore _db;

  VideoService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  /// Obtiene una referencia a la colección 'videoShowcases'.
  CollectionReference<Map<String, dynamic>> _videoCollection() {
    return _db.collection('videoShowcases');
  }

  /// Añade un nuevo video a Firestore.
  /// Se asume que el 'createdAt' ya está en el modelo.
  Future<DocumentReference> addVideoShowcase(VideoShowcaseModel video) async {
    try {
      // El 'id' se genera automáticamente por Firestore.
      // toJson() no incluye el 'id'.
      return await _videoCollection().add(video.toJson());
    } catch (e) {
      debugPrint('[VideoService] Error al añadir video: $e');
      rethrow;
    }
  }

  /// Actualiza un video existente en Firestore.
  /// Se usa para editar el título, o activar/desactivar isPromoted.
  Future<void> updateVideoShowcase(String videoId, Map<String, dynamic> dataToUpdate) async {
    try {
      await _videoCollection().doc(videoId).update(dataToUpdate);
    } catch (e) {
      debugPrint('[VideoService] Error al actualizar video: $e');
      rethrow;
    }
  }

  /// Elimina un video de Firestore.
  /// NOTA: La UI debe llamar a StorageService.deleteFileByUrl por separado
  /// para borrar los archivos de video y miniatura de Storage.
  Future<void> deleteVideoShowcase(String videoId) async {
    try {
      await _videoCollection().doc(videoId).delete();
    } catch (e) {
      debugPrint('[VideoService] Error al eliminar video: $e');
      rethrow;
    }
  }

  /// 1. (Para el Proveedor)
  /// Obtiene un stream con la lista de TODOS los videos de un proveedor específico.
  /// Usado en la pantalla 'ManageStoreScreen' o 'VideoManagerScreen'.
  Stream<List<VideoShowcaseModel>> getVideoShowcasesByProvider(String providerId) {
    return _videoCollection()
        .where('providerId', isEqualTo: providerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VideoShowcaseModel.fromFirestore(doc))
            .toList());
  }

  /// 2. (Para el Cliente - "Descubrir")
  /// Obtiene un stream de videos PROMOCIONADOS (pagados) de CUALQUIER proveedor.
  /// Usado en el carrusel de 'HomeScreen'.
  Stream<List<VideoShowcaseModel>> getPromotedVideos({int limit = 10}) {
    return _videoCollection()
        .where('isActive', isEqualTo: true)
        .where('isPromoted', isEqualTo: true) // ¡Solo los que pagaron!
        .orderBy('createdAt', descending: true) // O por 'order' si lo prefieres
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VideoShowcaseModel.fromFirestore(doc))
            .toList());
    // NOTA: Esta consulta requerirá un índice compuesto en Firestore.
    // La consola de Firebase te dará un link para crearlo la primera vez.
  }

  /// 3. (Para el Cliente - "Feed Orgánico")
  /// Obtiene un stream con los videos de los proveedores que un cliente SIGUE.
  /// Usado en la futura pantalla "Feed".
  Stream<List<VideoShowcaseModel>> getFollowingVideosFeed(List<String> followedProviderIds) {
    if (followedProviderIds.isEmpty) {
      // Si el usuario no sigue a nadie, devuelve un stream vacío.
      return Stream.value([]);
    }
    
    return _videoCollection()
        .where('isActive', isEqualTo: true)
        .where('providerId', whereIn: followedProviderIds) // Magia de Firestore (límite de 30 IDs)
        .orderBy('createdAt', descending: true)
        .limit(50) // Paginar el feed
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VideoShowcaseModel.fromFirestore(doc))
            .toList());
    // NOTA: Esta consulta también requerirá un índice compuesto.
  }
}