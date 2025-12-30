enum InsightType { 
  lowDensityTrend, 
  stockAlert, 
  seasonalOpportunity, 
  newLead // ✅ Nuevo tipo para detección de clientes potenciales
}

class SmartInsight {
  final String id;
  final String message; // El "reto" o aviso de Servi
  final InsightType type;
  final Map<String, dynamic> suggestedPromo; // Estructura base para el PromotionModel o datos del Lead
  final DateTime detectedAt;

  const SmartInsight({
    required this.id,
    required this.message,
    required this.type,
    required this.suggestedPromo,
    required this.detectedAt,
  });
}