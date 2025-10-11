// lib/features/auth/widgets/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../onboarding/screens/select_role_screen.dart';
import '../../onboarding/screens/initial_config_screen.dart';
import '../../shell/provider_shell.dart';
import 'unauthenticated_gate.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();

    if (firebaseUser == null) {
      return const UnauthenticatedGate();
    } else {
      return StreamBuilder<UserModel?>(
        stream: context.read<FirestoreService>().getUserStream(firebaseUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            // Esto es importante para el flujo de registro. Muestra la carga
            // mientras se crea el documento en Firestore.
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          final userModel = snapshot.data!;
          
          // --- INICIO DE LA MODIFICACIÓN ---
          // Una vez que tenemos el userModel, lo proveemos al resto del árbol de widgets
          // que construiremos a continuación.
          return Provider<UserModel>.value(
            value: userModel,
            child: _buildScreenFromUserModel(userModel),
          );
          // --- FIN DE LA MODIFICACIÓN ---
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
          return const Scaffold(body: Center(child: Text('Client Shell')));
        default:
          return const SelectRoleScreen();
      }
    }
  }
}