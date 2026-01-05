import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

// --- IMPORTS DE PAQUETE (Rutas Absolutas para evitar errores) ---
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/features/subscriptions/services/subscription_service.dart'; 

/// Un servicio para manejar todas las operaciones de autenticación con Firebase.
class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirestoreService _firestoreService;
  final FirebaseMessaging _firebaseMessaging;

  AuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    required FirestoreService firestoreService,
    FirebaseMessaging? firebaseMessaging,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _firestoreService = firestoreService,
        _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance;

  // --- STREAMS DE ESTADO (REACTIVIDAD) ---

  /// Stream básico de autenticación (Solo dice si hay usuario logueado o no).
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// [NUEVO] Stream Reactivo del Usuario Completo.
  /// Escucha cambios en Auth Y cambios en Firestore en tiempo real.
  /// Si pagas la suscripción, este stream emitirá un nuevo UserModel con planType='pro' al instante.
  Stream<UserModel?> get userModelStream {
    return _firebaseAuth.authStateChanges().asyncExpand((firebaseUser) {
      // 1. Si no hay usuario logueado, emitimos null
      if (firebaseUser == null) {
        return Stream.value(null);
      }

      // --- VERIFICACIÓN DE VENCIMIENTO (LAZY CHECK) ---
      // Lanzamos la verificación sin 'await' para no bloquear la UI.
      // Esto revisará en segundo plano si ya se le venció el mes y lo degradará a FREE si es necesario.
      try {
        // CORRECCIÓN: Al usar el import absoluto, esta clase ya será reconocida.
        SubscriptionService().checkSubscriptionStatus(firebaseUser.uid);
      } catch (e) {
        if (kDebugMode) print("Error en checkSubscriptionStatus: $e");
      }
      // ------------------------------------------------

      // 2. Si hay usuario, nos suscribimos a su documento en Firestore
      return FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .snapshots()
          .map((snapshot) {
            // Si el documento existe, lo convertimos a UserModel
            if (snapshot.exists && snapshot.data() != null) {
              return UserModel.fromJson(snapshot.data()!);
            }
            // Si el usuario está en Auth pero no tiene doc en DB (caso raro o nuevo registro)
            return null;
          });
    });
  }

  /// El usuario de Firebase actualmente autenticado (síncrono).
  User? get currentUser => _firebaseAuth.currentUser;

  // --- GESTIÓN DE NOTIFICACIONES (FCM) ---

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
          print('[AuthService] ✅ Permiso de notificaciones CONCEDIDO.');
        }

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

  Future<void> _updateFcmToken(String uid) async {
    try {
      final fcmToken = await _firebaseMessaging.getToken();
      
      if (fcmToken == null) {
        if (kDebugMode) print('[AuthService] No se pudo obtener el token FCM.');
        return;
      }
      
      if (kDebugMode) print('[AuthService] Guardando Token FCM: $fcmToken');
      await _firestoreService.saveDeviceToken(uid: uid, token: fcmToken);
    } catch (e) {
      if (kDebugMode) print('[AuthService] !! ERROR al guardar token FCM: $e');
    }
  }

  // --- MÉTODOS DE AUTENTICACIÓN ---

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await _updateFcmToken(userCredential.user!.uid);
      }
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

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
          'businessName': userCredential.user!.email,
        };
        final newUser = UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email,
          createdAt: Timestamp.now(),
          planType: 'free',
          isPremium: false, // Inicia como gratuito
          activeModules: ['clients', 'agenda'],
          role: null, 
          isProfileComplete: false, 
          personalization: personalizationData,
        );
        await _firestoreService.createUser(newUser);
      }
      
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user != null) {
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          final newUser = UserModel(
            uid: userCredential.user!.uid,
            email: userCredential.user!.email,
            createdAt: Timestamp.now(),
            planType: 'free',
            isPremium: false,
            activeModules: ['clients', 'agenda'],
            role: null, 
            isProfileComplete: false, 
            personalization: { 'businessName': userCredential.user!.displayName },
          );
          await _firestoreService.createUser(newUser);
        } else {
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

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}