import 'package:flutter/material.dart';
import '../models/promotion_model.dart';

class GiftCardWidget extends StatelessWidget {
  final PromotionModel promo;
  const GiftCardWidget({super.key, required this.promo});

  @override
  Widget build(BuildContext context) {
    // Definición de gradientes según el estilo
    LinearGradient gradient;
    switch (promo.style?.toLowerCase()) {
      case 'gold':
        gradient = const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]);
        break;
      case 'love':
        gradient = const LinearGradient(colors: [Color(0xFFFF007F), Color(0xFFFF4B2B)]);
        break;
      case 'cyber':
      default:
        gradient = const LinearGradient(colors: [Color(0xFF00FFFF), Color(0xFFBD00FF)]);
        break;
    }

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: gradient.colors.first.withValues(alpha: 0.3), blurRadius: 10)],
      ),
      child: Stack(
        children: [
          Positioned(right: -20, top: -20, child: Icon(Icons.redeem, size: 100, color: Colors.white12)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("GIFT CARD", style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 4),
                    Text(promo.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  ],
                ),
                Text("\$${promo.promoPrice.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}