// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

import 'firebase_options.dart';
import 'shared/theme/theme.dart';
import 'core/services/auth_service.dart';
import 'core/services/firestore_service.dart';
import 'core/models/user_model.dart';
import 'features/auth/widgets/auth_wrapper.dart';

/// Punto de entrada principal de la aplicación Servicly.
void main() async {
  // Asegura que los bindings de Flutter estén inicializados antes de cualquier
  // configuración asíncrona.
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase con la configuración específica de la plataforma.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

/// El widget raíz de la aplicación Servicly.
class MyApp extends StatelessWidget {
  /// Constructor para el widget raíz.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider inyecta todos los servicios y streams de datos necesarios
    // en la parte superior del árbol de widgets.
    return MultiProvider(
      providers: [
        // --- PROVEEDORES DE SERVICIOS ---

        // Provee una única instancia de FirestoreService a toda la aplicación.
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),

        // Provee AuthService, inyectándole la dependencia de FirestoreService.
        Provider<AuthService>(
          create: (context) => AuthService(
            firestoreService: context.read<FirestoreService>(),
          ),
        ),

        // --- STREAMS DE DATOS GLOBALES ---

        // Provee el estado de autenticación de Firebase (User?) en tiempo real.
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),

        // Provee el perfil de usuario de Firestore (UserModel?) en tiempo real.
        // Utiliza rxdart para cambiar de stream reactivamente: si el usuario
        // inicia sesión, escucha su documento; si cierra sesión, emite null.
        StreamProvider<UserModel?>(
          initialData: null,
          create: (context) {
            final authService = context.read<AuthService>();
            final firestoreService = context.read<FirestoreService>();

            return authService.authStateChanges.switchMap((firebaseUser) {
              if (firebaseUser == null) {
                // Si no hay usuario, emite un stream que contiene solo 'null'.
                return Stream.value(null);
              } else {
                // Si hay un usuario, cambia al stream de su perfil en Firestore.
                return firestoreService.getUserStream(firebaseUser.uid);
              }
            });
          },
        ),
      ],
      child: MaterialApp(
        title: 'Servicly',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        // El AuthWrapper ahora es el punto de entrada, decidiendo qué
        // pantalla mostrar (Onboarding, Auth, o Home).
        home: const AuthWrapper(),
      ),
    );
  }
}

