import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa el modelo de datos UNIFICADO para un producto.
/// Sirve tanto para la Tienda Virtual (Cliente) como para el Inventario Inteligente (Proveedor).
class ProductModel {
  // --- CAMPOS ORIGINALES (TIENDA) ---
  final String id;
  final String name;
  final String description;
  final double price; // Precio de Venta al Público (PVP)
  final Timestamp createdAt;
  final Timestamp? expiryDate;
  final String imageUrl;
  final double? promoPrice;
  final String? promoText;
  final String? categoryId;
  final String providerId;
  final int? quantity; // Stock actual
  final List<Map<String, dynamic>> mediaGallery;

  // --- ¡CAMPOS NUEVOS (ESTRATEGIA B2B & COSTOS)! ---
  // Estos campos son invisibles para el cliente final, solo para el proveedor.
  
  /// Costo Variable: Cuánto te costó comprar o fabricar este ítem (sin contar fijos).
  final double costPrice; 
  
  /// Costo Fijo Snapshot: El valor del "Costo Fijo Unitario" en el momento que creaste el producto.
  /// Se guarda para saber cuánto margen real tenías históricamente.
  final double fixedCostSnapshot; 
  
  /// Precio para venta al por mayor (Revendedores).
  final double wholesalePrice; 
  
  /// Precio especial para Embajadores de marca.
  final double ambassadorPrice; 
  
  /// Nivel de stock donde se dispara la alerta "Poco Stock".
  final int minStock;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.createdAt,
    required this.providerId,
    this.expiryDate,
    this.imageUrl = '',
    this.promoPrice,
    this.promoText,
    this.categoryId,
    this.quantity,
    this.mediaGallery = const [],
    // Inicializamos los nuevos campos con 0 por defecto para compatibilidad con productos viejos
    this.costPrice = 0.0,
    this.fixedCostSnapshot = 0.0,
    this.wholesalePrice = 0.0,
    this.ambassadorPrice = 0.0,
    this.minStock = 5, 
  });

  /// Convierte un documento de Firestore a una instancia de [ProductModel].
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    final List<Map<String, dynamic>> gallery = (data['mediaGallery'] as List<dynamic>?)
            ?.map((item) => Map<String, dynamic>.from(item as Map))
            .toList() ??
        [];

    return ProductModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Sin Nombre',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      providerId: data['providerId'] as String? ?? '',
      expiryDate: data['expiryDate'] as Timestamp?,
      imageUrl: data['imageUrl'] as String? ?? '',
      promoPrice: (data['promoPrice'] as num?)?.toDouble(),
      promoText: data['promoText'] as String?,
      categoryId: data['categoryId'] as String?,
      quantity: data['quantity'] as int?,
      mediaGallery: gallery,
      
      // --- MAPEO DE NUEVOS CAMPOS ---
      // Usamos '?? 0.0' para que si el producto es viejo y no tiene estos datos, no falle.
      costPrice: (data['costPrice'] as num?)?.toDouble() ?? 0.0,
      fixedCostSnapshot: (data['fixedCostSnapshot'] as num?)?.toDouble() ?? 0.0,
      wholesalePrice: (data['wholesalePrice'] as num?)?.toDouble() ?? 0.0,
      ambassadorPrice: (data['ambassadorPrice'] as num?)?.toDouble() ?? 0.0,
      minStock: (data['minStock'] as num?)?.toInt() ?? 5,
    );
  }

  /// Convierte la instancia del modelo a un mapa para guardarlo en Firestore.
  Map<String, dynamic> toJson() {
    return {
      // Datos Tienda
      'name': name,
      'description': description,
      'price': price,
      'createdAt': createdAt,
      'providerId': providerId,
      'expiryDate': expiryDate,
      'imageUrl': imageUrl,
      'promoPrice': promoPrice,
      'promoText': promoText,
      'categoryId': categoryId,
      'quantity': quantity,
      'mediaGallery': mediaGallery,
      
      // Datos Estrategia (Nuevos)
      'costPrice': costPrice,
      'fixedCostSnapshot': fixedCostSnapshot,
      'wholesalePrice': wholesalePrice,
      'ambassadorPrice': ambassadorPrice,
      'minStock': minStock,
    };
  }

  // --- GETTERS DE CONVENIENCIA ORIGINALES ---
  bool get isOnSale => promoPrice != null && promoPrice! > 0;
  
  bool get isExpired =>
      expiryDate != null && expiryDate!.toDate().isBefore(DateTime.now());
      
  bool get isExpiringSoon =>
      expiryDate != null &&
      !isExpired &&
      expiryDate!.toDate().difference(DateTime.now()).inDays <= 7;

  bool get isInStock => quantity == null || quantity! > 0;
  
  bool get isOutOfStock => quantity != null && quantity! <= 0;

  // --- ¡NUEVOS GETTERS INTELIGENTES! ---

  /// Calcula el costo TOTAL real (Costo Variable + La carga de estructura de costos).
  double get costoTotalReal => costPrice + fixedCostSnapshot;

  /// Calcula el porcentaje de ganancia real sobre el precio público.
  /// Ejemplo: Si vendes a 100 y tu costo total es 70, margen es 0.30 (30%).
  double get margenGananciaPublico {
    if (price <= 0) return 0.0;
    return (price - costoTotalReal) / price;
  }

  /// Determina si el stock está en nivel crítico (por debajo del mínimo configurado).
  bool get isLowStock => quantity != null && quantity! <= minStock && quantity! > 0;
}