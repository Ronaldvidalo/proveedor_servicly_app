import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FollowService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Colección de perfiles de marca (donde viven los seguidores)
  CollectionReference<Map<String, dynamic>> _brandProfilesCollection() {
    return _db.collection('brandProfiles');
  }

  // Colección de usuarios (donde vive la lista de "siguiendo")
  CollectionReference<Map<String, dynamic>> _usersCollection() {
    return _db.collection('users');
  }

  /// Sigue a un proveedor.
  /// Escribe en la lista "following" del cliente y en la lista "followers" del proveedor.
  Future<void> followProvider(String clientId, String providerId) async {
    try {
      final batch = _db.batch();
      final timestamp = FieldValue.serverTimestamp();

      // 1. Añadir a la lista "following" del cliente
      final followingRef = _usersCollection()
          .doc(clientId)
          .collection('following')
          .doc(providerId);
      batch.set(followingRef, {'followedAt': timestamp});

      // 2. Añadir al conteo de "followers" del proveedor
      final followerRef = _brandProfilesCollection()
          .doc(providerId)
          .collection('followers')
          .doc(clientId);
      batch.set(followerRef, {'followedAt': timestamp});

      await batch.commit();
    } catch (e) {
      debugPrint('Error al seguir al proveedor: $e');
      rethrow;
    }
  }

  /// Deja de seguir a un proveedor.
  /// Borra de ambas listas.
  Future<void> unfollowProvider(String clientId, String providerId) async {
    try {
      final batch = _db.batch();

      // 1. Borrar de la lista "following" del cliente
      final followingRef = _usersCollection()
          .doc(clientId)
          .collection('following')
          .doc(providerId);
      batch.delete(followingRef);

      // 2. Borrar del conteo de "followers" del proveedor
      final followerRef = _brandProfilesCollection()
          .doc(providerId)
          .collection('followers')
          .doc(clientId);
      batch.delete(followerRef);

      await batch.commit();
    } catch (e) {
      debugPrint('Error al dejar de seguir al proveedor: $e');
      rethrow;
    }
  }

  /// Verifica si el cliente actual ya está siguiendo al proveedor.
  /// Devuelve un Stream<bool> para que la UI reaccione en tiempo real.
  Stream<bool> isFollowing(String clientId, String providerId) {
    return _usersCollection()
        .doc(clientId)
        .collection('following')
        .doc(providerId)
        .snapshots()
        .map((snapshot) => snapshot.exists); // True si el documento existe
  }

  /// Obtiene el conteo de seguidores para el proveedor.
  /// Devuelve un Stream<int> para el StatsSummaryCard.
  Stream<int> getFollowersCount(String providerId) {
    return _brandProfilesCollection()
        .doc(providerId)
        .collection('followers')
        .snapshots()
        .map((snapshot) => snapshot.size); // Devuelve el número de documentos
  }
}