// lib/features/home/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';

/// La pantalla principal de la aplicación que se muestra después de que el
/// usuario ha iniciado sesión correctamente.
class HomeScreen extends StatelessWidget {
  /// Constructor para HomeScreen.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenemos la instancia de nuestro AuthService para poder llamar a signOut.
    final authService = context.read<AuthService>();

    // Escuchamos los cambios en el stream del usuario para obtener sus datos.
    // Usamos 'watch' aquí porque queremos que el widget se reconstruya si el
    // objeto de usuario cambia (aunque en esta pantalla es poco probable).
    final user = context.watch<User?>();

    return Scaffold(
      /// La barra de navegación superior de la pantalla.
      appBar: AppBar(
        title: const Text('Servicly'),
        actions: [
          // Botón para cerrar la sesión del usuario.
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              // Al presionar, llamamos al método signOut de nuestro servicio.
              // El StreamProvider se encargará de detectar el cambio de estado
              // y nuestro AuthWrapper nos redirigirá a la pantalla de login.
              await authService.signOut();
            },
          ),
        ],
      ),

      /// El cuerpo principal de la pantalla.
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¡Bienvenido!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            
            // Muestra el email del usuario si está disponible.
            // Esto confirma que el inicio de sesión fue exitoso y tenemos
            // acceso a los datos del usuario.
            Text(
              user?.email ?? 'No se pudo cargar el email',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}