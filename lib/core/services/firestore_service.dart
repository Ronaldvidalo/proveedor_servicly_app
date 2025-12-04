import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb, debugPrint y defaultTargetPlatform

// --- IMPORTS DE MODELOS ---
import '../models/user_model.dart';
import '../models/module_model.dart';
import '../models/category_model.dart'; // Para categorías de PRODUCTOS
import '../models/portfolio_category_model.dart'; // Para categorías de PORTAFOLIO
import '../models/portfolio_item_model.dart'; // Para ítems de PORTAFOLIO
import '../models/provider_profile_model.dart'; // ¡NECESARIO PARA getCatalogData!

/// Servicio central para manejar Firestore (CRUD, streams, etc.)
class FirestoreService {
  final FirebaseFirestore _db;
  late final CollectionReference<Map<String, dynamic>> _usersCollection;
  late final CollectionReference<Map<String, dynamic>> _modulesCollection;

  // --- ¡NUEVA COLECCIÓN! ---
  late final CollectionReference<Map<String, dynamic>> _catalogsCollection;

  // --- Constantes para subcolecciones ---
  final String _portfolioCategoriesCollection = 'portfolio_categories';
  final String _portfolioItemsCollection = 'portfolio_items';
  final String _productCategoriesCollection = 'categories';

  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance {
    _usersCollection = _db.collection('users');
    _modulesCollection = _db.collection('modules');
    // --- ¡NUEVA! ---
    _catalogsCollection = _db.collection('catalogs');
  }

  // ------------------------------
  // MÉTODOS USUARIOS (Sin cambios)
  // ------------------------------

  /// Crea un nuevo documento de usuario en Firestore.
  Future<void> createUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(user.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists && doc.data() != null) {
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
    if (kDebugMode) {
      debugPrint("[FirestoreService] Iniciando getUserStream para UID: $uid");
    }
    return _usersCollection.doc(uid).snapshots().map((snapshot) {
      if (kDebugMode) {
        debugPrint(
            "[FirestoreService] getUserStream snapshot recibido para UID: $uid. Existe: ${snapshot.exists}");
      }
      if (snapshot.exists && snapshot.data() != null) {
        try {
          final userModel = UserModel.fromJson(snapshot.data()!);
          if (kDebugMode) {
            debugPrint(
                "[FirestoreService] getUserStream emitiendo UserModel para UID: $uid");
          }
          return userModel;
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                "[FirestoreService] !! ERROR al convertir snapshot a UserModel para UID: $uid. Error: $e");
          }
          return null;
        }
      } else {
        if (kDebugMode) {
          debugPrint(
              "[FirestoreService] getUserStream emitiendo NULL para UID: $uid (Documento no existe)");
        }
        return null;
      }
    }).handleError((error) {
      if (kDebugMode) {
        debugPrint(
            "[FirestoreService] !! ERROR en el stream de snapshots para UID: $uid. Error: $error");
      }
      return null;
    });
  }

  /// Obtiene una única instantánea (snapshot) del documento del usuario.
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDocument(String uid) {
    if (kDebugMode) {
      debugPrint(
          "[FirestoreService] Solicitando getUserDocument (get) para UID: $uid");
    }
    return _usersCollection.doc(uid).get();
  }

  /// Actualiza los datos de un documento de usuario existente.
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    if (kDebugMode) {
      debugPrint(
          "[FirestoreService] Intentando actualizar usuario UID: $uid con datos: $data");
    }
    try {
      await _usersCollection.doc(uid).update(data);
      if (kDebugMode) {
        debugPrint(
            "[FirestoreService] Usuario ACTUALIZADO exitosamente para UID: $uid");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[FirestoreService] !! ERROR al actualizar usuario UID: $uid. Error: $e');
      }
      rethrow;
    }
  }

  // ------------------------------
  // MÉTODOS MÓDULOS (Sin cambios)
  // ------------------------------

  Future<List<ModuleModel>> getAvailableModules() async {
    // ... (código sin cambios) ...
    if (kDebugMode) {
      debugPrint("[FirestoreService] Solicitando getAvailableModules (Future)");
    }
    try {
      final snapshot =
          await _modulesCollection.orderBy('defaultOrder').get(); // Asumimos orden

      if (snapshot.docs.isEmpty) {
        if (kDebugMode) {
          debugPrint(
              "[FirestoreService] getAvailableModules: No se encontraron módulos.");
        }
        return [];
      }
      if (kDebugMode) {
        debugPrint(
            "[FirestoreService] getAvailableModules: ${snapshot.docs.length} módulos encontrados.");
      }
      return snapshot.docs.map((doc) => ModuleModel.fromFirestore(doc)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FirestoreService] !! ERROR al obtener availableModules: $e');
      }
      rethrow;
    }
  }

  Future<void> setPublicProfileTemplate({
    required String userId,
    required String templateId,
  }) async {
    // ... (código sin cambios) ...
    if (kDebugMode) {
      debugPrint(
          "[FirestoreService] Solicitando setPublicProfileTemplate para UID: $userId con templateId: $templateId");
    }
    try {
      await _usersCollection.doc(userId).update({
        'publicProfileCreated': true,
        'publicProfileTemplate': templateId,
      });
      if (kDebugMode) {
        debugPrint(
            "[FirestoreService] publicProfileTemplate ACTUALIZADO para UID: $userId");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[FirestoreService] !! ERROR al actualizar publicProfileTemplate para UID: $userId. Error: $e');
      }
      rethrow;
    }
  }

  // ------------------------------
  // CATEGORÍAS DE PRODUCTOS (Sin cambios)
  // ------------------------------

  Stream<List<CategoryModel>> getCategoriesStream(String uid) {
    if (kDebugMode) {
      debugPrint(
          "[FirestoreService] Solicitando getCategoriesStream (PRODUCTOS) para UID: $uid");
    }
    try {
      return _usersCollection
          .doc(uid)
          .collection(_productCategoriesCollection)
          .orderBy('order')
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty) {
          if (kDebugMode) {
            debugPrint(
                "[FirestoreService] getCategoriesStream (PRODUCTOS): No se encontraron categorías para UID: $uid.");
          }
          return <CategoryModel>[]; // Devolver lista vacía tipada
        }
        if (kDebugMode) {
          debugPrint(
              "[FirestoreService] getCategoriesStream (PRODUCTOS): ${snapshot.docs.length} categorías emitidas para UID: $uid.");
        }
        return snapshot.docs
            .map((doc) => CategoryModel.fromFirestore(doc))
            .toList();
      }).handleError((error) {
        if (kDebugMode) {
          debugPrint(
              '[FirestoreService] !! ERROR en getCategoriesStream (PRODUCTOS) para UID: $uid. Error: $error');
        }
        return <CategoryModel>[];
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[FirestoreService] !! ERROR al configurar getCategoriesStream (PRODUCTOS) para UID: $uid. Error: $e');
      }
      return Stream.value(<CategoryModel>[]).handleError((_) => throw e);
    }
  }

  Future<void> addCategory(String userId, String name) async {
    if (kDebugMode) {
      debugPrint(
          "[FirestoreService] Intentando añadir categoría de PRODUCTO '$name' para UID: $userId");
    }
    try {
      final categoriesCollection =
          _usersCollection.doc(userId).collection(_productCategoriesCollection);
      final currentCategories =
          await categoriesCollection.orderBy('order', descending: true).limit(1).get();
      final nextOrder = currentCategories.docs.isEmpty
          ? 0
          : (currentCategories.docs.first.data()['order'] as int? ?? -1) + 1;
      await categoriesCollection.add({'name': name, 'order': nextOrder});
      if (kDebugMode) {
        debugPrint(
            "[FirestoreService] Categoría de PRODUCTO '$name' añadida exitosamente para UID: $userId con orden $nextOrder");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FirestoreService] !! ERROR al añadir categoría de PRODUCTO: $e');
      }
      rethrow;
    }
  }

  Future<void> updateCategoryName(
      String userId, String categoryId, String newName) async {
    if (kDebugMode) {
      debugPrint(
          "[FirestoreService] Intentando actualizar categoría de PRODUCTO $categoryId a '$newName' para UID: $userId");
    }
    try {
      await _usersCollection
          .doc(userId)
          .collection(_productCategoriesCollection)
          .doc(categoryId)
          .update({'name': newName});
      if (kDebugMode) {
        debugPrint(
            "[FirestoreService] Categoría de PRODUCTO $categoryId actualizada exitosamente a '$newName' para UID: $userId");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[FirestoreService] !! ERROR al actualizar categoría de PRODUCTO: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteCategory(String userId, String categoryId) async {
    if (kDebugMode) {
      debugPrint(
          "[FirestoreService] Intentando eliminar categoría de PRODUCTO $categoryId para UID: $userId");
    }
    try {
      await _usersCollection
          .doc(userId)
          .collection(_productCategoriesCollection)
          .doc(categoryId)
          .delete();
      if (kDebugMode) {
        debugPrint(
            "[FirestoreService] Categoría de PRODUCTO $categoryId eliminada exitosamente para UID: $userId");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[FirestoreService] !! ERROR al eliminar categoría de PRODUCTO: $e');
      }
      rethrow;
    }
  }

  Future<void> reorderCategories(String userId, List<CategoryModel> currentList,
      int oldIndex, int newIndex) async {
    if (kDebugMode) {
      debugPrint(
          "[FirestoreService] Reordenando categorías de PRODUCTOS para UID: $userId de $oldIndex a $newIndex");
    }
    try {
      final batch = _db.batch();
      final categoriesCollection =
          _usersCollection.doc(userId).collection(_productCategoriesCollection);
      final List<CategoryModel> reorderedList = List.from(currentList);
      final item = reorderedList.removeAt(oldIndex);
      final int insertIndex = (newIndex > oldIndex) ? newIndex - 1 : newIndex;
      reorderedList.insert(insertIndex, item);
      for (int i = 0; i < reorderedList.length; i++) {
        batch.update(categoriesCollection.doc(reorderedList[i].id), {'order': i});
      }
      await batch.commit();
      if (kDebugMode) {
        debugPrint(
            "[FirestoreService] Categorías de PRODUCTOS reordenadas exitosamente en Firestore para UID: $userId");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[FirestoreService] !! ERROR al reordenar categorías de PRODUCTOS: $e');
      }
      rethrow;
    }
  }

  // ------------------------------
  // TOKEN FCM (CORREGIDO PARA WEB)
  // ------------------------------
  Future<void> saveDeviceToken(
      {required String uid, required String token}) async {
    if (kDebugMode) {
      debugPrint("[FirestoreService] Guardando token FCM para UID: $uid");
    }
    try {
      final tokensCollection = _usersCollection.doc(uid).collection('tokens');
      String platformIdentifier = 'unknown';

      // --- CAMBIO APLICADO: Uso de kIsWeb y defaultTargetPlatform ---
      if (kIsWeb) {
        platformIdentifier = 'web';
      } else {
        // defaultTargetPlatform es seguro para todas las plataformas
        platformIdentifier = defaultTargetPlatform.name;
      }

      await tokensCollection.doc(token).set({
        'createdAt': FieldValue.serverTimestamp(),
        'platform': platformIdentifier,
      });
      if (kDebugMode) {
        debugPrint(
            "[FirestoreService] Token FCM guardado exitosamente para plataforma: $platformIdentifier.");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FirestoreService] Error al guardar token FCM: $e');
      }
    }
  }

  // ================================================================
  // === ¡NUEVA SECCIÓN DE MÉTODOS PARA LA COLECCIÓN 'catalogs'! ===
  // ================================================================

  /// Escribe/sobrescribe el documento de catálogo de un proveedor.
  /// (Responde a 'setCatalogData')
  Future<void> setCatalogData(String userId, Map<String, dynamic> data) async {
    if (kDebugMode) {
      debugPrint("[FirestoreService] Guardando datos de catálogo para UID: $userId");
    }
    try {
      // Usamos SET (merge: true) para crear o sobrescribir
      // el documento de catálogo principal.
      await _catalogsCollection
          .doc(userId)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FirestoreService] !! ERROR al guardar datos de catálogo: $e');
      rethrow;
    }
  }

  /// Obtiene el documento de catálogo de un proveedor.
  /// (Usado por 'catalog_editor_screen' para cargar el perfil)
  Future<ProviderProfileModel?> getCatalogData(String userId) async {
    if (kDebugMode) {
      debugPrint(
          "[FirestoreService] Obteniendo catálogo desde 'catalogs' para UID: $userId");
    }
    try {
      final doc = await _catalogsCollection.doc(userId).get();
      if (doc.exists) {
        return ProviderProfileModel.fromFirestore(doc);
      }
      return null; // No existe catálogo
    } catch (e) {
      debugPrint('[FirestoreService] !! ERROR al obtener catálogo: $e');
      return null;
    }
  }

  // --- MÉTODOS DE PORTAFOLIO (Apuntando a 'catalogs') ---

  /// (Responde a 'getCatalogPortfolioCategoriesStream')
  Stream<List<PortfolioCategoryModel>> getCatalogPortfolioCategoriesStream(
      String userId) {
    if (kDebugMode) {
      debugPrint(
          "[FirestoreService] Solicitando getCatalogPortfolioCategoriesStream para UID: $userId");
    }
    return _catalogsCollection // <-- ¡CAMBIO!
        .doc(userId)
        .collection(_portfolioCategoriesCollection)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PortfolioCategoryModel.fromFirestore(doc))
            .toList())
        .handleError((error) {
      debugPrint(
          '[FirestoreService] Error en getCatalogPortfolioCategoriesStream: $error');
      return <PortfolioCategoryModel>[];
    });
  }

  /// (Responde a 'addCatalogPortfolioCategory')
  Future<void> addCatalogPortfolioCategory(String userId, String name) async {
    if (kDebugMode) {
      debugPrint(
          "[FirestoreService] Añadiendo categoría de PORTAFOLIO (catálogos) '$name' para UID: $userId");
    }
    try {
      final categoriesRef = _catalogsCollection // <-- ¡CAMBIO!
          .doc(userId)
          .collection(_portfolioCategoriesCollection);
      final querySnapshot =
          await categoriesRef.orderBy('order', descending: true).limit(1).get();
      int nextOrder = 0;
      if (querySnapshot.docs.isNotEmpty) {
        nextOrder =
            (querySnapshot.docs.first.data()['order'] as int? ?? -1) + 1;
      }
      await categoriesRef.add({
        'name': name,
        'order': nextOrder,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint(
          '[FirestoreService] Error al añadir categoría de portafolio (catálogos): $e');
      rethrow;
    }
  }

  /// (Responde a 'updateCatalogPortfolioCategory')
  Future<void> updateCatalogPortfolioCategory(
      String userId, String categoryId, String newName) async {
    if (kDebugMode) {
      debugPrint(
          "[FirestoreService] Actualizando categoría de PORTAFOLIO (catálogos) $categoryId a '$newName'");
    }
    try {
      await _catalogsCollection // <-- ¡CAMBIO!
          .doc(userId)
          .collection(_portfolioCategoriesCollection)
          .doc(categoryId)
          .update({'name': newName});
    } catch (e) {
      debugPrint(
          '[FirestoreService] Error al actualizar categoría de portafolio (catálogos): $e');
      rethrow;
    }
  }

  /// (Responde a 'deleteCatalogPortfolioCategory')
  Future<void> deleteCatalogPortfolioCategory(
      String userId, String categoryId) async {
    if (kDebugMode) {
      debugPrint(
          "[FirestoreService] Eliminando categoría de PORTAFOLIO (catálogos) $categoryId");
    }
    try {
      await _catalogsCollection // <-- ¡CAMBIO!
          .doc(userId)
          .collection(_portfolioCategoriesCollection)
          .doc(categoryId)
          .delete();
    } catch (e) {
      debugPrint(
          '[FirestoreService] Error al eliminar categoría de portafolio (catálogos): $e');
      rethrow;
    }
  }

  /// (Responde a 'updateCatalogPortfolioCategoriesOrder')
  Future<void> updateCatalogPortfolioCategoriesOrder(
      String userId, Map<String, int> newOrderMap) async {
    if (kDebugMode) {
      debugPrint(
          "[FirestoreService] Reordenando categorías de PORTAFOLIO (catálogos) para UID: $userId");
    }
    try {
      final batch = _db.batch();
      final categoriesRef = _catalogsCollection // <-- ¡CAMBIO!
          .doc(userId)
          .collection(_portfolioCategoriesCollection);

      newOrderMap.forEach((categoryId, newOrder) {
        batch.update(categoriesRef.doc(categoryId), {'order': newOrder});
      });
      await batch.commit();
    } catch (e) {
      debugPrint(
          '[FirestoreService] Error al reordenar categorías de portafolio (catálogos): $e');
      rethrow;
    }
  }

  // --- MÉTODOS DE ÍTEMS DE PORTAFOLIO (Apuntando a 'catalogs') ---

  /// (Responde a 'getCatalogPortfolioItemsStream')
  Stream<List<PortfolioItemModel>> getCatalogPortfolioItemsStream(
      String userId, String categoryId) {
    if (kDebugMode) {
      debugPrint(
          "[FirestoreService] Solicitando getCatalogPortfolioItemsStream UID: $userId CatID: $categoryId");
    }
    return _catalogsCollection // <-- ¡CAMBIO!
        .doc(userId)
        .collection(_portfolioItemsCollection)
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PortfolioItemModel.fromFirestore(doc))
          .toList();
    }).handleError((error) {
      if (kDebugMode) {
        debugPrint(
            '[FirestoreService] !! ERROR en getCatalogPortfolioItemsStream UID: $userId CatID: $categoryId. Error: $error');
      }
      return <PortfolioItemModel>[];
    });
  }

  /// (Responde a 'addCatalogPortfolioItem')
  Future<void> addCatalogPortfolioItem({
    required String userId,
    required String categoryId,
    required PortfolioItemType type,
    required String url,
    String? caption,
  }) async {
    if (kDebugMode) {
      debugPrint(
          "[FirestoreService] addCatalogPortfolioItem UID: $userId CatID: $categoryId Type: $type");
    }
    final itemsRef = _catalogsCollection // <-- ¡CAMBIO!
        .doc(userId)
        .collection(_portfolioItemsCollection);

    try {
      final querySnapshot = await itemsRef
          .where('categoryId', isEqualTo: categoryId)
          .orderBy('order', descending: true)
          .limit(1)
          .get();
      int nextOrder = 0;
      if (querySnapshot.docs.isNotEmpty) {
        nextOrder =
            (querySnapshot.docs.first.data()['order'] as int? ?? -1) + 1;
      }

      await itemsRef.add({
        'categoryId': categoryId,
        'type': type == PortfolioItemType.video ? 'video' : 'image',
        'url': url,
        'order': nextOrder,
        'caption': caption,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[FirestoreService] !! ERROR addCatalogPortfolioItem UID: $userId CatID: $categoryId. Error: $e');
      }
      rethrow;
    }
  }

  /// (Responde a 'deleteCatalogPortfolioItem')
  Future<void> deleteCatalogPortfolioItem(String userId, String itemId) async {
    if (kDebugMode) {
      debugPrint(
          "[FirestoreService] deleteCatalogPortfolioItem ItemID: $itemId UID: $userId");
    }
    try {
      await _catalogsCollection // <-- ¡CAMBIO!
          .doc(userId)
          .collection(_portfolioItemsCollection)
          .doc(itemId)
          .delete();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            "[FirestoreService] !! ERROR deleteCatalogPortfolioItem ItemID: $itemId UID: $userId. Error: $e");
      }
      rethrow;
    }
  }

  // --- MÉTODOS OBSOLETOS ---
  // (Estos apuntan a 'users' y ahora están deprecados)

  @deprecated
  Stream<List<PortfolioCategoryModel>> getPortfolioCategoriesStream(
      String userId) {
    debugPrint(
        "[FirestoreService] ADVERTENCIA: Usando método obsoleto getPortfolioCategoriesStream");
    return _usersCollection
        .doc(userId)
        .collection(_portfolioCategoriesCollection)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PortfolioCategoryModel.fromFirestore(doc))
            .toList())
        .handleError((error) {
      debugPrint(
          '[FirestoreService] Error en getPortfolioCategoriesStream (obsoleto): $error');
      return <PortfolioCategoryModel>[];
    });
  }

  @deprecated
  Stream<List<PortfolioItemModel>> getPortfolioItemsStream(
      String userId, String categoryId) {
    debugPrint(
        "[FirestoreService] ADVERTENCIA: Usando método obsoleto getPortfolioItemsStream");
    return _usersCollection
        .doc(userId)
        .collection(_portfolioItemsCollection)
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PortfolioItemModel.fromFirestore(doc))
          .toList();
    }).handleError((error) {
      if (kDebugMode) {
        debugPrint(
            '[FirestoreService] !! ERROR en getPortfolioItemsStream (obsoleto) UID: $userId CatID: $categoryId. Error: $error');
      }
      return <PortfolioItemModel>[];
    });
  }

  Future<void> setBrandProfile(String uid, Map<String, dynamic> data) async {
    // Apunta a la nueva colección 'brandProfiles'
    await _db
        .collection('brandProfiles')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  /// Obtiene un Stream del perfil de marca de un proveedor.
  /// Devuelve 'null' si el documento aún no existe.
  Stream<ProviderProfileModel?> getBrandProfile(String providerId) {
    return _db
        .collection('brandProfiles')
        .doc(providerId)
        .snapshots() // Escucha cambios en tiempo real
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        // Asumimos que tienes un factory 'fromFirestore' o 'fromMap'
        // Ajusta esto si tu factory se llama diferente (ej: ProviderProfileModel.fromMap(doc.data()!, doc.id))
        return ProviderProfileModel.fromFirestore(doc);
      } else {
        // Devuelve null si el perfil de marca aún no se ha creado
        return null;
      }
    });
  }

  // --- ¡MÉTODO NUEVO: ACTUALIZAR DISPONIBILIDAD! ---
  /// Actualiza la disponibilidad del proveedor para recibir trabajos (Switch "Disponible").
  Future<void> updateProviderAvailability(String uid, bool isAvailable) async {
    if (kDebugMode) {
      debugPrint(
          "[FirestoreService] Actualizando disponibilidad (isAvailable: $isAvailable) para UID: $uid");
    }
    try {
      // 1. Actualizar en 'users' (para lógica interna)
      await _usersCollection.doc(uid).update({'isAvailable': isAvailable});

      // 2. Actualizar en 'brandProfiles' (para el mapa público)
      await _db.collection('brandProfiles').doc(uid).set(
          {'isAvailable': isAvailable}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FirestoreService] Error al actualizar disponibilidad: $e');
    }
  }
} // Fin de la clase FirestoreService