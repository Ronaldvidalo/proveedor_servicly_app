// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 14/10/2025
// Style: Cyber Glow
// This screen was refactored to align with the "Cyber Glow" design philosophy.
// It features a modern, card-based layout for each setting option, creating
// a visually appealing and intuitive command center for the user.
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import 'brand_settings_screen.dart';

/// La "página matriz" de Configuración.
/// Actúa como un centro de mando para varias sub-pantallas de ajustes.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final user = context.watch<UserModel?>();
    
    const backgroundColor = Color(0xFF1A1A2E);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            children: [
              _SettingsCard(
                icon: Icons.palette_outlined,
                title: 'Personalizar mi Marca',
                subtitle: 'Sube tu logo, elige tus colores y más.',
                onTap: () {
                  if (user != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BrandSettingsScreen(user: user),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error: No se pudo cargar la información del usuario.')),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                icon: Icons.star_outline_rounded,
                title: 'Gestionar Suscripción',
                subtitle: 'Revisa tu plan actual y las opciones premium.',
                onTap: () {
                  // TODO: Navegar a la pantalla de gestión de planes.
                },
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                icon: Icons.logout_rounded,
                title: 'Cerrar Sesión',
                isDestructive: true,
                onTap: () async {
                  await authService.signOut();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un widget reutilizable para mostrar una opción de configuración estilizada.
class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);
    final destructiveColor = Colors.redAccent.shade100;

    final color = isDestructive ? destructiveColor : accentColor;

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        // CORRECCIÓN: Se usa '.withAlpha()' en lugar de '.withOpacity()'.
        splashColor: color.withAlpha(51), // 0.2 opacity
        highlightColor: color.withAlpha(26), // 0.1 opacity
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDestructive ? destructiveColor : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ]
                  ],
                ),
              ),
              if (!isDestructive)
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
