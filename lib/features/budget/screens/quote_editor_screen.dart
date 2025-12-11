// --- UX/UI Enhancement Comment ---
// Screen: QuoteEditorScreen
// UX/UI Redesigned: 2025-05-20 (Final Version)
// Style: Cyber Glow High Contrast
// Features:
// 1. Selector de Fecha de Vencimiento (validUntil).
// 2. Input de Condiciones optimizado (Padding + FontSize).
// 3. Simulación de IA operativa.
// 4. Flujo de guardado con feedback (Snackbars) y redirección.
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:proveedor_servicly_app/features/budget/models/quote_item_model.dart';
import 'package:proveedor_servicly_app/features/budget/providers/quote_provider.dart';
import 'package:proveedor_servicly_app/features/budget/widgets/product_selection_modal.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/features/budget/models/quote_request_model.dart';
import 'package:proveedor_servicly_app/features/inventory/data/inventory_repository.dart';
import 'package:proveedor_servicly_app/features/budget/services/quote_intelligence_service.dart';
import 'package:proveedor_servicly_app/shared/theme/widgets/cyber_container.dart';
import 'package:proveedor_servicly_app/features/budget/screens/quote_preview_screen.dart'; // Asegúrate de tener este import

class QuoteEditorScreen extends StatefulWidget {
  final bool isNew;
  final QuoteRequestModel? sourceRequest;

  const QuoteEditorScreen({
    super.key, 
    this.isNew = false,
    this.sourceRequest,
  });

  @override
  State<QuoteEditorScreen> createState() => _QuoteEditorScreenState();
}

class _QuoteEditorScreenState extends State<QuoteEditorScreen> {
  late TextEditingController _clientNameController;
  late TextEditingController _notesController;
  bool _isGeneratingAI = false;
  
  // --- NUEVO: ESTADO PARA FECHA DE VENCIMIENTO ---
  DateTime _validUntil = DateTime.now().add(const Duration(days: 15)); // Default 15 días

  @override
  void initState() {
    super.initState();
    final provider = context.read<QuoteProvider>();
    
    if (widget.isNew) {
      final user = context.read<UserModel?>();
      provider.startNewQuote(user);
      
      // Default fecha para nuevas
      _validUntil = DateTime.now().add(const Duration(days: 15));

      if (widget.sourceRequest != null) {
        final req = widget.sourceRequest!;
        provider.updateClientInfo(req.clientName, '');
        
        _notesController = TextEditingController(
          text: "Solicitud: ${req.serviceType}\nDetalle: ${req.description}\nUbicación: ${req.location}"
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.addItemToCurrent(QuoteItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: req.serviceType,
            description: "${req.description} (${req.quantity})",
            quantity: 1,
            unitPrice: 0, 
          ));
        });
      } else {
        _notesController = TextEditingController(text: '');
      }
    } else {
      // Edición: Cargar datos existentes
      _notesController = TextEditingController(text: provider.currentQuote?.notes ?? '');
      if (provider.currentQuote != null) {
        _validUntil = provider.currentQuote!.validUntil;
      }
    }
    
    if (widget.sourceRequest == null) {
       _clientNameController = TextEditingController(
        text: provider.currentQuote?.clientName ?? ''
      );
    } else {
       _clientNameController = TextEditingController(text: widget.sourceRequest!.clientName);
    }
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // --- SELECTOR DE FECHA (CYBER STYLE) ---
  Future<void> _selectDate(BuildContext context) async {
    final theme = Theme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _validUntil,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      // Personalización del calendario para modo oscuro
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: theme.colorScheme.primary, // Color de selección
              onPrimary: Colors.black, // Texto en selección
              surface: const Color(0xFF2D2D5A), // Fondo del calendario
              onSurface: Colors.white, // Texto general
            ),
            dialogBackgroundColor: const Color(0xFF1A1A2E),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _validUntil) {
      setState(() {
        _validUntil = picked;
        // Actualizamos el provider inmediatamente
        context.read<QuoteProvider>().updateExpirationDate(_validUntil);
      });
    }
  }

  // --- LÓGICA DE IA (SIMULACIÓN + PROD) ---
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
      // SIMULACIÓN: Para que veas el efecto visual ahora mismo
      await Future.delayed(const Duration(seconds: 2));
      
      final professionalText = "Estimado cliente,\n\nEn atención a su solicitud de '$text', presentamos la siguiente propuesta económica.\n\nCONDICIONES COMERCIALES:\n1. Forma de Pago: 50% anticipo y 50% contra entrega.\n2. Tiempo de Entrega: 3 a 5 días hábiles.\n3. Validez: Oferta válida hasta el ${DateFormat('dd/MM/yyyy').format(_validUntil)}.\n\nQuedamos a su entera disposición.";

      if (mounted) {
        setState(() {
          _notesController.text = professionalText;
          // Actualizamos también el provider
          context.read<QuoteProvider>().updateNotes(professionalText);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("✨ Texto mejorado con Inteligencia Artificial"),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
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

  // --- MODAL DE GUARDADO (CON ACCIONES REALES) ---
  void _showSaveOptions(BuildContext context, QuoteProvider provider) {
    final theme = Theme.of(context);
    
    // Aseguramos que las notas actuales estén en el provider antes de guardar
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
            const Text("Finalizar Cotización", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            // OPCIÓN 1: BORRADOR
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.save_as, color: Colors.white),
              ),
              title: const Text("Guardar como Borrador", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text("Guardar cambios y salir.", style: TextStyle(color: Colors.white70)),
              onTap: () async {
                Navigator.pop(ctx); // Cerrar modal
                
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Guardando borrador...")));

                await provider.saveCurrentQuote();
                if (provider.currentQuote != null) {
                  await provider.updateQuoteStatus(provider.currentQuote!.id, 'draft');
                }

                if (mounted) Navigator.pop(context); // Volver a la lista
              },
            ),
            const SizedBox(height: 12),
            
            // OPCIÓN 2: ENVIAR / FINALIZAR
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.send_rounded, color: theme.colorScheme.primary),
              ),
              title: const Text("Finalizar y Previsualizar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text("Lista para enviar al cliente.", style: TextStyle(color: Colors.white70)),
              onTap: () async {
                Navigator.pop(ctx); // Cerrar modal
                
                // Loader de bloqueo
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );

                await provider.saveCurrentQuote();
                
                if (provider.currentQuote != null) {
                   await provider.updateQuoteStatus(provider.currentQuote!.id, 'sent'); 
                }

                await Future.delayed(const Duration(milliseconds: 800)); // UX delay

                if (mounted) {
                  Navigator.pop(context); // Cerrar Loader
                  
                  final user = context.read<UserModel?>();
                  if (user != null && provider.currentQuote != null) {
                    // Redirigir al Preview
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuotePreviewScreen(quote: provider.currentQuote!, user: user),
                      ),
                    );
                  } else {
                    Navigator.pop(context); // Fallback a lista
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- MÉTODOS DE ITEMS ---
  void _openProductSelector(BuildContext context) async {
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

  void _addManualItem(BuildContext context) {
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.isNew ? "Crear Cotización" : "Editar Cotización", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(quote.number, style: TextStyle(fontSize: 12, fontFamily: 'Courier', color: theme.colorScheme.onSurface.withOpacity(0.6))),
          ],
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: () => _showSaveOptions(context, provider),
              icon: const Icon(Icons.check, size: 18),
              label: const Text("Finalizar"),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.black,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
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
            _CyberInput(
              label: "Cliente",
              icon: Icons.person_outline,
              defaultValue: _clientNameController.text,
              onChanged: (val) => provider.updateClientInfo(val, ''),
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
                    if (value == 'inventory') _openProductSelector(context);
                    if (value == 'manual') _addManualItem(context);
                  },
                  itemBuilder: (context) => [
                    _buildPopupItem(theme, 'inventory', Icons.inventory_2_outlined, 'Desde Inventario'),
                    _buildPopupItem(theme, 'manual', Icons.edit_note, 'Ítem Manual'),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text("AGREGAR", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            if (quote.items.isEmpty)
              _buildEmptyState(theme)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: quote.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildEditableItemRow(context, provider, quote.items[index], theme),
              ),

            // --- NUEVA SECCIÓN: FECHA DE VENCIMIENTO ---
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionHeader(title: "Configuración", icon: Icons.settings_outlined),
                
                // Visualizador de Fecha Interactivo
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month, size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("VÁLIDO HASTA", style: TextStyle(fontSize: 9, color: theme.colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            Text(
                              DateFormat('dd MMM yyyy').format(_validUntil),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.edit, size: 12, color: Colors.white30),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- SECCIÓN NOTAS / CONDICIONES (CORREGIDA) ---
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
                    decoration: BoxDecoration(
                      gradient: _isGeneratingAI 
                        ? LinearGradient(colors: [Colors.grey.shade700, Colors.grey.shade800])
                        : const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF2196F3)]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        if (!_isGeneratingAI)
                          BoxShadow(color: Colors.purple.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))
                      ],
                    ),
                    child: _isGeneratingAI 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                            SizedBox(width: 6),
                            Text("Mejorar con IA", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // TEXTFIELD CONDICIONES (OPTIMIZADO)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2), 
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: 5,
                // LETRA GRANDE (16px) PARA LECTURA FÁCIL
                style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                decoration: InputDecoration(
                  hintText: "Escribe condiciones de pago, entrega, garantía, etc...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  border: InputBorder.none,
                  // PADDING AMPLIO PARA QUE NO TOQUE BORDES
                  contentPadding: const EdgeInsets.all(16), 
                ),
                onChanged: (val) {
                  // Actualizamos el provider mientras escribe
                  provider.updateNotes(val);
                },
              ),
            ),

            const SizedBox(height: 32),

            // TOTALES
            CyberContainer(
              borderGlow: true, 
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSummaryRow(theme, "Subtotal", quote.total - (quote.total * (quote.taxRate / 100))), 
                  const SizedBox(height: 8),
                  _buildSummaryRow(theme, "Impuestos (${quote.taxRate}%)", quote.total * (quote.taxRate / 100)),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Colors.white.withOpacity(0.1))),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("TOTAL NETO", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.primary, letterSpacing: 1.5)),
                      Text(
                        NumberFormat.simpleCurrency(name: quote.currency).format(quote.total),
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: theme.colorScheme.primary, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---
  PopupMenuItem<String> _buildPopupItem(ThemeData theme, String value, IconData icon, String text) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(children: [Icon(icon, size: 20, color: Colors.white), const SizedBox(width: 12), Text(text, style: const TextStyle(color: Colors.white))]),
    );
  }

  Widget _buildEditableItemRow(BuildContext context, QuoteProvider provider, QuoteItem item, ThemeData theme) {
    return CyberContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
                  image: item.imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(item.imageUrl), fit: BoxFit.cover) : null,
                ),
                child: item.imageUrl.isEmpty ? Icon(Icons.inventory_2_outlined, size: 24, color: theme.colorScheme.onSurface.withOpacity(0.5)) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      initialValue: item.name,
                      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                    if (item.sku.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text("SKU: ${item.sku}", style: const TextStyle(fontSize: 10, color: Colors.white70)),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                onPressed: () => provider.removeItemFromCurrent(item.id),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(flex: 3, child: _CyberMiniInput(label: "CANT", value: item.quantity.toString(), onChanged: (val) => provider.updateItemInCurrent(item.id, quantity: double.tryParse(val) ?? 0))),
              const SizedBox(width: 12),
              Expanded(flex: 4, child: _CyberMiniInput(label: "PRECIO UNIT.", prefix: "\$", value: item.unitPrice.toStringAsFixed(2), onChanged: (val) => provider.updateItemInCurrent(item.id, price: double.tryParse(val) ?? 0))),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text("TOTAL", style: TextStyle(fontSize: 9, color: Colors.white38)), 
                const SizedBox(height: 4),
                Text("\$${item.total.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 14)),
              ])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme, String label, double amount) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
      Text("\$${amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
    ]);
  }

  Widget _buildEmptyState(ThemeData theme) {
    return CyberContainer(
      padding: const EdgeInsets.all(32),
      child: Center(child: Column(children: [
        Icon(Icons.add_shopping_cart, size: 48, color: theme.disabledColor.withOpacity(0.3)),
        const SizedBox(height: 16),
        Text("Cotización Vacía", style: TextStyle(fontWeight: FontWeight.bold, color: theme.disabledColor)),
      ])),
    );
  }
}

// --- WIDGETS PRIVADOS ---
class _SectionHeader extends StatelessWidget {
  final String title; final IconData icon;
  const _SectionHeader({required this.title, required this.icon});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Row(children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: theme.colorScheme.onSurface.withOpacity(0.6))),
      ]),
    );
  }
}

class _CyberInput extends StatelessWidget {
  final String label; final IconData icon; final Function(String) onChanged; final bool autofocus; final bool isNumeric; final String? defaultValue;
  const _CyberInput({required this.label, required this.icon, required this.onChanged, this.autofocus = false, this.isNumeric = false, this.defaultValue});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary, letterSpacing: 0.8)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.1))),
        child: Row(children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(
            initialValue: defaultValue, autofocus: autofocus, keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
            decoration: InputDecoration(border: InputBorder.none, hintText: "Escriba aquí...", hintStyle: TextStyle(color: Colors.white.withOpacity(0.3))),
            onChanged: onChanged,
          )),
        ]),
      )
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
      Container(
        height: 38, padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withOpacity(0.1))),
        child: Row(children: [
          if (prefix.isNotEmpty) Padding(padding: const EdgeInsets.only(right: 4), child: Text(prefix, style: const TextStyle(color: Colors.white38, fontSize: 12))),
          Expanded(child: TextFormField(
            initialValue: value, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10)),
            onChanged: onChanged,
          )),
        ]),
      ),
    ]);
  }
}