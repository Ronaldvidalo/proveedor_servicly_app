// lib/core/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa el modelo de datos para un usuario en la plataforma Servicly.
///
/// Este modelo contiene no solo la información básica, sino también el estado
/// de su rol, plan, módulos activos y configuraciones de personalización.
class UserModel {
  // --- Información Básica y de Autenticación ---
  final String uid;
  final String? email;
  final Timestamp? createdAt;
  final bool isProfileComplete;

  // --- NUEVO: Campos de Rol y Monetización ---
  /// El rol del usuario en la plataforma ('provider', 'client', 'both').
  /// Es nulo hasta que el usuario lo selecciona en el onboarding.
  final String? role;

  /// El tipo de plan de suscripción actual del usuario ('free', 'founder', 'premium').
  final String planType;

  /// Una lista de los IDs de los módulos que el usuario tiene activados.
  final List<String> activeModules;

  // --- NUEVO: Campo de Personalización ("Tu Negocio, Tu App") ---
  /// Un mapa que contiene los datos de la marca del proveedor.
  /// Ej: {'businessName': 'Plomería Total', 'logoUrl': '...', 'primaryColor': '#00BFFF'}
  final Map<String, dynamic> personalization;

  /// El nombre a mostrar del usuario, que se obtiene de la personalización.
  String? get displayName => personalization['businessName'] as String?;

  UserModel({
    required this.uid,
    this.email,
    this.createdAt,
    this.isProfileComplete = false,
    this.role, // Nulo por defecto al crear la cuenta.
    this.planType = 'free', // Todo usuario nuevo empieza en el plan gratuito.
    this.activeModules = const [], // Lista vacía por defecto.
    this.personalization = const {}, // Mapa vacío por defecto.
  });

  /// Convierte la instancia del modelo a un mapa para guardarlo en Firestore.
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'isProfileComplete': isProfileComplete,
      'role': role,
      'planType': planType,
      'activeModules': activeModules,
      'personalization': personalization,
    };
  }

  /// Crea una instancia del modelo a partir de un mapa leído desde Firestore.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      createdAt: json['createdAt'] as Timestamp?,
      isProfileComplete: json['isProfileComplete'] as bool? ?? false,
      role: json['role'] as String?,
      // Valores por defecto para garantizar que la app no falle si el campo no existe.
      planType: json['planType'] as String? ?? 'free',
      activeModules: List<String>.from(json['activeModules'] ?? []),
      personalization: Map<String, dynamic>.from(json['personalization'] ?? {}),
    );
  }
}