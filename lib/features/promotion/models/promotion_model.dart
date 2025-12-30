import 'package:cloud_firestore/cloud_firestore.dart';

/// Define el disparador inteligente analizado por Servi.
enum PromotionTrigger { 
  lowStock,    // Liquidación por bajo movimiento o stock estancado
  lowDensity,  // Refuerzo para días con pocas citas/ventas
  seasonal,    // Anticipación: Día de la madre, Navidad, etc.
  custom       // Configuración manual del profesional
}

/// Define el tipo de activo comercial
enum PromotionType {
  DISCOUNT,    // Oferta sobre producto físico
  GIFT_CARD    // Tarjeta de regalo digital
}

class PromotionModel {
  final String id;
  final String title;
  final String? description;
  final String? bannerUrl;
  final String providerId;

  // --- CLASIFICACIÓN Y ESTILO ---
  final PromotionType type; // 🚨 Campo crítico para la UI
  final String? style;      // 'Cyber', 'Gold', 'Love'
  final DateTime createdAt; // Para ordenamiento
  
  // --- ENLACE TÉCNICO ---
  final String? productId;  // ID del producto real
  final String? categoryId; // Si aplica a una categoría entera
  
  // --- ALGORITMO DE RENTABILIDAD ---
  final double discountPercentage; // Para mostrar el badge "-20%"
  final double promoPrice;         // El precio que paga el cliente final
  final double minPriceAllowed;    // wholesalePrice + margen_seguridad
  
  // --- INTELIGENCIA TEMPORAL ---
  final List<int> activeDays; // 1=Lunes, 7=Domingo
  final DateTime? startDate;
  final DateTime? endDate;    //
  
  final PromotionTrigger trigger;
  final bool isActive;        //

  const PromotionModel({
    required this.id,
    required this.title,
    this.description,
    this.bannerUrl,
    required this.type,
    this.style,
    required this.createdAt,
    this.productId,
    this.categoryId,
    required this.discountPercentage,
    required this.promoPrice,
    required this.minPriceAllowed,
    this.activeDays = const [],
    this.startDate,
    this.endDate,
    required this.trigger,
    this.isActive = true,
    required this.providerId,
  });

  // --- MÉTODOS DE VALIDACIÓN TÉCNICA ---

  /// Verifica si la promoción es rentable antes de publicarla.
  /// Evita vender por debajo del wholesalePrice.
  bool get isSafe => promoPrice >= minPriceAllowed;

  /// Validación local de vigencia para el frontend
  bool get isAvailableToday {
    final now = DateTime.now();
    // 1. Verificar si está activa manualmente
    if (!isActive) return false;
    // 2. Verificar fecha de expiración
    if (endDate != null && endDate!.isBefore(now)) return false;
    // 3. Verificar si aplica para el día de la semana actual
    if (activeDays.isNotEmpty && !activeDays.contains(now.weekday)) return false;
    
    return true;
  }

  // --- SERIALIZACIÓN ---

  factory PromotionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PromotionModel(
      id: doc.id,
      providerId: data['providerId'] ?? '', // ✅ Mapeo
      title: data['title'] ?? '',
      description: data['description'],
      bannerUrl: data['bannerUrl'],
      // Nuevos campos integrados
      type: _parseType(data['type']),
      style: data['style'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // Datos de inventario y costos
      productId: data['productId'],
      categoryId: data['categoryId'],
      discountPercentage: (data['discountPercentage'] ?? 0).toDouble(),
      promoPrice: (data['promoPrice'] ?? 0).toDouble(),
      minPriceAllowed: (data['minPriceAllowed'] ?? 0).toDouble(),
      activeDays: List<int>.from(data['activeDays'] ?? []),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      trigger: _parseTrigger(data['trigger']),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'providerId': providerId, // ✅ Persistencia
      'bannerUrl': bannerUrl,
      'type': type.name,
      'style': style,
      'createdAt': FieldValue.serverTimestamp(),
      'productId': productId,
      'categoryId': categoryId,
      'discountPercentage': discountPercentage,
      'promoPrice': promoPrice,
      'minPriceAllowed': minPriceAllowed,
      'activeDays': activeDays,
      'startDate': startDate,
      'endDate': endDate,
      'trigger': trigger.name,
      'isActive': isActive,
    };
  }

  static PromotionTrigger _parseTrigger(String? trigger) {
    return PromotionTrigger.values.firstWhere(
      (e) => e.name == trigger,
      orElse: () => PromotionTrigger.custom,
    );
  }

  static PromotionType _parseType(String? type) {
    return PromotionType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => PromotionType.DISCOUNT,
    );
  }
}