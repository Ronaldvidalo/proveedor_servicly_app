import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proveedor_servicly_app/core/models/category_model.dart';

/// Un servicio dedicado a gestionar las operaciones CRUD para las categorías de productos.
class CategoryService {
  final FirebaseFirestore _db;

  CategoryService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  /// Obtiene una referencia a la subcolección 'categories' de un usuario específico.
  CollectionReference<Map<String, dynamic>> _categoriesCollection(String userId) {
    return _db.collection('users').doc(userId).collection('categories');
  }

  /// Obtiene un stream con la lista de categorías de un usuario en tiempo real.
  Stream<List<CategoryModel>> getCategories(String userId) {
    return _categoriesCollection(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
    });
  }

  /// Añade una nueva categoría para un usuario.
  Future<void> addCategory(String userId, String categoryName) async {
    await _categoriesCollection(userId).add({'name': categoryName});
  }

  /// Actualiza el nombre de una categoría existente.
  Future<void> updateCategory(String userId, String categoryId, String newName) async {
    await _categoriesCollection(userId).doc(categoryId).update({'name': newName});
  }

  /// Elimina una categoría.
  /// (Nota: En una versión futura, necesitaremos lógica para manejar qué pasa
  /// con los productos que pertenecen a esta categoría).
  Future<void> deleteCategory(String userId, String categoryId) async {
    await _categoriesCollection(userId).doc(categoryId).delete();
  }
}
