import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart'; // Asegúrate que esta ruta sea la de tu modelo fusionado

class InventoryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  InventoryRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  String? get _userId => _auth.currentUser?.uid;

  /// Obtiene el flujo de productos desde la COLECCIÓN RAÍZ 'products'
  /// Filtrando solo los que pertenecen a este usuario (providerId)
  Stream<List<ProductModel>> getProductsStream() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('products') // <--- ESTO APUNTA A LA RAÍZ (Correcto)
        .where('providerId', isEqualTo: _userId) // <--- FILTRO VITAL
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
    });
  }

  /// Guarda o Actualiza un producto en la raíz
  Future<void> saveProduct(ProductModel product) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    await _firestore
        .collection('products')
        .doc(product.id)
        .set(product.toJson(), SetOptions(merge: true));
  }

  /// Actualiza stock rápido
  Future<void> updateStock(String productId, int newQuantity) async {
    await _firestore
        .collection('products')
        .doc(productId)
        .update({'quantity': newQuantity});
  }

  /// Elimina producto
  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }
  
  // --- HERRAMIENTA DE MIGRACIÓN (SOLO PARA USAR UNA VEZ) ---
  // Esta función moverá tus datos viejos de 'tienda/.../products' a 'products' (raíz)
  Future<void> migrarProductosARaiz() async {
    if (_userId == null) return;
    
    // 1. Leemos la colección antigua anidada
    final oldCollectionRef = _firestore
        .collection('tienda')
        .doc(_userId) // Tu ID de tienda/usuario (asumo que es el mismo)
        .collection('products');
        
    final snapshot = await oldCollectionRef.get();
    
    if (snapshot.docs.isEmpty) {
      print("No hay productos antiguos para migrar.");
      return;
    }

    final batch = _firestore.batch();
    final newCollectionRef = _firestore.collection('products');

    print("Migrando ${snapshot.docs.length} productos a la raíz...");

    for (var doc in snapshot.docs) {
      final data = doc.data();
      // Aseguramos que tenga el providerId seteadas
      data['providerId'] = _userId; 
      
      // Referencia al nuevo documento en la raíz con el MISMO ID
      final newDocRef = newCollectionRef.doc(doc.id);
      
      // Añadimos al lote de escritura
      batch.set(newDocRef, data, SetOptions(merge: true));
    }

    // Ejecutamos la migración
    await batch.commit();
    print("¡Migración completada con éxito!");
  }

  /// CARGA MASIVA: Guarda una lista de productos en una sola operación (Batch)
  Future<void> uploadBulkProducts(List<ProductModel> products) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    // Firestore permite máximo 500 escrituras por Batch.
    // Si son más, habría que dividir la lista (chunking).
    // Por simplicidad, asumimos bloques de < 500 o hacemos un loop seguro.
    
    final batch = _firestore.batch();
    
    for (var product in products) {
      // Referencia al documento (Generamos ID si no tiene, o usamos el existente)
      final docRef = _firestore.collection('products').doc(product.id.isNotEmpty ? product.id : null);
      
      // Aseguramos que el providerId sea el correcto
      // (Aunque el modelo lo traiga, forzamos el del usuario actual por seguridad)
      final data = product.toJson();
      // Nota: product.toJson() ya debería incluir el providerId si el modelo fue creado correctamente
      
      batch.set(docRef, data, SetOptions(merge: true));
    }

    await batch.commit();
  }
}