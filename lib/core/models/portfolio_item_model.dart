import 'package:cloud_firestore/cloud_firestore.dart';

enum PortfolioItemType { image, video }

/// Modelo para un ítem (foto o video) del portafolio.
class PortfolioItemModel {
  final String id; // ID del documento en Firestore
  final String categoryId; // ID de la categoría a la que pertenece
  final PortfolioItemType type; // 'image' o 'video'
  final String url; // URL del archivo en Firebase Storage
  final int order; // Para reordenar dentro de la categoría
  final String? caption; // Leyenda opcional <- Asegúrate que esté aquí

  PortfolioItemModel({
    required this.id,
    required this.categoryId,
    required this.type,
    required this.url,
    required this.order,
    this.caption, // <-- Asegúrate que esté aquí en el constructor
  });

  factory PortfolioItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PortfolioItemModel(
      id: doc.id,
      categoryId: data['categoryId'] as String? ?? '',
      type: (data['type'] == 'video') ? PortfolioItemType.video : PortfolioItemType.image,
      url: data['url'] as String? ?? '',
      order: data['order'] as int? ?? 0,
      caption: data['caption'] as String?, // <-- Añadir lectura aquí
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'type': type == PortfolioItemType.video ? 'video' : 'image',
      'url': url,
      'order': order,
      'caption': caption,
      // 'createdAt': FieldValue.serverTimestamp(), // Opcional
    };
  }
}