// *** CORRECCIÓN ***
// Ocultamos los nombres que entran en conflicto con el paquete 'provider'
// 'ProviderScope' no está oculto, por lo que podemos seguir usándolo.
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider, StreamProvider, ChangeNotifierProvider, Consumer;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rxdart/rxdart.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart'; // Importante para kDebugMode

// --- Importaciones de Firebase ---
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

// --- MODIFICACIÓN: TEMA DE LA APP ---
// Importamos el NUEVO provider de tema
import 'package:proveedor_servicly_app/providers/theme_provider.dart';
// Se elimina la importación antigua: import 'shared/theme/theme.dart';

// --- Servicios Core ---
import 'core/services/auth_service.dart';
import 'core/services/firestore_service.dart';
import 'core/services/provider_service.dart';
import 'core/services/product_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/category_service.dart';
import 'core/services/agenda_service.dart';
import 'package:proveedor_servicly_app/core/services/permissions_service.dart';
import 'package:proveedor_servicly_app/core/services/video_service.dart';

// --- Modelos y ViewModels ---
import 'core/models/user_model.dart';
import 'core/viewmodels/cart_provider.dart';
import 'package:proveedor_servicly_app/core/services/order_service.dart';

// --- UI ---
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

  // --- LÓGICA: SOLICITAR PERMISOS DE NOTIFICACIÓN ---
  try {
    final messaging = FirebaseMessaging.instance;
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

  // *** CORRECCIÓN APLICADA AQUÍ ***
  // Faltaba envolver tu ProviderScope con runApp()
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // --- MODIFICACIÓN: AÑADIMOS EL THEME PROVIDER ---
        // Este provider debe estar en la lista para que el Consumer en DashboardScreen lo encuentre
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),

        // --- PROVEEDORES DE SERVICIOS (Singletons) ---

        // 1. Servicios que no dependen de nada
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<ProductService>(create: (_) => ProductService()),
        Provider<CategoryService>(create: (_) => CategoryService()),
        Provider<AgendaService>(create: (_) => AgendaService()),
        Provider<OrderService>(create: (_) => OrderService()),
        Provider<VideoService>(create: (_) => VideoService()),

        // 2. FirestoreService (necesario para los demás)
        Provider<FirestoreService>(create: (_) => FirestoreService()),

        // 3. Servicios que dependen de otros servicios
        Provider<AuthService>(
          create: (context) => AuthService(
            firestoreService: context.read<FirestoreService>(),
            firebaseMessaging: FirebaseMessaging.instance,
          ),
        ),

        // --- ¡CORRECCIÓN APLICADA AQUÍ! ---
        // ProviderService ahora DEPENDE de FirestoreService.
        // Usamos un ProxyProvider para "inyectar" FirestoreService.
        ProxyProvider<FirestoreService, ProviderService>(
          update: (context, firestoreService, previousProviderService) =>
              ProviderService(firestoreService: firestoreService),
        ),
        // La línea antigua "Provider<ProviderService>(create: (_) => ProviderService())," fue reemplazada.

        // --- PROVIDERS DE ESTADO (Streams Globales) ---
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
                print(
                    "[StreamProvider<UserModel>] AuthState cambió. FirebaseUser UID: ${firebaseUser?.uid ?? 'null'}");
              }
              if (firebaseUser == null) {
                if (kDebugMode) {
                  print(
                      "[StreamProvider<UserModel>] Emitiendo Stream.value(null) porque firebaseUser es null.");
                }
                return Stream.value(null);
              } else {
                if (kDebugMode) {
                  print(
                      "[StreamProvider<UserModel>] Cambiando a firestoreService.getUserStream para UID: ${firebaseUser.uid}");
                }
                return firestoreService.getUserStream(firebaseUser.uid);
              }
            });
          },
        ),

        // Servicio de Permisos (depende de UserModel)
        ProxyProvider<UserModel?, PermissionsService>(
          update: (context, user, previousPermissions) {
            // Si user es null (ej. al cerrar sesión), pasamos un UserModel vacío
            return PermissionsService(user ?? UserModel.empty());
          },
        ),

        // --- VIEWMODELS ADICIONALES ---
        ChangeNotifierProvider<CartProvider>(
          create: (_) => CartProvider(),
        ),
      ],
      // --- MODIFICACIÓN: Envolvemos MaterialApp en un Consumer ---
      // Esto permite que el tema de la app cambie cuando el ThemeProvider se lo indique.
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Servicly',
            debugShowCheckedModeBanner: false,
            // Usamos los temas definidos DENTRO del ThemeProvider
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            // El modo (claro/oscuro) es controlado por el estado del provider
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}