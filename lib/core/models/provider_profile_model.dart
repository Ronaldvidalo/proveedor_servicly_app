import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Un modelo de datos que representa el perfil público de un proveedor.
class ProviderProfileModel {
  final String providerId;
  final String businessName;
  final String logoUrl;
  final Color brandColor;
  final List<String> activeModules;
  final String profileType;
  final String? publicProfileTheme;
  final String contactEmail;
  final String? address;

  // --- Campos Adicionales ---
  final String? slogan;
  final double? averageRating;
  final int? reviewCount;
  final String? openingHours;
  final String? phone;
  final String? whatsapp;

  // --- CAMPOS DE REDES ---
  final String? website;
  final String? instagram;
  final String? facebook;
  final String? tiktok;

  // --- CAMPO DE PARTNERS ---
  final List<Map<String, dynamic>> partners;

  // --- CAMPO DE PAGO P2P ---
  final String? paymentInstructions;

  // --- CAMPOS GEO, CATEGORÍA Y DISPONIBILIDAD ---
  final String? category; 
  final double? latitude; 
  final double? longitude;
  final bool isAvailable; 

  // --- Campos del Módulo de Bienvenida ---
  final bool showWelcomeModule;
  final String welcomeModuleType; 
  final String welcomeMessage;
  final String? welcomeVideoUrl;
  final String? welcomeVideoSourceType; 

  // --- Campos: Control de Visibilidad de Módulos ---
  final bool showPortfolioModule;
  final bool showReviewsModule;
  final bool showPromotionsModule;
  final bool showGiftCardModule;
  final bool showBookingModule; 
  final bool showQuotesModule; 

  const ProviderProfileModel({
    required this.providerId,
    required this.businessName,
    required this.logoUrl,
    required this.brandColor,
    required this.activeModules,
    required this.profileType,
    this.publicProfileTheme,
    required this.contactEmail,
    this.address,
    this.slogan,
    this.averageRating,
    this.reviewCount,
    this.openingHours,
    this.phone,
    this.whatsapp,
    this.website,
    this.instagram,
    this.facebook,
    this.tiktok,
    this.partners = const [],
    this.paymentInstructions,
    this.category,
    this.latitude,
    this.longitude,
    this.isAvailable = true, 
    required this.welcomeMessage,
    this.showWelcomeModule = true,
    this.welcomeModuleType = 'text',
    this.welcomeVideoUrl,
    this.welcomeVideoSourceType,
    this.showPortfolioModule = true,
    this.showReviewsModule = true,
    this.showPromotionsModule = true,
    this.showGiftCardModule = true,
    this.showBookingModule = true,
    this.showQuotesModule = false,
  });

  /// Constructor factory INTELIGENTE para leer desde Firestore.
  /// Maneja tanto estructuras anidadas ('users') como planas ('brandProfiles').
 factory ProviderProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // 1. Intentamos leer del mapa 'personalization' (Estructura nueva)
    final nested = data['personalization'] as Map<String, dynamic>? ?? {};
    
    // 2. Función auxiliar para buscar el dato en 'nested' y si no, en 'data' (raíz)
    dynamic get(String key) => nested[key] ?? data[key];

    // Leer mapas de configuración de módulos (estos suelen estar anidados)
    final welcomeModule = (get('welcomeModule') as Map<String, dynamic>?) ?? {};
    final portfolioModule = (get('portfolioModule') as Map<String, dynamic>?) ?? {};
    final reviewsModule = (get('reviewsModule') as Map<String, dynamic>?) ?? {};
    final promotionsModule = (get('promotionsModule') as Map<String, dynamic>?) ?? {};
    final giftCardModule = (get('giftCardModule') as Map<String, dynamic>?) ?? {};
    final bookingModule = (get('bookingModule') as Map<String, dynamic>?) ?? {};
    final quotesModule = (get('quotesModule') as Map<String, dynamic>?) ?? {};

    // Leer listas de forma segura
    final List<Map<String, dynamic>> partnersList =
        (get('partners') as List<dynamic>?)
                ?.map((item) => Map<String, dynamic>.from(item as Map))
                .toList() ?? [];
                
    final List<Map<String, dynamic>> paymentMethodsList =
        (get('paymentMethods') as List<dynamic>?)
                ?.map((item) => Map<String, dynamic>.from(item as Map))
                .toList() ?? [];

    return ProviderProfileModel(
      providerId: doc.id,
      // Usamos 'get()' para buscar en ambos lugares
      businessName: get('businessName') as String? ?? 'Nombre del Negocio',
      logoUrl: get('logoUrl') as String? ?? '',
      brandColor: _colorFromHex(get('primaryColor') as String?) ?? Colors.deepPurple,
      activeModules: List<String>.from(data['activeModules'] as List<dynamic>? ?? []),
      profileType: data['publicProfileTemplate'] as String? ?? get('publicProfileTemplate') as String? ?? 'store',
      contactEmail: get('contactEmail') as String? ?? data['email'] as String? ?? '',
      address: get('address') as String?,

      // Campos adicionales
      slogan: get('slogan') as String?,
      averageRating: (get('averageRating') as num?)?.toDouble(),
      reviewCount: get('reviewCount') as int?,
      openingHours: get('openingHours') as String?,
      phone: get('phone') as String?,
      whatsapp: get('whatsapp') as String?,

      // Redes Sociales
      website: get('website') as String?,
      instagram: get('instagram') as String?,
      facebook: get('facebook') as String?,
      tiktok: get('tiktok') as String?,
      
      // Listas
      partners: partnersList,
     

      // Módulos
      showWelcomeModule: welcomeModule['show'] as bool? ?? true,
      welcomeModuleType: welcomeModule['type'] as String? ?? 'text',
      welcomeMessage: welcomeModule['text_content'] as String? ?? get('welcomeMessage') as String? ?? 'Bienvenido a mi perfil.',
      welcomeVideoUrl: welcomeModule['video_url'] as String?,
      welcomeVideoSourceType: welcomeModule['video_source_type'] as String?,

      showPortfolioModule: portfolioModule['show'] as bool? ?? true,
      showReviewsModule: reviewsModule['show'] as bool? ?? true,
      showPromotionsModule: promotionsModule['show'] as bool? ?? true,
      showGiftCardModule: giftCardModule['show'] as bool? ?? true,
      showBookingModule: bookingModule['show'] as bool? ?? true,
      showQuotesModule: quotesModule['show'] as bool? ?? false,
    );
  }

  ProviderProfileModel copyWith({
    String? providerId,
    String? businessName,
    String? logoUrl,
    Color? brandColor,
    List<String>? activeModules,
    String? profileType,
    String? publicProfileTheme,
    String? contactEmail,
    String? address,
    String? slogan,
    double? averageRating,
    int? reviewCount,
    String? openingHours,
    String? phone,
    String? whatsapp,
    String? website,
    String? instagram,
    String? facebook,
    String? tiktok,
    List<Map<String, dynamic>>? partners,
    String? paymentInstructions,
    String? category,
    double? latitude,
    double? longitude,
    bool? isAvailable,
    String? welcomeMessage,
    bool? showWelcomeModule,
    String? welcomeModuleType,
    String? welcomeVideoUrl,
    String? welcomeVideoSourceType,
    bool? showPortfolioModule,
    bool? showReviewsModule,
    bool? showPromotionsModule,
    bool? showGiftCardModule,
    bool? showBookingModule,
    bool? showQuotesModule,
  }) {
    return ProviderProfileModel(
      providerId: providerId ?? this.providerId,
      businessName: businessName ?? this.businessName,
      logoUrl: logoUrl ?? this.logoUrl,
      brandColor: brandColor ?? this.brandColor,
      activeModules: activeModules ?? this.activeModules,
      profileType: profileType ?? this.profileType,
      publicProfileTheme: publicProfileTheme ?? this.publicProfileTheme,
      contactEmail: contactEmail ?? this.contactEmail,
      address: address ?? this.address,
      slogan: slogan ?? this.slogan,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      openingHours: openingHours ?? this.openingHours,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      website: website ?? this.website,
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      tiktok: tiktok ?? this.tiktok,
      partners: partners ?? this.partners,
      paymentInstructions: paymentInstructions ?? this.paymentInstructions,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isAvailable: isAvailable ?? this.isAvailable,
      welcomeMessage: welcomeMessage ?? this.welcomeMessage,
      showWelcomeModule: showWelcomeModule ?? this.showWelcomeModule,
      welcomeModuleType: welcomeModuleType ?? this.welcomeModuleType,
      welcomeVideoUrl: welcomeVideoUrl ?? this.welcomeVideoUrl,
      welcomeVideoSourceType: welcomeVideoSourceType ?? this.welcomeVideoSourceType,
      showPortfolioModule: showPortfolioModule ?? this.showPortfolioModule,
      showReviewsModule: showReviewsModule ?? this.showReviewsModule,
      showPromotionsModule: showPromotionsModule ?? this.showPromotionsModule,
      showGiftCardModule: showGiftCardModule ?? this.showGiftCardModule,
      showBookingModule: showBookingModule ?? this.showBookingModule,
      showQuotesModule: showQuotesModule ?? this.showQuotesModule,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'logoUrl': logoUrl,
      'primaryColor': brandColor.value.toRadixString(16).padLeft(8, '0').substring(2),
      'publicProfileTheme': publicProfileTheme,
      'contactEmail': contactEmail,
      'address': address,
      'slogan': slogan,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'openingHours': openingHours,
      'phone': phone,
      'whatsapp': whatsapp,
      'website': website,
      'instagram': instagram,
      'facebook': facebook,
      'tiktok': tiktok,
      'partners': partners,
      'paymentInstructions': paymentInstructions,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'isAvailable': isAvailable,
      'welcomeModule': {
        'show': showWelcomeModule,
        'type': welcomeModuleType,
        'text_content': welcomeMessage,
        'video_url': welcomeVideoUrl,
        'video_source_type': welcomeVideoSourceType,
      },
      'portfolioModule': { 'show': showPortfolioModule },
      'reviewsModule': { 'show': showReviewsModule },
      'promotionsModule': { 'show': showPromotionsModule },
      'giftCardModule': { 'show': showGiftCardModule },
      'bookingModule': { 'show': showBookingModule },
      'quotesModule': { 'show': showQuotesModule },
    };
  }
} 

Color? _colorFromHex(String? hexColor) {
  if (hexColor == null) return null;
  final hexCode = hexColor.replaceAll('#', '');
  if (hexCode.length == 6) {
    try {
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return null;
    }
  }
  return null;
}