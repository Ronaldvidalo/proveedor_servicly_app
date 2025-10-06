// lib/core/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Un servicio para manejar todas las operaciones de autenticación con Firebase.
///
/// Encapsula la lógica para el inicio de sesión con email/contraseña,
/// con Google, el registro de nuevos usuarios y el cierre de sesión.
class AuthService {
  /// La instancia principal de FirebaseAuth para interactuar con el backend.
  final FirebaseAuth _firebaseAuth;

  /// La instancia para gestionar el flujo de inicio de sesión de Google.
  final GoogleSignIn _googleSignIn;

  /// Constructor que permite inyectar instancias de FirebaseAuth y GoogleSignIn,
  /// facilitando las pruebas. Si no se proveen, usa las instancias por defecto.
  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        // Se inicializa GoogleSignIn especificando los scopes necesarios.
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  /// Un stream que notifica sobre los cambios en el estado de autenticación del usuario.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Obtiene el usuario actualmente autenticado.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Inicia sesión de un usuario existente usando su email y contraseña.
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

  /// Registra un nuevo usuario en Firebase con email y contraseña.
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // TODO: Aquí es un buen lugar para crear un documento de usuario en Firestore.
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Inicia el flujo de autenticación con una cuenta de Google.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Iniciar el flujo de Google Sign-In.
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // El usuario canceló el flujo.
        return null;
      }

      // 2. Obtener los detalles de autenticación. En esta versión, 'authentication' es un Future.
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Crear una credencial de Firebase con los tokens de Google.
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Iniciar sesión en Firebase con la credencial.
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      // TODO: Si es el primer inicio de sesión del usuario, crear su documento en Firestore.
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Cierra la sesión del usuario actual.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}

