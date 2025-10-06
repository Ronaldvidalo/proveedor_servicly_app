// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // CORRECCIÓN: Import necesario para User
import 'shared/theme/theme.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/auth/screens/auth_screen.dart'; // Importamos la pantalla de Auth
import 'core/services/auth_service.dart';

/// Punto de entrada principal de la aplicación Servicly.
void main() async {
  // Asegura que los widgets de Flutter estén inicializados.
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa Firebase.
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform, // Descomentar al usar FlutterFire CLI
  );
  
  // CORRECCIÓN: Se elimina 'const' porque el provider no es constante.
  runApp(const MyApp());
}

/// El widget raíz de la aplicación Servicly.
class MyApp extends StatelessWidget {
  /// Constructor para el widget raíz.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider inyecta los servicios en el árbol de widgets.
    return MultiProvider(
      providers: [
        // Provee la instancia de AuthService a toda la app.
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        
        // Escucha los cambios de estado de autenticación y provee el User.
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: 'Servicly',
        debugShowCheckedModeBanner: false,
        
        // --- Temas de la Aplicación ---
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        
        // --- Pantalla Inicial ---
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Un widget que decide qué pantalla mostrar basado en el estado de autenticación.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Escucha el stream de User? que provee el StreamProvider.
    final firebaseUser = context.watch<User?>();

    // Si hay un usuario, vamos a una pantalla principal (Placeholder por ahora).
    if (firebaseUser != null) {
      // TODO: Reemplazar con tu pantalla principal (HomeScreen).
      return const Scaffold(body: Center(child: Text('Home Screen')));
    }
    
    // Si no hay usuario, mostramos la pantalla de autenticación.
    // Podrías tener una lógica aquí para decidir si mostrar Onboarding o Auth.
    return const AuthScreen();
  }
}

