import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart'; // Import para PlatformException
import 'firestore_service.dart';
import '../models/user_model.dart';
// --- NUEVAS IMPORTACIONES ---
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'; // Para kDebugMode

/// Un servicio para manejar todas las operaciones de autenticación con Firebase.
class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirestoreService _firestoreService;
  // --- NUEVA DEPENDENCIA AÑADIDA ---
  final FirebaseMessaging _firebaseMessaging;

  /// Constructor que ahora requiere el FirestoreService y (opcionalmente) FirebaseMessaging.
  AuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    required FirestoreService firestoreService,
    FirebaseMessaging? firebaseMessaging, // --- AÑADIDO (inyectado desde main.dart) ---
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _firestoreService = firestoreService,
        // --- AÑADIDO ---
        _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance;

  /// Un stream que notifica sobre los cambios en el estado de autenticación.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// El usuario de Firebase actualmente autenticado.
  User? get currentUser => _firebaseAuth.currentUser;

  // --- NUEVO MÉTODO PÚBLICO: SOLICITAR PERMISOS (Trigger Manual) ---
  /// Lanza el diálogo nativo para pedir permisos de notificación.
  /// Retorna `true` si el usuario concedió el permiso, `false` si lo denegó.
  /// Si se concede, intenta guardar el token FCM inmediatamente.
  Future<bool> requestNotificationPermission() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        if (kDebugMode) {
          print('[AuthService] ✅ Permiso de notificaciones CONCEDIDO: ${settings.authorizationStatus}');
        }

        // Si hay un usuario logueado, guardamos el token ahora mismo
        // para que pueda empezar a recibir notificaciones ya.
        if (currentUser != null) {
          await _updateFcmToken(currentUser!.uid);
        }
        return true;
      } else {
        if (kDebugMode) {
          print('[AuthService] ❌ Permiso de notificaciones DENEGADO.');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AuthService] Error solicitando permisos: $e');
      }
      return false;
    }
  }
  // -------------------------------------------------------------

  // --- MÉTODO PRIVADO PARA FCM ---
  /// Obtiene el token FCM y lo guarda en una subcolección del usuario.
  Future<void> _updateFcmToken(String uid) async {
    try {
      // Intenta obtener el token del dispositivo
      // GetToken puede fallar o devolver null si no hay permisos en APNS (iOS)
      final fcmToken = await _firebaseMessaging.getToken();
      
      if (fcmToken == null) {
        if (kDebugMode) print('[AuthService] No se pudo obtener el token FCM (quizás no hay permisos).');
        return;
      }
      
      if (kDebugMode) print('[AuthService] Token FCM obtenido y guardando: $fcmToken');

      // Llama al método que creamos en FirestoreService
      await _firestoreService.saveDeviceToken(uid: uid, token: fcmToken);
    } catch (e) {
      if (kDebugMode) print('[AuthService] !! ERROR al guardar token FCM: $e');
      // No relanzamos el error para no interrumpir flujos
    }
  }

  /// Inicia sesión con email y contraseña (USUARIO EXISTENTE).
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // --- LÓGICA FCM ---
      // Intentamos actualizar el token, pero solo funcionará si ya tenía permisos previos.
      // Si es la primera vez, _updateFcmToken fallará silenciosamente o retornará null,
      // lo cual está bien porque pediremos permiso más tarde con el botón.
      if (userCredential.user != null) {
        await _updateFcmToken(userCredential.user!.uid);
      }
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Registra un nuevo usuario y crea su documento en Firestore.
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final personalizationData = {
          'businessName': userCredential.user!.email, // Un default temporal
        };
        final newUser = UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email,
          createdAt: Timestamp.now(),
          planType: 'free',
          activeModules: ['clients', 'agenda'],
          role: null, 
          isProfileComplete: false, 
          personalization: personalizationData,
        );
        await _firestoreService.createUser(newUser);
        
        // NOTA: Aquí NO pedimos token ni permisos.
        // Se hará en el Onboarding o Dashboard mediante requestNotificationPermission().
      }
      
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Envía un correo de restablecimiento de contraseña.
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Inicia sesión con Google.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // El usuario canceló

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Si es la primera vez que inicia sesión, creamos su documento
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          final newUser = UserModel(
            uid: userCredential.user!.uid,
            email: userCredential.user!.email,
            createdAt: Timestamp.now(),
            planType: 'free',
            activeModules: ['clients', 'agenda'],
            role: null, 
            isProfileComplete: false, 
            personalization: { 'businessName': userCredential.user!.displayName },
          );
          await _firestoreService.createUser(newUser);
          // Sin token por ahora.
        } else {
          // Usuario existente: Intentamos actualizar token si ya tiene permisos.
          await _updateFcmToken(userCredential.user!.uid);
        }
      }
      
      return userCredential;
    } on PlatformException { 
      rethrow;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Cierra la sesión del usuario.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}