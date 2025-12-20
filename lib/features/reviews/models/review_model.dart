// 📍 Ubicación: lib/features/reviews/models/review_model.dart
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

  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'authorId': authorId,
      'targetId': targetId,
      'role': role,
      'rating': rating,
      'tags': tags,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}