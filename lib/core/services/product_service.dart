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
    return _db.collection('users').doc(userId).collection('products');
  }

  /// Obtiene un stream con la lista de productos de un proveedor.
  /// 
  /// Si se proporciona un [categoryId], filtrará los productos para mostrar
  /// solo los que pertenecen a esa categoría. Si [categoryId] es nulo o una
  /// cadena vacía, mostrará todos los productos.
  Stream<List<ProductModel>> getProducts(String userId, {String? categoryId}) {
    Query<Map<String, dynamic>> query = _productsCollection(userId);

    // Si se especifica una categoría, se aplica el filtro.
    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }
    
    // Siempre ordenamos por fecha de creación.
    return query.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
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

