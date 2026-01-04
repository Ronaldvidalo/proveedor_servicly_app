import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Representa el modelo de datos para un usuario en la plataforma Servicly.
@immutable
class UserModel {
  // --- DATOS DE LA PLATAFORMA ---
  final String uid;
  final String? email;
  final Timestamp? createdAt;
  final bool isProfileComplete;
  final String? role;
  final String planType;
  final List<String> activeModules;

  // --- PERFIL PÚBLICO ---
  final bool publicProfileCreated;
  final String? publicProfileTemplate;

  // --- DATOS DE NEGOCIO Y VERIFICACIÓN ---
  // Mantenemos businessName como variable principal según tu estructura
  final String? businessName; 
  final String? logoUrl;
  
  // Nuevos campos detectados en tu Firestore:
  final bool isVerified;
  final String? verificationStatus; // "basic_verified"
  final Timestamp? verificationDate;
  
  // Métricas
  final num ratingAvg;   // Usamos num para soportar int (4) y double (4.5)
  final num ratingCount;

  // --- DATOS FLEXIBLES ---
  final Map<String, dynamic> personalization;

  // --- GETTERS DE CONVENIENCIA (COMO ESTABAN ANTES) ---
  /// Mantiene la compatibilidad con tus otros archivos.
  /// Obtiene el nombre del negocio o el nombre de pantalla.
  String? get displayName => businessName; 

  /// Alias para photoUrl usando el logoUrl
  String? get photoUrl => logoUrl;

  const UserModel({
    required this.uid,
    this.email,
    this.createdAt,
    this.isProfileComplete = false,
    this.role,
    this.planType = 'conecta', // Default según tu código anterior
    this.activeModules = const [],
    this.personalization = const {},
    this.publicProfileCreated = false,
    this.publicProfileTemplate,
    
    // Campos restaurados y nuevos
    this.businessName,
    this.logoUrl,
    this.isVerified = false,
    this.verificationStatus,
    this.verificationDate,
    this.ratingAvg = 0,
    this.ratingCount = 0,
  });

  /// Convierte a JSON para Firestore
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
      
      // Mapeo de campos de negocio
      'businessName': businessName,
      'displayName': businessName, // Guardamos businessName también como displayName para consistencia
      'logoUrl': logoUrl,
      'isVerified': isVerified,
      'verificationStatus': verificationStatus,
      'verificationDate': verificationDate,
      'ratingAvg': ratingAvg,
      'ratingCount': ratingCount,
    };
  }

  /// Crea desde Firestore
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      createdAt: json['createdAt'] as Timestamp?,
      isProfileComplete: json['isProfileComplete'] as bool? ?? false,
      role: json['role'] as String?,
      planType: json['planType'] as String? ?? 'conecta',
      activeModules: List<String>.from(json['activeModules'] ?? []),
      personalization: Map<String, dynamic>.from(json['personalization'] ?? {}),
      
      publicProfileCreated: json['publicProfileCreated'] as bool? ?? false,
      publicProfileTemplate: json['publicProfileTemplate'] as String?,

      // --- TRUCO DE COMPATIBILIDAD ---
      // Leemos 'businessName'. Si es nulo, intentamos leer 'displayName' (donde dice "Ronald").
      // Esto hace que tu getter displayName funcione aunque el campo en BD se llame diferente.
      businessName: (json['businessName'] as String?) ?? (json['displayName'] as String?),
      
      logoUrl: json['logoUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      verificationStatus: json['verificationStatus'] as String?,
      verificationDate: json['verificationDate'] as Timestamp?,
      
      // Lectura segura de números
      ratingAvg: json['ratingAvg'] as num? ?? 0,
      ratingCount: json['ratingCount'] as num? ?? 0,
    );
  }

  factory UserModel.empty() {
    return const UserModel(
      uid: '',
      email: '',
      role: '', 
      isProfileComplete: false,
      activeModules: [],
      personalization: {},
      planType: 'conecta',
      publicProfileCreated: false,
      businessName: null,
      logoUrl: null,
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    Timestamp? createdAt,
    bool? isProfileComplete,
    String? role,
    String? planType,
    List<String>? activeModules,
    bool? publicProfileCreated,
    String? publicProfileTemplate,
    Map<String, dynamic>? personalization,
    
    String? businessName,
    String? logoUrl,
    bool? isVerified,
    String? verificationStatus,
    Timestamp? verificationDate,
    num? ratingAvg,
    num? ratingCount,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      role: role ?? this.role,
      planType: planType ?? this.planType,
      activeModules: activeModules ?? this.activeModules,
      personalization: personalization ?? this.personalization,
      publicProfileCreated: publicProfileCreated ?? this.publicProfileCreated,
      publicProfileTemplate: publicProfileTemplate ?? this.publicProfileTemplate,
      
      businessName: businessName ?? this.businessName,
      logoUrl: logoUrl ?? this.logoUrl,
      isVerified: isVerified ?? this.isVerified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationDate: verificationDate ?? this.verificationDate,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }
}