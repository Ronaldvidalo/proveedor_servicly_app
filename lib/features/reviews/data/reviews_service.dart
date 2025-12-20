// 📍 Ubicación: lib/features/reviews/data/reviews_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

class ReviewsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Referencia a la colección
  CollectionReference get _reviewsRef => _db
      .collection('artifacts')
      .doc('servicly_v1')
      .collection('public')
      .doc('reviews')
      .collection('items');

  Future<void> sendReview(ReviewModel review) async {
    try {
      await _reviewsRef.add(review.toMap());
    } catch (e) {
      throw Exception("Error al enviar la reseña: $e");
    }
  }

  // Método opcional: Obtener reseñas de un usuario
  Stream<List<ReviewModel>> getUserReviews(String targetId) {
    return _reviewsRef
        .where('targetId', isEqualTo: targetId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return ReviewModel(
                id: doc.id,
                serviceId: data['serviceId'],
                authorId: data['authorId'],
                targetId: data['targetId'],
                role: data['role'],
                rating: data['rating'],
                tags: List<String>.from(data['tags']),
                comment: data['comment'] ?? '',
                // Conversión segura de Timestamp
                timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
              );
            }).toList());
  }
}