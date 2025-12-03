// Archivo: /lib/ai/services/servi_api_connector_service.dart

import 'package:proveedor_servicly_app/ai/services/gemini_service.dart';
import 'package:proveedor_servicly_app/features/agenda/data/repositories/agenda_repository.dart';
import 'package:proveedor_servicly_app/features/inventory/data/inventory_repository.dart';
import 'package:proveedor_servicly_app/features/inventory/services/inventory_intelligence_service.dart';
import 'package:intl/intl.dart'; // 👈 CORRECCIÓN: Importación para DateFormat
import 'dart:async';
import 'dart:convert'; // Advertencia de unused import (lo dejamos por si se usa en LLM)
import 'package:flutter/foundation.dart';


// --- CLASE QUE ACTÚA COMO EL CLIENTE DE LA CAPA PYTHON/API (Paso 4) ---
class ServiApiConnectorService {
    final GeminiService _geminiService;
    final AgendaRepository _agendaRepo;
    final InventoryRepository _inventoryRepo;
    final InventoryIntelligenceService _intelligenceService;

    ServiApiConnectorService(this._geminiService, this._agendaRepo, this._inventoryRepo, this._intelligenceService);

    Future<Map<String, dynamic>> callServiLLM(String query, String userId) async {
        
        final lowerQuery = query.toLowerCase().trim();
        debugPrint('>>> SERVI QUERY RECEIVED: $lowerQuery'); 

        // 1. --- LÓGICA DE BYPASS RÁPIDO (Saludo y Rol) ---
        if (lowerQuery.contains('quien') && lowerQuery.contains('eres')) {
            return {
                "TEXTO_ESCRITO": "Soy SERVI, tu Asistente de Inteligencia Empresarial...",
                "TEXTO_VOZ": "Soy SERVI, tu asistente empresarial...",
            };
        }
        if (lowerQuery.startsWith('hola')) {
             return {
                "TEXTO_ESCRITO": "¡Hola! Soy SERVI...",
                "TEXTO_VOZ": "¡Hola! Soy SERVI...",
            };
        }
        
        // 2. --- CLASIFICACIÓN DE INTENCIÓN REAL (Para el Flujo de Datos) ---
        final Map<String, dynamic> contextData = {};
        String classifiedIntent = 'GENERAL_QUERY';

        if (lowerQuery.contains('citas') || lowerQuery.contains('itinerario')) {
            classifiedIntent = 'AGENDA';
        } else if (lowerQuery.contains('stock') || lowerQuery.contains('inventario')) {
            classifiedIntent = 'INVENTARIO';
        }
        
        // 3. --- CONSULTA DE DATOS Y CONSTRUCCIÓN DEL CONTEXTO ---
        if (classifiedIntent == 'AGENDA') {
            // 💡 CORRECCIÓN: Usamos un método de Stream y tomamos el primer valor
            final nextAppointment = await _agendaRepo.getNextAppointmentStream().first; 
            
            if (nextAppointment != null) {
                // Asumiendo que 'nextAppointment' tiene una propiedad 'startTime' y 'title'
                contextData['agenda_data'] = [
                    {
                        "descripcion": nextAppointment.title, 
                        "hora": DateFormat('HH:mm').format(nextAppointment.startTime) // 👈 CORRECCIÓN DateFormat
                    } 
                ];
            } else {
                 contextData['agenda_data'] = null;
            }
        }
        // ... AGREGAR MÁS LÓGICA AQUÍ ...
        
        // 4. --- ESTRUCTURA DEL CONTEXTO FINAL (COMPANY_CONTEXT) ---
        final contextJson = {
            "fecha_consulta": DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(DateTime.now()), 
            "user_id": userId,
            "data": contextData 
        }; 
        
        // --- LLAMADA AL SERVICIO GEMINI ---
        final rawResponse = await _geminiService.callContextualLLM(query, contextJson); 
        
        return rawResponse;
    }
}