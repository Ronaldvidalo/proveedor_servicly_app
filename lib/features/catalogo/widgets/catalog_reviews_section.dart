import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- IMPORTS REQUERIDOS ---
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/features/reviews/models/review_model.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart'; // Solución al Error 1

class CatalogReviewsSection extends StatelessWidget {
  final ProviderProfileModel profile;

  const CatalogReviewsSection({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return StreamBuilder<List<ReviewModel>>(
      stream: firestoreService.getProviderReviews(profile.providerId),
      builder: (context, snapshot) {
        // 1. Estado de carga
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            )),
          );
        }

        // 2. Si no hay datos o la lista está vacía
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final reviews = snapshot.data!;

        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 0, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Opiniones Reales',
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 18, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: reviews.length,
                    itemBuilder: (context, index) => _ReviewCard(
                      review: reviews[index],
                      brandColor: profile.brandColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final Color brandColor;

  const _ReviewCard({required this.review, required this.brandColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Solución al Error 2: Reemplazo de withOpacity por withValues
        color: const Color(0xFF2D2D5A).withValues(alpha: 0.5), 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estrellas basadas en el rating del ReviewModel
          Row(
            children: List.generate(5, (index) => Icon(
              Icons.star,
              size: 14,
              color: index < review.rating ? Colors.amber : Colors.white12,
            )),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              review.comment.isEmpty ? "Sin comentario" : '"${review.comment}"',
              style: const TextStyle(
                color: Colors.white70, 
                fontSize: 13, 
                fontStyle: FontStyle.italic
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Cliente Verificado",
            style: TextStyle(
              color: Colors.white38, 
              fontSize: 10, 
              fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }
}