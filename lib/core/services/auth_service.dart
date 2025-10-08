// lib/core/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart'; // <-- PASO 1: Importar FirestoreService
import '../models/user_model.dart';   // <-- PASO 1: Importar UserModel

/// Un servicio para manejar todas las operaciones de autenticación con Firebase.
class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirestoreService _firestoreService; // <-- PASO 2: Añadir dependencia

  /// Constructor que ahora requiere el FirestoreService.
  AuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    required FirestoreService firestoreService, // <-- PASO 2: Inyectar dependencia
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _firestoreService = firestoreService;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
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

      // --- LÓGICA AGREGADA ---
      // Después de crear el usuario en Auth, creamos su documento en Firestore.
      if (userCredential.user != null) {
        final newUser = UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email,
        );
        await _firestoreService.createUser(newUser);
      }
      // --- FIN LÓGICA AGREGADA ---

      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Inicia sesión con Google y, si es un usuario nuevo, crea su documento.
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

      // --- LÓGICA AGREGADA ---
      // Verificamos si es la primera vez que el usuario inicia sesión.
      if (userCredential.additionalUserInfo?.isNewUser == true && userCredential.user != null) {
        final newUser = UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email,
          displayName: userCredential.user!.displayName, // Google nos da el nombre
        );
        await _firestoreService.createUser(newUser);
      }
      // --- FIN LÓGICA AGREGADA ---

      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}