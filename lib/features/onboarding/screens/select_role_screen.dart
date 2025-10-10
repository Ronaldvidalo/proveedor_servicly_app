/// lib/features/onboarding/screens/select_role_screen.dart
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/firestore_service.dart';
import 'initial_config_screen.dart'; // Aún no existe, pero lo crearemos a continuación.

/// Pantalla donde el nuevo usuario elige su rol principal en la plataforma.
class SelectRoleScreen extends StatefulWidget {
  const SelectRoleScreen({super.key});

  @override
  State<SelectRoleScreen> createState() => _SelectRoleScreenState();
}

class _SelectRoleScreenState extends State<SelectRoleScreen> {
  bool _isLoading = false;

  /// Actualiza el rol del usuario en Firestore y navega al siguiente paso.
  Future<void> _selectRole(String role) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final firestoreService = context.read<FirestoreService>();
    final user = context.read<User?>();

    if (user == null) {
      // Manejo de seguridad, aunque es improbable llegar aquí.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Sesión de usuario no válida.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      await firestoreService.updateUser(user.uid, {'role': role});
      
      if (mounted) {
        // Una vez guardado el rol, vamos al siguiente paso del onboarding.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const InitialConfigScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el rol: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '¿Cómo usarás Servicly?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Elige tu rol principal. Podrás actuar como cliente más adelante si eres proveedor.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  Wrap(
                    spacing: 24.0, // Espacio horizontal
                    runSpacing: 24.0, // Espacio vertical
                    alignment: WrapAlignment.center,
                    children: [
                      _RoleCard(
                        icon: Icons.store_mall_directory_outlined,
                        title: 'Soy Proveedor',
                        subtitle: 'Quiero gestionar mi negocio, clientes y finanzas.',
                        onTap: () => _selectRole('provider'),
                      ),
                      _RoleCard(
                        icon: Icons.person_search_outlined,
                        title: 'Busco un Servicio',
                        subtitle: 'Quiero encontrar y contratar profesionales.',
                        onTap: () => _selectRole('client'),
                      ),
                      _RoleCard(
                        icon: Icons.sync_alt_rounded,
                        title: 'Ambas Opciones',
                        subtitle: 'Quiero gestionar mi negocio y también contratar servicios.',
                        onTap: () => _selectRole('both'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Un widget reutilizable para mostrar una tarjeta de selección de rol.
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 250,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Icon(icon, size: 48, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}