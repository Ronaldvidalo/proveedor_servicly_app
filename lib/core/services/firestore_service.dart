// lib/core/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/module_model.dart';

/// Un servicio para gestionar todas las operaciones de lectura y escritura
/// con la base de datos de Cloud Firestore.
class FirestoreService {
  final FirebaseFirestore _db;
  late final CollectionReference<Map<String, dynamic>> _usersCollection;
  late final CollectionReference<Map<String, dynamic>> _modulesCollection;

  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance {
    _usersCollection = _db.collection('users');
    _modulesCollection = _db.collection('modules');
  }

  /// Crea un nuevo documento de usuario en Firestore.
  Future<void> createUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(user.toJson());
    } catch (e) {
      // En una app de producción, usarías un sistema de logging.
      rethrow;
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        // --- MODIFICACIÓN: Se usa el factory fromJson para ser consistente ---
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener el usuario: $e');
      rethrow;
    }
  }

  /// Obtiene un stream con los datos del perfil de un usuario en tiempo real.
  Stream<UserModel?> getUserStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserModel.fromJson(snapshot.data()!);
      } else {
        return null;
      }
    });
  }

  /// Actualiza los datos de un documento de usuario existente.
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(uid).update(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene la lista de todos los módulos disponibles desde la colección 'modules'.
  Future<List<ModuleModel>> getAvailableModules() async {
    try {
      final snapshot = await _modulesCollection.get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      return snapshot.docs.map((doc) => ModuleModel.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // --- NUEVO MÉTODO AÑADIDO ---
  /// Actualiza el perfil público de un usuario después de la configuración inicial.
  ///
  /// Establece la plantilla seleccionada y marca el perfil como creado.
  ///
  /// - [userId]: El ID del usuario a actualizar.
  /// - [templateId]: El identificador de la plantilla seleccionada (ej: 'tienda').
  Future<void> setPublicProfileTemplate({
    required String userId,
    required String templateId,
  }) async {
    try {
      await _usersCollection.doc(userId).update({
        'publicProfileCreated': true,
        'publicProfileTemplate': templateId,
      });
    } catch (e) {
      // En una aplicación real, es crucial manejar este error.
      debugPrint('Error al actualizar la plantilla del perfil público: $e');
      // Opcional: relanzar el error para que la UI pueda reaccionar.
      rethrow;
    }
  }
}

