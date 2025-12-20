// 📍 Ubicación: lib/features/reviews/widgets/reputation_card.dart
import 'package:flutter/material.dart';
import '../../../shared/theme/cyber_theme.dart';

class ReputationCard extends StatelessWidget {
  final double ratingAvg;
  final int ratingCount;

  const ReputationCard({Key? key, required this.ratingAvg, required this.ratingCount}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color statusColor = getRatingColor(ratingAvg.round());

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          // Score Numérico
          Column(
            children: [
              Text(
                ratingAvg.toStringAsFixed(1),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  shadows: getGlow(statusColor),
                ),
              ),
              Text("$ratingCount reseñas", style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          SizedBox(width: 16),
          // Visualización Estrellas estáticas
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Reputación", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < ratingAvg.round() ? Icons.star : Icons.star_border,
                      color: index < ratingAvg.round() ? statusColor : Colors.grey[800],
                      size: 20,
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}