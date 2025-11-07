import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';

/// Un servicio dedicado a gestionar las operaciones CRUD para los productos
/// de un proveedor específico en Firestore.
class ProductService {
  final FirebaseFirestore _db;

  /// Crea una instancia de [ProductService].
  ProductService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  /// Obtiene una referencia a la subcolección 'products' de un usuario específico.
  CollectionReference<Map<String, dynamic>> _productsCollection(String userId) {
    // --- IMPORTANTE: RUTA DE DATOS ---
    // Tu servicio está apuntando a: 'users/{userId}/products'
    // ¡Asegúrate de que tus Reglas de Storage (para subir fotos)
    // también apunten a una ruta coherente!
    // (Actualmente tu StorageService apunta a 'products/{userId}/main_images')
    //
    // Para alinear todo, ¿deberíamos cambiar esto a:
    // return _db.collection('brandProfiles').doc(userId).collection('products');
    // Por ahora, lo dejo como lo tienes para que tu app siga funcionando.
    return _db.collection('users').doc(userId).collection('products');
  }

  /// Obtiene un stream con la lista de productos de un proveedor.
  ///
  /// Si se proporciona un [categoryId], filtrará los productos por esa categoría.
  /// Si se proporciona un [limit], limitará el número de resultados.
  Stream<List<ProductModel>> getProducts(
    String userId, {
    String? categoryId,
    int? limit, // <-- ¡PARÁMETRO AÑADIDO!
  }) {
    Query<Map<String, dynamic>> query =
        _productsCollection(userId).orderBy('createdAt', descending: true);

    // Si se especifica una categoría, se aplica el filtro.
    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    // --- ¡LÓGICA AÑADIDA! ---
    // Si se especifica un límite, se aplica a la consulta.
    if (limit != null && limit > 0) {
      query = query.limit(limit);
    }
    // --- FIN DE LA LÓGICA ---

    // El map final se aplica a la consulta ya modificada.
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Añade un nuevo producto a Firestore para un usuario específico.
  Future<void> addProduct(String userId, ProductModel product) async {
    await _productsCollection(userId).add(product.toJson());
  }

  /// Actualiza un producto existente en Firestore.
  Future<void> updateProduct(String userId, ProductModel product) async {
    await _productsCollection(userId).doc(product.id).update(product.toJson());
  }

  /// Elimina un producto de Firestore.
  Future<void> deleteProduct(String userId, String productId) async {
    await _productsCollection(userId).doc(productId).delete();
  }
}