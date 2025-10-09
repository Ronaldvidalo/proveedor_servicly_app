/// lib/features/home/screens/home_screen.dart
library;

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
    final userModel = context.read<UserModel?>();

    if (userModel?.isProfileComplete == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Perfil completo! Navegando a la creación de presupuesto...'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating, // Estilo mejorado
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          margin: EdgeInsets.all(16),
        ),
      );
      // TODO: Navegar a la pantalla real de creación de presupuestos.
    } else {
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
                  Navigator.of(dialogContext).pop();
                },
              ),
              ElevatedButton(
                child: const Text('Completar Perfil'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _navigateToCreateProfile(context);
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
    // Ya no necesitamos la comprobación 'if (userModel == null)'
    // El AuthWrapper se encarga de eso por nosotros.
    final userModel = context.watch<UserModel?>()!; // Usamos '!' porque garantizamos que no será nulo.
    final authService = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        // UI Polish: AppBar más limpia que se integra con el fondo
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
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
      // --- INICIO MODIFICACIÓN RESPONSIVA 1: Contenido Centrado y Limitado ---
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960), // Ancho máximo del contenido principal
          child: ListView(
            padding: const EdgeInsets.all(24.0), // Padding aumentado para mejor espaciado
            children: [
              // --- MENSAJE DE BIENVENIDA ---
              Text(
                '¡Hola, ${userModel.displayName ?? 'bienvenido'}!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // --- BANNER DE PERFIL INCOMPLETO ---
              if (!userModel.isProfileComplete)
                _ProfileCompletionBanner(
                  onCompleteProfile: () => _navigateToCreateProfile(context),
                ),

              // --- ACCIONES PRINCIPALES ---
              const SizedBox(height: 24),
              Text(
                'Acciones Rápidas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Divider(height: 24),

              // --- INICIO MODIFICACIÓN RESPONSIVA 2: Grilla de Acciones Flexibles ---
              Wrap(
                spacing: 16.0,    // Espacio horizontal entre botones
                runSpacing: 16.0, // Espacio vertical entre filas de botones
                children: [
                  // Botón de Acción Protegida
                  _ActionCard(
                    title: 'Crear Presupuesto',
                    icon: Icons.add_card,
                    onTap: () => _onAttemptCreateQuote(context),
                  ),
                  // Otros botones de ejemplo
                  _ActionCard(
                    title: 'Ver Clientes',
                    icon: Icons.people_outline,
                    onTap: () { /* TODO */ },
                  ),
                   _ActionCard(
                    title: 'Agendar Cita',
                    icon: Icons.calendar_today_outlined,
                    onTap: () { /* TODO */ },
                  ),
                   _ActionCard(
                    title: 'Registrar Gasto',
                    icon: Icons.receipt_long_outlined,
                    onTap: () { /* TODO */ },
                  ),
                ],
              ),
              // --- FIN MODIFICACIÓN RESPONSIVA 2 ---
            ],
          ),
        ),
      ),
      // --- FIN MODIFICACIÓN RESPONSIVA 1 ---
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
      // UI Polish: Usamos el color primario con baja opacidad para un look más sutil
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3))
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Theme.of(context).primaryColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Finaliza la configuración de tu cuenta',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text('Completa tu perfil para poder generar contratos y presupuestos.'),
                ],
              ),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: onCompleteProfile,
              child: const Text('COMPLETAR'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- NUEVO WIDGET REUTILIZABLE PARA TARJETAS DE ACCIÓN ---
class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 160, // Ancho fijo para cada tarjeta
          height: 120, // Alto fijo para cada tarjeta
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}