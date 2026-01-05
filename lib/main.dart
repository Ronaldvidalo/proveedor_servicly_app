// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 26/11/2025
// Style: Cyber Glow Integration
// Update: Integración completa de Módulos Presupuesto (Quotes), Inventario e IA
// Update: Integración de Notificaciones Push (Firebase Messaging) + Navegación Global
// Update: Implementación de Reactividad de Suscripciones (UserModel Stream)
// FIX: GeminiService Singleton Injection
// ---------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider, StreamProvider, ChangeNotifierProvider, Consumer;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // --- FIX WEB: Importante para kIsWeb
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

// --- Importaciones de Firebase ---
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'firebase_options.dart';

// --- SERVICIOS DE TEMA ---
import 'package:proveedor_servicly_app/core/services/theme_service.dart';

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
import 'package:proveedor_servicly_app/core/services/notification_service.dart'; 

// --- UTILIDADES ---
import 'package:proveedor_servicly_app/core/utils/global_navigation.dart'; 
import 'package:proveedor_servicly_app/core/services/availability_service.dart';

// --- Modelos y ViewModels ---
import 'core/models/user_model.dart';
import 'core/viewmodels/cart_provider.dart';
import 'package:proveedor_servicly_app/features/dashboard/models/dashboard_metrics_viewmodel.dart';

// --- UI ---
import 'package:proveedor_servicly_app/features/splash/screens/splash_screen.dart'; 
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart'; 

// --- MÓDULO DE INVENTARIO ---
import 'package:proveedor_servicly_app/features/inventory/data/inventory_repository.dart';
import 'package:proveedor_servicly_app/features/inventory/services/inventory_intelligence_service.dart';
import 'package:proveedor_servicly_app/features/agenda/data/repositories/agenda_repository.dart';

// --- MÓDULO DE PRESUPUESTOS (QUOTES) & IA ---
import 'package:proveedor_servicly_app/features/budget/repositories/quote_repository.dart';
import 'package:proveedor_servicly_app/features/budget/providers/quote_provider.dart';
import 'package:proveedor_servicly_app/features/budget/services/quote_intelligence_service.dart'; 
import 'package:proveedor_servicly_app/ai/services/gemini_service.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ---------------------------------------------------------------------------
// --- MANEJADOR DE FONDO (BACKGROUND HANDLER) ---
// ---------------------------------------------------------------------------
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("🌙 Mensaje recibido en segundo plano: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);

  // --- FIX WEB: Manejo de .env ---
  // En Web, el .env debe estar en assets. Si falla, que no rompa la app.
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("⚠️ Advertencia: No se pudo cargar .env (Normal si es Web y no está en assets): $e");
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- FIX WEB: Background Handler ---
  // Solo registramos esto si NO es Web. En Web da error.
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // --- FIX WEB: App Check ---
  // AppCheck necesita configuración especial para Web (ReCaptcha). 
  // Por ahora lo activamos SOLO si NO es Web para evitar el crash.
  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.appAttest,
    );
  } else {
    // Opcional: Aquí iría la configuración Web con ReCaptcha V3 si la tienes
    // await FirebaseAppCheck.instance.activate(
    //   webProvider: ReCaptchaV3Provider('tu-clave-web-recaptcha'),
    // );
    print("ℹ️ AppCheck desactivado temporalmente en Web para evitar crash");
  }

  // --- Cargar el servicio de tema ---
  final themeService = ThemeService();
  await themeService.loadTheme(); 

  runApp(
    ProviderScope( 
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
        ChangeNotifierProvider.value(value: themeService),
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<ProductService>(create: (_) => ProductService()),
        Provider<CategoryService>(create: (_) => CategoryService()),
        Provider<AgendaService>(create: (_) => AgendaService()),
        Provider<OrderService>(create: (_) => OrderService()),
        Provider<VideoService>(create: (_) => VideoService()),
        Provider<FollowService>(create: (_) => FollowService()),
        Provider<PaymentService>(create: (_) => PaymentService()),
        
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        
        ChangeNotifierProvider(create: (_) => AvailabilityService()),
        Provider<GeminiService>(create: (_) => GeminiService()),
        Provider<NotificationService>(create: (_) => NotificationService()),

        Provider<AuthService>(create: (context) => AuthService(
            firestoreService: context.read<FirestoreService>(),
            firebaseMessaging: FirebaseMessaging.instance,
          ),
        ),
        
        ProxyProvider<FirestoreService, ProviderService>(
          update: (context, firestoreService, previousProviderService) =>
              ProviderService(firestoreService: firestoreService),
        ),

        Provider<CrmRepository>(create: (_) => CrmRepository()),

        ChangeNotifierProvider<DashboardMetricsViewModel>(
            create: (context) => DashboardMetricsViewModel(
              context.read<CrmRepository>(), 
            ),
        ),
        
        Provider<InventoryRepository>(
          create: (_) => InventoryRepository(
            firestore: FirebaseFirestore.instance,
            auth: FirebaseAuth.instance,
            intelligenceService: InventoryIntelligenceService(
              AgendaRepository(
                firestore: FirebaseFirestore.instance,
                auth: FirebaseAuth.instance,
              ), 
              FirebaseAuth.instance.currentUser?.uid ?? '',
            ),
          ),
        ),

        Provider<QuoteRepository>(create: (_) => QuoteRepository()),

        Provider<QuoteIntelligenceService>(
          create: (context) => QuoteIntelligenceService(
            context.read<GeminiService>(), 
          ),
        ),

        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
        
        StreamProvider<UserModel?>(
          create: (context) => context.read<AuthService>().userModelStream,
          initialData: null,
          catchError: (_, __) => null, 
        ),

        ProxyProvider<UserModel?, PermissionsService>(
          update: (context, user, previousPermissions) {
            return PermissionsService(user ?? UserModel.empty());
          },
        ),

        ChangeNotifierProvider<CartProvider>(
          create: (_) => CartProvider(),
        ),

        ChangeNotifierProxyProvider<UserModel?, QuoteProvider>(
          create: (context) => QuoteProvider(
            repository: context.read<QuoteRepository>(),
            userId: '', 
          ),
          update: (context, userModel, previous) => QuoteProvider(
            repository: context.read<QuoteRepository>(),
            userId: userModel?.uid ?? '',
          ),
        ),
      ],
      
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            navigatorKey: navigatorKey, 
            title: 'Servicly',
            debugShowCheckedModeBanner: false,
            theme: themeService.lightTheme, 
            darkTheme: themeService.darkTheme,
            themeMode: ThemeMode.system, 
            home: const SplashScreen(), 
          );
        },
      ),
    );
  }
}