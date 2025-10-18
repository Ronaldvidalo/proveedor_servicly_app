import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/features/home/screens/home_screen.dart';

import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../onboarding/screens/select_role_screen.dart';
import '../../onboarding/screens/initial_config_screen.dart';
import '../../shell/provider_shell.dart';
// --- MODIFICACIÓN ---
// Se reemplaza el 'gate' por la pantalla de autenticación principal.
import '../screens/auth_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();

    if (firebaseUser == null) {
      // --- MODIFICACIÓN ---
      // Se apunta a la pantalla de autenticación principal.
      return const AuthScreen();
    } else {
      return StreamBuilder<UserModel?>(
        stream: context.read<FirestoreService>().getUserStream(firebaseUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          final userModel = snapshot.data!;
          
          return Provider<UserModel>.value(
            value: userModel,
            child: _buildScreenFromUserModel(userModel),
          );
        },
      );
    }
  }

  /// Widget auxiliar para mantener la lógica de decisión limpia.
  Widget _buildScreenFromUserModel(UserModel userModel) {
    if (!userModel.isProfileComplete) {
      if (userModel.role == null) {
        return const SelectRoleScreen();
      } else {
        return InitialConfigScreen(userModel: userModel);
      }
    } else {
      switch (userModel.role) {
        case 'provider':
        case 'both':
          return const ProviderShell();
        case 'client':
          // --- MODIFICACIÓN CLAVE ---
          // Los clientes ahora son dirigidos a la HomeScreen (el marketplace).
          return const HomeScreen();
        default:
          return const SelectRoleScreen();
      }
    }
  }
}

