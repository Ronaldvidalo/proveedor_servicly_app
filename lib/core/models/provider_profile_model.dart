import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// Para debugPrint

/// Un modelo de datos que representa el perfil público de un proveedor.
class ProviderProfileModel {
  /// El identificador único del proveedor.
  final String providerId;

  /// El nombre comercial personalizado establecido por el proveedor.
  final String businessName;

  /// La URL del logo del proveedor.
  final String logoUrl;

  /// El color de marca principal elegido por el proveedor.
  final Color brandColor;

  /// Una lista de los IDs de los módulos que están activos para este proveedor.
  final List<String> activeModules;

  /// Este campo define el tipo de perfil (ej: 'store', 'booking', 'social').
  final String profileType;

  /// El email de contacto público.
  final String contactEmail;

  /// La dirección física del negocio, si se ha proporcionado.
  final String? address;

  // --- Campos Adicionales (Basados en el Mockup) ---
  final String? slogan;
  final double? averageRating;
  final int? reviewCount;
  final String? openingHours;
  final String? phone;
  final String? whatsapp;

  // --- ¡NUEVOS CAMPOS DE REDES! ---
  final String? website;
  final String? instagram;
  final String? facebook;
  final String? tiktok;

  // --- ¡NUEVO CAMPO DE PARTNERS! ---
  final List<Map<String, dynamic>> partners;
  
  // --- ¡NUEVO CAMPO DE PAGO P2P! ---
  final String? paymentInstructions; // <-- ¡AÑADIDO! (1/5)

  // --- Campos del Módulo de Bienvenida ---
  final bool showWelcomeModule;
  final String welcomeModuleType; // 'text' o 'video'
  final String welcomeMessage;
  final String? welcomeVideoUrl;
  final String? welcomeVideoSourceType; // 'url' o 'upload'

  // --- Campos: Control de Visibilidad de Módulos ---
  final bool showPortfolioModule;
  final bool showReviewsModule;
  final bool showPromotionsModule;
  final bool showGiftCardModule;
  final bool showBookingModule; // Módulo "Agendar Cita"
  final bool showQuotesModule; // Módulo de Presupuestos

  /// Crea una instancia de [ProviderProfileModel].
  const ProviderProfileModel({
    required this.providerId,
    required this.businessName,
    required this.logoUrl,
    required this.brandColor,
    required this.activeModules,
    required this.profileType,
    required this.contactEmail,
    this.address,
    // Nuevos campos
    this.slogan,
    this.averageRating,
    this.reviewCount,
    this.openingHours,
    this.phone,
    this.whatsapp,
    // --- ¡AÑADIDOS AL CONSTRUCTOR! ---
    this.website,
    this.instagram,
    this.facebook,
    this.tiktok,
    this.partners = const [],
    this.paymentInstructions, // <-- ¡AÑADIDO! (2/5)
    // Welcome module fields
    required this.welcomeMessage,
    this.showWelcomeModule = true,
    this.welcomeModuleType = 'text',
    this.welcomeVideoUrl,
    this.welcomeVideoSourceType,
    // Module visibility controls
    this.showPortfolioModule = true,
    this.showReviewsModule = true,
    this.showPromotionsModule = true, // Default true
    this.showGiftCardModule = true, // Default true
    this.showBookingModule = true, // Activo por defecto
    this.showQuotesModule = false, // Inactivo por defecto
  });

  /// Constructor factory para crear un [ProviderProfileModel] desde un documento de Firestore.
  factory ProviderProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final personalization = data['personalization'] as Map<String, dynamic>? ?? {};

    // Leer mapas de configuración de módulos
    final welcomeModule = personalization['welcomeModule'] as Map<String, dynamic>? ?? {};
    final portfolioModule = personalization['portfolioModule'] as Map<String, dynamic>? ?? {};
    final reviewsModule = personalization['reviewsModule'] as Map<String, dynamic>? ?? {};
    final promotionsModule = personalization['promotionsModule'] as Map<String, dynamic>? ?? {};
    final giftCardModule = personalization['giftCardModule'] as Map<String, dynamic>? ?? {};
    final bookingModule = personalization['bookingModule'] as Map<String, dynamic>? ?? {};
    final quotesModule = personalization['quotesModule'] as Map<String, dynamic>? ?? {};

    // --- ¡NUEVO! Leer la lista de partners de forma segura ---
    final List<Map<String, dynamic>> partnersList =
        (personalization['partners'] as List<dynamic>?)
                ?.map((item) => Map<String, dynamic>.from(item as Map))
                .toList() ??
            [];

    return ProviderProfileModel(
      providerId: doc.id,
      businessName: personalization['businessName'] as String? ?? 'Nombre del Negocio',
      logoUrl: personalization['logoUrl'] as String? ?? '',
      brandColor: _colorFromHex(personalization['primaryColor'] as String?) ?? Colors.deepPurple,
      activeModules: List<String>.from(data['activeModules'] as List<dynamic>? ?? []),
      profileType: data['publicProfileTemplate'] as String? ?? 'social',
      contactEmail: personalization['contactEmail'] as String? ?? data['email'] as String? ?? '',
      address: personalization['address'] as String?,

      // Leer campos adicionales desde 'personalization'
      slogan: personalization['slogan'] as String?,
      averageRating: (personalization['averageRating'] as num?)?.toDouble(),
      reviewCount: personalization['reviewCount'] as int?,
      openingHours: personalization['openingHours'] as String?,
      phone: personalization['phone'] as String?,
      whatsapp: personalization['whatsapp'] as String?,

      // --- ¡AÑADIDOS AL FACTORY! ---
      website: personalization['website'] as String?,
      instagram: personalization['instagram'] as String?,
      facebook: personalization['facebook'] as String?,
      tiktok: personalization['tiktok'] as String?,
      partners: partnersList,
      paymentInstructions: personalization['paymentInstructions'] as String?, // <-- ¡AÑADIDO! (3/5)

      // Leer campos del módulo de bienvenida
      showWelcomeModule: welcomeModule['show'] as bool? ?? true,
      welcomeModuleType: welcomeModule['type'] as String? ?? 'text',
      welcomeMessage: welcomeModule['text_content'] as String? ?? personalization['welcomeMessage'] as String? ?? 'Bienvenido a mi perfil.',
      welcomeVideoUrl: welcomeModule['video_url'] as String?,
      welcomeVideoSourceType: welcomeModule['video_source_type'] as String?,

      // Leer visibilidad de otros módulos
      showPortfolioModule: portfolioModule['show'] as bool? ?? true,
      showReviewsModule: reviewsModule['show'] as bool? ?? true,
      showPromotionsModule: promotionsModule['show'] as bool? ?? true,
      showGiftCardModule: giftCardModule['show'] as bool? ?? true,
      showBookingModule: bookingModule['show'] as bool? ?? true,
      showQuotesModule: quotesModule['show'] as bool? ?? false,
    );
  }

  /// Crea una copia de este modelo con los campos proporcionados sobrescritos.
  ProviderProfileModel copyWith({
    String? providerId,
    String? businessName,
    String? logoUrl,
    Color? brandColor,
    List<String>? activeModules,
    String? profileType,
    String? contactEmail,
    String? address,
    // Nuevos campos
    String? slogan,
    double? averageRating,
    int? reviewCount,
    String? openingHours,
    String? phone,
    String? whatsapp,
    // --- ¡AÑADIDOS AL COPYWITH! ---
    String? website,
    String? instagram,
    String? facebook,
    String? tiktok,
    List<Map<String, dynamic>>? partners,
    String? paymentInstructions, // <-- ¡AÑADIDO! (4/5)
    // Welcome module
    String? welcomeMessage,
    bool? showWelcomeModule,
    String? welcomeModuleType,
    String? welcomeVideoUrl,
    String? welcomeVideoSourceType,
    // Module visibility
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
      contactEmail: contactEmail ?? this.contactEmail,
      address: address ?? this.address,
      slogan: slogan ?? this.slogan,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      openingHours: openingHours ?? this.openingHours,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      // --- ¡AÑADIDOS AL COPYWITH! ---
      website: website ?? this.website,
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      tiktok: tiktok ?? this.tiktok,
      partners: partners ?? this.partners,
      paymentInstructions: paymentInstructions ?? this.paymentInstructions, // <-- ¡AÑADIDO!
      // Welcome module
      welcomeMessage: welcomeMessage ?? this.welcomeMessage,
      showWelcomeModule: showWelcomeModule ?? this.showWelcomeModule,
      welcomeModuleType: welcomeModuleType ?? this.welcomeModuleType,
      welcomeVideoUrl: welcomeVideoUrl ?? this.welcomeVideoUrl,
      welcomeVideoSourceType: welcomeVideoSourceType ?? this.welcomeVideoSourceType,
      // Module visibility
      showPortfolioModule: showPortfolioModule ?? this.showPortfolioModule,
      showReviewsModule: showReviewsModule ?? this.showReviewsModule,
      showPromotionsModule: showPromotionsModule ?? this.showPromotionsModule,
      showGiftCardModule: showGiftCardModule ?? this.showGiftCardModule,
      showBookingModule: showBookingModule ?? this.showBookingModule,
      showQuotesModule: showQuotesModule ?? this.showQuotesModule,
    );
  }

  /// Convierte este objeto ProviderProfileModel de nuevo a un Map anidado,
  /// listo para ser guardado en el campo 'personalization' de Firestore.
  Map<String, dynamic> toMap() {
    return {
      // Campos planos en 'personalization'
      'businessName': businessName,
      'logoUrl': logoUrl,
      'primaryColor': brandColor.value.toRadixString(16).padLeft(8, '0').substring(2),
      'contactEmail': contactEmail,
      'address': address,
      'slogan': slogan,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'openingHours': openingHours,
      'phone': phone,
      'whatsapp': whatsapp,
      // --- ¡AÑADIDOS AL TOMAP! ---
      'website': website,
      'instagram': instagram,
      'facebook': facebook,
      'tiktok': tiktok,
      'partners': partners,
      'paymentInstructions': paymentInstructions, // <-- ¡AÑADIDO! (5/5)

      // --- Módulos Anidados ---
      'welcomeModule': {
        'show': showWelcomeModule,
        'type': welcomeModuleType,
        'text_content': welcomeMessage,
        'video_url': welcomeVideoUrl,
        'video_source_type': welcomeVideoSourceType,
      },
      'portfolioModule': {
        'show': showPortfolioModule,
      },
      'reviewsModule': {
        'show': showReviewsModule,
      },
      'promotionsModule': {
        'show': showPromotionsModule,
      },
      'giftCardModule': {
        'show': showGiftCardModule,
      },
      'bookingModule': {
        'show': showBookingModule,
      },
      'quotesModule': {
        'show': showQuotesModule,
      },
    };
  }
} // Fin de la clase ProviderProfileModel

/// Función de utilidad para convertir un string de color hexadecimal a un objeto [Color].
Color? _colorFromHex(String? hexColor) {
  if (hexColor == null) return null;
  final hexCode = hexColor.replaceAll('#', '');
  if (hexCode.length == 6) {
    try {
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      debugPrint("Error parsing color: $hexColor");
      return null;
    }
  }
  return null;
}