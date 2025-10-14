import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa el modelo de datos para un producto en la tienda de un proveedor.
class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final Timestamp createdAt;
  final Timestamp? expiryDate;
  final String imageUrl;

  // --- NUEVOS CAMPOS PARA PROMOCIONES ---
  final double? promoPrice;
  final String? promoText;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.createdAt,
    this.expiryDate,
    this.imageUrl = '',
    this.promoPrice,
    this.promoText,
  });

  /// Convierte un documento de Firestore a una instancia de [ProductModel].
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProductModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Sin Nombre',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      expiryDate: data['expiryDate'] as Timestamp?,
      imageUrl: data['imageUrl'] as String? ?? '',
      promoPrice: (data['promoPrice'] as num?)?.toDouble(),
      promoText: data['promoText'] as String?,
    );
  }

  /// Convierte la instancia del modelo a un mapa para guardarlo en Firestore.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'createdAt': createdAt,
      'expiryDate': expiryDate,
      'imageUrl': imageUrl,
      'promoPrice': promoPrice,
      'promoText': promoText,
    };
  }

  // --- GETTER DE CONVENIENCIA ---
  bool get isOnSale => promoPrice != null && promoPrice! > 0;
  
  bool get isExpired =>
      expiryDate != null && expiryDate!.toDate().isBefore(DateTime.now());
  bool get isExpiringSoon =>
      expiryDate != null &&
      !isExpired &&
      expiryDate!.toDate().difference(DateTime.now()).inDays <= 7;
}

