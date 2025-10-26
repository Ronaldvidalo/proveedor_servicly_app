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

  // --- NUEVO MÉTODO PRIVADO PARA FCM ---
  /// Obtiene el token FCM y lo guarda en una subcolección del usuario.
  Future<void> _updateFcmToken(String uid) async {
    try {
      // Intenta obtener el token del dispositivo
      final fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken == null) {
        // Esto puede pasar si el usuario no ha dado permisos
        if (kDebugMode) print('[AuthService] No se pudo obtener el token FCM (quizás no hay permisos).');
        return;
      }
      if (kDebugMode) print('[AuthService] Token FCM obtenido: $fcmToken');

      // Llama al método que creamos en FirestoreService
      await _firestoreService.saveDeviceToken(uid: uid, token: fcmToken);
    } catch (e) {
      if (kDebugMode) print('[AuthService] !! ERROR al guardar token FCM: $e');
      // No relanzamos el error para no interrumpir el flujo de login
    }
  }
  // --- FIN NUEVO MÉTODO ---

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
      // --- LÓGICA FCM AÑADIDA ---
      // Si un usuario existente inicia sesión, actualizamos su token.
      if (userCredential.user != null) {
        await _updateFcmToken(userCredential.user!.uid);
      }
      // --- FIN LÓGICA FCM ---
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Registra un nuevo usuario y crea su documento en Firestore.
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String role,
    String? countryCode,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final personalizationData = {
          'country': countryCode,
          'businessName': userCredential.user!.email,
        };
        final newUser = UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email,
          createdAt: Timestamp.now(),
          planType: 'free',
          activeModules: ['clients', 'agenda'],
          role: role,
          isProfileComplete: false,
          personalization: personalizationData,
        );
        await _firestoreService.createUser(newUser);
        
        // --- LÓGICA FCM ELIMINADA DE AQUÍ ---
        // Ya no se llama a _updateFcmToken.
        // OnboardingScreen se encargará de esto después de pedir permiso.
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

  /// Inicia sesión con Google y, si es un usuario nuevo, crea su documento.
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
            // displayName: userCredential.user!.displayName, // Se quita para que coincida con el constructor
            createdAt: Timestamp.now(),
            planType: 'free',
            activeModules: ['clients', 'agenda'],
            role: 'client', 
            isProfileComplete: false, 
            personalization: { 'businessName': userCredential.user!.displayName },
          );
          await _firestoreService.createUser(newUser);
          
          // --- LÓGICA FCM ELIMINADA DE AQUÍ ---
          // OnboardingScreen se encargará de esto.
        } else {
          // --- LÓGICA FCM AÑADIDA PARA USUARIO EXISTENTE DE GOOGLE ---
          // Si es un usuario existente, actualizamos su token.
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
    // TODO: Considerar eliminar el token FCM del dispositivo al cerrar sesión
    // (requeriría llamar a _firebaseMessaging.deleteToken() y
    // eliminarlo de la subcolección en Firestore)
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}

