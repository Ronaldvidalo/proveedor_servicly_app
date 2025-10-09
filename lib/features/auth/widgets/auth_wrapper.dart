// lib/features/auth/widgets/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_model.dart';
import '../../home/screens/home_screen.dart';
import '../../onboarding/screens/onboarding_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();
    print("--- AuthWrapper Build ---");

    if (firebaseUser != null) {
      print("--- AuthWrapper: firebaseUser is NOT NULL (UID: ${firebaseUser.uid}). Checking for userModel... ---");
      final userModel = context.watch<UserModel?>();

      if (userModel != null) {
        print("--- AuthWrapper: userModel is NOT NULL. Navigating to HomeScreen. ---");
        return const HomeScreen();
      } else {
        print("--- AuthWrapper: userModel is NULL. Showing loading screen... ---");
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
    } else {
      print("--- AuthWrapper: firebaseUser is NULL. Navigating to OnboardingScreen. ---");
      return const OnboardingScreen();
    }
  }
}