import 'package:flutter/material.dart';

/// Un botón reutilizable diseñado para entornos de desarrollo.
/// Se usa para navegar rápidamente a pantallas de prueba o nuevos diseños (Sandbox).
class DevNavigationButton extends StatelessWidget {
  final String label;
  final Widget destinationScreen;
  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const DevNavigationButton({
    super.key,
    required this.destinationScreen,
    this.label = '🚧 Ver Nuevo Diseño (Beta)',
    this.icon = Icons.science_outlined,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            // Por defecto usa colores "Terciarios" para destacar como algo especial/experimental
            backgroundColor: backgroundColor ?? colors.tertiaryContainer,
            foregroundColor: foregroundColor ?? colors.onTertiaryContainer,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: (foregroundColor ?? colors.onTertiaryContainer).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            elevation: 2,
          ),
          icon: Icon(icon),
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => destinationScreen),
            );
          },
        ),
      ),
    );
  }
}