// lib/core/services/auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart';
import '../models/user_model.dart';

/// Un servicio para manejar todas las operaciones de autenticación con Firebase.
class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirestoreService _firestoreService;

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
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Registra un nuevo usuario y crea su documento inicial en Firestore.
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
        // Creamos el UserModel con los valores por defecto de la plataforma.
        final newUser = UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email,
          createdAt: Timestamp.now(),
          planType: 'free', // Todo usuario nuevo empieza como 'free'.
          // Módulos básicos que todo usuario 'free' tendrá al registrarse.
          activeModules: ['clients', 'agenda'], 
          role: null, // El rol se definirá en el onboarding.
          isProfileComplete: false, // El perfil se completará en el onboarding.
          personalization: {}, // La personalización se configura después.
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
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.additionalUserInfo?.isNewUser == true && userCredential.user != null) {
        // Creamos el UserModel con los valores por defecto, aprovechando el nombre de Google.
        final newUser = UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email,
          createdAt: Timestamp.now(),
          planType: 'free',
          activeModules: ['clients', 'agenda'],
          role: null,
          isProfileComplete: false,
          // Guardamos el nombre de Google en el mapa de personalización.
          personalization: { 'businessName': userCredential.user!.displayName },
        );
        await _firestoreService.createUser(newUser);
      }
      
      return userCredential;
    } on PlatformException {
      // Dejamos este print comentado para depuración futura si es necesario.
      // print('--- ERROR DETALLADO DE PLATFORM EXCEPTION ---');
      // print('Código de error: ${e.code}');
      // print('Mensaje: ${e.message}');
      // print('Detalles: ${e.details}');
      // print('-------------------------------------------');
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

