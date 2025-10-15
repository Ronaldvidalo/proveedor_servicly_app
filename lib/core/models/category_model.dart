import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa el modelo de datos para una categoría de productos.
class CategoryModel {
  final String id;
  final String name;

  CategoryModel({
    required this.id,
    required this.name,
  });

  /// Crea una instancia de [CategoryModel] desde un documento de Firestore.
  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CategoryModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Sin Nombre',
    );
  }

  /// Convierte la instancia del modelo a un mapa para guardarlo en Firestore.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }
}
