/// lib/features/home/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../profile/screens/create_profile_screen.dart';

/// La pantalla principal que se muestra después de que el usuario inicia sesión.
///
/// Es "inteligente": muestra contenido y habilita/restringe acciones
/// basándose en si el perfil del usuario está completo.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Navega a la pantalla para completar el perfil.
  void _navigateToCreateProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateProfileScreen()),
    );
  }

  /// Lógica para la acción protegida "Crear Presupuesto".
  void _onAttemptCreateQuote(BuildContext context) {
    // Usamos 'read' porque estamos dentro de un callback, no necesitamos reconstruir.
    final userModel = context.read<UserModel?>();

    // Verificamos si el perfil está completo.
    if (userModel?.isProfileComplete == true) {
      // Si está completo, procedemos con la acción.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Perfil completo! Navegando a la creación de presupuesto...'),
          backgroundColor: Colors.green,
        ),
      );
      // TODO: Navegar a la pantalla real de creación de presupuestos.
    } else {
      // Si no está completo, mostramos el diálogo de advertencia.
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Perfil Incompleto'),
            content: const Text(
                'Para crear presupuestos y usar todas las funciones, primero necesitas completar tu perfil.'),
            actions: [
              TextButton(
                child: const Text('Más Tarde'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Cierra el diálogo
                },
              ),
              ElevatedButton(
                child: const Text('Completar Perfil'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Cierra el diálogo
                  _navigateToCreateProfile(context); // Navega a la pantalla de perfil
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos 'watch' aquí para que la UI se reconstruya cuando cambien los datos del perfil.
    final userModel = context.watch<UserModel?>();
    final authService = context.read<AuthService>();

    // Mostramos un indicador de carga si aún no tenemos los datos del usuario.
    if (userModel == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicly - Inicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await authService.signOut();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- MENSAJE DE BIENVENIDA ---
          Text(
            // Usamos el displayName del perfil si existe, si no, un saludo genérico.
            '¡Hola, ${userModel.displayName ?? 'bienvenido'}!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),

          // --- BANNER DE PERFIL INCOMPLETO (Notificación Pasiva) ---
          // Este widget solo aparece si el perfil no está completo.
          if (!userModel.isProfileComplete)
            _ProfileCompletionBanner(
              onCompleteProfile: () => _navigateToCreateProfile(context),
            ),

          // --- ACCIONES PRINCIPALES ---
          const SizedBox(height: 16),
          Text(
            'Acciones Rápidas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Divider(height: 24),

          // --- BOTÓN DE ACCIÓN PROTEGIDA ---
          ElevatedButton.icon(
            icon: const Icon(Icons.add_card),
            label: const Text('Crear Presupuesto'),
            onPressed: () => _onAttemptCreateQuote(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          
          // Aquí irían otros botones de acción...
          // ElevatedButton(onPressed: () {}, child: Text('Ver Clientes')),
          // ElevatedButton(onPressed: () {}, child: Text('Agendar Cita')),
        ],
      ),
    );
  }
}

/// Widget privado para el banner que solicita completar el perfil.
class _ProfileCompletionBanner extends StatelessWidget {
  final VoidCallback onCompleteProfile;

  const _ProfileCompletionBanner({required this.onCompleteProfile});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceVariant,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Finaliza la configuración de tu cuenta',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
                'Completa tu perfil para poder generar contratos, presupuestos y más.'),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCompleteProfile,
                child: const Text('COMPLETAR AHORA'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}