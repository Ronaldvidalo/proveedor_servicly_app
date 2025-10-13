import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa el modelo de datos para un producto en la tienda de un proveedor.
class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final Timestamp createdAt;
  final Timestamp? expiryDate;

  // --- NUEVO CAMPO ---
  /// La URL pública de la imagen del producto almacenada en Firebase Storage.
  final String imageUrl;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.createdAt,
    this.expiryDate,
    this.imageUrl = '', // Valor por defecto para productos sin imagen.
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
      // Leemos el nuevo campo de la base de datos.
      imageUrl: data['imageUrl'] as String? ?? '',
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
      // Añadimos el nuevo campo para que se guarde en la base de datos.
      'imageUrl': imageUrl,
    };
  }

  // --- GETTERS DE CONVENIENCIA ---
  /// Verdadero si la fecha de vencimiento ya pasó.
  bool get isExpired =>
      expiryDate != null && expiryDate!.toDate().isBefore(DateTime.now());

  /// Verdadero si el producto está a 7 días o menos de vencer.
  bool get isExpiringSoon =>
      expiryDate != null &&
      !isExpired &&
      expiryDate!.toDate().difference(DateTime.now()).inDays <= 7;
}

