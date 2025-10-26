import 'package:flutter/material.dart';
import '../screens/auth_screen.dart';
// --- CORRECCIÓN: Importar IntroScreen en lugar de OnboardingScreen ---
import '../../onboarding/screens/intro_screen.dart'; // Corregido

/// Este widget gestiona el flujo para un usuario NO autenticado.
/// Muestra primero la Intro y luego la pantalla de Autenticación.
class UnauthenticatedGate extends StatefulWidget {
  const UnauthenticatedGate({super.key});

  @override
  State<UnauthenticatedGate> createState() => _UnauthenticatedGateState();
}

class _UnauthenticatedGateState extends State<UnauthenticatedGate> {
  // Ahora el estado controla si se debe mostrar la INTRO.
  bool _showIntro = true; 

  void _onIntroFinished() {
    setState(() {
      _showIntro = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showIntro) {
      // --- CORRECCIÓN: Llamar a IntroScreen con el callback correcto ---
      return IntroScreen(onFinished: _onIntroFinished);
    } else {
      // Una vez terminada la intro, se muestra la pantalla de autenticación.
      return const AuthScreen();
    }
  }
}

