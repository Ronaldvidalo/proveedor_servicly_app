/// lib/features/auth/widgets/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../home/screens/home_screen.dart';
import '../screens/auth_screen.dart';

/// Un widget que actúa como "guardián" de la autenticación.
///
/// Escucha los cambios en el estado de autenticación del usuario y muestra
/// la pantalla [HomeScreen] si el usuario está autenticado, o la
/// pantalla [AuthScreen] si no lo está.
class AuthWrapper extends StatelessWidget {
  /// Constructor para AuthWrapper.
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos context.watch<User?>() para escuchar el StreamProvider que
    // configuramos en main.dart. Cada vez que el estado de autenticación
    // cambie (login, logout), este widget se reconstruirá.
    final firebaseUser = context.watch<User?>();

    if (firebaseUser != null) {
      // Si el objeto User no es nulo, el usuario ha iniciado sesión.
      return const HomeScreen();
    } else {
      // Si el objeto User es nulo, nadie ha iniciado sesión.
      return const AuthScreen();
    }
  }
}