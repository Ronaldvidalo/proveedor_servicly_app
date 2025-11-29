// /lib/features/inventory/data/inventory_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart'; // <-- ¡IMPORTACIÓN AÑADIDA! (Para Uuid().v4())

// Importamos el alias de cloud_firestore para referenciar cloud_firestore.Timestamp
import 'package:cloud_firestore/cloud_firestore.dart' as cloud_firestore; 

// Modelos existentes y nuevos de SERVI
import 'package:proveedor_servicly_app/core/models/product_model.dart'; 
import 'package:proveedor_servicly_app/ai/model/ai_response_model.dart'; 
import 'package:proveedor_servicly_app/features/inventory/services/inventory_intelligence_service.dart';

class InventoryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final InventoryIntelligenceService _intelligenceService;

  // El constructor requiere las instancias de Firebase para la inyección de dependencias
  InventoryRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required InventoryIntelligenceService intelligenceService, // DI
  })  : _firestore = firestore,
        _auth = auth,
        _intelligenceService = intelligenceService;

  String? get _userId => _auth.currentUser?.uid;

  // ----------------------------------------------------------------------
  // --- OPERACIONES CRUD BÁSICAS DE PRODUCTO ---
  // ----------------------------------------------------------------------

  /// Obtiene el flujo de productos desde la COLECCIÓN RAÍZ 'products'
  Stream<List<ProductModel>> getProductsStream() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('products')
        .where('providerId', isEqualTo: _userId) // FILTRO VITAL por usuario
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
    
    // Después de guardar, monitoreamos para tareas de agenda (MVP 1.3)
    // Esto asegura que la alerta de stock o caducidad se dispare al guardar manual.
    await _intelligenceService.monitorAndSuggestTasks(product); 
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
  
  // ----------------------------------------------------------------------
  // --- FUNCIONALIDAD SERVI (OCR, ANALÍTICA y AGENDA) ---
  // ----------------------------------------------------------------------

  /// Obtiene el costo promedio histórico de un producto específico.
  Future<double> getHistoricalAverageCost(String productName) async {
    if (_userId == null) return 0.0;
    
    try {
      // Buscar productos por nombre exacto (se puede expandir a búsqueda fuzzy)
      final snapshot = await _firestore
          .collection('products')
          .where('providerId', isEqualTo: _userId)
          .where('name', isEqualTo: productName) 
          .limit(10) // Limita el scope a los últimos 10 registros para velocidad
          .get();
          
      if (snapshot.docs.isEmpty) return 0.0;

      // Calcular el promedio
      double totalCost = 0;
      int count = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final cost = (data['cost'] as num?)?.toDouble() ?? 0.0;
        if (cost > 0) {
          totalCost += cost;
          count++;
        }
      }
      return count > 0 ? totalCost / count : 0.0;
    } catch (e) {
      print("Error al calcular costo histórico: $e");
      return 0.0;
    }
  }

/// Obtiene el Costo Fijo Unitario actualmente calculado por el módulo de Estructura de Costo.
Future<double> getCurrentFixedCostSnapshot() async {
  if (_userId == null) return 0.0;
  
  try {
    final doc = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('settings')
        .doc('financial_config')
        .get();
        
    if (doc.exists && doc.data() != null) {
      // Usamos el campo que su módulo de costo calcula y almacena
      return (doc.data()!['costoFijoUnitarioCalculado'] as num?)?.toDouble() ?? 0.0;
    }
    return 0.0;
  } catch (e) {
    print("Error al leer el costo fijo actual: $e");
    return 0.0;
  }
}


  /// Mapea los items de la factura (LineItem) a sus modelos de inventario (ProductModel).
  List<ProductModel> _convertLineItemsToProducts({
        required Invoice invoice, 
        required double fixedCostSnapshot // Se recibe el valor real de la estructura
    }) {
    if (_userId == null) return [];
    final uuid = Uuid();

    return invoice.lineItems.map((item) {
      final quantity = item.quantity; 
      
      return ProductModel(
        id: uuid.v4(), // CORRECCIÓN: Usamos Uuid().v4()
        providerId: _userId!,
        name: item.description,
        description: 'Producto ingresado automáticamente desde factura N° ${invoice.invoiceNumber}. Proveedor: ${invoice.vendorName}',
        // ASUMIMOS PVP: Aquí puedes ajustar tu lógica de margen (ej: costo * 1.5)
        price: item.unitPrice * 1.5, 
        quantity: quantity,     
        cost: item.unitPrice,   
        sku: '', 
        category: 'Compra: ${invoice.vendorName}',
        // CORRECCIÓN: Usamos el valor real de la estructura de costos
        fixedCostSnapshot: fixedCostSnapshot, 
        imageUrl: '',
        createdAt: cloud_firestore.Timestamp.now(), 
      );
    }).toList();
  }

  /// Guarda la factura en la colección de auditoría y carga los items como productos.
  /// Este es el método llamado por la pantalla de escaneo.
  Future<void> saveInvoice(Invoice invoice) async {
    final userId = _userId;
    if (userId == null) {
      throw Exception("Usuario no autenticado. No se puede guardar la factura.");
    }
    
    // 0. OBTENER EL COSTO FIJO REAL ANTES DE CONVERTIR (Necesario para el ProductModel)
    final fixedCost = await getCurrentFixedCostSnapshot();

    // 1. Crear los objetos ProductModel a partir de los LineItems extraídos por Gemini
    final productsToUpload = _convertLineItemsToProducts(
        invoice: invoice, 
        fixedCostSnapshot: fixedCost,
    );

    // 2. Guardar los objetos ProductModel en la COLECCIÓN RAÍZ 'products'
    if (productsToUpload.isNotEmpty) {
        await uploadBulkProducts(productsToUpload);
    }
    
    // 3. Guardar el documento original de la factura para auditoría
    final auditRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('invoices');

    await auditRef.add(invoice.toFirestore());

    print("Factura ${invoice.invoiceNumber} guardada en auditoría y productos cargados.");
    
    // 4. ¡NUEVO! Monitoreo Inteligente de Agenda (MVP 1.3)
    // Analizamos cada nuevo producto para generar tareas de reabastecimiento/caducidad
    for (var product in productsToUpload) {
      // Llamamos al servicio inyectado
      await _intelligenceService.monitorAndSuggestTasks(product);
    }
  }
  
  /// CARGA MASIVA: Guarda una lista de productos en una sola operación (Batch)
  Future<void> uploadBulkProducts(List<ProductModel> products) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final batch = _firestore.batch();
    
    for (var product in products) {
      // Referencia al documento (Generamos ID si no tiene, o usamos el existente)
      final docRef = _firestore.collection('products').doc(product.id.isNotEmpty ? product.id : null);
      
      final data = product.toJson();
      
      batch.set(docRef, data, SetOptions(merge: true));
    }

    await batch.commit();
  }

  // ----------------------------------------------------------------------
  // --- HERRAMIENTA DE MIGRACIÓN (Utilidad existente) ---
  // ----------------------------------------------------------------------

  /// Función de migración (si es necesario)
  Future<void> migrarProductosARaiz() async {
    if (_userId == null) return;
    
    // 1. Leemos la colección antigua anidada
    final oldCollectionRef = _firestore
        .collection('tienda')
        .doc(_userId)
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
      data['providerId'] = _userId; 
      
      final newDocRef = newCollectionRef.doc(doc.id);
      batch.set(newDocRef, data, SetOptions(merge: true));
    }

    await batch.commit();
    print("¡Migración completada con éxito!");
  }
}
