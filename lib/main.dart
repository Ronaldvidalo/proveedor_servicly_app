// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

import 'firebase_options.dart'; // MUY IMPORTANTE
import 'shared/theme/theme.dart';
import 'core/services/auth_service.dart';
import 'core/services/firestore_service.dart';
import 'core/models/user_model.dart';
import 'features/auth/widgets/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // MUY IMPORTANTE
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
        Provider<AuthService>(
          create: (context) => AuthService(
            firestoreService: context.read<FirestoreService>(),
          ),
        ),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
        StreamProvider<UserModel?>(
          initialData: null,
          create: (context) {
            final authService = context.read<AuthService>();
            final firestoreService = context.read<FirestoreService>();
            
            return authService.authStateChanges.switchMap((firebaseUser) {
              if (firebaseUser == null) {
                print("--- AuthWrapper: User is logged out. Emitting null UserModel. ---");
                return Stream.value(null);
              } else {
                print("--- AuthWrapper: User is logged in (${firebaseUser.uid}). Fetching UserModel stream... ---");
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