import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'shared/theme/theme.dart';
import 'core/services/auth_service.dart';
import 'core/services/firestore_service.dart';
import 'core/services/provider_service.dart';
import 'core/services/product_service.dart';
import 'core/services/storage_service.dart';
// --- NUEVA IMPORTACIÓN ---
import 'core/viewmodels/cart_provider.dart';
import 'features/auth/widgets/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<AuthService>(
          create: (context) => AuthService(
            firestoreService: context.read<FirestoreService>(),
          ),
        ),
        Provider<ProviderService>(
          create: (_) => ProviderService(),
        ),
        Provider<ProductService>(
          create: (_) => ProductService(),
        ),
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
        // --- MODIFICACIÓN CLAVE ---
        // Registramos el CartProvider como un ChangeNotifierProvider para que la UI
        // pueda escuchar sus cambios y reconstruirse automáticamente.
        ChangeNotifierProvider<CartProvider>(
          create: (_) => CartProvider(),
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

