import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';

/// Un servicio dedicado a gestionar las operaciones CRUD para los productos.
///
/// ACTUALIZADO: Ahora utiliza la colección RAÍZ 'products' y filtra por 'providerId'.
class ProductService {
  final FirebaseFirestore _db;

  /// Crea una instancia de [ProductService].
  ProductService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  /// Referencia directa a la colección RAÍZ de productos.
  CollectionReference<Map<String, dynamic>> get _productsRef {
    return _db.collection('products');
  }

  /// Obtiene un stream con la lista de productos de un proveedor.
  Stream<List<ProductModel>> getProducts(
    String userId, {
    String? categoryId,
    int? limit,
  }) {
    // 1. Empezamos filtrando por el Dueño (providerId)
    Query<Map<String, dynamic>> query = _productsRef
        .where('providerId', isEqualTo: userId);

    // 2. Si hay categoría, agregamos ese filtro
    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    // 3. Ordenamos por fecha (Lo más nuevo primero)
    // NOTA: Esto requerirá crear un índice compuesto en Firebase la primera vez.
    query = query.orderBy('createdAt', descending: true);

    // 4. Limitamos si es necesario
    if (limit != null && limit > 0) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Obtiene un stream de productos FILTRADOS POR CATEGORÍA.
  Stream<List<ProductModel>> getProductsByCategory(String userId, String categoryId, {int? limit}) {
    Query<Map<String, dynamic>> query = _productsRef
        .where('providerId', isEqualTo: userId) // Filtro de seguridad
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('createdAt', descending: true);

    if (limit != null && limit > 0) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
    });
  }

  /// Añade un nuevo producto a Firestore (Colección Raíz).
  Future<void> addProduct(String userId, ProductModel product) async {
    // Aseguramos que el modelo tenga el providerId correcto antes de guardar
    // (Aunque el modelo ya debería tenerlo, esto es doble seguridad)
    final productData = product.toJson();
    productData['providerId'] = userId;

    // Usamos .set con el ID del producto para consistencia
    await _productsRef.doc(product.id).set(productData);
  }

  /// Actualiza un producto existente en Firestore.
  Future<void> updateProduct(String userId, ProductModel product) async {
    // Solo actualizamos si el ID existe en la raíz
    await _productsRef.doc(product.id).update(product.toJson());
  }

  /// Elimina un producto de Firestore.
  Future<void> deleteProduct(String userId, String productId) async {
    await _productsRef.doc(productId).delete();
  }
}