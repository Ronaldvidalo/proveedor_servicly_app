import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/user_model.dart';
import '../../features/subscriptions/screens/subscription_screen.dart';

class PremiumGuard extends StatelessWidget {
  final Widget child;
  final String featureName; // Ej: "Estadísticas Avanzadas"

  const PremiumGuard({
    super.key,
    required this.child,
    this.featureName = "esta función",
  });

  @override
  Widget build(BuildContext context) {
    // Escuchamos el usuario reactivamente
    final user = context.watch<UserModel?>();
    final isPremium = user?.isPremium ?? false;

    // SI ES PREMIUM: Dejamos pasar (renderizamos el hijo)
    if (isPremium) {
      return child;
    }

    // SI ES FREE: Mostramos pantalla de bloqueo (Upsell)
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono de Candado
            Icon(
              Icons.lock_outline_rounded,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            
            Text(
              "Función Premium",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Actualiza tu plan para acceder a $featureName y desbloquear todo el potencial de Servicly.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            
            // Botón que lleva a la suscripción
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.star_rounded),
                label: const Text("MEJORAR MI PLAN"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}