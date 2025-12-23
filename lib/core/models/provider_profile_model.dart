import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Un modelo de datos que representa el perfil público de un proveedor.
/// Diseñado para ser compatible con estructuras de datos planas y anidadas.
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
  final String planType;
  final String? publicProfileTemplate; // Campo clave
  final String? primaryColor;
  final String? mainCategory; // ✅ Campo clave para Servi

  // --- Campos Adicionales ---
  final String? slogan;
  final double? averageRating;
  final int? reviewCount;
  final String? openingHours;
  final String? phone;
  final String? whatsapp;

  // --- Redes Sociales ---
  final String? website;
  final String? instagram;
  final String? facebook;
  final String? tiktok;

  // --- Partners y Pagos ---
  final List<Map<String, dynamic>> partners;
  final String? paymentInstructions;

  // --- Geo, Categoría y Disponibilidad ---
  final String? category;
  final double? latitude;
  final double? longitude;
  final bool isAvailable;
  final String? country;

  // --- Módulo de Bienvenida ---
  final bool showWelcomeModule;
  final String welcomeModuleType;
  final String welcomeMessage;
  final String? welcomeVideoUrl;
  final String? welcomeVideoSourceType;

  // --- Control de Visibilidad de Módulos ---
  final bool showPortfolioModule;
  final bool showReviewsModule;
  final bool showPromotionsModule;
  final bool showGiftCardModule;
  final bool showBookingModule;
  final bool showQuotesModule;

  const ProviderProfileModel({
    this.planType = 'free',
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
    this.publicProfileTemplate,
    this.country,
    this.primaryColor,
    this.mainCategory // ✅ Correcto en el constructor
  });

  /// Constructor factory inteligente para leer desde Firestore.
  factory ProviderProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // 1. Intentamos leer del mapa 'personalization' (Estructura anidada si existe)
    final nested = data['personalization'] as Map<String, dynamic>? ?? {};
    
    // 2. Función auxiliar robusta: Raíz tiene prioridad sobre anidado
    dynamic get(String key) => data[key] ?? nested[key];

    // Leer mapas de configuración de módulos de forma segura
    final welcomeModule = (get('welcomeModule') as Map<String, dynamic>?) ?? {};
    final portfolioModule = (get('portfolioModule') as Map<String, dynamic>?) ?? {};
    final reviewsModule = (get('reviewsModule') as Map<String, dynamic>?) ?? {};
    final promotionsModule = (get('promotionsModule') as Map<String, dynamic>?) ?? {};
    final giftCardModule = (get('giftCardModule') as Map<String, dynamic>?) ?? {};
    final bookingModule = (get('bookingModule') as Map<String, dynamic>?) ?? {};
    final quotesModule = (get('quotesModule') as Map<String, dynamic>?) ?? {};

    // Leer lista de partners
    final List<Map<String, dynamic>> partnersList =
        (get('partners') as List<dynamic>?)
                ?.map((item) => Map<String, dynamic>.from(item as Map))
                .toList() ?? [];

    return ProviderProfileModel(
      providerId: doc.id,
      mainCategory: get('mainCategory') as String?, // ✅ Correcto: lee de la DB
      businessName: get('businessName') as String? ?? 'Nombre del Negocio',
      logoUrl: get('logoUrl') as String? ?? '',
      brandColor: _colorFromHex(get('primaryColor') as String?) ?? Colors.deepPurple,
      activeModules: List<String>.from(data['activeModules'] as List<dynamic>? ?? []),
      
      profileType: get('profileType') as String? ?? get('publicProfileTemplate') as String? ?? 'social',
      
      contactEmail: get('contactEmail') as String? ?? data['email'] as String? ?? '',
      address: get('address') as String?,
      planType: data['planType'] as String? ?? 'free',

      slogan: get('slogan') as String?,
      averageRating: (get('averageRating') as num?)?.toDouble(),
      reviewCount: get('reviewCount') as int?,
      openingHours: get('openingHours') as String?,
      phone: get('phone') as String?,
      whatsapp: get('whatsapp') as String?,

      website: get('website') as String?,
      instagram: get('instagram') as String?,
      facebook: get('facebook') as String?,
      tiktok: get('tiktok') as String?,
      
      country: get('country') as String?,
      
      partners: partnersList,
      paymentInstructions: get('paymentInstructions') as String?,

      category: data['mainCategory'] as String? ?? data['category'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      
      publicProfileTemplate: get('publicProfileTemplate') as String?,
      publicProfileTheme: get('publicProfileTheme') as String?,
      isAvailable: data['isAvailable'] as bool? ?? true,
      primaryColor: get('primaryColor') as String?,

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

  /// Crea una copia del modelo con campos actualizados.
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
    String? planType,
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
    String? publicProfileTemplate,
    String? country,
    String? primaryColor,
    String? mainCategory, // ✅ Agregado argumento
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
      planType: planType ?? this.planType,
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
      publicProfileTemplate: publicProfileTemplate ?? this.publicProfileTemplate,
      country: country ?? this.country,
      primaryColor: primaryColor ?? this.primaryColor,
      mainCategory: mainCategory ?? this.mainCategory, // ✅ Agregada asignación
    );
  }

  /// Convierte el modelo a un mapa para guardar en Firestore.
  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'logoUrl': logoUrl,
      // Usamos toARGB32() para evitar el warning de deprecación de .value
      'primaryColor': brandColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2),
      'profileType': profileType,
      'publicProfileTheme': publicProfileTheme,
      'contactEmail': contactEmail,
      'address': address,
      'planType': planType,
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
      'country': country,
      'partners': partners,
      'paymentInstructions': paymentInstructions,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'publicProfileTemplate': publicProfileTemplate,
      'isAvailable': isAvailable,
      'mainCategory': mainCategory, // ✅ Agregado: CRÍTICO para que se guarde en DB
      'welcomeModule': {
        'show': showWelcomeModule,
        'type': welcomeModuleType,
        'text_content': welcomeMessage,
        'video_url': welcomeVideoUrl,
        'video_source_type': welcomeVideoSourceType,
      },
      'portfolioModule': {'show': showPortfolioModule},
      'reviewsModule': {'show': showReviewsModule},
      'promotionsModule': {'show': showPromotionsModule},
      'giftCardModule': {'show': showGiftCardModule},
      'bookingModule': {'show': showBookingModule},
      'quotesModule': {'show': showQuotesModule},
    };
  }
}

/// Función de utilidad para convertir un string hex a [Color].
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