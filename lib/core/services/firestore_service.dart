import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb y debugPrint
// --- IMPORT CONDICIONAL CORREGIDO ---
import 'dart:io' if (dart.library.html) 'firestore_service_web.dart'; // O usa 'universal_io'

// --- IMPORTS DE MODELOS ---
// Asegúrate que estas rutas sean correctas para tu proyecto
import '../models/user_model.dart';
import '../models/module_model.dart';
import '../models/category_model.dart'; // Para categorías de PRODUCTOS
import '../models/portfolio_category_model.dart'; // Para categorías de PORTAFOLIO
// --- IMPORT AÑADIDO ---
import '../models/portfolio_item_model.dart'; // Para ítems de PORTAFOLIO (incluye PortfolioItemType)


/// Servicio central para manejar Firestore (CRUD, streams, etc.)
class FirestoreService {
  final FirebaseFirestore _db;
  late final CollectionReference<Map<String, dynamic>> _usersCollection;
  late final CollectionReference<Map<String, dynamic>> _modulesCollection;

  // --- Constantes para subcolecciones ---
  final String _portfolioCategoriesCollection = 'portfolio_categories';
  // --- NUEVA CONSTANTE ---
  final String _portfolioItemsCollection = 'portfolio_items';
  final String _productCategoriesCollection = 'categories';

  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance {
    _usersCollection = _db.collection('users');
    _modulesCollection = _db.collection('modules');
  }

  // ------------------------------
  // MÉTODOS USUARIOS (Tu código original)
  // ------------------------------

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
      debugPrint('[FirestoreService] Error al obtener el usuario: $e');
      rethrow;
    }
  }

  /// Obtiene un stream con los datos del perfil de un usuario en tiempo real.
  Stream<UserModel?> getUserStream(String uid) {
    // (Añadimos logs de depuración para la carga infinita)
    if (kDebugMode) {
      debugPrint("[FirestoreService] Iniciando getUserStream para UID: $uid");
    }
    return _usersCollection.doc(uid).snapshots().map((snapshot) {
      if (kDebugMode) {
        debugPrint("[FirestoreService] getUserStream snapshot recibido para UID: $uid. Existe: ${snapshot.exists}");
      }
      if (snapshot.exists && snapshot.data() != null) {
        try {
          final userModel = UserModel.fromJson(snapshot.data()!);
           if (kDebugMode) {
             debugPrint("[FirestoreService] getUserStream emitiendo UserModel para UID: $uid");
           }
          return userModel;
        } catch (e) {
           if (kDebugMode) {
             debugPrint("[FirestoreService] !! ERROR al convertir snapshot a UserModel para UID: $uid. Error: $e");
           }
           return null;
        }
      } else {
         if (kDebugMode) {
           debugPrint("[FirestoreService] getUserStream emitiendo NULL para UID: $uid (Documento no existe)");
         }
        return null;
      }
    }).handleError((error) {
       if (kDebugMode) {
         debugPrint("[FirestoreService] !! ERROR en el stream de snapshots para UID: $uid. Error: $error");
       }
       return null;
    });
  }

  /// Obtiene una única instantánea (snapshot) del documento del usuario.
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDocument(String uid) {
     if (kDebugMode) {
       debugPrint("[FirestoreService] Solicitando getUserDocument (get) para UID: $uid");
     }
    return _usersCollection.doc(uid).get();
  }

  /// Actualiza los datos de un documento de usuario existente.
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    if (kDebugMode) {
       debugPrint("[FirestoreService] Intentando actualizar usuario UID: $uid con datos: $data");
    }
    try {
      await _usersCollection.doc(uid).update(data);
       if (kDebugMode) {
         debugPrint("[FirestoreService] Usuario ACTUALIZADO exitosamente para UID: $uid");
       }
    } catch (e) {
       if (kDebugMode) {
         debugPrint('[FirestoreService] !! ERROR al actualizar usuario UID: $uid. Error: $e');
       }
      rethrow;
    }
  }

  // ------------------------------
  // MÓDULOS (Tu código original)
  // ------------------------------

  /// Obtiene la lista de todos los módulos disponibles desde la colección 'modules'.
  Future<List<ModuleModel>> getAvailableModules() async {
     if (kDebugMode) {
       debugPrint("[FirestoreService] Solicitando getAvailableModules (Future)");
     }
    try {
      final snapshot = await _modulesCollection.orderBy('defaultOrder').get(); // Asumimos orden

      if (snapshot.docs.isEmpty) {
        if (kDebugMode) debugPrint("[FirestoreService] getAvailableModules: No se encontraron módulos.");
        return [];
      }
       if (kDebugMode) debugPrint("[FirestoreService] getAvailableModules: ${snapshot.docs.length} módulos encontrados.");
      return snapshot.docs.map((doc) => ModuleModel.fromFirestore(doc)).toList();
    } catch (e) {
       if (kDebugMode) debugPrint('[FirestoreService] !! ERROR al obtener availableModules: $e');
      rethrow;
    }
  }

  /// Actualiza el perfil público de un usuario después de la configuración inicial.
  Future<void> setPublicProfileTemplate({
    required String userId,
    required String templateId,
  }) async {
    if (kDebugMode) debugPrint("[FirestoreService] Solicitando setPublicProfileTemplate para UID: $userId con templateId: $templateId");
    try {
      await _usersCollection.doc(userId).update({
        'publicProfileCreated': true,
        'publicProfileTemplate': templateId,
      });
      if (kDebugMode) debugPrint("[FirestoreService] publicProfileTemplate ACTUALIZADO para UID: $userId");
    } catch (e) {
      if (kDebugMode) debugPrint('[FirestoreService] !! ERROR al actualizar publicProfileTemplate para UID: $userId. Error: $e');
      rethrow;
    }
  }

  // ------------------------------
  // CATEGORÍAS DE PRODUCTOS (Tu código original)
  // ------------------------------

  /// Obtiene un Stream de la lista de categorías para un usuario específico, ordenadas.
  Stream<List<CategoryModel>> getCategoriesStream(String uid) {
      if (kDebugMode) {
          debugPrint("[FirestoreService] Solicitando getCategoriesStream (PRODUCTOS) para UID: $uid");
      }
      try {
          return _usersCollection.doc(uid).collection(_productCategoriesCollection).orderBy('order').snapshots().map((snapshot) {
              if (snapshot.docs.isEmpty) {
                  if (kDebugMode) debugPrint("[FirestoreService] getCategoriesStream (PRODUCTOS): No se encontraron categorías para UID: $uid.");
                 return <CategoryModel>[]; // Devolver lista vacía tipada
              }
               if (kDebugMode) debugPrint("[FirestoreService] getCategoriesStream (PRODUCTOS): ${snapshot.docs.length} categorías emitidas para UID: $uid.");
             return snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
          }).handleError((error) {
               if (kDebugMode) debugPrint('[FirestoreService] !! ERROR en getCategoriesStream (PRODUCTOS) para UID: $uid. Error: $error');
             return <CategoryModel>[];
          });
      } catch (e) {
          if (kDebugMode) debugPrint('[FirestoreService] !! ERROR al configurar getCategoriesStream (PRODUCTOS) para UID: $uid. Error: $e');
         return Stream.value(<CategoryModel>[]).handleError((_) => throw e);
      }
   }


    /// Añade una nueva categoría a la subcolección del usuario.
    Future<void> addCategory(String userId, String name) async {
       if (kDebugMode) debugPrint("[FirestoreService] Intentando añadir categoría de PRODUCTO '$name' para UID: $userId");
       try {
           final categoriesCollection = _usersCollection.doc(userId).collection(_productCategoriesCollection);
           final currentCategories = await categoriesCollection.orderBy('order', descending: true).limit(1).get();
           final nextOrder = currentCategories.docs.isEmpty ? 0 : (currentCategories.docs.first.data()['order'] as int? ?? -1) + 1;
           await categoriesCollection.add({'name': name, 'order': nextOrder});
            if (kDebugMode) debugPrint("[FirestoreService] Categoría de PRODUCTO '$name' añadida exitosamente para UID: $userId con orden $nextOrder");
       } catch (e) {
           if (kDebugMode) debugPrint('[FirestoreService] !! ERROR al añadir categoría de PRODUCTO: $e');
           rethrow;
       }
   }

    /// Actualiza el nombre de una categoría específica.
    Future<void> updateCategoryName(String userId, String categoryId, String newName) async {
       if (kDebugMode) debugPrint("[FirestoreService] Intentando actualizar categoría de PRODUCTO $categoryId a '$newName' para UID: $userId");
       try {
           await _usersCollection.doc(userId).collection(_productCategoriesCollection).doc(categoryId).update({'name': newName});
            if (kDebugMode) debugPrint("[FirestoreService] Categoría de PRODUCTO $categoryId actualizada exitosamente a '$newName' para UID: $userId");
       } catch (e) {
            if (kDebugMode) debugPrint('[FirestoreService] !! ERROR al actualizar categoría de PRODUCTO: $e');
            rethrow;
       }
   }

    /// Elimina una categoría específica.
    Future<void> deleteCategory(String userId, String categoryId) async {
       if (kDebugMode) debugPrint("[FirestoreService] Intentando eliminar categoría de PRODUCTO $categoryId para UID: $userId");
       try {
           await _usersCollection.doc(userId).collection(_productCategoriesCollection).doc(categoryId).delete();
            if (kDebugMode) debugPrint("[FirestoreService] Categoría de PRODUCTO $categoryId eliminada exitosamente para UID: $userId");
       } catch (e) {
            if (kDebugMode) debugPrint('[FirestoreService] !! ERROR al eliminar categoría de PRODUCTO: $e');
            rethrow;
       }
   }

    /// Reordena las categorías después de que el usuario las arrastra en la UI.
    Future<void> reorderCategories(String userId, List<CategoryModel> currentList, int oldIndex, int newIndex) async {
         if (kDebugMode) debugPrint("[FirestoreService] Reordenando categorías de PRODUCTOS para UID: $userId de $oldIndex a $newIndex");
        try {
            final batch = _db.batch();
            final categoriesCollection = _usersCollection.doc(userId).collection(_productCategoriesCollection);
            // Corrección lógica reordenamiento
            final List<CategoryModel> reorderedList = List.from(currentList);
            final item = reorderedList.removeAt(oldIndex);
            final int insertIndex = (newIndex > oldIndex) ? newIndex - 1 : newIndex;
            reorderedList.insert(insertIndex, item);
            // Fin Corrección
            for (int i = 0; i < reorderedList.length; i++) {
               batch.update(categoriesCollection.doc(reorderedList[i].id), {'order': i});
            }
            await batch.commit();
             if (kDebugMode) debugPrint("[FirestoreService] Categorías de PRODUCTOS reordenadas exitosamente en Firestore para UID: $userId");
        } catch (e) {
             if (kDebugMode) debugPrint('[FirestoreService] !! ERROR al reordenar categorías de PRODUCTOS: $e');
             rethrow;
        }
   }

  // ------------------------------
  // TOKEN FCM (Tu código original - corregido para web)
  // ------------------------------
  Future<void> saveDeviceToken({required String uid, required String token}) async {
    if (kDebugMode) {
      debugPrint("[FirestoreService] Guardando token FCM para UID: $uid");
    }
    try {
      final tokensCollection = _usersCollection.doc(uid).collection('tokens');
      String platformIdentifier = 'unknown'; // Valor por defecto

      if (kIsWeb) {
        platformIdentifier = 'web';
      } else {
        // Platform solo se usa si no es web, gracias al import condicional
        platformIdentifier = Platform.operatingSystem;
      }

      await tokensCollection.doc(token).set({
        'createdAt': FieldValue.serverTimestamp(),
        'platform': platformIdentifier,
      });
       if (kDebugMode) {
        debugPrint("[FirestoreService] Token FCM guardado exitosamente para plataforma: $platformIdentifier.");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FirestoreService] Error al guardar token FCM: $e');
      }
    }
  }

  // ------------------------------
  // CATEGORÍAS DE PORTAFOLIO (Tu código original - ya estaba correcto)
  // ------------------------------
  Stream<List<PortfolioCategoryModel>> getPortfolioCategoriesStream(String userId) {
    if (kDebugMode) {
        debugPrint("[FirestoreService] Solicitando getPortfolioCategoriesStream para UID: $userId");
    }
   return _usersCollection // Usar la referencia correcta
       .doc(userId)
       .collection(_portfolioCategoriesCollection)
       .orderBy('order')
       .snapshots()
       .map((snapshot) =>
           snapshot.docs.map((doc) => PortfolioCategoryModel.fromFirestore(doc)).toList())
       .handleError((error) {
     debugPrint('[FirestoreService] Error en getPortfolioCategoriesStream: $error');
     return <PortfolioCategoryModel>[];
   });
 }

 Future<void> addPortfolioCategory(String userId, String name) async {
    if (kDebugMode) debugPrint("[FirestoreService] Intentando añadir categoría de PORTAFOLIO '$name' para UID: $userId");
   try {
     final categoriesRef =
         _usersCollection // Usar la referencia correcta
             .doc(userId)
             .collection(_portfolioCategoriesCollection);
     final querySnapshot =
         await categoriesRef.orderBy('order', descending: true).limit(1).get();
     int nextOrder = 0;
     if (querySnapshot.docs.isNotEmpty) {
       nextOrder = (querySnapshot.docs.first.data()['order'] as int? ?? -1) + 1;
     }

     await categoriesRef.add({
       'name': name,
       'order': nextOrder,
       'createdAt': FieldValue.serverTimestamp(),
     });
      if (kDebugMode) debugPrint("[FirestoreService] Categoría de PORTAFOLIO '$name' añadida exitosamente para UID: $userId con orden $nextOrder");
   } catch (e) {
     debugPrint('[FirestoreService] Error al añadir categoría de portafolio: $e');
     rethrow;
   }
 }

 Future<void> updatePortfolioCategory(
     String userId, String categoryId, String newName) async {
      if (kDebugMode) debugPrint("[FirestoreService] Intentando actualizar categoría de PORTAFOLIO $categoryId a '$newName' para UID: $userId");
   try {
     await _usersCollection // Usar la referencia correcta
         .doc(userId)
         .collection(_portfolioCategoriesCollection)
         .doc(categoryId)
         .update({'name': newName});
      if (kDebugMode) debugPrint("[FirestoreService] Categoría de PORTAFOLIO $categoryId actualizada exitosamente a '$newName' para UID: $userId");
   } catch (e) {
     debugPrint('[FirestoreService] Error al actualizar categoría de portafolio: $e');
     rethrow;
   }
 }

 Future<void> deletePortfolioCategory(String userId, String categoryId) async {
    if (kDebugMode) debugPrint("[FirestoreService] Intentando eliminar categoría de PORTAFOLIO $categoryId para UID: $userId");
   try {
     await _usersCollection // Usar la referencia correcta
         .doc(userId)
         .collection(_portfolioCategoriesCollection)
         .doc(categoryId)
         .delete();
      if (kDebugMode) debugPrint("[FirestoreService] Categoría de PORTAFOLIO $categoryId eliminada exitosamente para UID: $userId");
   } catch (e) {
     debugPrint('[FirestoreService] Error al eliminar categoría de portafolio: $e');
     rethrow;
   }
 }

 Future<void> updatePortfolioCategoriesOrder(
     String userId, Map<String, int> newOrderMap) async {
      if (kDebugMode) debugPrint("[FirestoreService] Reordenando categorías de PORTAFOLIO para UID: $userId");
   try {
     final batch = _db.batch();
     final categoriesRef =
         _usersCollection // Usar la referencia correcta
             .doc(userId)
             .collection(_portfolioCategoriesCollection);

     newOrderMap.forEach((categoryId, newOrder) {
       batch.update(categoriesRef.doc(categoryId), {'order': newOrder});
     });

     await batch.commit();
      if (kDebugMode) debugPrint("[FirestoreService] Categorías de PORTAFOLIO reordenadas exitosamente en Firestore para UID: $userId");
   } catch (e) {
     debugPrint('[FirestoreService] Error al reordenar categorías de portafolio: $e');
     rethrow;
   }
 }

  // --- NUEVOS MÉTODOS PARA ITEMS DEL PORTAFOLIO ---
  // (Añadidos al final, usando _usersCollection correctamente)

  /// Obtiene un stream de los ítems del portafolio para una categoría específica, ordenados.
  Stream<List<PortfolioItemModel>> getPortfolioItemsStream(String userId, String categoryId) {
     if (kDebugMode) {
         debugPrint("[FirestoreService] Solicitando getPortfolioItemsStream UID: $userId CatID: $categoryId");
     }
    return _usersCollection // Usar la referencia correcta
        .doc(userId)
        .collection(_portfolioItemsCollection) // Usar la constante correcta
        .where('categoryId', isEqualTo: categoryId) // Filtrar por categoría
        .orderBy('order') // Ordenar por el campo 'order'
        .snapshots()
        .map((snapshot) {
           if (kDebugMode && snapshot.docs.isNotEmpty) debugPrint("[FirestoreService] getPortfolioItemsStream: ${snapshot.docs.length} ítems emitidos.");
           if (kDebugMode && snapshot.docs.isEmpty) debugPrint("[FirestoreService] getPortfolioItemsStream: No se encontraron ítems.");
           // Asegúrate que PortfolioItemModel.fromFirestore existe y es correcto
           return snapshot.docs
            .map((doc) => PortfolioItemModel.fromFirestore(doc))
            .toList();
        }).handleError((error){
             if (kDebugMode) debugPrint('[FirestoreService] !! ERROR en getPortfolioItemsStream UID: $userId CatID: $categoryId. Error: $error');
             return <PortfolioItemModel>[];
        });
  }

  /// Añade un nuevo ítem (foto o video) al portafolio de un usuario en una categoría específica.
  /// Calcula automáticamente el siguiente 'order'.
  Future<void> addPortfolioItem({
    required String userId,
    required String categoryId,
    required PortfolioItemType type, // Ahora debería ser reconocido
    required String url,
    String? caption,
  }) async {
    if (kDebugMode) debugPrint("[FirestoreService] addPortfolioItem UID: $userId CatID: $categoryId Type: $type");
    final itemsRef = _usersCollection // Usar la referencia correcta
        .doc(userId)
        .collection(_portfolioItemsCollection); // Usar la constante correcta

    try {
      // Obtener el último 'order' DENTRO DE ESA CATEGORÍA
      final querySnapshot = await itemsRef
          .where('categoryId', isEqualTo: categoryId)
          .orderBy('order', descending: true)
          .limit(1)
          .get();
      int nextOrder = 0;
      if (querySnapshot.docs.isNotEmpty) {
        nextOrder = (querySnapshot.docs.first.data()['order'] as int? ?? -1) + 1;
      }

      await itemsRef.add({
        'categoryId': categoryId,
        // Usar el enum PortfolioItemType aquí también
        'type': type == PortfolioItemType.video ? 'video' : 'image',
        'url': url,
        'order': nextOrder,
        'caption': caption,
        'createdAt': FieldValue.serverTimestamp(), // Opcional
      });
       if (kDebugMode) debugPrint("[FirestoreService] addPortfolioItem OK UID: $userId CatID: $categoryId Order: $nextOrder");
    } catch (e) {
        if (kDebugMode) debugPrint('[FirestoreService] !! ERROR addPortfolioItem UID: $userId CatID: $categoryId. Error: $e');
        rethrow;
    }
  }

  /// Elimina un ítem del portafolio.
  Future<void> deletePortfolioItem(String userId, String itemId) async {
    if (kDebugMode) debugPrint("[FirestoreService] deletePortfolioItem ItemID: $itemId UID: $userId");
    try {
      await _usersCollection // Usar la referencia correcta
          .doc(userId)
          .collection(_portfolioItemsCollection) // Usar la constante correcta
          .doc(itemId)
          .delete();
      if (kDebugMode) debugPrint("[FirestoreService] deletePortfolioItem OK ItemID: $itemId UID: $userId");
      // Considerar eliminar el archivo de Storage también usando la URL del ítem
    } catch (e) {
      if (kDebugMode) debugPrint("[FirestoreService] !! ERROR deletePortfolioItem ItemID: $itemId UID: $userId. Error: $e");
      rethrow;
    }
  }

  /// Actualiza el orden de múltiples ítems DENTRO de una categoría.
 Future<void> updatePortfolioItemsOrder(String userId, String categoryId, Map<String, int> newOrderMap) async {
     if (kDebugMode) debugPrint("[FirestoreService] updatePortfolioItemsOrder UID: $userId CatID: $categoryId");
    try {
      final batch = _db.batch();
      final itemsRef = _usersCollection // Usar la referencia correcta
          .doc(userId)
          .collection(_portfolioItemsCollection); // Usar la constante correcta

      newOrderMap.forEach((itemId, newOrder) {
        batch.update(itemsRef.doc(itemId), {'order': newOrder});
      });

      await batch.commit();
       if (kDebugMode) debugPrint("[FirestoreService] updatePortfolioItemsOrder OK UID: $userId CatID: $categoryId");
    } catch (e) {
       if (kDebugMode) debugPrint('[FirestoreService] !! ERROR updatePortfolioItemsOrder UID: $userId CatID: $categoryId. Error: $e');
       rethrow;
    }
  }

} // Fin de la clase FirestoreService

// --- ARCHIVO FICTICIO PARA IMPORT CONDICIONAL ---
// Necesitas crear un archivo vacío llamado 'firestore_service_web.dart'
// en la misma carpeta (lib/core/services) o usar un paquete como 'universal_io'.
// Contenido mínimo para firestore_service_web.dart:
// library firestore_service_web;
// class Platform { static String get operatingSystem => 'web'; }