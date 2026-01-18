import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Clase de apoyo para definir rangos de tiempo (ej. 08:00 a 13:00)
class TimeRange {
  final String start;
  final String end;

  TimeRange({required this.start, required this.end});

  Map<String, dynamic> toMap() => {
    'start': start,
    'end': end,
  };

  factory TimeRange.fromMap(Map<String, dynamic> map) {
    return TimeRange(
      start: map['start'] as String? ?? '',
      end: map['end'] as String? ?? '',
    );
  }
}

class ProviderProfileModel {
  final String id;
  // Es String NO NULO. Si viene nulo de Firebase, fromFirestore le asigna doc.id
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
  final String? publicProfileTemplate;
  final String? primaryColor;
  final String? mainCategory;
  final String? coverImageUrl;
  final String? promoTitle;
  final String? promoSubtitle;

  // --- Campos Adicionales ---
  final String? slogan;
  
  // ✅ CAMPOS ESTANDARIZADOS PARA RATING
  final double ratingAvg;   
  final int ratingCount;    
  
  final String? openingHours;
  final String? phone;
  final String? whatsapp;
  final String actionType;

  // --- CAMPOS DE ACCIÓN DEL BOTÓN ---
  final String? bookingActionType; // 'agenda' o 'presupuesto'
  final String? bookingButtonText; // Texto automático

  // --- Redes Sociales ---
  final String? website;
  final String? instagram;
  final String? facebook;
  final String? tiktok;

  // --- Partners y Trust Signals ---
  final List<Map<String, dynamic>> partners;
  final List<Map<String, dynamic>> trustSignals; 
  final String? paymentInstructions;

  // --- Geo, Categoría y Disponibilidad ---
  final String? category;
  final double? latitude;
  final double? longitude;
  final bool isAvailable;
  final String? country;

  // --- Módulos ---
  final bool showWelcomeModule;
  final String welcomeModuleType;
  final String welcomeMessage;
  final String? welcomeVideoUrl;
  final String? welcomeVideoSourceType;

  final bool showPortfolioModule;
  final bool showReviewsModule;
  final bool showPromotionsModule;
  final bool showGiftCardModule;
  final bool showBookingModule;
  final bool showQuotesModule;

  // --- NUEVOS CAMPOS DE DISPONIBILIDAD TÉCNICA ---
  final Map<int, List<TimeRange>>? weeklySchedule;
  final int slotDuration; 
  final bool worksOnHolidays; 

  // Metadatos
  final bool isVerified;
  final bool isActive;
  final DateTime? createdAt;

  const ProviderProfileModel({
    required this.id,
    required this.providerId,
    required this.businessName,
    required this.logoUrl,
    required this.brandColor,
    required this.activeModules,
    required this.profileType,
    required this.contactEmail,
    required this.welcomeMessage,
    this.planType = 'free',
    this.publicProfileTheme,
    this.address,
    this.slogan,
    
    // ✅ Inicialización por defecto
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
    
    this.openingHours,
    this.phone,
    this.whatsapp,
    this.website,
    this.instagram,
    this.facebook,
    this.tiktok,
    this.partners = const [],
    this.trustSignals = const [],
    this.paymentInstructions,
    this.category,
    this.latitude,
    this.longitude,
    this.isAvailable = true,
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
    this.mainCategory,
    this.coverImageUrl,
    this.promoTitle,
    this.promoSubtitle,
    this.bookingActionType,
    this.bookingButtonText,
    this.actionType = 'booking',
    this.weeklySchedule,
    this.slotDuration = 30,
    this.worksOnHolidays = false,
    this.isVerified = false,
    this.isActive = true,
    this.createdAt,
  });

  factory ProviderProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final nested = data['personalization'] as Map<String, dynamic>? ?? {};
    
    dynamic get(String key) => data[key] ?? nested[key];

    String rawLogo = get('logoUrl') as String? ?? '';
    String safeLogo = rawLogo.toLowerCase().contains('.mp4') ? '' : rawLogo;

    final welcomeModule = (get('welcomeModule') as Map<String, dynamic>?) ?? {};
    final portfolioModule = (get('portfolioModule') as Map<String, dynamic>?) ?? {};
    final reviewsModule = (get('reviewsModule') as Map<String, dynamic>?) ?? {};
    final promotionsModule = (get('promotionsModule') as Map<String, dynamic>?) ?? {};
    final giftCardModule = (get('giftCardModule') as Map<String, dynamic>?) ?? {};
    final bookingModule = (get('bookingModule') as Map<String, dynamic>?) ?? {};
    final quotesModule = (get('quotesModule') as Map<String, dynamic>?) ?? {};

    final scheduleData = get('weeklySchedule') as Map<String, dynamic>?;
    Map<int, List<TimeRange>>? parsedSchedule;
    if (scheduleData != null) {
      parsedSchedule = scheduleData.map((key, value) {
        final dayKey = int.tryParse(key.toString()) ?? 0;
        final slots = (value as List<dynamic>?)?.map((s) {
          return TimeRange.fromMap(Map<String, dynamic>.from(s as Map));
        }).toList();
        return MapEntry(dayKey, slots ?? []);
      });
    }

    return ProviderProfileModel(
      id: doc.id,
      // AQUÍ SE ASEGURA QUE NUNCA SEA NULO
      providerId: data['providerId'] as String? ?? doc.id,
      businessName: get('businessName') as String? ?? 'Nombre del Negocio',
      logoUrl: safeLogo,
      brandColor: _colorFromHex(get('primaryColor') as String?) ?? Colors.deepPurple,
      activeModules: List<String>.from(data['activeModules'] as List<dynamic>? ?? []),
      profileType: get('profileType') as String? ?? get('publicProfileTemplate') as String? ?? 'social',
      contactEmail: get('contactEmail') as String? ?? data['email'] as String? ?? '',
      address: get('address') as String?,
      planType: data['planType'] as String? ?? 'free',
      slogan: get('slogan') as String?,
      
      // ✅ Lectura robusta con paréntesis para el casteo correcto
      ratingAvg: ((get('ratingAvg') ?? get('ranking_promedio') ?? get('averageRating')) as num?)?.toDouble() ?? 0.0,
      ratingCount: ((get('ratingCount') ?? get('total_valoraciones') ?? get('reviewCount')) as num?)?.toInt() ?? 0,
      
      openingHours: get('openingHours') as String?,
      phone: get('phone') as String?,
      whatsapp: get('whatsapp') as String?,
      website: get('website') as String?,
      instagram: get('instagram') as String?,
      facebook: get('facebook') as String?,
      tiktok: get('tiktok') as String?,
      country: get('country') as String?,
      partners: (get('partners') as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList(),
      trustSignals: (data['trustSignals'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList(),
      paymentInstructions: get('paymentInstructions') as String?,
      category: data['mainCategory'] as String? ?? data['category'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      publicProfileTemplate: get('publicProfileTemplate') as String?,
      publicProfileTheme: get('publicProfileTheme') as String?,
      isAvailable: data['isAvailable'] as bool? ?? true,
      primaryColor: get('primaryColor') as String?,
      mainCategory: get('mainCategory') as String?,
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
      coverImageUrl: data['coverImageUrl'] as String?,
      promoTitle: data['promoTitle'] as String?,
      promoSubtitle: data['promoSubtitle'] as String?,
      bookingActionType: data['bookingActionType'] as String?, 
      bookingButtonText: data['bookingButtonText'] as String?,
      actionType: data['actionType'] ?? 'booking',
      weeklySchedule: parsedSchedule,
      slotDuration: data['slotDuration'] as int? ?? 30,
      worksOnHolidays: data['worksOnHolidays'] as bool? ?? false,
      
      isVerified: data['isVerified'] ?? false,
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : null,
    );
  }

  ProviderProfileModel copyWith({
    String? id,
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
    double? ratingAvg,
    int? ratingCount, 
    String? openingHours,
    String? phone,
    String? whatsapp,
    String? website,
    String? instagram,
    String? facebook,
    String? tiktok,
    List<Map<String, dynamic>>? partners,
    List<Map<String, dynamic>>? trustSignals,
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
    String? mainCategory,
    String? coverImageUrl,
    String? promoTitle,
    String? promoSubtitle,
    Map<int, List<TimeRange>>? weeklySchedule,
    int? slotDuration,
    bool? worksOnHolidays,
    bool? isVerified,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ProviderProfileModel(
      id: id ?? this.id,
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
      ratingAvg: ratingAvg ?? this.ratingAvg, 
      ratingCount: ratingCount ?? this.ratingCount, 
      openingHours: openingHours ?? this.openingHours,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      website: website ?? this.website,
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      tiktok: tiktok ?? this.tiktok,
      partners: partners ?? this.partners,
      trustSignals: trustSignals ?? this.trustSignals,
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
      mainCategory: mainCategory ?? this.mainCategory,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      promoTitle: promoTitle ?? this.promoTitle,
      promoSubtitle: promoSubtitle ?? this.promoSubtitle,
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
      slotDuration: slotDuration ?? this.slotDuration,
      worksOnHolidays: worksOnHolidays ?? this.worksOnHolidays,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {
      'providerId': providerId,
      'businessName': businessName,
      'logoUrl': logoUrl,
      // ✅ CORRECCIÓN: Uso de .value en lugar de .toARGB32()
      'primaryColor': '#${brandColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
      'profileType': profileType,
      'planType': planType,
      'isAvailable': isAvailable,
      'actionType': actionType,
      'welcomeModule': {
        'show': showWelcomeModule,
        'type': welcomeModuleType,
        'text_content': welcomeMessage,
        if (welcomeVideoUrl != null) 'video_url': welcomeVideoUrl,
        if (welcomeVideoSourceType != null) 'video_source_type': welcomeVideoSourceType,
      },
      'portfolioModule': {'show': showPortfolioModule},
      'reviewsModule': {'show': showReviewsModule},
      'promotionsModule': {'show': showPromotionsModule},
      'giftCardModule': {'show': showGiftCardModule},
      'bookingModule': {'show': showBookingModule},
      'quotesModule': {'show': showQuotesModule},
      'slotDuration': slotDuration,
      'worksOnHolidays': worksOnHolidays,
      
      'ratingAvg': ratingAvg,
      'ratingCount': ratingCount,
      
      'isVerified': isVerified,
      'isActive': isActive,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };

    if (weeklySchedule != null) {
      data['weeklySchedule'] = weeklySchedule!.map((key, value) {
        return MapEntry(key.toString(), value.map((v) => v.toMap()).toList());
      });
    }

    void addIfValid(String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.isEmpty) return;
      if (value is List && value.isEmpty) return;
      data[key] = value;
    }

    addIfValid('publicProfileTheme', publicProfileTheme);
    addIfValid('contactEmail', contactEmail);
    addIfValid('address', address);
    addIfValid('slogan', slogan);
    addIfValid('openingHours', openingHours);
    addIfValid('phone', phone);
    addIfValid('whatsapp', whatsapp);
    addIfValid('website', website);
    addIfValid('instagram', instagram);
    addIfValid('facebook', facebook);
    addIfValid('tiktok', tiktok);
    addIfValid('country', country);
    addIfValid('partners', partners);
    addIfValid('trustSignals', trustSignals);
    addIfValid('paymentInstructions', paymentInstructions);
    addIfValid('category', category);
    addIfValid('latitude', latitude);
    addIfValid('longitude', longitude);
    addIfValid('publicProfileTemplate', publicProfileTemplate);
    addIfValid('mainCategory', mainCategory);
    addIfValid('coverImageUrl', coverImageUrl);
    addIfValid('promoTitle', promoTitle);
    addIfValid('promoSubtitle', promoSubtitle);
    addIfValid('bookingActionType', bookingActionType);
    addIfValid('bookingButtonText', bookingButtonText);

    return data;
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
  } else if (hexCode.length == 8) {
     try {
      return Color(int.parse(hexCode, radix: 16));
    } catch (e) {
      return null;
    }
  }
  return null;
}