// /lib/ai/model/analyzed_line_item.dart

import 'package:proveedor_servicly_app/ai/model/ai_response_model.dart';

class AnalyzedLineItem {
  final LineItem item; // El dato crudo de la factura
  final double historicalAvgCost;
  final double costDeviationPercentage; // Desviación en porcentaje (ej: 0.20 para 20%)
  final double sellingPrice; 
  final double fixedCostSnapshot; // Costo Fijo del Módulo de Costos
  final String suggestedCategory; // Sugerencia de SERVI (Gemini)

  AnalyzedLineItem({
    required this.item,
    required this.historicalAvgCost,
    required this.costDeviationPercentage,
    required this.sellingPrice,
    required this.fixedCostSnapshot,
    required this.suggestedCategory,
  });

    // ------------------------------------------------------------------
    // --- LÓGICA DE ALERTA DE COSTO (Definida solo una vez) ---
    // ------------------------------------------------------------------
    
    bool get requiresAlert => costDeviationPercentage.abs() > 0.20; 
  
    String get alertMessage {
      if (requiresAlert) {
          final percentage = (costDeviationPercentage * 100).toStringAsFixed(1);
          final direction = costDeviationPercentage > 0 ? 'MÁS ALTO' : 'MÁS BAJO';
          // Aseguramos que la descripción del item se acceda correctamente
          return '🚨 Costo (${item.description}) es un $percentage% $direction que el promedio histórico de \$$historicalAvgCost.';
      }
      return 'Costo normalizado.';
    }
    
    // ------------------------------------------------------------------
    // --- LÓGICA DE MARGEN PROYECTADO (Integración con Módulo de Costos) ---
    // ------------------------------------------------------------------
    
    /// Costo total proyectado (Costo Unitario de Compra + Costo Fijo de la Estructura)
    double get projectedTotalCost => item.unitPrice + fixedCostSnapshot;

    /// Margen de Ganancia Bruta Proyectada (en valor absoluto)
    double get grossProfitMargin {
      if (sellingPrice <= 0) return 0.0;
      return (sellingPrice - projectedTotalCost) / sellingPrice;
    }
  
    /// Mensaje de margen proyectado con análisis de estado (Óptimo, Aceptable, Bajo)
    String get marginMessage {
      final margin = (grossProfitMargin * 100).toStringAsFixed(1);
      final status = grossProfitMargin > 0.25 ? 'Óptimo' : (grossProfitMargin >= 0.10 ? 'Aceptable' : 'Bajo');
      return 'Margen Proyectado: $margin% ($status). Cat. Sugerida: $suggestedCategory';
    }
}
