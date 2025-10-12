/// lib/features/settings/screens/settings_screen.dart
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import 'brand_settings_screen.dart';

/// La "página matriz" de Configuración.
/// Actúa como un centro de mando para varias sub-pantallas de ajustes.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            children: [
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Personalizar mi Marca'),
                subtitle: const Text('Sube tu logo, elige tus colores y más.'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BrandSettingsScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('Gestionar Suscripción'),
                subtitle: const Text('Revisa tu plan actual y las opciones premium.'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Navegar a la pantalla de gestión de planes.
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                title: Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
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