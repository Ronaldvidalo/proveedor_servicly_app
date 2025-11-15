import 'package:flutter/material.dart';

/// Un botón de icono de contacto reutilizable, estilizado.
class ContactIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const ContactIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00BFFF);
    
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: accentColor.withAlpha(100),
        highlightColor: accentColor.withAlpha(50),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accentColor.withAlpha(30), // Fondo suave
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withAlpha(50)),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}