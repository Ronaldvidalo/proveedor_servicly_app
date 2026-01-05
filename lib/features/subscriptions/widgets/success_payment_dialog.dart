import 'package:flutter/material.dart';
import '../../../../shared/theme/cyber_theme.dart';

class SuccessPaymentDialog extends StatelessWidget {
  final String planName;
  final VoidCallback onContinue;

  const SuccessPaymentDialog({
    super.key,
    required this.planName,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Color de éxito (Verde Neón en Dark, Verde Bosque en Light)
    final successColor = isDark 
        ? const Color(0xFF00FF7F) // Spring Green
        : const Color(0xFF007A33);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: successColor.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: CyberStyles.getGlow(context, color: successColor, isFocused: true),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono animado (simulado con Scale)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: successColor.withValues(alpha: 0.2),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: successColor,
                      size: 48,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              "¡PAGO EXITOSO!",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: successColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Bienvenido al plan $planName.\nTu cuenta ha sido actualizada correctamente.",
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: successColor,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("COMENZAR AHORA"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}