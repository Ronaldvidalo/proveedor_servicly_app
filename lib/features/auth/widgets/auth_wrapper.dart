// lib/features/auth/widgets/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../home/screens/home_screen.dart';
import '../../onboarding/screens/onboarding_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();

    if (firebaseUser != null) {
      // Si el usuario está logueado, va a la Home.
      return const HomeScreen();
    } else {
      // Si no, el punto de entrada para un nuevo usuario es el Onboarding.
      return const OnboardingScreen();
    }
  }
}