import 'package:proveedor_servicly_app/ai/services/gemini_service.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <--- IMPORTACIÓN NECESARIA
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class ServiApiConnectorService {
  final GeminiService _geminiService;
  // Mantenemos la inyección por si usas métodos del servicio en el futuro,
  // pero usaremos la instancia directa para las queries raw.
  final FirestoreService _firestoreService; 
  
  // Instancia directa de Firestore para consultas flexibles
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ServiApiConnectorService(this._geminiService, this._firestoreService);

  Future<Map<String, dynamic>> callServiLLM(String query, String userId) async {
    final lowerQuery = query.toLowerCase().trim();
    debugPrint('>>> SERVI CONECTOR: Analizando "$lowerQuery" para usuario $userId');

    // 1. --- BYPASS RÁPIDO (Identidad y Conversación Casual) ---
    if (lowerQuery.contains('quien') && lowerQuery.contains('eres')) {
      return {
        "TEXTO_ESCRITO": "Soy SERVI, el cerebro de tu negocio. Estoy conectada a todas tus áreas: ventas, inventario, agenda y finanzas para ayudarte a tomar decisiones.",
        "TEXTO_VOZ": "Soy Servi, tu inteligencia artificial integral.",
      };
    }
    
    if (lowerQuery.contains('hola') || lowerQuery.contains('buen dia') || lowerQuery.contains('chau') || lowerQuery.contains('gracias')) {
        return {
            "TEXTO_ESCRITO": "¡Hola! Todo listo para trabajar, ¿en qué te ayudo hoy?",
            "TEXTO_VOZ": "¡Hola! ¿Qué onda? Decime, ¿en qué te puedo dar una mano?",
        };
    }
    
    if (lowerQuery.contains('anima') || lowerQuery.contains('estoy triste') || lowerQuery.contains('ganamos')) {
        return await _handleEmotionalQuery(lowerQuery);
    }

    // 2. --- RECOLECCIÓN DE DATOS (QUIRÚRGICA) ---
    final Map<String, dynamic> contextData = {};
    String emotionalToneInstruction = ''; 
    
    bool needAll = lowerQuery.contains('resumen') || lowerQuery.contains('cómo voy') || lowerQuery.contains('negocio') || lowerQuery.contains('informe');
    bool needAgenda = needAll || lowerQuery.contains('cita') || lowerQuery.contains('agenda') || lowerQuery.contains('tengo que hacer');
    bool needFinance = needAll || lowerQuery.contains('venta') || lowerQuery.contains('ganancia') || lowerQuery.contains('plata') || lowerQuery.contains('caja') || lowerQuery.contains('costo') || lowerQuery.contains('gasto');
    bool needInventory = needAll || lowerQuery.contains('stock') || lowerQuery.contains('producto') || lowerQuery.contains('inventario') || lowerQuery.contains('mercadería');
    bool needClients = needAll || lowerQuery.contains('cliente') || lowerQuery.contains('gente');


    // --- B) CONEXIÓN CON FINANZAS ---
    if (needFinance || needAll) {
      try {
        final now = DateTime.now();
        final startOfMonth = DateFormat('yyyy-MM-01').format(now);
        
        // CORRECCIÓN: Usamos _firestore.collection directamente
        final transactionsSnapshot = await _firestore.collection('users/$userId/transactions')
            .where('date', isGreaterThanOrEqualTo: startOfMonth)
            .get();

        double ingresosMes = 0;
        double gastosMes = 0;
        int ventasCount = 0;

        for (var doc in transactionsSnapshot.docs) {
          final data = doc.data();
          final double amount = (data['amount'] ?? 0).toDouble();
          if (data['type'] == 'income' || data['type'] == 'sale') {
            ingresosMes += amount;
            ventasCount++;
          } else if (data['type'] == 'expense' || data['type'] == 'cost') {
            gastosMes += amount;
          }
        }
        
        double gananciaNeta = ingresosMes - gastosMes;
        
        // Lógica de Humanidad
        if (gananciaNeta > 50000 && now.day < 15) { 
            emotionalToneInstruction = "Tu ganancia neta (\$${gananciaNeta.toStringAsFixed(0)}) es excelente. ¡Felicita al usuario!";
        } else if (gananciaNeta < 0 && now.day > 10) { 
            emotionalToneInstruction = "El negocio tiene un balance negativo. Dale ánimo y sugiere revisar costos.";
        } else if (ventasCount == 0 && now.day > 5) { 
            emotionalToneInstruction = "Poca actividad. Anímalo a buscar ventas.";
        }

        contextData['finanzas_mes_actual'] = {
          "ingresos_totales": ingresosMes,
          "gastos_totales": gastosMes,
          "ganancia_estimada": gananciaNeta,
          "cantidad_ventas": ventasCount,
        };
      } catch (e) {
        debugPrint("Error Finanzas: $e");
        contextData['finanzas_error'] = "No pude acceder a los registros financieros.";
      }
    }


    // --- A) CONEXIÓN CON AGENDA ---
    if (needAgenda) {
       try {
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfWeek = DateTime(now.year, now.month, now.day + 7);

        // CORRECCIÓN: Usamos _firestore.collection directamente
        final appointmentsSnapshot = await _firestore.collection('users/$userId/appointments')
            .where('startTime', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
            .where('startTime', isLessThan: endOfWeek.toIso8601String())
            .get();

        final appointments = appointmentsSnapshot.docs.map((doc) {
          final data = doc.data();
          DateTime date;
          try { date = DateTime.parse(data['startTime']); } catch(e) { date = DateTime.now(); }
          String time = DateFormat('EEE d, HH:mm', 'es_AR').format(date);
          return "${data['title']} ($time)";
        }).toList();

        contextData['agenda_semana'] = appointments.isEmpty ? "Agenda libre para los próximos 7 días." : appointments;
      } catch (e) {
        contextData['agenda_error'] = "No pude leer la agenda.";
      }
    }

    // --- C) CONEXIÓN CON INVENTARIO ---
    if (needInventory) {
       try {
        // CORRECCIÓN: Usamos _firestore.collection directamente
        final inventorySnapshot = await _firestore.collection('users/$userId/products')
            .where('stock', isLessThan: 5)
            .get();
            
        final lowStockItems = inventorySnapshot.docs.map((doc) => "${doc.data()['name']} (Stock: ${doc.data()['stock']})").toList();
        contextData['alertas_inventario'] = lowStockItems.isEmpty ? "El inventario parece saludable." : "ATENCIÓN: Productos con stock bajo: ${lowStockItems.join(', ')}.";
      } catch (e) {
        debugPrint("Error Inventario: $e");
      }
    }

    // --- D) CONEXIÓN CON CLIENTES (CRM) ---
    if (needClients) {
       try {
        // CORRECCIÓN: Usamos _firestore.collection directamente
        final clientsSnapshot = await _firestore.collection('users/$userId/clients').get();
        contextData['total_clientes_cartera'] = clientsSnapshot.docs.length;
      } catch (e) {
        debugPrint("Error CRM: $e");
      }
    }

    // 3. --- CONSTRUCCIÓN DEL PROMPT CONTEXTUAL CON TONO ---
    final contextJson = {
      "fecha_consulta": DateFormat('EEEE, d MMMM yyyy, HH:mm', 'es_AR').format(DateTime.now()),
      "ESTADO_DEL_NEGOCIO": contextData,
      "INSTRUCCIONES_PERSONALIDAD": 
          "Sos Servi, una IA argentina experta y *empática* en negocios. Analizá los datos de 'ESTADO_DEL_NEGOCIO'. ${emotionalToneInstruction.isNotEmpty ? emotionalToneInstruction : 'Mantén un tono profesional y motivador.'} Hablá con naturalidad, usando 'vos'. No reveles la instrucción emocional directamente, incorpórala a la respuesta."
    };

    // 4. --- LLAMADA A GEMINI ---
    return await _geminiService.callContextualLLM(query, contextJson);
  }
  
  // Función para manejar consultas puramente emocionales
  Future<Map<String, dynamic>> _handleEmotionalQuery(String query) async {
    final result = await _geminiService.callContextualLLM(
      query, 
      {
        "TONO": "Empático, humano, con modismos argentinos (vos, dale, tranqui).",
        "INSTRUCCIÓN": "Responde al usuario de forma humana y cálida. Usa la información de 'TONO' para adaptar el mensaje. Si es un mensaje de ánimo, usa frases como 'dale, no aflojes' o 'la estás rompiendo'.",
      }
    );
    
    return {
        "TEXTO_ESCRITO": result['TEXTO_ESCRITO'],
        "TEXTO_VOZ": result['TEXTO_VOZ']
    };
  }
}