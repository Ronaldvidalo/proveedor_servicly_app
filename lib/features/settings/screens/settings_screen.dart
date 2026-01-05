// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 14/10/2025
// Style: Cyber Glow
// Updated: Integration with Subscription Module
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import 'brand_settings_screen.dart';

// IMPORTACIÓN NUEVA: Módulo de Suscripciones
// Ajusta la ruta si tus carpetas tienen nombres ligeramente diferentes
import '../../subscriptions/screens/subscription_screen.dart';

/// La "página matriz" de Configuración.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    // Escuchamos el usuario para (opcionalmente) mostrar su plan actual en el subtítulo
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
              
              // --- TARJETA DE SUSCRIPCIÓN CONECTADA ---
              _SettingsCard(
                icon: Icons.star_outline_rounded,
                title: 'Gestionar Suscripción',
                // Mejora UX: Mostramos el plan actual si existe el dato
                subtitle: user?.planType != null 
                    ? 'Plan actual: ${user!.planType.toUpperCase()}. Ver mejoras.' 
                    : 'Revisa tu plan actual y las opciones premium.',
                onTap: () {
                  // Navegación a la nueva pantalla Cyber Glow de suscripciones
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionScreen(),
                    ),
                  );
                },
              ),
              // -----------------------------------------

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
    super.key, // Uso de super.key para Dart moderno
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00BFFF); // Deep Sky Blue (Neon compatible)
    const surfaceColor = Color(0xFF2D2D5A);
    final destructiveColor = Colors.redAccent.shade100;

    final color = isDestructive ? destructiveColor : accentColor;

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        // Clean Code: withAlpha (0-255)
        splashColor: color.withAlpha(50), 
        highlightColor: color.withAlpha(25), 
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              // Efecto de brillo sutil en el icono
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (!isDestructive)
                      BoxShadow(
                        color: color.withAlpha(40),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                  ]
                ),
                child: Icon(icon, color: color, size: 28),
              ),
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
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
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