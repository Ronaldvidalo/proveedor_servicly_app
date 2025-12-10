// --- UX/UI Enhancement Comment ---
// Pantalla: QuoteEditorScreen
// Actualización: Soporte para convertir 'QuoteRequestModel' (Leads) en Cotizaciones reales.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:proveedor_servicly_app/features/budget/models/quote_item_model.dart';
import 'package:proveedor_servicly_app/features/budget/providers/quote_provider.dart';
import 'package:proveedor_servicly_app/features/budget/widgets/product_selection_modal.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/features/budget/models/quote_request_model.dart'; // Importar el modelo de solicitud
import 'package:proveedor_servicly_app/features/inventory/data/inventory_repository.dart';
import 'package:proveedor_servicly_app/features/budget/services/quote_intelligence_service.dart';

class QuoteEditorScreen extends StatefulWidget {
  final bool isNew;
  final QuoteRequestModel? sourceRequest; // <-- NUEVO: Lead origen

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

  @override
  void initState() {
    super.initState();
    final provider = context.read<QuoteProvider>();
    
    if (widget.isNew) {
      final user = context.read<UserModel?>();
      provider.startNewQuote(user);

      // --- LOGICA DE CONVERSIÓN DE LEAD ---
      if (widget.sourceRequest != null) {
        final req = widget.sourceRequest!;
        // 1. Pre-llenar nombre del cliente
        provider.updateClientInfo(req.clientName, '');
        
        // 2. Pre-llenar notas con la descripción del cliente
        _notesController = TextEditingController(
          text: "Solicitud: ${req.serviceType}\nDetalle: ${req.description}\nUbicación: ${req.location}\nPara: ${DateFormat.yMMMd().format(req.preferredDate)}"
        );

        // 3. (Opcional) Agregar un ítem genérico basado en la solicitud
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.addItemToCurrent(QuoteItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: req.serviceType,
            description: "${req.description} (${req.quantity})",
            quantity: 1,
            unitPrice: 0, // El proveedor debe poner el precio
          ));
        });
      } else {
        _notesController = TextEditingController(text: '');
      }
    } else {
      _notesController = TextEditingController(text: provider.currentQuote?.id ?? ''); // Ajustar si tienes campo notas en modelo
    }
    
    // Si no vino del lead, usamos el controller normal
    if (widget.sourceRequest == null) {
       _clientNameController = TextEditingController(
        text: provider.currentQuote?.clientName ?? ''
      );
      if (!widget.isNew) {
         // Aquí deberías cargar las notas si existieran en el modelo Quote
         _notesController = TextEditingController(text: ''); 
      }
    } else {
       // Si vino del lead, el controller ya se inicializó arriba indirectamente, 
       // pero necesitamos vincularlo al widget
       _clientNameController = TextEditingController(text: widget.sourceRequest!.clientName);
    }
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _openProductSelector(BuildContext context) async {
    try {
      final inventoryRepo = context.read<InventoryRepository>();
      final QuoteItem? selectedItem = await showModalBottomSheet<QuoteItem>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => ProductSelectionModal(inventoryRepository: inventoryRepo),
      );

      if (selectedItem != null && mounted) {
        context.read<QuoteProvider>().addItemToCurrent(selectedItem);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al abrir inventario: $e")),
      );
    }
  }

  Future<void> _enhanceNotesWithAI() async {
    final text = _notesController.text;
    if (text.trim().length < 5) return;

    setState(() => _isGeneratingAI = true);

    try {
      final aiService = context.read<QuoteIntelligenceService>();
      final professionalText = await aiService.professionalizeTerms(text);

      setState(() {
        _notesController.text = professionalText;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al conectar con la IA")),
      );
    } finally {
      setState(() => _isGeneratingAI = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<QuoteProvider>();
    final quote = provider.currentQuote;

    if (quote == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isNew ? "Nueva Cotización" : "Editar Cotización",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              quote.number,
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          TextButton.icon(
            onPressed: () async {
              if (_clientNameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Ingresa el nombre del cliente")),
                );
                return;
              }
              await provider.saveCurrentQuote();
              if (context.mounted) Navigator.pop(context);
            },
            icon: Icon(Icons.save, color: theme.colorScheme.primary),
            label: Text("Guardar", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECCIÓN CLIENTE
            _buildSectionTitle(theme, "Información del Cliente", Icons.person_outline),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(theme),
              child: TextField(
                controller: _clientNameController,
                decoration: _inputDecoration(theme, "Nombre del Cliente / Empresa", Icons.business),
                onChanged: (val) => provider.updateClientInfo(val, ''),
              ),
            ),

            const SizedBox(height: 24),

            // SECCIÓN ÍTEMS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle(theme, "Productos y Servicios", Icons.shopping_bag_outlined),
                TextButton.icon(
                  onPressed: () => _openProductSelector(context),
                  icon: const Icon(Icons.add_circle, size: 18),
                  label: const Text("Agregar"),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            if (quote.items.isEmpty)
              _buildEmptyState(theme)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: quote.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = quote.items[index];
                  return _buildEditableItemRow(context, provider, item, theme);
                },
              ),

            const SizedBox(height: 24),

            // SECCIÓN NOTAS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle(theme, "Notas y Condiciones", Icons.notes),
                InkWell(
                  onTap: _isGeneratingAI ? null : _enhanceNotesWithAI,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.purple.shade400, Colors.blue.shade600]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))
                      ],
                    ),
                    child: _isGeneratingAI 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text("Mejorar con IA", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: _cardDecoration(theme),
              child: TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Ej: Pago 50% adelantado, entrega el viernes...",
                  border: InputBorder.none,
                ),
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
              ),
            ),

            const SizedBox(height: 24),

            // SECCIÓN TOTALES
            _buildSectionTitle(theme, "Resumen Financiero", Icons.attach_money),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _cardDecoration(theme).copyWith(
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(theme, "Subtotal", quote.total - (quote.total * (quote.taxRate / 100))), 
                  const SizedBox(height: 8),
                  _buildSummaryRow(theme, "Impuestos (${quote.taxRate}%)", quote.total * (quote.taxRate / 100)),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "TOTAL",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      ),
                      Text(
                        NumberFormat.simpleCurrency(name: quote.currency).format(quote.total),
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
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

  Widget _buildEditableItemRow(BuildContext context, QuoteProvider provider, QuoteItem item, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(theme),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  image: item.imageUrl.isNotEmpty
                      ? DecorationImage(image: NetworkImage(item.imageUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: item.imageUrl.isEmpty ? const Icon(Icons.image, size: 20) : null,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (item.sku.isNotEmpty)
                      Text("SKU: ${item.sku}", style: TextStyle(fontSize: 10, color: theme.disabledColor)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.redAccent),
                onPressed: () => provider.removeItemFromCurrent(item.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildMiniInput(theme, label: "Cant.", value: item.quantity.toString(), onChanged: (val) => provider.updateItemInCurrent(item.id, quantity: double.tryParse(val) ?? 0)),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: _buildMiniInput(theme, label: "Precio Unit.", value: item.unitPrice.toStringAsFixed(2), prefix: "\$", onChanged: (val) => provider.updateItemInCurrent(item.id, price: double.tryParse(val) ?? 0)),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("Total", style: TextStyle(fontSize: 10, color: theme.disabledColor)),
                    const SizedBox(height: 4),
                    Text("\$${item.total.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniInput(ThemeData theme, {required String label, required String value, required Function(String) onChanged, String prefix = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: theme.disabledColor)),
        const SizedBox(height: 4),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              if (prefix.isNotEmpty) Text(prefix, style: TextStyle(color: theme.disabledColor, fontSize: 12)),
              Expanded(
                child: TextFormField(
                  initialValue: value,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
      ],
    );
  }

  Widget _buildSummaryRow(ThemeData theme, String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
        Text("\$${amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(border: Border.all(color: theme.dividerColor), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(Icons.add_shopping_cart, size: 40, color: theme.disabledColor.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text("Agrega productos o servicios", style: TextStyle(color: theme.disabledColor)),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(ThemeData theme) {
    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
    );
  }

  InputDecoration _inputDecoration(ThemeData theme, String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: theme.colorScheme.primary.withValues(alpha: 0.7), size: 20),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
    );
  }
}