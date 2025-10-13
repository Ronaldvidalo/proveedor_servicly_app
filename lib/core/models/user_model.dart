import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Representa el modelo de datos para un usuario en la plataforma Servicly.
///
/// Este modelo contiene no solo la información de la plataforma (rol, plan),
/// sino también un mapa flexible 'personalization' que almacena todos los
/// datos del negocio del proveedor.
@immutable
class UserModel {
  // --- DATOS DE LA PLATAFORMA (Gestionados por Servicly) ---
  final String uid;
  final String? email;
  final Timestamp? createdAt;
  final bool isProfileComplete;
  final String? role;
  final String planType;
  final List<String> activeModules;

  // --- MODIFICACIÓN: Campos para el nuevo flujo de perfil público ---
  /// Indica si el usuario ya ha completado la creación de su perfil público.
  /// Por defecto es `false`.
  final bool publicProfileCreated;
  /// Almacena el identificador de la plantilla seleccionada (ej: 'cv', 'tienda').
  /// Es `null` si el perfil no ha sido creado.
  final String? publicProfileTemplate;

  // --- DATOS DEL NEGOCIO (Gestionados por el Proveedor) ---
  /// Mapa flexible para almacenar toda la configuración de la marca y el perfil público.
  final Map<String, dynamic> personalization;

  // --- GETTERS DE CONVENIENCIA ---
  /// Acceso directo al nombre del negocio desde el mapa de personalización.
  String? get displayName => personalization['businessName'] as String?;

  const UserModel({
    required this.uid,
    this.email,
    this.createdAt,
    this.isProfileComplete = false,
    this.role,
    this.planType = 'free',
    this.activeModules = const [],
    this.personalization = const {},
    // --- MODIFICACIÓN: Se añaden los nuevos campos al constructor ---
    this.publicProfileCreated = false,
    this.publicProfileTemplate,
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
      'publicProfileCreated': publicProfileCreated,
      'publicProfileTemplate': publicProfileTemplate,
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
      planType: json['planType'] as String? ?? 'free',
      activeModules: List<String>.from(json['activeModules'] ?? []),
      personalization: Map<String, dynamic>.from(json['personalization'] ?? {}),
      // --- MODIFICACIÓN: Se leen los nuevos campos de forma segura ---
      publicProfileCreated: json['publicProfileCreated'] as bool? ?? false,
      publicProfileTemplate: json['publicProfileTemplate'] as String?,
    );
  }
}

