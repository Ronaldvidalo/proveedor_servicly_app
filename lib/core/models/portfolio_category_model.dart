import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para una categoría del portafolio.
class PortfolioCategoryModel {
  final String id; // ID del documento en Firestore
  final String name;
  final int order; // Para reordenar

  PortfolioCategoryModel({
    required this.id,
    required this.name,
    required this.order,
  });

  factory PortfolioCategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PortfolioCategoryModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Sin Nombre',
      order: data['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'order': order,
    };
  }
}