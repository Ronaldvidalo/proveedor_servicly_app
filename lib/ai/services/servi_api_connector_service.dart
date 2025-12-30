import 'package:proveedor_servicly_app/ai/services/gemini_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

// --- IMPORT NECESARIO PARA PROMOS ---
import 'package:proveedor_servicly_app/features/promotion/models/smart_insight_model.dart'; 

class ServiApiConnectorService {
  final GeminiService _geminiService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ServiApiConnectorService(this._geminiService);

  // --- CEREBRO CENTRAL 360° + EJECUTOR + CONSEJERO ---
  Future<Map<String, dynamic>> callServiLLM(String query, String userId) async {
    final lowerQuery = query.toLowerCase().trim();
    debugPrint('>>> SERVI SUPER MASTER: Escaneando para: "$lowerQuery"');

    // 1. IDENTIDAD
    if (lowerQuery.contains('quien') && lowerQuery.contains('eres')) {
      return {
        "TEXTO_ESCRITO": "Soy SERVI. Puedo redactar presupuestos, cargar productos al inventario, buscar profesionales y analizar tu negocio.",
        "TEXTO_VOZ": "Soy Servi. Tu asistente ejecutivo para todo el ecosistema.",
      };
    }

    // 2. DETECCIÓN DE INTENCIÓN
    
    // A. INTENCIÓN DE ACCIÓN 1: PRESUPUESTOS (Ya existente)
    bool isQuoteIntent = lowerQuery.contains('presupuesto') || lowerQuery.contains('cotiza') || (lowerQuery.contains('crear') && lowerQuery.contains('nota'));

    // B. INTENCIÓN DE ACCIÓN 2: INVENTARIO (NUEVO 📦)
    // Detecta frases como "Agregar producto Coca Cola", "Cargar stock de zapatillas", "Nuevo articulo"
    bool isProductIntent = (lowerQuery.contains('agregar') || lowerQuery.contains('cargar') || lowerQuery.contains('subir') || lowerQuery.contains('crear')) && 
                           (lowerQuery.contains('producto') || lowerQuery.contains('articulo') || lowerQuery.contains('stock') || lowerQuery.contains('inventario'));

    // C. BÚSQUEDA EXTERNA (Marketplace)
    bool searchMarketplace = lowerQuery.contains('buscar') || lowerQuery.contains('necesito') || lowerQuery.contains('quiero') || lowerQuery.contains('tienda') || lowerQuery.contains('precio') || lowerQuery.contains('cerca') ||
                             lowerQuery.contains('tecnico') || lowerQuery.contains('plomero') || lowerQuery.contains('electricista') || lowerQuery.contains('veterinaria') || lowerQuery.contains('peluqueria') || lowerQuery.contains('medico');
    
    // D. GESTIÓN INTERNA (Personal)
    bool searchPersonal = lowerQuery.contains('mi ') || lowerQuery.contains('pedido') || lowerQuery.contains('venta') || lowerQuery.contains('agenda') || lowerQuery.contains('ganancia') || lowerQuery.contains('estatus') || lowerQuery.contains('stock');

    // Si es ambiguo y no es una acción clara, activamos búsqueda personal por defecto
    if (!searchMarketplace && !searchPersonal && !isQuoteIntent && !isProductIntent) searchPersonal = true; 

    // 3. EJECUCIÓN PARALELA DE TODAS LAS SONDAS
    final Map<String, dynamic> globalContext = {};
    final Map<String, dynamic> businessHealth = {}; 
    
    await Future.wait([
        // Sonda de Acción 1 (Presupuestos)
        if (isQuoteIntent) _analyzeQuoteContext(userId, lowerQuery, globalContext),

        // Sonda de Acción 2 (Productos - NUEVO)
        if (isProductIntent) _analyzeProductContext(userId, lowerQuery, globalContext),
        
        // Sonda de Marketplace (Solo si no es una orden de acción)
        if (searchMarketplace && !isQuoteIntent && !isProductIntent) _scanMarketplace(lowerQuery, globalContext),
        
        // Sonda de Datos Personales (Solo si no es una orden de acción)
        if (searchPersonal && !isQuoteIntent && !isProductIntent) _scanPersonalData(userId, lowerQuery, globalContext),
        
        // El Consejero de Salud (SIEMPRE ACTIVO)
        _checkBusinessHealth(userId, businessHealth),
    ]);

    // 4. GENERACIÓN DE RESPUESTA CON ESTRUCTURA DE COMANDO
    final contextJson = {
      "fecha_actual": DateFormat('EEEE d MMMM, HH:mm', 'es_AR').format(DateTime.now()),
      "RESULTADOS_DATA": globalContext,
      "SALUD_NEGOCIO": businessHealth, 
      "INSTRUCCIONES": """
          Sos SERVI, asistente ejecutivo de Servicly.
          
          CASO 1: EL USUARIO QUIERE UN PRESUPUESTO (isQuoteIntent):
          - Analiza la frase y extrae: Cliente, Concepto y Precio.
          - JSON Respuesta:
            {
               "TEXTO_ESCRITO": "Abriendo presupuesto...",
               "TEXTO_VOZ": "Dale, abriendo el editor de presupuestos.",
               "ACCION": "NAVEGAR_PRESUPUESTO",
               "DATOS_PRECARGA": { "cliente_nombre": "...", "concepto": "...", "precio_estimado": 0.0, "sugerencia_ia": "..." }
            }

          CASO 2: EL USUARIO QUIERE AGREGAR UN PRODUCTO (isProductIntent):
          - Analiza la frase y extrae: Nombre del Producto, Precio y Stock (Cantidad).
          - Si no menciona stock, asume 0. Si no menciona precio, asume 0.
          - Revisa 'PRODUCTOS_SIMILARES' en el contexto. Si ya existe algo parecido, avísalo en "aviso_ia".
          - JSON Respuesta:
            {
               "TEXTO_ESCRITO": "Preparando nuevo producto...",
               "TEXTO_VOZ": "Abriendo ficha de producto. Revisa los datos.",
               "ACCION": "NAVEGAR_PRODUCTO",
               "DATOS_PRECARGA": { 
                  "nombre_producto": "...", 
                  "precio": 0.0, 
                  "stock": 0,
                  "aviso_ia": "..." 
               }
            }

          CASO 3: CONSULTA NORMAL:
          - Responde la duda usando 'RESULTADOS_DATA'.
          - Revisa 'SALUD_NEGOCIO'. Si hay alertas graves (InventoryEmpty, NoCostStructure), agrega un "💡 Tip Servi" al final.
          
          TONO: Profesional, ejecutivo, argentino.
      """
    };

    return await _geminiService.callContextualLLM(query, contextJson);
  }

  // ==============================================================================
  // 🧠 NUEVO: GENERADOR DE ALERTAS PROACTIVAS (PROMOS)
  // ==============================================================================
  Future<Map<String, dynamic>> generateProactiveMessage(SmartInsight insight, String userName) async {
    
    // 1. Construimos el contexto específico para la Promo
    final String contextData = """
    DATOS DEL HALLAZGO (INSIGHT):
    - Tipo: ${insight.type.name}
    - Mensaje Técnico: ${insight.message}
    - Datos Sugeridos: ${insight.suggestedPromo.toString()}
    
    OBJETIVO:
    Actúa como un socio comercial experto (con modismos argentinos profesionales).
    Debes comunicarle este hallazgo al usuario '$userName' y proponerle activar la promoción sugerida.
    Tu tono debe ser de "Alerta de Oportunidad", no de regaño.
    """;

    // 2. Prompt del Sistema específico para Insights
    const String systemPrompt = """
    Eres Servi, el asistente IA de la App Servicly.
    Tu tarea es transformar datos técnicos en consejos de negocios accionables.
    
    REGLAS DE RESPUESTA JSON:
    Debes responder SIEMPRE con este JSON exacto:
    {
      "INTENCION": "PROACTIVE_INSIGHT",
      "TEXTO_VOZ": "Tu frase vendedora y empática aquí...",
      "DATOS_ACCION": {
         "screen": "PROMO_CREATOR",
         "promo_data": { ...copia los datos sugeridos del insight aquí... }
      }
    }
    """;

    // 3. Llamada a Gemini
    try {
       // Simulamos una "pregunta del sistema" para disparar la generación
       final response = await _geminiService.callContextualLLM(
         "Genera la alerta proactiva basada en el insight.", 
         { 
           "system_role": systemPrompt,
           "current_insight": contextData
         }
       );
       return response;
    } catch (e) {
       return {
         "TEXTO_VOZ": "Che, vi algo interesante en tus métricas, ¿lo revisamos?",
         "INTENCION": "ERROR"
       };
    }
  }

  // ==============================================================================
  // 📝 SONDA 0: ANALISTA DE PRESUPUESTOS
  // ==============================================================================
  Future<void> _analyzeQuoteContext(String userId, String query, Map<String, dynamic> context) async {
      try {
          final servicesSnapshot = await _firestore.collection('users/$userId/products').limit(50).get();
          final List<String> priceHistory = [];
          final queryWords = query.toLowerCase().split(' ').where((w) => w.length > 3).toList();

          for(var doc in servicesSnapshot.docs) {
              final d = doc.data();
              String name = (d['name'] ?? '').toString().toLowerCase();
              if (queryWords.any((word) => name.contains(word))) { 
                  double price = double.tryParse(d['price'].toString()) ?? 0.0;
                  priceHistory.add("${d['name']}: \$$price");
              }
          }
          context['HISTORIAL_PRECIOS_SIMILARES'] = priceHistory.isEmpty ? "No hay referencias previas." : priceHistory;
      } catch (e) { debugPrint("⚠️ Error analizando presupuesto: $e"); }
  }

  // ==============================================================================
  // 📦 SONDA 0.5: ANALISTA DE PRODUCTOS (NUEVO)
  // ==============================================================================
  Future<void> _analyzeProductContext(String userId, String query, Map<String, dynamic> context) async {
      try {
          // Buscamos si ya existen productos con nombres similares para evitar duplicados
          final productsSnapshot = await _firestore.collection('users/$userId/products').limit(100).get();
          final List<String> similarProducts = [];
          final queryLower = query.toLowerCase();

          for(var doc in productsSnapshot.docs) {
              final d = doc.data();
              String name = (d['name'] ?? '').toString();
              // Chequeo simple de coincidencia
              if (queryLower.contains(name.toLowerCase()) || name.toLowerCase().contains(queryLower.split(' ').last)) {
                  similarProducts.add("$name (Stock: ${d['stock']})");
              }
          }
          if (similarProducts.isNotEmpty) {
             context['PRODUCTOS_SIMILARES_EXISTENTES'] = similarProducts;
          }
      } catch (e) { debugPrint("⚠️ Error analizando productos: $e"); }
  }

  // ==============================================================================
  // 🏥 SONDA 1: CONSEJERO DE SALUD (PROACTIVO)
  // ==============================================================================
  Future<void> _checkBusinessHealth(String userId, Map<String, dynamic> healthReport) async {
    try {
        final productsSnapshot = await _firestore.collection('users/$userId/products').limit(1).get();
        if (productsSnapshot.docs.isEmpty) {
            healthReport['ALERTA'] = "InventoryEmpty";
            healthReport['DETALLE'] = "Usuario sin productos.";
            return; 
        }
        final lowStockSnapshot = await _firestore.collection('users/$userId/products').where('stock', isLessThan: 5).limit(3).get();
        if (lowStockSnapshot.docs.isNotEmpty) {
            final names = lowStockSnapshot.docs.map((d) => d.data()['name']).join(", ");
            healthReport['ALERTA_STOCK'] = "LowStock";
            healthReport['PRODUCTOS_BAJOS'] = names;
        }
        final configSnapshot = await _firestore.collection('users').doc(userId).collection('settings').doc('financial_config').get();
        double fixedCost = 0.0;
        if (configSnapshot.exists) {
            fixedCost = double.tryParse(configSnapshot.data()?['costoFijoUnitarioCalculado']?.toString() ?? '0') ?? 0.0;
        }
        if (fixedCost <= 0) {
            healthReport['ALERTA_FINANCIERA'] = "NoCostStructure";
        }
    } catch (e) { debugPrint("⚠️ Error Salud Negocio: $e"); }
  }

  // ==============================================================================
  // 🌍 SONDA 2: MARKETPLACE (PROFESIONALES + PRODUCTOS)
  // ==============================================================================
  Future<void> _scanMarketplace(String query, Map<String, dynamic> context) async {
      try {
          final profilesSnapshot = await _firestore.collectionGroup('brandProfile').limit(50).get();
          final List<String> foundProfessionals = [];
          for (var doc in profilesSnapshot.docs) {
              final data = doc.data();
              String category = (data['mainCategory'] ?? '').toString(); 
              String businessName = (data['businessName'] ?? data['name'] ?? 'Profesional').toString();
              String city = (data['city'] ?? 'Zona General').toString();
              
              bool matchCategory = category.toLowerCase().contains(query.toLowerCase()) || 
                                   query.toLowerCase().contains(category.toLowerCase().substring(0, category.length > 3 ? category.length - 1 : category.length));
              bool matchName = businessName.toLowerCase().contains(query.toLowerCase());

              if (matchCategory || matchName) {
                   foundProfessionals.add("$businessName ($category) - $city");
              }
          }
          if (foundProfessionals.isNotEmpty) {
            context['PROFESIONALES_ENCONTRADOS'] = foundProfessionals.take(5).toList();
          } else if (query.contains('necesito') || query.contains('busco')) {
            context['AVISO_PROFESIONALES'] = "Sin coincidencias en perfiles.";
          }

          if (!query.contains('servi') && !query.contains('tecnico')) {
              final productsSnapshot = await _firestore.collectionGroup('products').limit(30).get();
              final List<String> foundProducts = [];
              for (var doc in productsSnapshot.docs) {
                  final data = doc.data();
                  String name = (data['name'] ?? '').toString();
                  if (name.toLowerCase().contains(query)) {
                      double price = double.tryParse(data['price'].toString()) ?? 0.0;
                      foundProducts.add("$name (\$$price)");
                  }
              }
              if (foundProducts.isNotEmpty) {
                context['PRODUCTOS_MERCADO'] = foundProducts.take(5).toList();
              }
          }
      } catch (e) { debugPrint("⚠️ Error Marketplace: $e"); }
  }

  // ==============================================================================
  // 🏠 SONDA 3: DATOS PERSONALES (GESTIÓN BLINDADA)
  // ==============================================================================
  Future<void> _scanPersonalData(String userId, String query, Map<String, dynamic> context) async {
      try {
          // A. MIS PEDIDOS (Cliente)
          if (query.contains('pedido') || query.contains('compra')) {
              final ordersSnapshot = await _firestore.collection('orders')
                  .where('clientId', isEqualTo: userId)
                  .orderBy('createdAt', descending: true).limit(5).get();
              final List<String> myOrders = [];
              for (var doc in ordersSnapshot.docs) {
                  final d = doc.data();
                  myOrders.add("Pedido a ${d['storeName']}: ${d['status']}");
              }
              context['MIS_PEDIDOS_CLIENTE'] = myOrders.isEmpty ? "Sin pedidos recientes." : myOrders;
          }

          // B. MI NEGOCIO (Proveedor)
          if (query.contains('venta') || query.contains('agenda') || query.contains('resumen') || query.contains('ganancia') || query.contains('stock')) {
              
              final now = DateTime.now();
              final startMonth = DateFormat('yyyy-MM-01').format(now);
              final transactions = await _firestore.collection('users/$userId/transactions').limit(300).get();
              
              double ingresos = 0;
              double gastos = 0;
              
              for(var doc in transactions.docs) {
                  final d = doc.data();
                  String dateStr = (d['date'] ?? '').toString();
                  
                  if (dateStr.compareTo(startMonth) >= 0) {
                      double amount = 0.0;
                      if (d['amount'] is num) amount = (d['amount'] as num).toDouble();
                      else if (d['amount'] is String) amount = double.tryParse(d['amount']) ?? 0.0;

                      if (d['type'] == 'income' || d['type'] == 'sale') {
                          ingresos += amount;
                      } else if (d['type'] == 'expense' || d['type'] == 'cost') {
                          gastos += amount;
                      }
                  }
              }
              
              final startDay = DateTime(now.year, now.month, now.day);
              final endWeek = startDay.add(const Duration(days: 7));
              final eventsSnapshot = await _firestore.collection('events').where('providerId', isEqualTo: userId).get();
              
              final List<String> agenda = [];
              for (var doc in eventsSnapshot.docs) {
                  final d = doc.data();
                  DateTime? evtDate;
                  try { 
                      if (d['startTime'] is Timestamp) evtDate = (d['startTime'] as Timestamp).toDate();
                      else if (d['startTime'] is String) evtDate = DateTime.tryParse(d['startTime']);
                  } catch (_) {}

                  if (evtDate != null && evtDate.isAfter(startDay) && evtDate.isBefore(endWeek)) {
                      String day = DateFormat('EEEE d', 'es_AR').format(evtDate);
                      String time = DateFormat('HH:mm').format(evtDate);
                      agenda.add("$day $time: ${d['title']}");
                  }
              }
              
              context['MI_NEGOCIO'] = {
                  "ingresos_mes": ingresos,
                  "gastos_mes": gastos,
                  "agenda_semanal": agenda.isEmpty ? "Libre." : agenda
              };
          }
      } catch (e) { debugPrint("⚠️ Error Datos Personales: $e"); }
  }
  Future<String> generateSalesStrategy(String serviceName, String clientName) async {
    const systemPrompt = """
    Eres un Coach de Ventas Experto. Tu usuario es un proveedor de servicios.
    Acaba de recibir un lead. Tu objetivo es darle un consejo CORTO y LETAL de 15 palabras para cerrar la venta.
    Sugiere un gancho (descuento, urgencia, beneficio).
    Tono: Argentino profesional, motivador.
    """;

    try {
      final response = await _geminiService.callContextualLLM(
        "Generar consejo venta", 
        {
          "system_role": systemPrompt,
          "context": "Cliente: $clientName. Interesado en: $serviceName."
        }
      );
      
      // Si usas el método que devuelve Map, extrae el texto. Si devuelve String, úsalo directo.
      return response['TEXTO_VOZ'] ?? "Ofrecele un turno inmediato para ganarle a la competencia.";
    } catch (e) {
      return "Contactalo rápido, la velocidad es clave para cerrar ventas.";
    }
  }
}