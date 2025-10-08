// lib/features/auth/widgets/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/models/user_model.dart';
import '../../home/screens/home_screen.dart';
import '../../onboarding/screens/onboarding_screen.dart';
import '../../auth/screens/auth_screen.dart'; // Asegúrate de tener esta pantalla

/// Widget que actúa como un guardián de autenticación, decidiendo qué
/// pantalla mostrar basado en el estado del usuario de Auth y de Firestore.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos ambos streams: el de autenticación y el del perfil de usuario.
    final firebaseUser = context.watch<User?>();
    final userModel = context.watch<UserModel?>();

    // Lógica de decisión de navegación:
    if (firebaseUser != null) {
      // CASO 1: El usuario está autenticado en Firebase.
      // Ahora debemos esperar a que su perfil de Firestore esté disponible.
      if (userModel != null) {
        // PERFIL LISTO: El usuario de Auth y su perfil de Firestore existen.
        // Este es el único momento en que es seguro ir a HomeScreen.
        return const HomeScreen();
      } else {
        // ESPERANDO PERFIL: El usuario de Auth existe, pero su documento en
        // Firestore aún no ha sido creado o cargado. Mostramos una pantalla
        // de carga global para evitar el "salto" a HomeScreen.
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
    } else {
      // CASO 2: El usuario no está autenticado en Firebase.
      // Lo enviamos a la pantalla de autenticación.
      // La lógica de si mostrar Onboarding o Auth puede ir aquí.
      // Por simplicidad, asumimos que Onboarding lleva a Auth.
      return const OnboardingScreen();
    }
  }
}
