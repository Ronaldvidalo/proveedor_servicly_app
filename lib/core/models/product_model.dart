import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa el modelo de datos para un producto en la tienda de un proveedor.
///
/// Actualizado para incluir gestión de inventario (quantity) y una
/// galería multimedia (mediaGallery) que soporta imágenes y videos.
class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final Timestamp createdAt;
  final Timestamp? expiryDate;
  
  /// La imagen principal o miniatura del producto.
  final String imageUrl; 
  
  final double? promoPrice;
  final String? promoText;
  final String? categoryId;

  // --- ¡CAMPO REQUERIDO AÑADIDO! ---
  // El ID del proveedor que es dueño de este producto.
  final String providerId;

  // --- ¡NUEVO CAMPO PARA INVENTARIO! ---
  /// La cantidad de stock disponible.
  /// Un valor 'null' puede significar "disponibilidad infinita" o "es un servicio".
  final int? quantity;

  // --- ¡NUEVO CAMPO PARA GALERÍA! ---
  /// Una lista de mapas que representa la galería de medios.
  final List<Map<String, dynamic>> mediaGallery;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.createdAt,
    required this.providerId, // <-- AÑADIDO
    this.expiryDate,
    this.imageUrl = '',
    this.promoPrice,
    this.promoText,
    this.categoryId,
    this.quantity, 
    this.mediaGallery = const [],
  });

  /// Convierte un documento de Firestore a una instancia de [ProductModel].
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Conversión segura para la galería de medios
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
      providerId: data['providerId'] as String? ?? '', // <-- AÑADIDO
      expiryDate: data['expiryDate'] as Timestamp?,
      imageUrl: data['imageUrl'] as String? ?? '',
      promoPrice: (data['promoPrice'] as num?)?.toDouble(),
      promoText: data['promoText'] as String?,
      categoryId: data['categoryId'] as String?,
      quantity: data['quantity'] as int?, 
      mediaGallery: gallery,
    );
  }

  /// Convierte la instancia del modelo a un mapa para guardarlo en Firestore.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'createdAt': createdAt,
      'providerId': providerId, // <-- AÑADIDO
      'expiryDate': expiryDate,
      'imageUrl': imageUrl,
      'promoPrice': promoPrice,
      'promoText': promoText,
      'categoryId': categoryId,
      'quantity': quantity,
      'mediaGallery': mediaGallery,
    };
  }

  // --- GETTERS DE CONVENIENCIA ---
  bool get isOnSale => promoPrice != null && promoPrice! > 0;
  
  bool get isExpired =>
      expiryDate != null && expiryDate!.toDate().isBefore(DateTime.now());
      
  bool get isExpiringSoon =>
      expiryDate != null &&
      !isExpired &&
      expiryDate!.toDate().difference(DateTime.now()).inDays <= 7;

  // --- ¡NUEVOS GETTERS DE INVENTARIO! ---
  
  /// Verdadero si el producto tiene stock.
  /// Si quantity es 'null', se asume que es un servicio o tiene stock infinito.
  bool get isInStock => quantity == null || quantity! > 0;
  
  /// Verdadero solo si el stock está explícitamente en 0 o menos.
  bool get isOutOfStock => quantity != null && quantity! <= 0;
}