// lib/features/auth/widgets/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../../core/models/user_model.dart';
import '../../home/screens/home_screen.dart';
import 'unauthenticated_gate.dart'; // <-- IMPORTAR NUEVO WIDGET

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();

    if (firebaseUser != null) {
      final userModel = context.watch<UserModel?>();
      if (userModel != null) {
        return const HomeScreen();
      } else {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
    } else {
      // Si el usuario no está logueado, mostramos nuestro gestor de estado "no autenticado".
      return const UnauthenticatedGate(); // <-- USAR NUEVO WIDGET
    }
  }
}