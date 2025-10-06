// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'shared/theme/theme.dart';
import 'features/onboarding/screens/onboarding_screen.dart'; // Aún no existe, pero lo crearemos.

/// Punto de entrada principal de la aplicación Servicly.
///
/// Inicializa los bindings de Flutter y la conexión con Firebase
/// antes de ejecutar la aplicación.
void main() async {
  // Asegura que los widgets de Flutter estén inicializados antes de cualquier
  // configuración asíncrona.
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa Firebase. Es un paso crucial para conectar la app
  // con los servicios de backend.
  await Firebase.initializeApp(
    // Las opciones de configuración de Firebase (firebase_options.dart)
    // se suelen generar automáticamente con el CLI de FlutterFire.
    // options: DefaultFirebaseOptions.currentPlatform, 
  );
  
  runApp(const MyApp());
}

/// El widget raíz de la aplicación Servicly.
///
/// Configura el [MaterialApp] y provee los temas, el título y la pantalla
/// inicial. También establece el [MultiProvider] para la gestión de estado.
class MyApp extends StatelessWidget {
  /// Constructor para el widget raíz.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider es el widget que inyectará todos nuestros servicios y
    // view models a lo largo del árbol de widgets.
    return MultiProvider(
      providers: [
        // Aquí agregaremos nuestros providers globales.
        // Ejemplo:
        // Provider<AuthService>(create: (_) => AuthService()),
        // ChangeNotifierProvider<UserViewModel>(create: (_) => UserViewModel()),
      ],
      child: MaterialApp(
        title: 'Servicly',
        debugShowCheckedModeBanner: false, // Opcional: elimina el banner de debug.
        
        // --- Temas de la Aplicación ---
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system, // El tema se adapta al del sistema operativo.
        
        // --- Pantalla Inicial ---
        // Aquí definimos la primera pantalla que el usuario verá.
        // Empezaremos con la pantalla de Onboarding.
        home: const OnboardingScreen(),
      ),
    );
  }
}