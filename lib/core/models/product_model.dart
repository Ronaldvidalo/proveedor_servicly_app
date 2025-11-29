// /lib/core/models/product_model.dart (VERSION FINAL Y ESTABLE)

import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  // --- CAMPOS BÁSICOS (USAN TIMESTAMP) ---
  final String id;
  final String name;
  final String description;
  final double price; // Precio de Venta al Público (PVP)
  final Timestamp createdAt; // Lo mantenemos como Timestamp
  final Timestamp? expiryDate;
  final String providerId;
  final int? quantity; // Stock actual
  final List<Map<String, dynamic>> mediaGallery;
    
  // --- CAMPOS DE TIENDA Y PROMOCIÓN ---
  final String imageUrl;
  final double? promoPrice;
  final String? promoText;
  final String? categoryId; // Categoría para la tienda (navegación)
  
  // --- CAMPOS NUEVOS DE INVENTARIO Y COSTOS (SERVI) ---
  final double cost; // <-- Costo variable (Antes costPrice)
  final String sku; // <-- SKU/Código
  final String category; // <-- Categoría de Inventario (Gestión)
  final double fixedCostSnapshot; // Costo Fijo Unitario
  final double wholesalePrice; 
  final double ambassadorPrice; 
  final int minStock;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.createdAt, // Es Timestamp
    required this.providerId,
    
    // **CAMPOS REQUERIDOS AÑADIDOS**
    required this.cost, 
    required this.sku, 
    required this.category,

    // Campos Opcionales/Por Defecto
    this.expiryDate,
    this.imageUrl = '',
    this.promoPrice,
    this.promoText,
    this.categoryId,
    this.quantity,
    this.mediaGallery = const [],
    
    // Campos de Estrategia B2B
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
            .toList() ?? [];

    // Mapeo Costo: Acepta 'costPrice' (viejo) o 'cost' (nuevo)
    final double mappedCost = (data['cost'] as num?)?.toDouble() 
                               ?? (data['costPrice'] as num?)?.toDouble() ?? 0.0;


    return ProductModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Sin Nombre',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(), // Timestamp
      providerId: data['providerId'] as String? ?? '',
      expiryDate: data['expiryDate'] as Timestamp?, // Timestamp
      imageUrl: data['imageUrl'] as String? ?? '',
      promoPrice: (data['promoPrice'] as num?)?.toDouble(),
      promoText: data['promoText'] as String?,
      categoryId: data['categoryId'] as String?,
      quantity: data['quantity'] as int?,
      mediaGallery: gallery,
      
      // --- MAPEO DE NUEVOS CAMPOS ---
      cost: mappedCost, // Usamos la variable mapeada
      sku: data['sku'] as String? ?? '',
      category: data['category'] as String? ?? 'General',
      
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
      'id': id,
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
      'cost': cost, // Usamos 'cost'
      'sku': sku,
      'category': category,
      'fixedCostSnapshot': fixedCostSnapshot,
      'wholesalePrice': wholesalePrice,
      'ambassadorPrice': ambassadorPrice,
      'minStock': minStock,
    };
  }

  // --- GETTERS DE CONVENIENCIA ORIGINALES ---
  bool get isOnSale => promoPrice != null && promoPrice! > 0;
  
  // CORRECCIÓN: Usamos .toDate() en los getters, ya que el campo es Timestamp.
  bool get isExpired => expiryDate != null && expiryDate!.toDate().isBefore(DateTime.now());
  	 
  bool get isExpiringSoon => expiryDate != null && !isExpired && expiryDate!.toDate().difference(DateTime.now()).inDays <= 7;

  bool get isInStock => quantity == null || quantity! > 0;
  bool get isOutOfStock => quantity != null && quantity! <= 0;

  // --- ¡NUEVOS GETTERS INTELIGENTES! ---
  // CORRECCIÓN: Usamos 'cost' en lugar de costPrice
  double get costoTotalReal => cost + fixedCostSnapshot; 

  double get margenGananciaPublico {
    if (price <= 0) return 0.0;
    return (price - costoTotalReal) / price;
  }

  bool get isLowStock => quantity != null && quantity! <= minStock && quantity! > 0;
}
