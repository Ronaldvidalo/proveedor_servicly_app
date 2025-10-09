// lib/features/auth/widgets/unauthenticated_gate.dart

import 'package:flutter/material.dart';
import '../screens/auth_screen.dart';
import '../../onboarding/screens/onboarding_screen.dart';

/// Este widget gestiona el flujo para un usuario NO autenticado.
/// Decide si mostrar la pantalla de Onboarding (para la primera vez)
/// o la pantalla de Autenticación.
class UnauthenticatedGate extends StatefulWidget {
  const UnauthenticatedGate({super.key});

  @override
  State<UnauthenticatedGate> createState() => _UnauthenticatedGateState();
}

class _UnauthenticatedGateState extends State<UnauthenticatedGate> {
  // Por defecto, siempre mostramos el Onboarding al iniciar.
  bool _showOnboarding = true;

  /// Esta función se llama cuando el usuario termina el Onboarding.
  void _onOnboardingFinished() {
    setState(() {
      // Cambiamos el estado para que ahora se muestre la pantalla de Auth.
      _showOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      // Si debemos mostrar el Onboarding, lo construimos y le pasamos la función
      // que debe llamar cuando termine.
      return OnboardingScreen(onFinished: _onOnboardingFinished);
    } else {
      // Si el Onboarding ya terminó, mostramos la pantalla de Autenticación.
      return const AuthScreen();
    }
  }
}