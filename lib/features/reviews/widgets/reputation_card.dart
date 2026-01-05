// 📍 Ubicación: lib/features/reviews/widgets/reputation_card.dart
import 'package:flutter/material.dart';
import '../../../shared/theme/cyber_theme.dart';

class ReputationCard extends StatelessWidget {
  final double ratingAvg;
  final int ratingCount;

  const ReputationCard({
    super.key, // Sintaxis moderna
    required this.ratingAvg, 
    required this.ratingCount
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // 1. CORRECCIÓN: Usamos CyberStyles pasando el contexto
    Color statusColor = CyberStyles.getRatingColor(context, ratingAvg.round());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // 2. CORRECCIÓN: Fondo dinámico (Card Color del tema)
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        // Borde sutil basado en el divisor del tema
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            // Sombra suave adaptativa (negra en dark, grisacea en light)
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10, 
            offset: const Offset(0, 4)
          )
        ],
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
                  // 3. CORRECCIÓN: Glow dinámico (Neón en Dark, Sombra en Light)
                  shadows: CyberStyles.getGlow(context, color: statusColor, isFocused: true),
                ),
              ),
              Text(
                "$ratingCount reseñas", 
                // 4. CORRECCIÓN: Color de texto secundario del tema
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.disabledColor
                )
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Visualización Estrellas estáticas
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Reputación", 
                  // 5. CORRECCIÓN: Texto principal legible en ambos modos
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold
                  )
                ),
                Row(
                  children: List.generate(5, (index) {
                    bool isActive = index < ratingAvg.round();
                    return Icon(
                      isActive ? Icons.star : Icons.star_border,
                      // 6. CORRECCIÓN: Color inactivo del tema (disabledColor)
                      color: isActive ? statusColor : theme.disabledColor,
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