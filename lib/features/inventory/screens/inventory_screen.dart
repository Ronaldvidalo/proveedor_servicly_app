import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as cloud_firestore;
// --- IMPORTAR SHOWCASE ---
import 'package:showcaseview/showcaseview.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart'; // Importante para PlayerState
import 'package:shared_preferences/shared_preferences.dart'; // Para recordar si ya vio el tour

// --- Modelos ---
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:provider/provider.dart' as provider;

// --- Arquitectura ---
import '../providers/inventory_providers.dart';
import '../widgets/inventory_product_card.dart';

// --- Pantallas ---
import 'package:proveedor_servicly_app/features/manage_store/presentation/screens/add_edit_product_screen.dart';

// --- Widgets Reutilizables ---
import 'package:proveedor_servicly_app/features/cost_structure/screen/mentor_card.dart';

// --- SERVICIOS DE IA (NUEVOS) ---
import 'package:proveedor_servicly_app/ai/services/voice_service.dart';
import 'package:proveedor_servicly_app/ai/services/servi_brain_service.dart';
import 'package:proveedor_servicly_app/ai/widgets/servi_avatar.dart';
import 'package:proveedor_servicly_app/ai/services/gemini_service.dart';
import 'package:proveedor_servicly_app/ai/services/servi_api_connector_service.dart';
import 'package:proveedor_servicly_app/ai/services/servi_conversational_service.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart'; 

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String _filterStatus = 'Todos'; // 'Todos', 'Bajo Stock', 'Agotado'
  bool _isImporting = false;
  bool _showMentor = true;

  // Control para el tour
  bool _isTourCheckPending = true;

  // --- KEYS PARA EL TOUR VIRTUAL ---
  final GlobalKey _keyImportBtn = GlobalKey();
  final GlobalKey _keyAddBtn = GlobalKey();
  final GlobalKey _keySearch = GlobalKey();
  final GlobalKey _keyFilters = GlobalKey();
  
  // --- IA SERVI INTEGRADA ---
  final ServiVoiceService _voiceService = ServiVoiceService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  late ServiBrainService _serviBrain;
  
  bool _isSpeaking = false;
  bool _isListening = false;
  bool _isThinking = false;

  final List<String> _fillers = [
    "Revisando el depósito...",
    "Chequeando stock...",
    "A ver qué tenemos...",
    "Dame un segundo...",
  ];

  @override
  void initState() {
    super.initState();
    
    // Inicialización del Cerebro IA
    final firestoreService = FirestoreService(); 
    final geminiService = GeminiService();
    final apiConnector = ServiApiConnectorService(geminiService, firestoreService);
    final conversationalService = ServiConversationalService(apiConnector);
    _serviBrain = ServiBrainService(advancedBrain: conversationalService);
    
    _initVoiceListeners();
  }
  
  void _initVoiceListeners() {
    _voiceService.player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isSpeaking = state == PlayerState.playing);
      }
    });
  }
  
  void _updateSpeakingState(bool speaking) {
      if(mounted) setState(() => _isSpeaking = speaking);
  }

  Future<void> _speak(String text) async {
    _updateSpeakingState(true);
    await _voiceService.speak(text);
    // El listener se encarga de ponerlo en false cuando termina
  }

  Future<void> _listen() async {
    if (_isListening || _isThinking) return;

    if (_isSpeaking) {
      await _voiceService.stop();
      _updateSpeakingState(false);
    }

    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening') setState(() => _isListening = false);
      },
      onError: (error) {
        setState(() => _isListening = false);
        _speak("No te entendí bien. ¿Repetimos?");
      },
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) {
          if (val.finalResult) {
            setState(() => _isListening = false);
            _processVoiceCommand(val.recognizedWords);
          }
        },
        localeId: 'es_AR',
      );
    } else {
      _speak("Habilitá el micrófono por favor.");
    }
  }

  Future<void> _processVoiceCommand(String command) async {
    if (command.trim().isEmpty) return;
    
    setState(() => _isThinking = true);
    
    if (command.split(' ').length > 2) {
       _fillers.shuffle();
       _speak(_fillers.first);
    }

    try {
        final userModel = provider.Provider.of<UserModel?>(context, listen: false);
        
        if (userModel != null) {
            String response = await _serviBrain.processCommand(command, userModel.uid);
            
            // Acciones inteligentes basadas en la respuesta
            if (command.toLowerCase().contains("bajo stock") || command.toLowerCase().contains("falta")) {
                setState(() => _filterStatus = 'Bajo Stock');
            } else if (command.toLowerCase().contains("todos")) {
                setState(() => _filterStatus = 'Todos');
            }

            if (mounted) setState(() => _isThinking = false);
            _speak(response);
        }
    } catch (e) {
        if (mounted) setState(() => _isThinking = false);
        _speak("Tuve un error al buscar. Probá manual.");
    }
  }
  
  void _handleAvatarTap() {
    if (_isThinking) return;
    if (_isListening) {
      _listen(); 
    } else if (_isSpeaking) {
      _voiceService.stop();
      _updateSpeakingState(false);
    } else {
      _speak("¿Qué buscamos en el inventario?"); 
      Future.delayed(const Duration(milliseconds: 1500), _listen);
    }
  }

  // =========================================================
  // --- LÓGICA DEL TOUR HABLADO (NUEVO) ---
  // =========================================================

  String _getScriptForStep(GlobalKey key) {
    if (key == _keyImportBtn) return "Acá arriba podés subir tu inventario masivo desde Excel.";
    if (key == _keyAddBtn) return "O usá este botón para cargar productos uno por uno.";
    if (key == _keySearch) return "Si buscás algo rápido, escribí el nombre acá.";
    if (key == _keyFilters) return "Y usá estos filtros para detectar qué te falta reponer urgente.";
    return "";
  }

  void _onShowcaseStepStart(int? index, GlobalKey key) {
    // Aseguramos que el widget sea visible
    if (key.currentContext != null) {
      Scrollable.ensureVisible(key.currentContext!, duration: const Duration(milliseconds: 500), alignment: 0.5);
    }
    
    // Servi habla
    String script = _getScriptForStep(key);
    if (script.isNotEmpty) {
      // Pequeño delay para que la animación visual termine antes de hablar
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _speak(script);
      });
    }
  }

  Future<void> _checkIfFirstTime(BuildContext showcaseContext) async {
    final prefs = await SharedPreferences.getInstance();
    // Usamos una key única para este tour
    const String tourKey = 'hasSeenInventoryTour_v1'; 
    final bool hasSeenTour = prefs.getBool(tourKey) ?? false;

    if (!hasSeenTour) {
      // Saludo inicial antes de arrancar los pasos
      await _speak("Bienvenido a tu depósito digital. Vamos a organizar tu stock.");
      
      if (mounted) {
        ShowCaseWidget.of(showcaseContext).startShowCase([ 
           _keyImportBtn,
           _keyAddBtn,
           _keySearch,
           _keyFilters,
        ]);
        prefs.setBool(tourKey, true);
      }
    }
  }
  
  // Reinicio manual del tour (para el botón de ayuda)
  void _manualTourStart(BuildContext showcaseContext) {
      _speak("Dale, repasemos cómo gestionar el stock.");
      ShowCaseWidget.of(showcaseContext).startShowCase([
        _keyImportBtn,
        _keyAddBtn,
        _keySearch,
        _keyFilters,
      ]);
  }
  
  @override
  void dispose() {
      _voiceService.dispose();
      _speech.stop();
      super.dispose();
  }

  // =========================================================
  // 1. LÓGICA DE IMPORTACIÓN (CSV)
  // =========================================================

  void _showImportInfo(String userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D5A), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFF00BFFF)),
            SizedBox(width: 10),
            Text("Formato del CSV", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Para importar correctamente, tu archivo Excel/CSV debe tener estas 5 columnas en este orden exacto:",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            _buildFormatRow("1. Nombre", "Ej: Shampoo Premium"),
            _buildFormatRow("2. Descripción", "Ej: 500ml Anti-caída"),
            _buildFormatRow("3. Precio Venta", "Ej: 1500.00"),
            _buildFormatRow("4. Stock", "Ej: 50"),
            _buildFormatRow("5. Costo", "Ej: 800.00 (Opcional)"),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: Colors.orangeAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                // ignore: deprecated_member_use
                border: Border.all(color: Colors.orangeAccent.withOpacity(0.3))
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "La primera fila del archivo se ignorará (úsala para títulos).",
                      style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.white54)),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00BFFF)),
            icon: const Icon(Icons.folder_open, color: Colors.black),
            label: const Text("Seleccionar Archivo", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx); 
              _importCSV(userId); 
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFormatRow(String title, String example) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(example, style: const TextStyle(color: Colors.white38, fontSize: 12), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Future<void> _importCSV(String userId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null) return;

      setState(() => _isImporting = true);

      double currentFixedCost = 0.0;
      try {
        final configSnapshot = await cloud_firestore.FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('settings')
            .doc('financial_config')
            .get();

        if (configSnapshot.exists && configSnapshot.data() != null) {
          currentFixedCost = (configSnapshot.data()!['costoFijoUnitarioCalculado'] as num?)?.toDouble() ?? 0.0;
        }
      } catch (e) {
        debugPrint("Advertencia CSV: No se pudo leer costos fijos: $e");
      }

      final file = File(result.files.single.path!);
      final input = file.openRead();
      final fields = await input
          .transform(utf8.decoder)
          .transform(const CsvToListConverter())
          .toList();

      List<ProductModel> newProducts = [];
      
      for (int i = 1; i < fields.length; i++) {
        final row = fields[i];
        if (row.isEmpty || row[0].toString().isEmpty) continue;

        final String name = row[0].toString();
        final String desc = row.length > 1 ? row[1].toString() : '';
        final double price = row.length > 2 ? (double.tryParse(row[2].toString()) ?? 0.0) : 0.0;
        final int stock = row.length > 3 ? (int.tryParse(row[3].toString()) ?? 0) : 0;
        final double cost = row.length > 4 ? (double.tryParse(row[4].toString()) ?? 0.0) : 0.0;

        newProducts.add(ProductModel(
          id: const Uuid().v4(),
          providerId: userId,
          name: name,
          description: desc,
          price: price,
          quantity: stock,
          cost: cost, 
          sku: '', 
          category: 'Importado', 
          createdAt: cloud_firestore.Timestamp.now(),
          imageUrl: '', 
          minStock: 5,
          fixedCostSnapshot: currentFixedCost, 
          wholesalePrice: 0,
          ambassadorPrice: 0,
        ));
      }

      if (newProducts.isNotEmpty) {
        final repo = ref.read(inventoryRepositoryProvider);
        await repo.uploadBulkProducts(newProducts);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('¡${newProducts.length} productos importados con Costo Fijo: $currentFixedCost!'), backgroundColor: Colors.green)
          );
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al importar: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  // =========================================================
  // 2. INTERFAZ (BUILD)
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);
    final userModel = provider.Provider.of<UserModel?>(context);

    const backgroundColor = Color(0xFF1A1A2E);
    const surfaceColor = Color(0xFF2D2D5A);
    const accentColor = Color(0xFF00BFFF);

    // --- 1. Envolvemos todo en ShowCaseWidget con callbacks ---
    return ShowCaseWidget(
      onStart: (index, key) => _onShowcaseStepStart(index, key),
      onComplete: (index, key) { 
          if (index == 3) _speak("¡Listo! Cualquier duda sobre el stock, preguntame."); 
      },
      blurValue: 1,
      builder: (context) {
        
        // --- 2. Disparador del Tour ---
        if (_isTourCheckPending) {
          _isTourCheckPending = false;
          WidgetsBinding.instance.addPostFrameCallback((_) => _checkIfFirstTime(context));
        }

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: const Text("Inventario Smart"),
            backgroundColor: backgroundColor,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              if (!_isImporting)
                Showcase(
                  key: _keyImportBtn,
                  title: 'Importación Masiva',
                  description: 'Sube tu inventario desde un Excel o CSV en segundos.',
                  child: IconButton(
                    icon: const Icon(Icons.upload_file),
                    tooltip: 'Importar CSV',
                    onPressed: () {
                      if (userModel != null) _showImportInfo(userModel.uid);
                    },
                  ),
                ),
              
              Showcase(
                key: _keyAddBtn,
                title: 'Añadir Producto',
                description: 'Crea productos uno a uno manualmente.',
                child: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Añadir Manual',
                  onPressed: () {
                    if (userModel != null) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AddEditProductScreen(user: userModel)
                      ));
                    }
                  },
                ),
              ),
              
              IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.white54),
                tooltip: 'Ayuda',
                onPressed: () => _manualTourStart(context),
              ),
            ],
          ),
          
          // --- BOTÓN FLOTANTE IA ---
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: GestureDetector(
              onTap: _handleAvatarTap,
              child: ServiAvatar(
                isSpeaking: _isSpeaking,
                isListening: _isListening, 
                isThinking: _isThinking, 
                size: 60, 
              ),
            ),
          ),
          
          body: _isImporting 
            ? const Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: accentColor),
                  SizedBox(height: 16),
                  Text("Procesando CSV...", style: TextStyle(color: Colors.white))
                ],
              ))
            : Column(
            children: [
              
              if (_showMentor)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: MentorCard(
                    title: "Centro de Comando",
                    message: "Mantén tu stock al día para calcular ganancias reales. \n💡 Tip: Usa el botón de 'Carga' arriba para subir tu Excel masivo.",
                    onDismiss: () => setState(() => _showMentor = false),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Showcase(
                  key: _keySearch,
                  title: 'Buscador Rápido',
                  description: 'Encuentra cualquier producto por nombre al instante.',
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: "Buscar producto...",
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: accentColor),
                      filled: true,
                      fillColor: surfaceColor,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accentColor, width: 2)),
                    ),
                  ),
                ),
              ),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Showcase(
                  key: _keyFilters,
                  title: 'Filtros Inteligentes',
                  description: 'Detecta productos agotados o con stock bajo.',
                  child: Row(
                    children: [
                      _FilterChip(label: 'Todos', isSelected: _filterStatus == 'Todos', onSelected: (v) => setState(() => _filterStatus = 'Todos')),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Bajo Stock', isSelected: _filterStatus == 'Bajo Stock', onSelected: (v) => setState(() => _filterStatus = 'Bajo Stock')),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Agotado', isSelected: _filterStatus == 'Agotado', onSelected: (v) => setState(() => _filterStatus = 'Agotado')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: productsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: accentColor)),
                  error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                  data: (allProducts) {
                    final filteredProducts = allProducts.where((product) {
                      final matchesSearch = product.name.toLowerCase().contains(_searchQuery.toLowerCase());
                      if (!matchesSearch) return false;
                      if (_filterStatus == 'Bajo Stock') return product.isLowStock;
                      if (_filterStatus == 'Agotado') return product.isOutOfStock;
                      return true;
                    }).toList();

                    if (filteredProducts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // ignore: deprecated_member_use
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.white.withOpacity(0.2)),
                            const SizedBox(height: 16),
                            const Text("Inventario Vacío", style: TextStyle(color: Colors.white54, fontSize: 18)),
                            const SizedBox(height: 8),
                            Text(
                              _filterStatus == 'Todos' 
                                ? "Sube tu primer CSV o agrega manual" 
                                : "No hay productos en este estado",
                              style: const TextStyle(color: Colors.white30)
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredProducts.length,
                      itemBuilder: (ctx, i) => InventoryProductCard(
                        product: filteredProducts[i], 
                        onTap: () {
                            if (userModel != null) {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => AddEditProductScreen(
                                  user: userModel, 
                                  productToEdit: filteredProducts[i]
                                )
                              ));
                            }
                        }
                      )
                    );
                  },
                ),
              ),
            ],
          ));
        },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({required this.label, required this.isSelected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: const Color(0xFF2D2D5A),
      // ignore: deprecated_member_use
      selectedColor: const Color(0xFF00BFFF).withOpacity(0.3),
      checkmarkColor: const Color(0xFF00BFFF),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF00BFFF) : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF00BFFF) : Colors.white12,
        ),
      ),
    );
  }
}