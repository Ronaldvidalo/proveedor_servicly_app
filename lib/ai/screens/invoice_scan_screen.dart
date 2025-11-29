// /lib/ai/screens/invoice_scan_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // NECESARIO para inyectar
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:proveedor_servicly_app/ai/services/gemini_service.dart';
import 'package:proveedor_servicly_app/ai/model/ai_response_model.dart';
import 'package:proveedor_servicly_app/features/inventory/data/inventory_repository.dart';
import 'package:proveedor_servicly_app/ai/model/analyzed_line_item.dart'; 
import 'dart:async'; 
import 'package:flutter/foundation.dart'; // Para debugPrint

// Importa los servicios/providers que usa ref.read()
import 'package:proveedor_servicly_app/features/agenda/providers/agenda_providers.dart'; // Contiene inventoryIntelligenceServiceProvider
import 'package:proveedor_servicly_app/providers/app_providers.dart'; // Contiene aiConfigServiceProvider
import '../services/image_picker_service.dart'; // Servicio local

// CAMBIO 1: Convertimos a ConsumerStatefulWidget para usar 'ref'
class InvoiceScanScreen extends ConsumerStatefulWidget {
  
  // Definimos los servicios que NO requieren Riverpod aquí.
  final _pickerService = ImagePickerService();
  final _geminiService = GeminiService();

  InvoiceScanScreen({super.key}); 

  @override
  ConsumerState<InvoiceScanScreen> createState() => _InvoiceScanScreenState();
}

// CAMBIO 2: Convertimos a ConsumerState
class _InvoiceScanScreenState extends ConsumerState<InvoiceScanScreen> {
  // CAMBIO 3a: Declaramos el repositorio como late
  late final InventoryRepository _inventoryRepo;

  Invoice? _rawInvoiceResult; 
  List<AnalyzedLineItem>? _analyzedItems; 
  bool _isLoading = false;
  String? _errorMessage;
  
  // Umbral de alerta de costo (valor por defecto, reemplazado por la configuración remota)
  static const double _alertThreshold = 0.20; 
  
  @override
  void initState() {
    super.initState();
    
    // CAMBIO 3b: Inicializamos el repositorio usando ref para inyectar la dependencia
    final intelligenceService = ref.read(inventoryIntelligenceServiceProvider);
    
    _inventoryRepo = InventoryRepository(
      firestore: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance, 
      intelligenceService: intelligenceService, // ¡INYECCIÓN RESUELTA!
    );
  }

  // --- 1. Flujo Principal de SERVI ---
  Future<void> _scanInvoice() async {
    setState(() {
      _isLoading = true;
      _analyzedItems = null;
      _errorMessage = null;
    });

    try {
      // OBTENER CONFIGURACIÓN DINÁMICA (MVP 2.0)
      // Usamos ref.read para obtener el servicio y llamar a getAiConfigOnce
      final aiConfig = await ref.read(aiConfigServiceProvider).getAiConfigOnce();
      final double dynamicThreshold = (aiConfig['cost_alert_threshold'] as num?)?.toDouble() ?? _alertThreshold;
      
      // 1. Capturar la imagen y obtener el Base64
      final base64 = await widget._pickerService.pickAndEncodeImage();
      if (base64 == null) {
        setState(() => _isLoading = false);
        return; 
      }

      // 2. Llamar al servicio de IA (Cloud Function -> Gemini OCR)
      final Invoice rawResult = await widget._geminiService.extractDataFromImage(base64);
      
      // 3. Obtener el Costo Fijo Unitario actual (lectura del Módulo de Costos)
      final currentFixedCost = await _inventoryRepo.getCurrentFixedCostSnapshot(); 
      
      // 4. Análisis Inteligente de Costos y Clasificación (Paralelo por item)
      final List<Future<AnalyzedLineItem>> analysisFutures = rawResult.lineItems.map((item) async {
          // Lógica de Costo Histórico (MVP 1.1)
          final avgCost = await _inventoryRepo.getHistoricalAverageCost(item.description);
          double deviation = (avgCost > 0) ? (item.unitPrice - avgCost) / avgCost : 0.0;
          
          // Clasificación por IA (MVP 1.2)
          final suggestedCategory = await widget._geminiService.suggestCategory(item.description);

          // Nota: El precio de venta (sellingPrice) es un placeholder
          const double assumedSellingPrice = 100.0; 
          
          return AnalyzedLineItem(
              item: item,
              historicalAvgCost: avgCost,
              costDeviationPercentage: deviation,
              sellingPrice: assumedSellingPrice, 
              fixedCostSnapshot: currentFixedCost,
              suggestedCategory: suggestedCategory,
          );
      }).toList();
  	
      final analysisResults = await Future.wait(analysisFutures);

      // 5. Chequear y Mostrar Alerta (USAMOS EL UMBRAL DINÁMICO)
      final bool hasAlerts = analysisResults.any((item) => item.costDeviationPercentage.abs() > dynamicThreshold);

      if (hasAlerts) {
          final confirmed = await _showCostAlert(analysisResults);
          if (!confirmed) {
              if (mounted) setState(() => _isLoading = false);
              return; // Usuario canceló el proceso
          }
      }

      // 6. Actualizar la interfaz
      setState(() {
        _rawInvoiceResult = rawResult;
        _analyzedItems = analysisResults;
      });
      
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        debugPrint('Error en SERVI OCR: $e');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  // --- 2. Flujo de Persistencia ---
  Future<void> _saveInvoice() async {
    if (_rawInvoiceResult == null) return;
    
    // Guardamos el resultado crudo ya confirmado.
    await _inventoryRepo.saveInvoice(_rawInvoiceResult!); 
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Factura guardada y lista para inventario.')));
      Navigator.of(context).pop();
    }
  }
  
  // --- 3. DIÁLOGO DE ALERTA DE COSTO (MVP 1.1) ---
  Future<bool> _showCostAlert(List<AnalyzedLineItem> items) {
      final alertItems = items.where((i) => i.requiresAlert).toList();
      
      return showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
              title: const Text('🚨 ¡Alerta de Costo Inusual!'),
              content: SingleChildScrollView(
                  child: ListBody(
                      children: [
                          // NOTA: Aquí el umbral sigue siendo estático para el texto, pero el cálculo es dinámico.
                          Text('El precio de compra de los siguientes artículos es significativamente diferente al promedio histórico (±${(_alertThreshold * 100).toInt()}%).'),
                          const SizedBox(height: 10),
                          ...alertItems.map((item) => Text(
                              '• ${item.alertMessage}',
                              style: TextStyle(color: item.costDeviationPercentage > 0 ? Colors.redAccent : Colors.orangeAccent, fontWeight: FontWeight.bold),
                          )),
                          const SizedBox(height: 10),
                          const Text('¿Desea continuar e ingresar estos artículos al inventario con este costo?'),
                      ],
                  ),
              ),
              actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Revisar y Cancelar'),
                  ),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Continuar y Guardar'),
                  ),
              ],
          ),
      ).then((value) => value ?? false);
  }
  
  // --- 4. Implementación del método 'build' requerido ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SERVI: Escaneo de Factura'),
      ),
      body: Center(
        child: _isLoading 
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('SERVI Analizando... ¡Casi listo!'),
                ],
              )
            : _errorMessage != null
                ? Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red))
                : _rawInvoiceResult == null
                    ? ElevatedButton(
                        onPressed: _scanInvoice,
                        child: const Text('Escanear Nueva Factura con SERVI'),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildInvoiceForm(), // Llama a la nueva UI
                      ),
      ),
    );
  }
  
  // --- 5. Implementación del método '_buildInvoiceForm' ---
  Widget _buildInvoiceForm() {
    // Si hay análisis, usa los datos analizados, sino usa la factura cruda.
    // Utilizamos el resultado analizado si existe, si no, creamos un análisis placeholder
    final displayItems = _analyzedItems ?? _rawInvoiceResult!.lineItems.map((e) => AnalyzedLineItem(
        item: e, 
        historicalAvgCost: 0, 
        costDeviationPercentage: 0.0,
        sellingPrice: 0.0, // Placeholder
        fixedCostSnapshot: 0.0, // Placeholder
        suggestedCategory: 'Pendiente', // Placeholder
    )).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Proveedor: ${_rawInvoiceResult!.vendorName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text('Monto Total: \$${_rawInvoiceResult!.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
        const Divider(height: 30),
        
        const Text('Items y Análisis Proyectado (SERVI):', style: TextStyle(fontWeight: FontWeight.bold)),
        
        // Lista de items extraídos y analizados
        ...displayItems.map((analyzedItem) {
            final isAlert = analyzedItem.requiresAlert;
            final item = analyzedItem.item;
            return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        ListTile(
                            leading: Icon(isAlert ? Icons.warning_rounded : Icons.check_circle_outline, color: isAlert ? Colors.redAccent : Colors.green),
                            title: Text(item.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                'Cant: ${item.quantity} | Costo Unitario de Compra: \$${item.unitPrice.toStringAsFixed(2)}',
                            ),
                            trailing: isAlert ? const Icon(Icons.info_outline, color: Colors.red) : null,
                        ),
                        Padding(
                            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    // Muestra la alerta de costo (MVP 1.1)
                                    if (isAlert) 
                                        Text(analyzedItem.alertMessage, style: const TextStyle(fontSize: 12, color: Colors.red, fontStyle: FontStyle.italic)),
                                    
                                    const SizedBox(height: 4),
                                    
                                    // Muestra la categoría y el margen (MVP 1.2)
                                    Text(analyzedItem.marginMessage, style: TextStyle(
                                        fontSize: 13, 
                                        color: analyzedItem.grossProfitMargin > 0.25 ? Colors.green : Colors.orange,
                                        fontWeight: FontWeight.w600,
                                    )),
                                    Text('Costo Fijo Aplicado: \$${analyzedItem.fixedCostSnapshot.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                            ),
                        ),
                        const Divider(height: 1),
                    ],
                ),
            );
        }),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _saveInvoice,
          child: const Text('Confirmar y Guardar en Inventario'),
        ),
      ],
    );
  }
}
