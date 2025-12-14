import 'package:proveedor_servicly_app/ai/services/gemini_service.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class ServiApiConnectorService {
  final GeminiService _geminiService;
  final FirestoreService _firestoreService; 
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ServiApiConnectorService(this._geminiService, this._firestoreService);

  Future<Map<String, dynamic>> callServiLLM(String query, String userId) async {
    final lowerQuery = query.toLowerCase().trim();
    debugPrint('>>> SERVI CONECTOR: Analizando "$lowerQuery" para usuario $userId');

    // 1. --- BYPASS RÁPIDO ---
    if (lowerQuery.contains('quien') && lowerQuery.contains('eres')) {
      return {
        "TEXTO_ESCRITO": "Soy SERVI, tu asistente de inteligencia artificial conectado a Servicly.",
        "TEXTO_VOZ": "Soy Servi, tu asistente virtual.",
      };
    }
    
    if (lowerQuery.contains('hola') || lowerQuery.contains('buen dia') || lowerQuery.contains('chau')) {
        return {
            "TEXTO_ESCRITO": "¡Hola! Todo listo. ¿Revisamos la agenda o las ventas?",
            "TEXTO_VOZ": "¡Hola! ¿Cómo venimos hoy? Decime en qué te ayudo.",
        };
    }
    
    if (lowerQuery.contains('anima') || lowerQuery.contains('triste') || lowerQuery.contains('felicita')) {
        return await _handleEmotionalQuery(lowerQuery);
    }

    // 2. --- RECOLECCIÓN DE DATOS ---
    final Map<String, dynamic> contextData = {};
    String emotionalToneInstruction = ''; 
    
    bool needAll = lowerQuery.contains('resumen') || lowerQuery.contains('cómo voy') || lowerQuery.contains('negocio');
    bool needAgenda = needAll || lowerQuery.contains('cita') || lowerQuery.contains('agenda') || lowerQuery.contains('calendario') || lowerQuery.contains('tengo');
    bool needFinance = needAll || lowerQuery.contains('venta') || lowerQuery.contains('ganancia') || lowerQuery.contains('plata') || lowerQuery.contains('caja');
    bool needInventory = needAll || lowerQuery.contains('stock') || lowerQuery.contains('producto') || lowerQuery.contains('inventario');
    bool needClients = needAll || lowerQuery.contains('cliente');


    // --- A) CONEXIÓN CON AGENDA (BLINDADA) ---
    if (needAgenda) {
       try {
        final now = DateTime.now();
        // Definimos el rango: Desde el inicio de hoy hasta 7 días después
        final startOfRange = DateTime(now.year, now.month, now.day); 
        final endOfRange = startOfRange.add(const Duration(days: 7));

        // 1. TRAEMOS TODO (Filtrado solo por usuario para evitar problemas de tipos)
        final appointmentsSnapshot = await _firestore.collection('events')
            .where('providerId', isEqualTo: userId) 
            .get();

        debugPrint("🔍 Eventos crudos encontrados en DB: ${appointmentsSnapshot.docs.length}");

        // 2. PROCESAMOS Y FILTRAMOS EN MEMORIA
        final List<String> validAppointments = [];

        for (var doc in appointmentsSnapshot.docs) {
            final data = doc.data();
            DateTime? eventDate;

            // Detección inteligente de tipo de fecha
            if (data['startTime'] is Timestamp) {
                eventDate = (data['startTime'] as Timestamp).toDate();
            } else if (data['startTime'] is String) {
                eventDate = DateTime.tryParse(data['startTime']);
            }

            // Si la fecha es válida y cae en esta semana
            if (eventDate != null && 
                eventDate.isAfter(startOfRange.subtract(const Duration(hours: 1))) && 
                eventDate.isBefore(endOfRange)) {
                
                String dayName = DateFormat('EEEE', 'es_AR').format(eventDate);
                String time = DateFormat('HH:mm').format(eventDate);
                String title = data['title'] ?? 'Cita sin título';
                
                validAppointments.add("$dayName a las $time: $title");
            }
        }

        contextData['agenda_semana'] = validAppointments.isEmpty 
            ? "Agenda libre para los próximos 7 días." 
            : validAppointments;
            
        debugPrint("📅 Agenda filtrada final: $validAppointments"); 

      } catch (e) {
        debugPrint("❌ Error Agenda: $e");
        contextData['agenda_error'] = "No pude leer la colección 'events'.";
      }
    }

    // --- B) CONEXIÓN CON FINANZAS ---
    if (needFinance || needAll) {
      try {
        // Para finanzas mantenemos la query simple por ahora, o aplicamos la misma lógica si falla
        final now = DateTime.now();
        // Formato string para comparar en transactions (asumiendo que ahí sí guardas string YYYY-MM-DD)
        final startOfMonthStr = DateFormat('yyyy-MM-01').format(now);
        
        final transactionsSnapshot = await _firestore.collection('users/$userId/transactions')
            .get(); // Traemos todo y filtramos fecha en memoria por seguridad

        double ingresosMes = 0;
        double gastosMes = 0;
        int ventasCount = 0;

        for (var doc in transactionsSnapshot.docs) {
          final data = doc.data();
          // Verificar fecha
          final String? dateStr = data['date'] as String?;
          if (dateStr != null && dateStr.compareTo(startOfMonthStr) >= 0) {
              // Pertenece a este mes
              final double amount = (data['amount'] ?? 0).toDouble();
              if (data['type'] == 'income' || data['type'] == 'sale') {
                ingresosMes += amount;
                ventasCount++;
              } else if (data['type'] == 'expense' || data['type'] == 'cost') {
                gastosMes += amount;
              }
          }
        }
        
        double gananciaNeta = ingresosMes - gastosMes;
        
        if (gananciaNeta > 50000 && now.day < 15) { 
            emotionalToneInstruction = "Tu ganancia neta es excelente. ¡Felicítalo!";
        } else if (gananciaNeta < 0 && now.day > 10) { 
            emotionalToneInstruction = "El negocio tiene balance negativo. Dale ánimo.";
        }

        contextData['finanzas_mes_actual'] = {
          "ingresos": ingresosMes,
          "gastos": gastosMes,
          "ganancia": gananciaNeta,
          "cantidad_ventas": ventasCount,
        };
      } catch (e) {
        debugPrint("Error Finanzas: $e");
        contextData['finanzas_error'] = "No pude acceder a transactions.";
      }
    }

    // --- C) CONEXIÓN CON INVENTARIO ---
    if (needInventory) {
       try {
        final inventorySnapshot = await _firestore.collection('users/$userId/products')
            .where('stock', isLessThan: 5)
            .get();
            
        final lowStockItems = inventorySnapshot.docs.map((doc) => "${doc.data()['name']} (${doc.data()['stock']})").toList();
        contextData['alertas_inventario'] = lowStockItems.isEmpty ? "Stock saludable." : "BAJO STOCK: ${lowStockItems.join(', ')}.";
      } catch (e) {
        debugPrint("Error Inventario: $e");
      }
    }

    // --- D) CONEXIÓN CON CLIENTES ---
    if (needClients) {
       try {
        final clientsSnapshot = await _firestore.collection('users/$userId/clients').get();
        contextData['total_clientes'] = clientsSnapshot.docs.length;
      } catch (e) {
        debugPrint("Error CRM: $e");
      }
    }

    // 3. --- CONTEXTO FINAL ---
    final contextJson = {
      "fecha_hoy": DateFormat('EEEE d MMMM yyyy', 'es_AR').format(DateTime.now()),
      "ESTADO_NEGOCIO": contextData,
      "INSTRUCCIONES": 
          "Sos Servi. Analizá 'ESTADO_NEGOCIO'. ${emotionalToneInstruction.isNotEmpty ? emotionalToneInstruction : ''} Responde natural."
    };

    return await _geminiService.callContextualLLM(query, contextJson);
  }
  
  Future<Map<String, dynamic>> _handleEmotionalQuery(String query) async {
    final result = await _geminiService.callContextualLLM(
      query, 
      {"MODO": "Empatía pura", "INSTRUCCIÓN": "Responde con calidez humana argentina."}
    );
    return result;
  }
}