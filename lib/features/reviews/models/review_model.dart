import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String? id;
  final String serviceId;
  final String authorId;
  final String targetId;
  final String role; // 'PROVIDER' o 'CLIENT'
  final int rating;
  final List<String> tags;
  final String comment;
  final DateTime? timestamp;

  ReviewModel({
    this.id,
    required this.serviceId,
    required this.authorId,
    required this.targetId,
    required this.role,
    required this.rating,
    required this.tags,
    this.comment = '',
    this.timestamp,
  });

  /// Convierte el modelo a un Map para subirlo a Firebase
  Map<String, dynamic> toMap() {
    return {
      'orderId': serviceId,    // Mapeado a orderId en DB
      'clientId': authorId,     // Mapeado a clientId en DB
      'providerId': targetId,   // Mapeado a providerId en DB
      'role': role,
      'rating': rating,
      'tags': tags,
      'comment': comment,
      'createdAt': timestamp != null 
          ? Timestamp.fromDate(timestamp!) 
          : FieldValue.serverTimestamp(), //
    };
  }

  /// Factory para crear una instancia de ReviewModel desde un documento de Firestore
  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    // Verificamos que los datos no sean nulos
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ReviewModel(
      id: doc.id,
      // Mapeamos los nombres de los campos de tu Firebase
      serviceId: data['orderId'] ?? '',
      authorId: data['clientId'] ?? '',
      targetId: data['providerId'] ?? '',
      role: data['role'] ?? 'CLIENT',
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      comment: data['comment'] ?? '',
      // Convertimos el Timestamp de Firebase a DateTime de Dart
      timestamp: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Método para copiar el modelo con modificaciones (opcional, útil para estados)
  ReviewModel copyWith({
    String? id,
    String? serviceId,
    String? authorId,
    String? targetId,
    String? role,
    int? rating,
    List<String>? tags,
    String? comment,
    DateTime? timestamp,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      authorId: authorId ?? this.authorId,
      targetId: targetId ?? this.targetId,
      role: role ?? this.role,
      rating: rating ?? this.rating,
      tags: tags ?? this.tags,
      comment: comment ?? this.comment,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}