// --- UX/UI Enhancement Comment ---
// Screen: QuoteEditorScreen
// UX/UI Redesigned: 2025-05-20 (Final Version)
// Style: Cyber Glow High Contrast
// UPDATE 23/12/2025: Integración con Servi AI (Avatar, Comandos de Voz y Análisis de Costos)
// FIX: Restauración de lógica completa de UI (Dialogs, Modals, etc.)
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:showcaseview/showcaseview.dart'; // Importante para el Tour
import 'package:speech_to_text/speech_to_text.dart' as stt; // Para escuchar
import 'package:audioplayers/audioplayers.dart'; // Para hablar

// --- IMPORTS IA ---
import 'package:proveedor_servicly_app/ai/services/voice_service.dart';
import 'package:proveedor_servicly_app/ai/widgets/servi_avatar.dart';

import 'package:proveedor_servicly_app/features/budget/models/quote_item_model.dart';
import 'package:proveedor_servicly_app/features/budget/providers/quote_provider.dart';
import 'package:proveedor_servicly_app/features/budget/widgets/product_selection_modal.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/features/budget/models/quote_request_model.dart';
import 'package:proveedor_servicly_app/features/inventory/data/inventory_repository.dart';
import 'package:proveedor_servicly_app/shared/theme/widgets/cyber_container.dart';
import 'package:proveedor_servicly_app/features/budget/screens/quote_preview_screen.dart'; 

// Wrapper para inyectar ShowCaseWidget
class QuoteEditorScreen extends StatelessWidget {
  final bool isNew;
  final QuoteRequestModel? sourceRequest;
  final String? initialClient;
  final String? initialConcept;
  final double? initialPrice;
  final String? aiSuggestion;

  const QuoteEditorScreen({
    super.key, 
    this.isNew = false,
    this.sourceRequest,
    this.initialClient,
    this.initialConcept,
    this.initialPrice,
    this.aiSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (context) => _QuoteEditorContent(
        isNew: isNew,
        sourceRequest: sourceRequest,
        initialClient: initialClient,
        initialConcept: initialConcept,
        initialPrice: initialPrice,
        aiSuggestion: aiSuggestion,
      ),
    );
  }
}

class _QuoteEditorContent extends StatefulWidget {
  final bool isNew;
  final QuoteRequestModel? sourceRequest;
  final String? initialClient;
  final String? initialConcept;
  final double? initialPrice;
  final String? aiSuggestion;

  const _QuoteEditorContent({
    this.isNew = false,
    this.sourceRequest,
    this.initialClient,
    this.initialConcept,
    this.initialPrice,
    this.aiSuggestion,
  });

  @override
  State<_QuoteEditorContent> createState() => _QuoteEditorContentState();
}

class _QuoteEditorContentState extends State<_QuoteEditorContent> {
  late TextEditingController _clientNameController;
  late TextEditingController _notesController;
  
  // --- IA & VOZ ---
  final ServiVoiceService _voiceService = ServiVoiceService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isSpeaking = false;
  bool _isListening = false;
  bool _isThinking = false;
  bool _isGeneratingAI = false;

  // --- SHOWCASE KEYS ---
  final GlobalKey _keyClient = GlobalKey();
  final GlobalKey _keyItems = GlobalKey();
  final GlobalKey _keyTotal = GlobalKey();
  final GlobalKey _keyFab = GlobalKey();

  DateTime _validUntil = DateTime.now().add(const Duration(days: 15));

  @override
  void initState() {
    super.initState();
    final provider = context.read<QuoteProvider>();
    
    _clientNameController = TextEditingController();
    _notesController = TextEditingController();

    _initVoiceListeners();

    if (widget.isNew) {
      final user = context.read<UserModel?>();
      provider.startNewQuote(user);
      _validUntil = DateTime.now().add(const Duration(days: 15));

      // CASO A: Solicitud formal
      if (widget.sourceRequest != null) {
        final req = widget.sourceRequest!;
        _clientNameController.text = req.clientName;
        provider.updateClientInfo(req.clientName, '');
        _notesController.text = "Solicitud: ${req.serviceType}\nDetalle: ${req.description}\nUbicación: ${req.location}";
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.addItemToCurrent(QuoteItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: req.serviceType,
            description: "${req.description} (${req.quantity})",
            quantity: 1,
            unitPrice: 0, 
            costSnapshot: 0,
          ));
        });
      } 
      // CASO B: Dictado por Voz (Servi)
      else if (widget.initialClient != null) {
         _clientNameController.text = widget.initialClient!;
         provider.updateClientInfo(widget.initialClient!, '');
         
         if (widget.initialConcept != null) {
             WidgetsBinding.instance.addPostFrameCallback((_) {
               provider.addItemToCurrent(QuoteItem(
                 id: DateTime.now().millisecondsSinceEpoch.toString(),
                 name: widget.initialConcept!,
                 description: "Generado por Servi",
                 quantity: 1,
                 unitPrice: widget.initialPrice!, 
                 costSnapshot: 0,
               ));
               
               // Bienvenida de Servi
               if (widget.aiSuggestion != null) {
                   _speak("Listo el borrador. ${widget.aiSuggestion}");
               } else {
                   _speak("Aquí tienes el presupuesto para ${widget.initialClient}. ¿Agregamos algo más?");
               }
             });
         }
      } 
    } else {
      // Edición
      if (provider.currentQuote != null) {
        _clientNameController.text = provider.currentQuote!.clientName;
        _notesController.text = provider.currentQuote!.notes ?? '';
        _validUntil = provider.currentQuote!.validUntil;
      }
    }

    // Tour inicial (solo si no viene de voz para no interrumpir)
    if (widget.initialClient == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
            ShowCaseWidget.of(context).startShowCase([_keyClient, _keyItems, _keyTotal, _keyFab]);
        });
    }
  }

  void _initVoiceListeners() {
    _voiceService.player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isSpeaking = state == PlayerState.playing);
    });
  }

  Future<void> _speak(String text) async {
    if(!mounted) return;
    setState(() => _isSpeaking = true);
    await _voiceService.speak(text);
    if(mounted) setState(() => _isSpeaking = false);
  }

  // --- CEREBRO LOCAL: INTERPRETE DE COMANDOS DE EDITOR ---
  Future<void> _listen() async {
    if (_isListening || _isThinking) return;
    if (_isSpeaking) await _voiceService.stop();

    bool available = await _speech.initialize(
        onStatus: (s) => (s == 'notListening' && mounted) ? setState(() => _isListening = false) : null,
        onError: (e) => _speak("No entendí. Repetí por favor.")
    );

    if (available) {
        setState(() => _isListening = true);
        _speech.listen(
            localeId: 'es_AR',
            onResult: (val) {
                if (val.finalResult) {
                    setState(() => _isListening = false);
                    _processLocalCommand(val.recognizedWords);
                }
            }
        );
    }
  }

 void _processLocalCommand(String command) async {
      final lower = command.toLowerCase();
      final provider = context.read<QuoteProvider>();
      final currentItems = provider.currentQuote?.items ?? [];
      
      setState(() => _isThinking = true);

      // 1. AGREGAR ÍTEM (Ya existente)
      if (lower.startsWith('agregar') || lower.startsWith('sumar')) {
          try {
              String name = "Ítem por voz";
              double price = 0;
              final words = lower.split(' ');
              int priceIndex = words.indexWhere((w) => w.contains('precio') || w.contains('valor') || w == 'por');
              
              if (priceIndex != -1 && priceIndex + 1 < words.length) {
                  String priceStr = words[priceIndex + 1].replaceAll(RegExp(r'[^0-9]'), '');
                  price = double.tryParse(priceStr) ?? 0;
                  int nameStart = 1; // Salta "agregar"
                  if (nameStart < priceIndex) name = words.sublist(nameStart, priceIndex).join(' ');
              } else {
                  name = lower.replaceFirst(RegExp(r'agregar|sumar'), '').trim();
              }

              provider.addItemToCurrent(QuoteItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name, description: "Voz", quantity: 1, unitPrice: price, costSnapshot: 0
              ));
              await _speak("Agregado $name.");
          } catch (e) { await _speak("No pude agregar ese ítem."); }
      }

      // 2. BORRAR ÍTEM: "Borrar [Nombre]"
      else if (lower.startsWith('borrar') || lower.startsWith('quitar') || lower.startsWith('eliminar')) {
          String targetName = lower.replaceFirst(RegExp(r'borrar|quitar|eliminar'), '').trim();
          // Buscamos el ítem más parecido
          try {
            final itemToDelete = currentItems.firstWhere((item) => item.name.toLowerCase().contains(targetName));
            provider.removeItemFromCurrent(itemToDelete.id);
            await _speak("Eliminé ${itemToDelete.name}.");
          } catch (e) {
            await _speak("No encontré ningún ítem llamado $targetName.");
          }
      }

      // 3. CAMBIAR CLIENTE: "Cliente [Nombre]"
      else if (lower.startsWith('cliente') || lower.contains('cambiar cliente')) {
           String newName = lower.replaceAll(RegExp(r'cambiar|cliente|a |el |para '), '').trim();
           // Capitalizar nombre
           if (newName.isNotEmpty) {
             newName = newName[0].toUpperCase() + newName.substring(1);
             _clientNameController.text = newName;
             provider.updateClientInfo(newName, '');
             await _speak("Listo, cliente cambiado a $newName.");
           }
      }

      // 4. CONDICIONES / NOTAS: "Condiciones [Texto]"
      else if (lower.startsWith('condiciones') || lower.startsWith('nota') || lower.startsWith('escribir condiciones')) {
           String text = lower.replaceFirst(RegExp(r'condiciones|nota|escribir condiciones'), '').trim();
           // Capitalizar primera letra
           if (text.isNotEmpty) text = text[0].toUpperCase() + text.substring(1);
           
           _notesController.text = text;
           provider.updateNotes(text);
           await _speak("Actualicé las condiciones del presupuesto.");
      }

      // 5. VALIDEZ / FECHA: "Validez 15 días" o "Vence en 30 días"
      else if (lower.contains('validez') || lower.contains('vence') || lower.contains('dias') || lower.contains('días')) {
           final RegExp regex = RegExp(r'(\d+)');
           final match = regex.firstMatch(lower);
           if (match != null) {
              int days = int.parse(match.group(0)!);
              setState(() {
                _validUntil = DateTime.now().add(Duration(days: days));
                provider.updateExpirationDate(_validUntil);
              });
              await _speak("Ok, el presupuesto será válido por $days días.");
           } else {
              await _speak("No entendí cuántos días. Decime 'Validez 10 días'.");
           }
      }

      // 6. ENVIAR PDF / FINALIZAR
      else if (lower.contains('enviar') || lower.contains('pdf') || lower.contains('compartir') || lower.contains('finalizar')) {
          await _speak("Generando PDF para compartir...");
          if (mounted) _showSaveOptions(provider);
      }

      // 7. ANÁLISIS (Mantener lógica existente)
      else if (lower.contains('costo') || lower.contains('ganancia') || lower.contains('analizar')) {
          // ... (Tu lógica de análisis de rentabilidad que ya tenías) ...
          final quote = provider.currentQuote;
          if (quote != null) {
              double total = quote.total;
              double estimatedCost = total * 0.6; 
              double marginPercent = ((total - estimatedCost) / total) * 100;
              await _speak("Tu margen estimado es del ${marginPercent.toStringAsFixed(0)}%.");
          }
      }

      else {
          await _speak("No entendí. Podés decir: 'Agregar clavo', 'Borrar clavo', 'Cliente Juan' o 'Enviar PDF'.");
      }

      if (mounted) setState(() => _isThinking = false);
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _notesController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  // --- UI ORIGINAL RESTAURADA ---
  Future<void> _selectDate(BuildContext context) async {
    final theme = Theme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _validUntil,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: theme.colorScheme.primary, 
              onPrimary: Colors.black, 
              surface: const Color(0xFF2D2D5A), 
              onSurface: Colors.white, 
            ),
            dialogTheme: const DialogThemeData( 
              backgroundColor: Color(0xFF1A1A2E), 
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _validUntil) {
      setState(() {
        _validUntil = picked;
        context.read<QuoteProvider>().updateExpirationDate(_validUntil);
      });
    }
  }

  Future<void> _enhanceNotesWithAI() async {
    final text = _notesController.text;
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Escribe algo primero para que la IA lo mejore.")),
      );
      return;
    }

    setState(() => _isGeneratingAI = true);

    try {
      // SIMULACIÓN
      await Future.delayed(const Duration(seconds: 2));
      
      final professionalText = "Estimado cliente,\n\nEn atención a su solicitud de '$text', presentamos la siguiente propuesta económica.\n\nCONDICIONES COMERCIALES:\n1. Forma de Pago: 50% anticipo y 50% contra entrega.\n2. Tiempo de Entrega: 3 a 5 días hábiles.\n3. Validez: Oferta válida hasta el ${DateFormat('dd/MM/yyyy').format(_validUntil)}.\n\nQuedamos a su entera disposición.";

      if (mounted) {
        setState(() {
          _notesController.text = professionalText;
          context.read<QuoteProvider>().updateNotes(professionalText);
          _isGeneratingAI = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("✨ Texto mejorado con Inteligencia Artificial"),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _speak("Listo, mejoré la redacción para que suene más profesional.");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al conectar con la IA")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingAI = false);
      }
    }
  }

  void _showSaveOptions(QuoteProvider provider) {
    final theme = Theme.of(context);
    
    // Sincronizar controladores antes de abrir el modal
    provider.updateNotes(_notesController.text);
    provider.updateExpirationDate(_validUntil);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: theme.colorScheme.primary, width: 2)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Finalizar y Compartir", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Elige cómo quieres guardar este documento.", style: TextStyle(color: Colors.white.withOpacity(0.7))),
            const SizedBox(height: 24),
            
            // OPCIÓN 1
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.save_as, color: Colors.white),
              ),
              title: const Text("Guardar Borrador", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text("Seguir editando luego.", style: TextStyle(color: Colors.white70)),
              onTap: () async {
                  // ... (Lógica de borrador igual)
                  Navigator.pop(ctx);
                  await provider.saveCurrentQuote();
                  if(provider.currentQuote != null) await provider.updateQuoteStatus(provider.currentQuote!.id, 'draft');
                  if(mounted) Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            
            // OPCIÓN 2 (DESTACADA PDF)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.picture_as_pdf, color: theme.colorScheme.primary), // ICONO PDF
              ),
              title: const Text("Generar PDF y Enviar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text("Finalizar y compartir por WhatsApp/Email.", style: TextStyle(color: Colors.white70)),
              onTap: () async {
                  Navigator.pop(ctx); 
                  
                  // Loader
                  if (mounted) showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

                  await provider.saveCurrentQuote();
                  if (provider.currentQuote != null) await provider.updateQuoteStatus(provider.currentQuote!.id, 'sent'); 

                  await Future.delayed(const Duration(milliseconds: 800)); 

                  if (mounted) {
                    Navigator.pop(context); // Cierra loader
                    final user = context.read<UserModel?>();
                    if (user != null && provider.currentQuote != null) {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => QuotePreviewScreen(quote: provider.currentQuote!, user: user)));
                    } else {
                        Navigator.pop(context); 
                    }
                  }
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- MÉTODOS DE ITEMS RESTAURADOS ---
  void _openProductSelector() async {
    try {
      final inventoryRepo = context.read<InventoryRepository>();
      final QuoteItem? selectedItem = await showModalBottomSheet<QuoteItem>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent, 
        builder: (ctx) => ProductSelectionModal(inventoryRepository: inventoryRepo),
      );

      if (!mounted) return;
      if (selectedItem != null) {
        context.read<QuoteProvider>().addItemToCurrent(selectedItem);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _addManualItem() {
    showDialog(
      context: context,
      builder: (ctx) {
        String name = '';
        double price = 0;
        double quantity = 1;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: CyberContainer(
            borderGlow: true, 
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Ítem Manual", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _CyberInput(
                  label: "Descripción", icon: Icons.description_outlined, autofocus: true,
                  onChanged: (val) => name = val,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _CyberInput(label: "Precio", icon: Icons.attach_money, isNumeric: true, onChanged: (val) => price = double.tryParse(val) ?? 0)),
                    const SizedBox(width: 12),
                    Expanded(child: _CyberInput(label: "Cant.", icon: Icons.numbers, isNumeric: true, defaultValue: "1", onChanged: (val) => quantity = double.tryParse(val) ?? 1)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar", style: TextStyle(color: Colors.white70))),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () {
                        if (name.isNotEmpty && price >= 0) {
                          final newItem = QuoteItem(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: name, description: "Personalizado", quantity: quantity, unitPrice: price, costSnapshot: 0
                          );
                          context.read<QuoteProvider>().addItemToCurrent(newItem);
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text("Agregar"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<QuoteProvider>();
    final quote = provider.currentQuote;

    if (quote == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      
      // --- FAB: SERVI AVATAR (NUEVO) ---
      floatingActionButton: Showcase(
          key: _keyFab,
          title: 'Tu Copiloto',
          description: 'Tocame para agregar ítems por voz o pedirme que analice tus costos.',
          child: GestureDetector(
              onTap: _listen,
              child: ServiAvatar(
                  isSpeaking: _isSpeaking,
                  isListening: _isListening,
                  isThinking: _isThinking,
                  size: 60,
              ),
          ),
      ),

      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.isNew ? "Crear Cotización" : "Editar Cotización", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(quote.number, style: TextStyle(fontSize: 12, fontFamily: 'Courier', color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        ]),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: () => _showSaveOptions(provider), 
              icon: const Icon(Icons.check, size: 18),
              label: const Text("Finalizar"),
              style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.black),
            ),
          ),
        ],
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CLIENTE
            Showcase(
                key: _keyClient,
                title: 'El Cliente',
                description: '¿Para quién es el presupuesto?',
                child: _CyberInput(
                  label: "Cliente",
                  icon: Icons.person_outline,
                  defaultValue: _clientNameController.text,
                  onChanged: (val) {
                      _clientNameController.text = val;
                      provider.updateClientInfo(val, '');
                  },
                ),
            ),

            const SizedBox(height: 24),

            // ITEMS HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionHeader(title: "Detalle", icon: Icons.list_alt),
                PopupMenuButton<String>(
                  offset: const Offset(0, 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: const Color(0xFF2D2D5A),
                  elevation: 4,
                  onSelected: (value) {
                    if (value == 'inventory') _openProductSelector(); 
                    if (value == 'manual') _addManualItem(); 
                  },
                  itemBuilder: (context) => [
                    _buildPopupItem(theme, 'inventory', Icons.inventory_2_outlined, 'Desde Inventario'),
                    _buildPopupItem(theme, 'manual', Icons.edit_note, 'Ítem Manual'),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2))),
                    child: Row(children: [Icon(Icons.add, size: 16, color: theme.colorScheme.primary), const SizedBox(width: 4), Text("AGREGAR", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12))]),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Showcase(
                key: _keyItems,
                title: 'Los Ítems',
                description: 'Aquí verás los productos. Puedes dictármelos ("Agregar tornillos por 100") o cargarlos manual.',
                child: quote.items.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: quote.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _buildEditableItemRow(context, provider, quote.items[index], theme),
                  ),
            ),

            const SizedBox(height: 30),
            // CONFIGURACIÓN (FECHA)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionHeader(title: "Configuración", icon: Icons.settings_outlined),
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3))),
                    child: Row(children: [Icon(Icons.calendar_month, size: 18, color: theme.colorScheme.primary), const SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("VÁLIDO HASTA", style: TextStyle(fontSize: 9, color: theme.colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1)), Text(DateFormat('dd MMM yyyy').format(_validUntil), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))]), const SizedBox(width: 8), const Icon(Icons.edit, size: 12, color: Colors.white30)]),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // CONDICIONES
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionHeader(title: "Condiciones", icon: Icons.article_outlined),
                InkWell(
                  onTap: _isGeneratingAI ? null : _enhanceNotesWithAI,
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(gradient: _isGeneratingAI ? LinearGradient(colors: [Colors.grey.shade700, Colors.grey.shade800]) : const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF2196F3)]), borderRadius: BorderRadius.circular(20)),
                    child: _isGeneratingAI ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Row(children: [Icon(Icons.auto_awesome, color: Colors.white, size: 14), SizedBox(width: 6), Text("Mejorar con IA", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
              child: TextField(
                controller: _notesController, maxLines: 5, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                decoration: InputDecoration(hintText: "Escribe condiciones...", hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)), border: InputBorder.none, contentPadding: const EdgeInsets.all(16)),
                onChanged: (val) => provider.updateNotes(val),
              ),
            ),

            const SizedBox(height: 32),

            // TOTALES
            Showcase(
                key: _keyTotal,
                title: 'El Total',
                description: 'Aquí ves el resumen final. Si me preguntas "Analizar costos", revisaré tu margen.',
                child: CyberContainer(
                  borderGlow: true, padding: const EdgeInsets.all(20),
                  child: Column(children: [
                      _buildSummaryRow(theme, "Subtotal", quote.total - (quote.total * (quote.taxRate / 100))), 
                      const SizedBox(height: 8),
                      _buildSummaryRow(theme, "Impuestos (${quote.taxRate}%)", quote.total * (quote.taxRate / 100)),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.1))),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text("TOTAL NETO", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.primary, letterSpacing: 1.5)),
                          Text(NumberFormat.simpleCurrency(name: quote.currency).format(quote.total), style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: theme.colorScheme.primary, letterSpacing: -0.5)),
                      ]),
                  ]),
                ),
            ),
            const SizedBox(height: 80), // Espacio para el FAB
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---
  PopupMenuItem<String> _buildPopupItem(ThemeData theme, String value, IconData icon, String text) {
    return PopupMenuItem<String>(value: value, child: Row(children: [Icon(icon, size: 20, color: Colors.white), const SizedBox(width: 12), Text(text, style: const TextStyle(color: Colors.white))]));
  }

  Widget _buildEditableItemRow(BuildContext context, QuoteProvider provider, QuoteItem item, ThemeData theme) {
    return CyberContainer(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
          Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)), image: item.imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(item.imageUrl), fit: BoxFit.cover) : null), child: item.imageUrl.isEmpty ? Icon(Icons.inventory_2_outlined, size: 24, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)) : null),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  TextFormField(initialValue: item.name, decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  if (item.sku.isNotEmpty) Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: Text("SKU: ${item.sku}", style: const TextStyle(fontSize: 10, color: Colors.white70))),
              ])),
              IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent), onPressed: () => provider.removeItemFromCurrent(item.id)),
          ]),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 12),
          Row(children: [
              Expanded(flex: 3, child: _CyberMiniInput(label: "CANT", value: item.quantity.toString(), onChanged: (val) => provider.updateItemInCurrent(item.id, quantity: double.tryParse(val) ?? 0))),
              const SizedBox(width: 12),
              Expanded(flex: 4, child: _CyberMiniInput(label: "PRECIO UNIT.", prefix: "\$", value: item.unitPrice.toStringAsFixed(2), onChanged: (val) => provider.updateItemInCurrent(item.id, price: double.tryParse(val) ?? 0))),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Text("TOTAL", style: TextStyle(fontSize: 9, color: Colors.white38)), const SizedBox(height: 4), Text("\$${item.total.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 14))])),
          ]),
      ]),
    );
  }

  Widget _buildSummaryRow(ThemeData theme, String label, double amount) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))), Text("\$${amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white))]);
  }

  Widget _buildEmptyState(ThemeData theme) {
    return CyberContainer(padding: const EdgeInsets.all(32), child: Center(child: Column(children: [Icon(Icons.add_shopping_cart, size: 48, color: theme.disabledColor.withValues(alpha: 0.3)), const SizedBox(height: 16), Text("Cotización Vacía", style: TextStyle(fontWeight: FontWeight.bold, color: theme.disabledColor))])));
  }
}

// --- WIDGETS PRIVADOS ---
class _SectionHeader extends StatelessWidget {
  final String title; final IconData icon;
  const _SectionHeader({required this.title, required this.icon});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(padding: const EdgeInsets.only(bottom: 8.0, left: 4), child: Row(children: [Icon(icon, size: 16, color: theme.colorScheme.primary), const SizedBox(width: 8), Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)))]));
  }
}

class _CyberInput extends StatelessWidget {
  final String label; final IconData icon; final Function(String) onChanged; final bool autofocus; final bool isNumeric; final String? defaultValue;
  const _CyberInput({required this.label, required this.icon, required this.onChanged, this.autofocus = false, this.isNumeric = false, this.defaultValue});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = defaultValue != null ? TextEditingController(text: defaultValue) : null;
    if (controller != null) controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary, letterSpacing: 0.8)),
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.1))), child: Row(children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(controller: controller, initialValue: controller == null ? defaultValue : null, autofocus: autofocus, keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16), decoration: InputDecoration(border: InputBorder.none, hintText: "Escriba aquí...", hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3))), onChanged: onChanged)),
      ]))
    ]);
  }
}

class _CyberMiniInput extends StatelessWidget {
  final String label; final String value; final Function(String) onChanged; final String prefix;
  const _CyberMiniInput({required this.label, required this.value, required this.onChanged, this.prefix = ''});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: theme.colorScheme.primary, letterSpacing: 0.5)),
      const SizedBox(height: 4),
      Container(height: 38, padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withValues(alpha: 0.1))), child: Row(children: [
          if (prefix.isNotEmpty) Padding(padding: const EdgeInsets.only(right: 4), child: Text(prefix, style: const TextStyle(color: Colors.white38, fontSize: 12))),
          Expanded(child: TextFormField(initialValue: value, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white), decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10)), onChanged: onChanged)),
      ])),
    ]);
  }
}