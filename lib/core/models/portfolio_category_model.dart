import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para una categoría del portafolio técnico del proveedor.
class PortfolioCategoryModel {
  final String id;    // ID único del documento en Firestore
  final String name;  // Nombre de la categoría (ej: "Obras Civiles", "Inspecciones")
  final int order;    // Posición para el reordenamiento visual

  const PortfolioCategoryModel({
    required this.id,
    required this.name,
    required this.order,
  });

  /// Crea una instancia desde un DocumentSnapshot de Firestore.
  factory PortfolioCategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PortfolioCategoryModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Sin Nombre',
      order: (data['order'] as num? ?? 0).toInt(), // Conversión segura de num a int
    );
  }

  /// Crea una instancia desde un Mapa simple (útil para datos locales).
  factory PortfolioCategoryModel.fromMap(Map<String, dynamic> data, String documentId) {
    return PortfolioCategoryModel(
      id: documentId,
      name: data['name'] as String? ?? 'Sin Nombre',
      order: (data['order'] as num? ?? 0).toInt(),
    );
  }

  /// Convierte el modelo a un Mapa para guardar en Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'order': order,
    };
  }

  /// Permite crear una copia del modelo con campos específicos actualizados.
  /// Vital para la lógica de reordenamiento y edición rápida.
  PortfolioCategoryModel copyWith({
    String? id,
    String? name,
    int? order,
  }) {
    return PortfolioCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
    );
  }
}