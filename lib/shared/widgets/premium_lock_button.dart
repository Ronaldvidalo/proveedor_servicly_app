import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/user_model.dart';
import '../../features/subscriptions/screens/subscription_screen.dart';

class PremiumLockButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child; // El contenido normal del botón (ej: Texto "Generar IA")
  final String featureName;
  final ButtonStyle? style;

  const PremiumLockButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.featureName = "esta función premium",
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    // Escucha reactiva del usuario
    final user = context.watch<UserModel?>();
    
    // Verificación robusta (Premium o Corp)
    final isUnlocked = user != null && (user.isPremium || user.planType == 'corporate');

    return FilledButton(
      style: style ?? FilledButton.styleFrom(
        backgroundColor: isUnlocked ? null : Colors.grey.shade800, // Gris si está bloqueado
      ),
      onPressed: () {
        if (isUnlocked) {
          // Si es PRO, ejecuta la acción real
          onPressed();
        } else {
          // Si es FREE, muestra diálogo de Upsell
          _showUpsellDialog(context);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isUnlocked) ...[
            const Icon(Icons.lock_outline, size: 16, color: Colors.amberAccent),
            const SizedBox(width: 8),
          ],
          child,
        ],
      ),
    );
  }

  void _showUpsellDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 10),
            Text("Función Premium"),
          ],
        ),
        content: Text("El acceso a $featureName está reservado para miembros Pro."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Quizás luego"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Navegar a la pantalla de suscripción
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
            child: const Text("DESBLOQUEAR AHORA"),
          ),
        ],
      ),
    );
  }
}