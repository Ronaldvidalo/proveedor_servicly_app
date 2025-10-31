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
// import '../../profile/screens/create_profile_screen.dart'; // Opcional si OnboardingScreen no es la pantalla

/// Widget guardián que dirige el flujo principal de la aplicación.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasSeenIntro = false; // TODO: Usar SharedPreferences
  UserModel? _directFetchedUserModel; 
  bool _attemptedDirectFetch = false; 
  bool _directFetchFailed = false; // Bandera clave

  void _markIntroAsSeen() {
    setState(() => _hasSeenIntro = true);
    // TODO: Guardar en SharedPreferences
  }

  // --- FUNCIÓN DE LECTURA DIRECTA (MODIFICADA) ---
  Future<void> _tryDirectFetch(String uid) async {
      if (_attemptedDirectFetch || !mounted) return; 
      setState(() {
        _attemptedDirectFetch = true;
        _directFetchFailed = false; 
      });
      if (kDebugMode) {
          print("[AuthWrapper] Intentando lectura directa para UID: $uid");
      }
      try {
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
            await Future.delayed(const Duration(seconds: 2));
            if (!mounted) return;

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
                if (mounted) {
                  setState(() {
                    _directFetchFailed = true; // ¡Documento NO existe!
                  });
                }
            }
        }
      } catch (e) {
         if (kDebugMode) {
           print("[AuthWrapper] !! ERROR en lectura directa: $e");
         }
         if (mounted) {
            setState(() {
              _directFetchFailed = true; // Error también cuenta como fallo
            });
         }
      }
  }
  
  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();
    final userModelFromStream = context.watch<UserModel?>(); 

    final userModel = _directFetchedUserModel ?? userModelFromStream;

    // --- Logs de Depuración (Sin cambios) ---
    if (kDebugMode) {
      print("===== AuthWrapper Build =====");
      print("  Firebase User: ${firebaseUser?.uid ?? 'null'}");
      print("  User Model (Stream): ${userModelFromStream?.uid ?? 'null'}");
      print("  User Model (Direct): ${_directFetchedUserModel?.uid ?? 'null'}");
      print("  User Model (Final): ${userModel?.uid ?? 'null'}");
      print("  Direct Fetch Failed: $_directFetchFailed");
      if (userModel != null) {
        print("    isProfileComplete: ${userModel.isProfileComplete}");
        print("    Role: ${userModel.role ?? 'null'}");
      }
      print("=============================");
    }

    // Flujo 1: Usuario NO autenticado
    if (firebaseUser == null) {
      if (kDebugMode) print("-> Estado: No autenticado. Mostrando Intro/Auth.");
        _attemptedDirectFetch = false;
        _directFetchedUserModel = null;
        _directFetchFailed = false; 
      if (!_hasSeenIntro) {
        return IntroScreen(onFinished: _markIntroAsSeen);
      } else {
        return const AuthScreen();
      }
    }
    // Flujo 2: Usuario SÍ autenticado en Firebase
    else {
      if (userModel == null) {
        
        // --- ¡LÓGICA DE CORRECCIÓN DEFINITIVA! ---
        if (_directFetchFailed) {
            if (kDebugMode) print("-> Estado: Autenticado, PERO UserModel no existe (Fantasma/Nuevo). Mostrando OnboardingScreen.");
            
            // Creamos un UserModel temporal VÁLIDO usando los datos de Auth
            // y la estructura de tu UserModel.
            final tempUserModel = UserModel(
              uid: firebaseUser.uid,
              email: firebaseUser.email, // Es nullable, está bien
              isProfileComplete: false, // Es nuevo, así que no está completo
              personalization: {
                // Pre-poblamos el nombre del negocio con el de Auth (si existe)
                'businessName': firebaseUser.displayName 
              },
              // Todos los demás campos (planType, etc.) usarán 
              // los valores por defecto definidos en tu constructor de UserModel.
            );
            
            // Enviamos este usuario temporal a OnboardingScreen.
            // OnboardingScreen es responsable de llamar a firestoreService.createUser()
            // cuando el usuario termine de elegir su rol y completar datos.
            return OnboardingScreen(userModel: tempUserModel);
        }
        // --- FIN DE LA CORRECCIÓN ---

        if (!_attemptedDirectFetch) {
           Future.microtask(() => _tryDirectFetch(firebaseUser.uid));
        }
        
        if (kDebugMode) print("-> Estado: Autenticado, esperando UserModel (Stream o Directo). Mostrando Carga.");
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      // Flujo 3: Usuario autenticado Y perfil de Firestore CARGADO
      else {
         _attemptedDirectFetch = false;
         _directFetchFailed = false;

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