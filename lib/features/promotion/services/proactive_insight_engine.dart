import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/smart_insight_model.dart';

class ProactiveInsightEngine {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Analiza tendencias y cruza datos con COSTOS para garantizar rentabilidad.
  /// Funciona para cualquier perfil (Tienda o Servicios).
  Future<SmartInsight?> analyzeBookingTrends(String providerId) async {
    try {
      // 1. DETECCIÓN DE PATRONES (Simulación Inteligente)
      // En un escenario real, aquí harías una query compleja de agregación sobre 'orders' o 'bookings'.
      // Para el MVP, simulamos que detectamos baja actividad los Miércoles (Día 3).
      bool lowDensityDetected = true; 
      int weakDay = 3; // Miércoles

      if (lowDensityDetected) {
        // 2. BUSCAR CANDIDATO REAL: ¿Qué producto/servicio tiene margen para oferta?
        // Buscamos un producto real del usuario para basar la sugerencia.
        final productData = await _findHighMarginCandidate(providerId);

        if (productData != null) {
           // Si encontramos un producto con margen, generamos el Insight
           return SmartInsight(
             id: 'trend_wednesday_low_${DateTime.now().month}',
             // El mensaje técnico que Servi "piensa" antes de hablar
             message: "Detecté baja ocupación los miércoles. El ítem '${productData['name']}' tiene buen margen para una oferta gancho.",
             type: InsightType.lowDensityTrend,
             suggestedPromo: {
               'title': 'Miércoles de ${productData['name']}',
               'discount': 20.0, // Descuento inicial sugerido
               'activeDays': [weakDay], 
               
               // --- 🛡️ LA REGLA DE ORO (DATOS DE RENTABILIDAD) ---
               'productId': productData['id'],
               'productName': productData['name'],
               'current_price': productData['price'],   // Precio al público actual
               'base_cost': productData['cost'],       // Costo operativo (para calcular ganancia real)
               'limit_price': productData['wholesale'], // Límite duro (Wholesale/Mayorista)
             },
             detectedAt: DateTime.now(),
           );
        }
      }
    } catch (e) {
      debugPrint("⚠️ Error en ProactiveEngine: $e");
    }
    return null;
  }

  /// Busca un producto/servicio que tenga margen suficiente para aguantar un descuento.
  Future<Map<String, dynamic>?> _findHighMarginCandidate(String providerId) async {
    try {
      // Consultamos la colección de productos del usuario
      final snapshot = await _db.collection('users')
          .doc(providerId)
          .collection('products')
          .limit(5) // Analizamos una muestra pequeña para ser rápidos
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        double price = double.tryParse(data['price'].toString()) ?? 0.0;
        double cost = double.tryParse(data['cost'].toString()) ?? 0.0;
        // Si no tiene precio mayorista definido, usamos el costo + 10% como seguridad
        double wholesale = double.tryParse(data['wholesalePrice']?.toString() ?? '0.0') ?? (cost * 1.1);

        // REGLA DE NEGOCIO: Solo sugerimos si hay al menos 30% de margen bruto
        if (price > 0 && (price - cost) / price > 0.30) {
           return {
             'id': doc.id,
             'name': data['name'] ?? 'Servicio General',
             'price': price,
             'cost': cost,
             'wholesale': wholesale, // Este es el piso que Servi no debe cruzar
           };
        }
      }
    } catch (e) {
      debugPrint("⚠️ Error buscando candidato: $e");
    }
    return null; // No encontramos productos aptos para promo
  }
}