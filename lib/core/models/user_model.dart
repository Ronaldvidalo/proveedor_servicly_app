/// lib/core/models/user_model.dart
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa el modelo de datos para un usuario en la plataforma Servicly.
///
/// Este modelo contiene no solo la información de la plataforma (rol, plan),
/// sino también un mapa flexible 'personalization' que almacena todos los
/// datos del negocio del proveedor.
class UserModel {
  // --- DATOS DE LA PLATAFORMA (Gestionados por Servicly) ---
  final String uid;
  final String? email;
  final Timestamp? createdAt;
  final bool isProfileComplete;
  final String? role;
  final String planType;
  final List<String> activeModules;

  // --- DATOS DEL NEGOCIO (Gestionados por el Proveedor) ---
  /// Mapa flexible para almacenar toda la configuración de la marca y el perfil público.
  /// Ejemplos de claves:
  /// - 'businessName': String
  /// - 'logoUrl': String
  /// - 'primaryColor': String (en formato Hex '#RRGGBB')
  /// - 'publicProfileFormat': String ('cv', 'portfolio', 'store')
  /// - 'welcomeMessage': String
  /// - 'address': String
  /// - 'country': String
  /// - 'phoneNumber': String
  /// - 'contactEmail': String
  /// - 'bankDetails': Map<String, String> (ej: {'cbu': '...', 'alias': '...'})
  final Map<String, dynamic> personalization;

  // --- GETTERS DE CONVENIENCIA ---
  /// Acceso directo al nombre del negocio desde el mapa de personalización.
  String? get displayName => personalization['businessName'] as String?;

  UserModel({
    required this.uid,
    this.email,
    this.createdAt,
    this.isProfileComplete = false,
    this.role,
    this.planType = 'free',
    this.activeModules = const [],
    this.personalization = const {},
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
      planType: json['planType'] as String? ?? 'free',
      activeModules: List<String>.from(json['activeModules'] ?? []),
      personalization: Map<String, dynamic>.from(json['personalization'] ?? {}),
    );
  }
}