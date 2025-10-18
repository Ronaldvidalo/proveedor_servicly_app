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
    required String role,
    String? countryCode, // Parámetro opcional para el país del proveedor
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
          createdAt: Timestamp.now(),
          planType: 'free',
          activeModules: ['clients', 'agenda'], 
          role: role, 
          isProfileComplete: false,
          // --- MODIFICACIÓN ---
          // Si es un proveedor, guardamos su país en el mapa de personalización.
          personalization: role == 'provider' ? {'country': countryCode} : {},
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
        final newUser = UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email,
          createdAt: Timestamp.now(),
          planType: 'free',
          activeModules: ['clients', 'agenda'],
          // Los usuarios de Google son clientes por defecto, no necesitan país al inicio.
          role: 'client', 
          isProfileComplete: true,
          personalization: { 'businessName': userCredential.user!.displayName },
        );
        await _firestoreService.createUser(newUser);
      }
      
      return userCredential;
    } on PlatformException {
      rethrow;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Envía un correo electrónico para restablecer la contraseña.
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}

