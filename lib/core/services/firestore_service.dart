import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/module_model.dart';
import '../models/category_model.dart'; // Asegúrate que esta ruta es correcta
import 'dart:io'; // Import para Platform.operatingSystem

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
    // (Añadimos logs de depuración para la carga infinita)
    if (kDebugMode) {
      print("[FirestoreService] Iniciando getUserStream para UID: $uid");
    }
    return _usersCollection.doc(uid).snapshots().map((snapshot) {
      if (kDebugMode) {
        print("[FirestoreService] getUserStream snapshot recibido para UID: $uid. Existe: ${snapshot.exists}");
      }
      if (snapshot.exists && snapshot.data() != null) {
        try {
          final userModel = UserModel.fromJson(snapshot.data()!);
           if (kDebugMode) {
             print("[FirestoreService] getUserStream emitiendo UserModel para UID: $uid");
           }
          return userModel;
        } catch (e) {
           if (kDebugMode) {
             print("[FirestoreService] !! ERROR al convertir snapshot a UserModel para UID: $uid. Error: $e");
           }
           return null;
        }
      } else {
         if (kDebugMode) {
           print("[FirestoreService] getUserStream emitiendo NULL para UID: $uid (Documento no existe)");
         }
        return null;
      }
    }).handleError((error) {
       if (kDebugMode) {
         print("[FirestoreService] !! ERROR en el stream de snapshots para UID: $uid. Error: $error");
       }
       return null;
    });
  }

  /// Obtiene una única instantánea (snapshot) del documento del usuario.
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDocument(String uid) {
     if (kDebugMode) {
       print("[FirestoreService] Solicitando getUserDocument (get) para UID: $uid");
     }
    return _usersCollection.doc(uid).get();
  }

  /// Actualiza los datos de un documento de usuario existente.
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    if (kDebugMode) {
       print("[FirestoreService] Intentando actualizar usuario UID: $uid con datos: $data");
    }
    try {
      await _usersCollection.doc(uid).update(data);
       if (kDebugMode) {
         print("[FirestoreService] Usuario ACTUALIZADO exitosamente para UID: $uid");
       }
    } catch (e) {
       if (kDebugMode) {
         print('[FirestoreService] !! ERROR al actualizar usuario UID: $uid. Error: $e');
       }
      rethrow;
    }
  }

  /// Obtiene la lista de todos los módulos disponibles desde la colección 'modules'.
  Future<List<ModuleModel>> getAvailableModules() async {
     if (kDebugMode) {
       print("[FirestoreService] Solicitando getAvailableModules (Future)");
     }
    try {
      final snapshot = await _modulesCollection.orderBy('defaultOrder').get(); // Asumimos orden

      if (snapshot.docs.isEmpty) {
        if (kDebugMode) print("[FirestoreService] getAvailableModules: No se encontraron módulos.");
        return [];
      }
       if (kDebugMode) print("[FirestoreService] getAvailableModules: ${snapshot.docs.length} módulos encontrados.");
      return snapshot.docs.map((doc) => ModuleModel.fromFirestore(doc)).toList();
    } catch (e) {
       if (kDebugMode) print('[FirestoreService] !! ERROR al obtener availableModules: $e');
      rethrow;
    }
  }

  /// Actualiza el perfil público de un usuario después de la configuración inicial.
  Future<void> setPublicProfileTemplate({
    required String userId,
    required String templateId,
  }) async {
    if (kDebugMode) print("[FirestoreService] Solicitando setPublicProfileTemplate para UID: $userId con templateId: $templateId");
    try {
      await _usersCollection.doc(userId).update({
        'publicProfileCreated': true,
        'publicProfileTemplate': templateId,
      });
      if (kDebugMode) print("[FirestoreService] publicProfileTemplate ACTUALIZADO para UID: $userId");
    } catch (e) {
      if (kDebugMode) print('[FirestoreService] !! ERROR al actualizar publicProfileTemplate para UID: $userId. Error: $e');
      rethrow;
    }
  }
  
  /// Obtiene un Stream de la lista de categorías para un usuario específico, ordenadas.
  Stream<List<CategoryModel>> getCategoriesStream(String uid) {
      if (kDebugMode) {
         print("[FirestoreService] Solicitando getCategoriesStream para UID: $uid");
      }
      try {
         return _usersCollection.doc(uid).collection('categories').orderBy('order').snapshots().map((snapshot) {
             if (snapshot.docs.isEmpty) {
                 if (kDebugMode) print("[FirestoreService] getCategoriesStream: No se encontraron categorías para UID: $uid.");
                return <CategoryModel>[]; // Devolver lista vacía tipada
             }
              if (kDebugMode) print("[FirestoreService] getCategoriesStream: ${snapshot.docs.length} categorías emitidas para UID: $uid.");
             return snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
         }).handleError((error) {
              if (kDebugMode) print('[FirestoreService] !! ERROR en getCategoriesStream para UID: $uid. Error: $error');
             return <CategoryModel>[]; 
         });
      } catch (e) {
          if (kDebugMode) print('[FirestoreService] !! ERROR al configurar getCategoriesStream para UID: $uid. Error: $e');
         return Stream.value(<CategoryModel>[]).handleError((_) => throw e);
      }
   }


   /// Añade una nueva categoría a la subcolección del usuario.
   Future<void> addCategory(String userId, String name) async {
       if (kDebugMode) print("[FirestoreService] Intentando añadir categoría '$name' para UID: $userId");
       try {
           final categoriesCollection = _usersCollection.doc(userId).collection('categories');
           final currentCategories = await categoriesCollection.orderBy('order', descending: true).limit(1).get();
           final nextOrder = currentCategories.docs.isEmpty ? 0 : (currentCategories.docs.first.data()['order'] as int? ?? -1) + 1;
           await categoriesCollection.add({'name': name, 'order': nextOrder});
            if (kDebugMode) print("[FirestoreService] Categoría '$name' añadida exitosamente para UID: $userId con orden $nextOrder");
       } catch (e) {
           if (kDebugMode) print('[FirestoreService] !! ERROR al añadir categoría: $e');
           rethrow;
       }
   }

   /// Actualiza el nombre de una categoría específica.
   Future<void> updateCategoryName(String userId, String categoryId, String newName) async {
       if (kDebugMode) print("[FirestoreService] Intentando actualizar categoría $categoryId a '$newName' para UID: $userId");
       try {
           await _usersCollection.doc(userId).collection('categories').doc(categoryId).update({'name': newName});
            if (kDebugMode) print("[FirestoreService] Categoría $categoryId actualizada exitosamente a '$newName' para UID: $userId");
       } catch (e) {
            if (kDebugMode) print('[FirestoreService] !! ERROR al actualizar categoría: $e');
            rethrow;
       }
   }

   /// Elimina una categoría específica.
   Future<void> deleteCategory(String userId, String categoryId) async {
       if (kDebugMode) print("[FirestoreService] Intentando eliminar categoría $categoryId para UID: $userId");
       try {
           await _usersCollection.doc(userId).collection('categories').doc(categoryId).delete();
            if (kDebugMode) print("[FirestoreService] Categoría $categoryId eliminada exitosamente para UID: $userId");
       } catch (e) {
            if (kDebugMode) print('[FirestoreService] !! ERROR al eliminar categoría: $e');
            rethrow;
       }
   }

   /// Reordena las categorías después de que el usuario las arrastra en la UI.
   Future<void> reorderCategories(String userId, List<CategoryModel> currentList, int oldIndex, int newIndex) async {
        if (kDebugMode) print("[FirestoreService] Reordenando categorías para UID: $userId de $oldIndex a $newIndex");
       try {
           final batch = _db.batch();
           final categoriesCollection = _usersCollection.doc(userId).collection('categories');
           final item = currentList.removeAt(oldIndex);
           currentList.insert(newIndex, item);
           for (int i = 0; i < currentList.length; i++) {
              batch.update(categoriesCollection.doc(currentList[i].id), {'order': i});
           }
           await batch.commit();
            if (kDebugMode) print("[FirestoreService] Categorías reordenadas exitosamente en Firestore para UID: $userId");
       } catch (e) {
            if (kDebugMode) print('[FirestoreService] !! ERROR al reordenar categorías: $e');
            rethrow;
       }
   }

  // --- MÉTODO AÑADIDO PARA GUARDAR TOKEN FCM ---
  /// Guarda un token FCM en la subcolección 'tokens' del usuario.
  /// Usar .set() con el token como ID de documento previene duplicados.
  Future<void> saveDeviceToken({required String uid, required String token}) async {
    if (kDebugMode) {
      print("[FirestoreService] Guardando token FCM para UID: $uid");
    }
    try {
      final tokensCollection = _usersCollection.doc(uid).collection('tokens');
      // Usamos el token como ID del documento para evitar duplicados
      await tokensCollection.doc(token).set({
        'createdAt': FieldValue.serverTimestamp(),
        // Guardamos la plataforma para saber si es Android o iOS
        'platform': Platform.operatingSystem, 
      });
      if (kDebugMode) {
        print("[FirestoreService] Token FCM guardado exitosamente.");
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FirestoreService] !! ERROR al guardar token FCM: $e');
      }
      // No relanzamos para no romper el flujo de login
    }
  }
}

