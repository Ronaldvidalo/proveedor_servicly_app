import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/features/booking/screens/booking_screen.dart';

class CatalogQuickActions extends StatelessWidget {
  final ProviderProfileModel profile;

  const CatalogQuickActions({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final String ratingText = profile.averageRating != null
        ? profile.averageRating!.toStringAsFixed(1)
        : '5.0';
    final String reviewCountText = profile.reviewCount != null && profile.reviewCount! > 0
        ? '(${profile.reviewCount} Reseñas)'
        : '(Sin Reseñas)';

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          children: [
            // --- Área de Rating Refinada ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.amber[600], size: 18),
                const SizedBox(width: 6),
                Text(
                  ratingText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  reviewCountText,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // --- Botón de Acción Principal Compacto y Estilizado ---
            // Eliminamos el double.infinity agresivo y damos un tamaño más armónico
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: profile.brandColor,
                      foregroundColor: ThemeData.estimateBrightnessForColor(profile.brandColor) == Brightness.dark 
                          ? Colors.white 
                          : Colors.black,
                      elevation: 4,
                      shadowColor: profile.brandColor.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25), // Bordes muy redondeados tipo pastilla
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => BookingScreen(providerId: profile.providerId),
                      ));
                    },
                    child: const Text(
                      'AGENDAR CITA AHORA',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}