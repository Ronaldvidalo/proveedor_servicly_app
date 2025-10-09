// lib/core/services/auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart'; // Import necesario para Timestamp
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart';
import '../models/user_model.dart';
import 'package:flutter/services.dart';

/// Un servicio para manejar todas las operaciones de autenticación con Firebase.
class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirestoreService _firestoreService;

  /// Constructor que ahora requiere el FirestoreService.
  AuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    required FirestoreService firestoreService,
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

      if (userCredential.user != null) {
        final newUser = UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email,
          createdAt: Timestamp.now(), // <-- ADAPTACIÓN AÑADIDA
        );
        await _firestoreService.createUser(newUser);
      }
      
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Inicia sesión con Google y, si es un usuario nuevo, crea su documento.
  Future<UserCredential?> signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      print('--- DEBUG: El usuario canceló el flujo de Google Sign-In ---');
      return null;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);

    if (userCredential.additionalUserInfo?.isNewUser == true && userCredential.user != null) {
      final newUser = UserModel(
        uid: userCredential.user!.uid,
        email: userCredential.user!.email,
        displayName: userCredential.user!.displayName,
        createdAt: Timestamp.now(),
      );
      await _firestoreService.createUser(newUser);
    }

    return userCredential;
  } on PlatformException catch (e) {
    // ESTE BLOQUE ES NUEVO Y ES EL MÁS IMPORTANTE
    print('--- ERROR DETALLADO DE PLATFORM EXCEPTION ---');
    print('Código de error: ${e.code}');
    print('Mensaje: ${e.message}');
    print('Detalles: ${e.details}');
    print('-------------------------------------------');
    rethrow;
  } on FirebaseAuthException catch (e) {
    print('--- ERROR DE FIREBASE AUTH ---');
    print('Código de error: ${e.code}');
    print('Mensaje: ${e.message}');
    print('----------------------------');
    rethrow;
  } catch (e) {
    print('--- ERROR GENÉRICO INESPERADO ---');
    print(e.toString());
    print('---------------------------------');
    rethrow;
  }
}
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}