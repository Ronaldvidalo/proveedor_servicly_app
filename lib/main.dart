// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart'; // <-- 1. IMPORTAMOS RXDART

import 'shared/theme/theme.dart';
import 'core/services/auth_service.dart';
import 'core/services/firestore_service.dart'; // <-- 2. IMPORTAMOS FIRESTORESERVICE
import 'core/models/user_model.dart';           // <-- 2. IMPORTAMOS USERMODEL
import 'features/auth/widgets/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // --- SERVICIOS ---
        // 3. PROVEEMOS FIRESTORESERVICE PRIMERO
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
        // 4. ARREGLAMOS AUTHSERVICE PASÁNDOLE LA DEPENDENCIA
        Provider<AuthService>(
          create: (context) => AuthService(
            firestoreService: context.read<FirestoreService>(),
          ),
        ),

        // --- STREAMS DE DATOS GLOBALES ---
        // Este provider nos da el estado de autenticación (User de FirebaseAuth)
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
        
        // 5. NUEVO STREAMPROVIDER PARA EL PERFIL DE USUARIO (USERMODEL)
        // Este es el provider que nuestra UI usará para obtener los datos del perfil.
        StreamProvider<UserModel?>(
          initialData: null,
          create: (context) {
            final authService = context.read<AuthService>();
            final firestoreService = context.read<FirestoreService>();
            
            // Escuchamos el stream de autenticación.
            return authService.authStateChanges.switchMap((firebaseUser) {
              if (firebaseUser == null) {
                // Si el usuario cierra sesión, emitimos un stream con 'null'.
                return Stream.value(null);
              } else {
                // Si el usuario inicia sesión, cambiamos al stream de su documento
                // en Firestore para obtener el UserModel.
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
        home: const AuthWrapper(),
      ),
    );
  }
}