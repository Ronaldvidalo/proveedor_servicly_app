// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'shared/theme/theme.dart';
import 'core/services/auth_service.dart';
import 'features/auth/widgets/auth_wrapper.dart'; // Importamos el AuthWrapper externo

/// Punto de entrada principal de la aplicación Servicly.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

/// El widget raíz de la aplicación Servicly.
class MyApp extends StatelessWidget {
  /// Constructor para el widget raíz.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
        // Ahora el home apunta correctamente al AuthWrapper que está en su propio archivo.
        home: const AuthWrapper(),
      ),
    );
  }
}