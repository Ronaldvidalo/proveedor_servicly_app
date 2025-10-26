import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rxdart/rxdart.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart'; // Importante para kDebugMode
import 'package:cloud_firestore/cloud_firestore.dart'; // Necesario para Timestamp

// --- NUEVA IMPORTACIÓN ---
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'shared/theme/theme.dart';
import 'core/services/auth_service.dart';
import 'core/services/firestore_service.dart';
import 'core/services/provider_service.dart';
import 'core/services/product_service.dart';
import 'core/services/storage_service.dart';
import 'core/viewmodels/cart_provider.dart';
import 'core/services/category_service.dart';
import 'core/services/agenda_service.dart';
import 'core/models/user_model.dart';
import 'features/auth/widgets/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- INICIALIZAR APP CHECK ---
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    // appleProvider: AppleProvider.debug, // Descomentar para debug en simulador iOS
  );
  // -----------------------------

  // --- NUEVA LÓGICA: SOLICITAR PERMISOS DE NOTIFICACIÓN ---
  // (Esto no obtiene el token, solo pide permiso al usuario)
  try {
    final messaging = FirebaseMessaging.instance;
    // Solicitar permisos de notificación al usuario
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  } catch (e) {
    if (kDebugMode) {
      print('[main] Error al solicitar permisos de notificación: $e');
    }
  }
  // ----------------------------------------------------

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // --- PROVEEDORES DE SERVICIOS ---
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<AuthService>(
          create: (context) => AuthService(
            firestoreService: context.read<FirestoreService>(),
            // --- NUEVA INYECCIÓN DE DEPENDENCIA ---
            // Se pasa la instancia de FirebaseMessaging al AuthService
            firebaseMessaging: FirebaseMessaging.instance,
          ),
        ),
        Provider<ProviderService>(create: (_) => ProviderService()),
        Provider<ProductService>(create: (_) => ProductService()),
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<CategoryService>(create: (_) => CategoryService()),
        Provider<AgendaService>(create: (_) => AgendaService()),

        // --- PROVIDERS DE ESTADO/VIEWMODELS ---
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
        StreamProvider<UserModel?>(
          initialData: null,
          create: (context) {
            final authService = context.read<AuthService>();
            final firestoreService = context.read<FirestoreService>();

            if (kDebugMode) {
              print("[StreamProvider<UserModel>] Creando stream REAL...");
            }

            return authService.authStateChanges.switchMap((firebaseUser) {
              if (kDebugMode) {
                print("[StreamProvider<UserModel>] AuthState cambió. FirebaseUser UID: ${firebaseUser?.uid ?? 'null'}");
              }
              if (firebaseUser == null) {
                if (kDebugMode) {
                  print("[StreamProvider<UserModel>] Emitiendo Stream.value(null) porque firebaseUser es null.");
                }
                return Stream.value(null);
              } else {
                if (kDebugMode) {
                  print("[StreamProvider<UserModel>] Cambiando a firestoreService.getUserStream para UID: ${firebaseUser.uid}");
                }
                // (Se eliminan los logs de .listen() para limpiar la salida)
                return firestoreService.getUserStream(firebaseUser.uid);
              }
            });
          },
        ),
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

