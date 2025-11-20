import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/features/auth/widgets/auth_wrapper.dart'; // Ajusta si tu AuthWrapper está en otra ruta

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    // Configuración de la animación (Duración: 2 segundos)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Efecto de "Zoom In" suave
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Efecto de aparición (Fade In)
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    // Iniciar animación
    _controller.forward();

    // Navegar a la App principal después de 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // Usamos pushReplacement para que el usuario no pueda volver atrás al Splash
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const AuthWrapper(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Usamos el mismo color de fondo que configuraste en flutter_native_splash
    // para que la transición sea invisible.
    const backgroundColor = Color(0xFF1A1A2E); 

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          // Asegúrate de que esta ruta coincida con tu logo
          child: Image.asset(
            'assets/images/servicly_logo.png',
            width: 180, // Un poco más grande que el icono nativo para el efecto
            height: 180,
          ),
        ),
      ),
    );
  }
}