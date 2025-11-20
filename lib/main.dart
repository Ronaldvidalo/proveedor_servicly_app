// --- UX/UI Enhancement Comment ---
// This main.dart file has been updated to integrate the new dynamic
// ThemeService while respecting the existing Riverpod/Provider hybrid setup.
// 1. 'main()' now initializes and loads the ThemeService.
// 2. The old 'ThemeProvider' has been replaced with the new 'ThemeService'
//    in the MultiProvider list.
// 3. MaterialApp now consumes ThemeService and uses ThemeMode.system.
// 4. (NUEVO) Se ha integrado SplashScreen como pantalla de inicio.
// 5. (UX) Eliminada la solicitud automática de permisos de notificación al inicio.
// ---------------------------------

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
// Importamos el NUEVO provider de tema y el archivo de temas
import 'package:proveedor_servicly_app/core/services/theme_service.dart';
import 'package:proveedor_servicly_app/shared/theme/app_themes.dart';

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
import 'package:proveedor_servicly_app/core/services/follow_service.dart';
import 'package:proveedor_servicly_app/core/services/payment_service.dart';

// --- Modelos y ViewModels ---
import 'core/models/user_model.dart';
import 'core/viewmodels/cart_provider.dart';
import 'package:proveedor_servicly_app/core/services/order_service.dart';

// --- UI ---
import 'package:proveedor_servicly_app/features/splash/screens/splash_screen.dart'; 

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

  // --- UX: Solicitud de permisos ELIMINADA del inicio ---
  // Se solicitará contextualmente dentro de la app (Dashboard/Onboarding)
  // para mejorar la tasa de aceptación.
  
  // --- 1. Cargar el NUEVO servicio de tema ---
  final themeService = ThemeService();
  await themeService.loadTheme(); // Carga la paleta guardada por el usuario

  runApp(
    ProviderScope( // Mantenemos tu ProviderScope
      child: MyApp(themeService: themeService), // 2. Pasamos el servicio
    ),
  );
}

class MyApp extends StatelessWidget {
  // --- 2. Aceptamos el servicio ---
  final ThemeService themeService;
  const MyApp({super.key, required this.themeService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // --- 3. Añadimos el NUEVO ThemeService ---
        ChangeNotifierProvider.value(value: themeService),

        // --- PROVEEDORES DE SERVICIOS (Singletons) ---
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<ProductService>(create: (_) => ProductService()),
        Provider<CategoryService>(create: (_) => CategoryService()),
        Provider<AgendaService>(create: (_) => AgendaService()),
        Provider<OrderService>(create: (_) => OrderService()),
        Provider<VideoService>(create: (_) => VideoService()),
        Provider<FollowService>(create: (_) => FollowService()),
        Provider<PaymentService>(create: (_) => PaymentService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<AuthService>(
          create: (context) => AuthService(
            firestoreService: context.read<FirestoreService>(),
            firebaseMessaging: FirebaseMessaging.instance,
          ),
        ),
        ProxyProvider<FirestoreService, ProviderService>(
          update: (context, firestoreService, previousProviderService) =>
              ProviderService(firestoreService: firestoreService),
        ),

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

        ProxyProvider<UserModel?, PermissionsService>(
          update: (context, user, previousPermissions) {
            return PermissionsService(user ?? UserModel.empty());
          },
        ),

        // --- VIEWMODELS ADICIONALES ---
        ChangeNotifierProvider<CartProvider>(
          create: (_) => CartProvider(),
        ),
      ],
      // --- MODIFICACIÓN: Envolvemos MaterialApp en un Consumer ---
      // 4. Cambiamos de Consumer<ThemeProvider> a Consumer<ThemeService>
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'Servicly',
            debugShowCheckedModeBanner: false,
            // 5. Usamos los temas dinámicos de ThemeService
            theme: themeService.lightTheme,
            darkTheme: themeService.darkTheme,
            // 6. Usamos ThemeMode.system para el modo claro/oscuro automático
            themeMode: ThemeMode.system, 
            // 7. ¡NUEVO! Iniciamos con el Splash Screen animado
            home: const SplashScreen(), 
          );
        },
      ),
    );
  }
}