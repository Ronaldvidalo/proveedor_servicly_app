import 'package:cloud_firestore/cloud_firestore.dart';

enum PortfolioItemType { image, video }

/// Modelo para un ítem (foto o video) del portafolio técnico.
class PortfolioItemModel {
  final String id;          
  final String categoryId;  
  final PortfolioItemType type; 
  final String url;         
  final int order;          
  final String? caption;    

  // --- CAMPOS DE INTERACCIÓN ---
  final int likeCount;      
  final List<String> likedBy; 
  final int viewCount;      

  // --- NUEVO CAMPO: SELECCIÓN PARA REPORTE ---
  final bool selectedForReport; // ✅ Decisión manual del usuario

  const PortfolioItemModel({
    required this.id,
    required this.categoryId,
    required this.type,
    required this.url,
    required this.order,
    this.caption,
    this.likeCount = 0,
    this.likedBy = const [],
    this.viewCount = 0,
    this.selectedForReport = false, // Por defecto no está en el reporte
  });

  factory PortfolioItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PortfolioItemModel.fromMap(data, doc.id);
  }

  factory PortfolioItemModel.fromMap(Map<String, dynamic> data, String documentId) {
    return PortfolioItemModel(
      id: documentId,
      categoryId: data['categoryId'] as String? ?? '',
      type: (data['type'] == 'video') ? PortfolioItemType.video : PortfolioItemType.image,
      url: data['url'] as String? ?? '',
      order: (data['order'] as num? ?? 0).toInt(),
      caption: data['caption'] as String?,
      likeCount: (data['likeCount'] as num? ?? 0).toInt(),
      likedBy: List<String>.from(data['likedBy'] as List<dynamic>? ?? []),
      viewCount: (data['viewCount'] as num? ?? 0).toInt(),
      selectedForReport: data['selectedForReport'] as bool? ?? false, // ✅ Mapeo
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'type': type == PortfolioItemType.video ? 'video' : 'image',
      'url': url,
      'order': order,
      'caption': caption,
      'likeCount': likeCount,
      'likedBy': likedBy,
      'viewCount': viewCount,
      'selectedForReport': selectedForReport, // ✅ Persistencia
    };
  }

  bool isLikedBy(String userId) => likedBy.contains(userId);

  PortfolioItemModel copyWith({
    String? id,
    String? categoryId,
    PortfolioItemType? type,
    String? url,
    int? order,
    String? caption,
    int? likeCount,
    List<String>? likedBy,
    int? viewCount,
    bool? selectedForReport,
  }) {
    return PortfolioItemModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      url: url ?? this.url,
      order: order ?? this.order,
      caption: caption ?? this.caption,
      likeCount: likeCount ?? this.likeCount,
      likedBy: likedBy ?? this.likedBy,
      viewCount: viewCount ?? this.viewCount,
      selectedForReport: selectedForReport ?? this.selectedForReport,
    );
  }
}