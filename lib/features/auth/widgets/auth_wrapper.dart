import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Para kDebugMode

import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart'; // Necesario para lectura directa
import '../../home/screens/home_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../onboarding/screens/intro_screen.dart';
import '../../auth/screens/auth_screen.dart';
import '../../onboarding/screens/onboarding_screen.dart';


/// Widget guardián que dirige el flujo principal de la aplicación.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasSeenIntro = false; // TODO: Usar SharedPreferences
  UserModel? _directFetchedUserModel; // Variable para intento de lectura directa
  bool _attemptedDirectFetch = false; // Bandera para evitar bucles

  void _markIntroAsSeen() {
    setState(() => _hasSeenIntro = true);
    // TODO: Guardar en SharedPreferences
  }

  // --- FUNCIÓN DE LECTURA DIRECTA (PARA EVITAR CARRERA) ---
  Future<void> _tryDirectFetch(String uid) async {
      if (_attemptedDirectFetch || !mounted) return; // Evitar múltiples llamadas
      setState(() {
        _attemptedDirectFetch = true;
      });
      if (kDebugMode) {
         print("[AuthWrapper] Intentando lectura directa para UID: $uid");
      }
      try {
        // Usamos get() en lugar de snapshots() para una sola lectura
        final doc = await context.read<FirestoreService>().getUserDocument(uid);
        if (doc.exists && doc.data() != null) {
           final fetchedModel = UserModel.fromJson(doc.data()!);
           if (mounted) {
              setState(() {
                _directFetchedUserModel = fetchedModel;
                if (kDebugMode) {
                   print("[AuthWrapper] Lectura directa exitosa: ${fetchedModel.uid}");
                }
              });
           }
        } else {
           if (kDebugMode) {
              print("[AuthWrapper] Lectura directa: Documento no encontrado para UID: $uid");
           }
            // Podríamos intentar de nuevo tras un breve retraso si sospechamos lentitud de Firestore
            await Future.delayed(const Duration(seconds: 2));
            if (!mounted) return;
            // Segundo intento
              final docRetry = await context.read<FirestoreService>().getUserDocument(uid);
              if (docRetry.exists && docRetry.data() != null) {
                final fetchedModelRetry = UserModel.fromJson(docRetry.data()!);
                 if (mounted) {
                   setState(() {
                     _directFetchedUserModel = fetchedModelRetry;
                      if (kDebugMode) {
                         print("[AuthWrapper] Lectura directa (REINTENTO) exitosa: ${fetchedModelRetry.uid}");
                      }
                   });
                 }
              } else {
                  if (kDebugMode) {
                     print("[AuthWrapper] Lectura directa (REINTENTO): Documento aún no encontrado.");
                  }
              }
        }
      } catch (e) {
         if (kDebugMode) {
            print("[AuthWrapper] !! ERROR en lectura directa: $e");
         }
      }
  }
  // --- Fin Nueva Función ---
  
  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();
    final userModelFromStream = context.watch<UserModel?>(); // El del StreamProvider

    // Usamos el modelo leído directamente si el del stream aún es null y ya intentamos leerlo
    final userModel = _directFetchedUserModel ?? userModelFromStream;

    // --- Logs de Depuración ---
    if (kDebugMode) {
      print("===== AuthWrapper Build =====");
      print("  Firebase User: ${firebaseUser?.uid ?? 'null'}");
      print("  User Model (Stream): ${userModelFromStream?.uid ?? 'null'}");
      print("  User Model (Direct): ${_directFetchedUserModel?.uid ?? 'null'}");
      print("  User Model (Final): ${userModel?.uid ?? 'null'}");
      if (userModel != null) {
        print("    isProfileComplete: ${userModel.isProfileComplete}");
        print("    Role: ${userModel.role ?? 'null'}");
      }
      print("=============================");
    }

    // Flujo 1: Usuario NO autenticado
    if (firebaseUser == null) {
      if (kDebugMode) print("-> Estado: No autenticado. Mostrando Intro/Auth.");
       // Reseteamos banderas si el usuario cierra sesión
       _attemptedDirectFetch = false;
       _directFetchedUserModel = null;
      if (!_hasSeenIntro) {
        return IntroScreen(onFinished: _markIntroAsSeen);
      } else {
        return const AuthScreen();
      }
    }
    // Flujo 2: Usuario SÍ autenticado en Firebase
    else {
      if (userModel == null) {
        // --- MODIFICACIÓN: Intentar lectura directa ---
        // Si el stream aún no emite, pero estamos autenticados,
        // intentamos una lectura directa (solo una vez).
        if (!_attemptedDirectFetch) {
           // Llamamos a la función asíncrona sin await para no bloquear el build
           Future.microtask(() => _tryDirectFetch(firebaseUser.uid));
        }
        // Mientras esperamos (ya sea el stream o la lectura directa), mostramos carga.
        if (kDebugMode) print("-> Estado: Autenticado, esperando UserModel (Stream o Directo). Mostrando Carga.");
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
        // --- Fin Modificación ---
      }
      // Flujo 3: Usuario autenticado Y perfil de Firestore CARGADO (desde Stream o directo)
      else {
         // Reseteamos la bandera de intento directo si ya tenemos un modelo
         _attemptedDirectFetch = false;
        if (userModel.isProfileComplete) {
          if (kDebugMode) print("-> Estado: Perfil Completo. Decidiendo por Rol (${userModel.role}).");
          if (userModel.role == 'provider') {
            if (kDebugMode) print("--> Navegando a DashboardScreen (Provider)");
            return const DashboardScreen();
          } else {
             if (kDebugMode) print("--> Navegando a HomeScreen (Client)");
            return const HomeScreen();
          }
        } else {
          if (kDebugMode) print("-> Estado: Perfil Incompleto. Mostrando OnboardingScreen (Configuración).");
          return OnboardingScreen(userModel: userModel);
        }
      }
    }
  }
}

