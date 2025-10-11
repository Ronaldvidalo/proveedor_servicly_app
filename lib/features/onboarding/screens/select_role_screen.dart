// lib/features/onboarding/screens/select_role_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/firestore_service.dart';
// import 'initial_config_screen.dart'; // Ya no es necesario importar esto aquí.

// --- Placeholder para la siguiente pantalla (solo para que el proyecto compile si aún no la tienes) ---
// Si ya tienes 'initial_config_screen.dart' creado, puedes borrar este placeholder.


/// Pantalla donde el nuevo usuario elige su rol principal en la plataforma.
class SelectRoleScreen extends StatefulWidget {
  const SelectRoleScreen({super.key});

  @override
  State<SelectRoleScreen> createState() => _SelectRoleScreenState();
}

class _SelectRoleScreenState extends State<SelectRoleScreen> {
  // UX Improvement: Se maneja el estado de carga por rol.
  String? _loadingRole;

  /// Actualiza el rol del usuario en Firestore.
  /// El AuthWrapper se encargará de la navegación.
  Future<void> _selectRole(String role) async {
    if (_loadingRole != null) return;

    setState(() => _loadingRole = role);

    final firestoreService = context.read<FirestoreService>();
    final user = context.read<User?>();

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Sesión de usuario no válida.')),
      );
      setState(() => _loadingRole = null);
      return;
    }

    try {
      // CORRECCIÓN: La única misión de esta función es actualizar el rol.
      await firestoreService.updateUser(user.uid, {'role': role});
      
      // Se elimina el Navigator.of(context).pushReplacement(...);
      // El AuthWrapper detectará el cambio en el 'UserModel' y reconstruirá la UI
      // mostrando la 'InitialConfigScreen' automáticamente.
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el rol: $e')),
        );
        setState(() => _loadingRole = null);
      }
    }
    // No revertimos el estado de carga en caso de éxito, porque
    // el AuthWrapper reemplazará esta pantalla antes de que el usuario lo note.
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF00BFFF);
    const backgroundColor = Color(0xFF1A1A2E);
    const textColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '¿Cómo usarás la App?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Elige tu rol principal para personalizar tu experiencia.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Wrap(
                  spacing: 24.0,
                  runSpacing: 24.0,
                  alignment: WrapAlignment.center,
                  children: [
                    _RoleCard(
                      icon: Icons.store_mall_directory_outlined,
                      title: 'Soy Proveedor',
                      subtitle: 'Quiero gestionar mi negocio, clientes y finanzas.',
                      onTap: () => _selectRole('provider'),
                      isLoading: _loadingRole == 'provider',
                    ),
                    _RoleCard(
                      icon: Icons.person_search_outlined,
                      title: 'Busco un Servicio',
                      subtitle: 'Quiero encontrar y contratar profesionales.',
                      onTap: () => _selectRole('client'),
                      isLoading: _loadingRole == 'client',
                    ),
                    _RoleCard(
                      icon: Icons.sync_alt_rounded,
                      title: 'Ambas Opciones',
                      subtitle: 'Quiero gestionar mi negocio y también contratar servicios.',
                      onTap: () => _selectRole('both'),
                      isLoading: _loadingRole == 'both',
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

/// Un widget reutilizable y estilizado para mostrar una tarjeta de selección de rol.
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLoading;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);
    const textColor = Colors.white;

    return SizedBox(
      width: 280,
      child: Material(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        elevation: 5,
        shadowColor: primaryColor.withOpacity(0.3),
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: primaryColor.withOpacity(0.2),
          highlightColor: primaryColor.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isLoading
                      ? SizedBox(
                          key: const ValueKey('loader'),
                          height: 48,
                          width: 48,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          ),
                        )
                      : Icon(icon, key: const ValueKey('icon'), size: 48, color: primaryColor),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70
                      ),
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