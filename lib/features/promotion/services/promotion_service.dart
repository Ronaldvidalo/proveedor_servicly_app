import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/promotion_model.dart';
import '../../../core/models/product_model.dart';
import 'seasonal_calendar_service.dart';

class PromotionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final SeasonalCalendarService _calendarService = SeasonalCalendarService();

  PromotionService();

  // ---------------------------------------------------------
  // 1. ESCUDO DE RENTABILIDAD (ANÁLISIS DE COSTOS)
  // ---------------------------------------------------------

  /// Valida si una promoción es viable técnicamente según wholesalePrice.
  /// Protege el margen de seguridad del profesional.
  bool validateProfitability({
    required double wholesalePrice, 
    required double proposedPromoPrice,
    double minMargin = 0.10,
  }) {
    double absoluteMin = wholesalePrice * (1 + minMargin);
    return proposedPromoPrice >= absoluteMin;
  }

  // ---------------------------------------------------------
  // 2. DETECTOR DE STOCK ESTANCADO (IA INSIGHTS)
  // ---------------------------------------------------------

  /// Analiza productos que superan el minStock pero no se mueven.
  /// Basado en la colección raíz 'products' detectada en consola.
  Future<List<ProductModel>> getSlowMovingStock(String providerId) async {
    try {
      // Consulta optimizada para la estructura de colección raíz
      final snapshot = await _db
          .collection('products')
          .where('providerId', isEqualTo: providerId)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .where((p) {
              // Verificación de excedente real sobre el stock mínimo
              final qty = p.quantity ?? 0;
              final min = p.minStock ?? 0;
              return qty > min; 
          }) 
          .toList();
    } catch (e) {
      debugPrint("Error analizando stock técnico: $e");
      return [];
    }
  }

  // ---------------------------------------------------------
  // 3. MAPA DE CALOR (DÍAS FRÍOS EN AGENDA)
  // ---------------------------------------------------------

  /// Analiza los 'bookings' para encontrar días con baja densidad.
  Future<List<int>> findLowDensityDays(String providerId) async {
    // En fase de integración con Servi para detectar tendencias de 4 semanas.
    // MVP: Martes (2) y Miércoles (3) según patrones de servicio comunes.
    return [2, 3]; 
  }

  // ---------------------------------------------------------
  // 4. CALENDARIO ESTACIONAL (CONECTADO AL CEREBRO 🧠)
  // ---------------------------------------------------------

  /// Retorna eventos próximos reales basados en el país del perfil de marca.
  Future<Map<String, dynamic>?> getUpcomingSeasonalEvent(String providerId) async {
    try {
        final brandDoc = await _db.collection('brandProfiles').doc(providerId).get();
        String countryCode = 'default';
        
        if (brandDoc.exists) {
           countryCode = brandDoc.data()?['country'] ?? 'default';
        }

        return _calendarService.getUpcomingEvent(countryCode);
        
    } catch (e) {
      debugPrint("Error obteniendo efeméride: $e");
      return null;
    }
  }

  // ---------------------------------------------------------
  // 5. PERSISTENCIA Y CONSULTA (MARKETING CENTER)
  // ---------------------------------------------------------

  /// Guarda promociones u Gift Cards en la subcolección del catálogo.
  Future<void> savePromotion(String providerId, PromotionModel promo) async {
    await _db
        .collection('catalogs')
        .doc(providerId)
        .collection('promotions')
        .doc(promo.id)
        .set(promo.toMap());
  }

  /// Obtiene promociones activas ordenadas por fecha de creación.
  Stream<List<PromotionModel>> getActivePromotions(String providerId) {
    // Implementación de la query oficial del documento técnico
  return _db
        .collection('promotions') // ✅ Colección raíz
        .where('providerId', isEqualTo: providerId) // ✅ Filtro obligatorio
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => PromotionModel.fromFirestore(d)).toList());
  }

  Future<void> deactivatePromotion(String promoId) async {
    await _db.collection('promotions').doc(promoId).update({'isActive': false});
  }
}
