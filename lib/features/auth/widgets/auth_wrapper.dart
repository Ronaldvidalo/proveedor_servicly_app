/// lib/features/auth/widgets/auth_wrapper.dart
library;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../../core/models/user_model.dart';
import '../../onboarding/screens/select_role_screen.dart';
import '../../shell/provider_shell.dart'; // <-- 1. IMPORTAR EL NUEVO SHELL
import 'unauthenticated_gate.dart';

/// El widget "Director de Orquesta" de la aplicación.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();

    if (firebaseUser == null) {
      return const UnauthenticatedGate();
    } else {
      final userModel = context.watch<UserModel?>();

      if (userModel == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      if (!userModel.isProfileComplete) {
        return const SelectRoleScreen();
      } else {
        switch (userModel.role) {
          case 'provider':
          case 'both':
            // --- 2. USAR EL PROVIDERSHELL ---
            // Ahora, en lugar de una simple pantalla, cargamos el contenedor
            // principal de la interfaz de proveedor.
            return const ProviderShell(); 
          case 'client':
            // TODO: Reemplazar con el ClientShell cuando lo creemos.
            return const Scaffold(body: Center(child: Text('Client Shell')));
          default:
            return const SelectRoleScreen();
        }
      }
    }
  }
}