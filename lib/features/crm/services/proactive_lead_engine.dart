import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:proveedor_servicly_app/features/promotion/models/smart_insight_model.dart'; 

class ProactiveLeadEngine {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Escucha en tiempo real nuevos leads no analizados.
  Stream<SmartInsight?> listenForNewLeads(String providerId) {
    return _db
        .collection('leads') // ⚠️ Asegúrate que tu colección se llame 'leads' o 'clientes'
        // Si usas subcolección de usuarios, cambia a: .collection('users').doc(providerId).collection('leads')
        .where('providerId', isEqualTo: providerId) // ⚠️ Asegúrate que el lead tenga este campo
        // Ajustamos al modelo Cliente: buscamos por 'estadoCRM' en lugar de 'status' si es necesario, 
        // o mantenemos 'status' si tu backend lo guarda así. 
        // Para este test, asumiremos que el documento tiene un campo 'ia_analyzed'.
        .where('ia_analyzed', isEqualTo: false) 
        .limit(1) 
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) return null;

          final doc = snapshot.docs.first;
          final data = doc.data();

          // Mapeo flexible (Soporta tu modelo Cliente y campos legacy)
          String serviceName = data['serviceName'] ?? data['servicioInteres'] ?? 'Servicio General';
          String clientName = data['nombreCompleto'] ?? data['clientName'] ?? 'Cliente Nuevo';
          String source = data['source'] ?? 'App';

          debugPrint("🔥 ENGINE: Lead detectado -> $clientName ($serviceName)");

          return SmartInsight(
            id: doc.id,
            type: InsightType.newLead, 
            message: "¡Entró un interesado! $clientName pregunta por $serviceName.",
            detectedAt: DateTime.now(),
            suggestedPromo: {
              'leadId': doc.id,
              'clientName': clientName,
              'serviceName': serviceName,
              'source': source,
              'type': 'LEAD_OPPORTUNITY'
            },
          );
        });
  }

  /// Marca el lead como "Analizado"
  Future<void> markLeadAsAnalyzed(String leadId) async {
    try {
      // ⚠️ Ajusta la colección si es diferente
      await _db.collection('leads').doc(leadId).update({'ia_analyzed': true});
    } catch (e) {
      debugPrint("Error marcando lead: $e");
    }
  }
}