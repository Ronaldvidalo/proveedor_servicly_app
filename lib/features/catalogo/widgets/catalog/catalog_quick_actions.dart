import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/features/booking/screens/booking_screen.dart';

class CatalogQuickActions extends StatelessWidget {
  final ProviderProfileModel profile;

  const CatalogQuickActions({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    // CORRECCIÓN 1: Usar los nuevos campos 'ratingAvg' y 'ratingCount' del modelo actualizado.
    // Como ya no son nulos (tienen valores por defecto en el modelo), la lógica es más simple.
    
    final String ratingText = profile.ratingAvg > 0
        ? profile.ratingAvg.toStringAsFixed(1)
        : 'Nuevo'; // O '5.0' si prefieres mantener el estilo anterior

    final String reviewCountText = profile.ratingCount > 0
        ? '(${profile.ratingCount} Reseñas)'
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
                      // CORRECCIÓN 2: Usar withValues(alpha: ...) en lugar de withOpacity (Deprecated)
                      shadowColor: profile.brandColor.withValues(alpha: 0.4),
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