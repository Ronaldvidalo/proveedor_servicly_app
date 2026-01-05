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
  
  // --- SUSCRIPCIONES Y PAGOS (NUEVO) ---
  final String planType; // 'free', 'pro', 'corporate'
  final bool isPremium;  // true si pagó
  final Timestamp? subscriptionExpiry; // Fecha de vencimiento

  final List<String> activeModules;

  // --- PERFIL PÚBLICO ---
  final bool publicProfileCreated;
  final String? publicProfileTemplate;

  // --- DATOS DE NEGOCIO Y VERIFICACIÓN ---
  final String? businessName; 
  final String? logoUrl;
  
  // Datos de verificación
  final bool isVerified;
  final String? verificationStatus; // "basic_verified"
  final Timestamp? verificationDate;
  
  // Métricas
  final num ratingAvg;
  final num ratingCount;

  // --- DATOS FLEXIBLES ---
  final Map<String, dynamic> personalization;

  // --- GETTERS DE CONVENIENCIA ---
  String? get displayName => businessName; 
  String? get photoUrl => logoUrl;

  const UserModel({
    required this.uid,
    this.email,
    this.createdAt,
    this.isProfileComplete = false,
    this.role,
    this.planType = 'free',
    this.isPremium = false, // Default false
    this.subscriptionExpiry,
    this.activeModules = const [],
    this.personalization = const {},
    this.publicProfileCreated = false,
    this.publicProfileTemplate,
    
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
      
      // Suscripción
      'planType': planType,
      'isPremium': isPremium,
      'subscriptionExpiry': subscriptionExpiry,

      'activeModules': activeModules,
      'personalization': personalization,
      'publicProfileCreated': publicProfileCreated,
      'publicProfileTemplate': publicProfileTemplate,
      
      // Negocio
      'businessName': businessName,
      'displayName': businessName, 
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
      
      // Suscripción
      planType: json['planType'] as String? ?? 'free',
      isPremium: json['isPremium'] as bool? ?? false,
      subscriptionExpiry: json['subscriptionExpiry'] as Timestamp?,

      activeModules: List<String>.from(json['activeModules'] ?? []),
      personalization: Map<String, dynamic>.from(json['personalization'] ?? {}),
      
      publicProfileCreated: json['publicProfileCreated'] as bool? ?? false,
      publicProfileTemplate: json['publicProfileTemplate'] as String?,

      // Truco de compatibilidad para nombres
      businessName: (json['businessName'] as String?) ?? (json['displayName'] as String?),
      
      logoUrl: json['logoUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      verificationStatus: json['verificationStatus'] as String?,
      verificationDate: json['verificationDate'] as Timestamp?,
      
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
      planType: 'free',
      isPremium: false,
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
    bool? isPremium,
    Timestamp? subscriptionExpiry,
    
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
      isPremium: isPremium ?? this.isPremium,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,

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