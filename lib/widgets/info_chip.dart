import 'package:flutter/material.dart';

/// Un widget de Chip compacto y estilizado ("Cyber Glow") para mostrar
/// información de contacto (teléfono, email, redes sociales).
class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00BFFF);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
            color: accentColor.withAlpha(20),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: accentColor.withAlpha(80))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accentColor, size: 14),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper para íconos de marcas que no están en Material por defecto
class IconsKE {
  static const IconData instagram = IconData(0xe49a, fontFamily: 'MaterialIcons');
}