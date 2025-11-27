// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 26/11/2025
// Style: Cyber Glow Integration
// ---------------------------------

// Ocultamos conflictos de nombres entre Riverpod y Provider
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider, StreamProvider, ChangeNotifierProvider, Consumer;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rxdart/rxdart.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart'; 

// --- Importaciones de Firebase ---
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

// --- SERVICIOS DE TEMA (NUEVO) ---
import 'package:proveedor_servicly_app/core/services/theme_service.dart';
// Nota: AppThemes se usa dentro de ThemeService, no es estrictamente necesario importarlo aquí
// a menos que uses AppPalette en el main, pero lo dejamos por si acaso.
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
import 'package:proveedor_servicly_app/core/services/order_service.dart';

// --- Modelos y ViewModels ---
import 'core/models/user_model.dart';
import 'core/viewmodels/cart_provider.dart';

// --- UI ---
import 'package:proveedor_servicly_app/features/splash/screens/splash_screen.dart'; 
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- INICIALIZAR APP CHECK ---
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  // --- 1. Cargar el NUEVO servicio de tema ---
  final themeService = ThemeService();
  await themeService.loadTheme(); // Carga la paleta guardada por el usuario

  runApp(
    ProviderScope( // Riverpod Scope
      child: MyApp(themeService: themeService), 
    ),
  );
}

class MyApp extends StatelessWidget {
  final ThemeService themeService;
  
  const MyApp({super.key, required this.themeService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // --- 2. Inyectamos el ThemeService actualizado ---
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
        Provider<CrmRepository>(create: (_) => CrmRepository()),
        
        Provider<AuthService>(create: (context) => AuthService(
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
            
            return authService.authStateChanges.switchMap((firebaseUser) {
              if (firebaseUser == null) {
                return Stream.value(null);
              } else {
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
      
      // --- 3. Consumimos el ThemeService para aplicar cambios en tiempo real ---
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'Servicly',
            debugShowCheckedModeBanner: false,
            
            // --- AQUÍ OCURRE LA MAGIA ---
            // Los temas vienen dinámicamente desde AppThemes a través del servicio
            theme: themeService.lightTheme, 
            darkTheme: themeService.darkTheme,
            
            // Permitimos que el sistema decida (o puedes forzarlo aquí)
            themeMode: ThemeMode.system, 
            
            home: const SplashScreen(), 
          );
        },
      ),
    );
  }
}