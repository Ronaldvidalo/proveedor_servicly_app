// --- UX/UI Enhancement: CRM + Inteligencia de Catálogo ---
// Pantalla: LeadDetailScreen
// Modelo: Cliente (Original del proyecto)
// Integración: Servi Coach IA + Acciones Rápidas

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

// ✅ IMPORTAMOS TU MODELO ORIGINAL
import 'package:proveedor_servicly_app/features/crm/data/models/cliente_model.dart';
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart';
import 'package:proveedor_servicly_app/features/crm/core/crm_enums.dart';

// Módulo de Presupuestos
import 'package:proveedor_servicly_app/features/budget/screens/quote_editor_screen.dart';
import 'package:proveedor_servicly_app/features/budget/models/quote_request_model.dart'; 

// ✅ WIDGET COACH IA
import 'package:proveedor_servicly_app/ai/widgets/servi_coach_widget.dart';

class LeadDetailScreen extends StatefulWidget {
  final Cliente lead; // ✅ Usamos Cliente

  const LeadDetailScreen({super.key, required this.lead});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> {
  bool _isLoading = false;
  String _salesStrategy = "Analizando perfil..."; // Estado para el Coach

  @override
  void initState() {
    super.initState();
    _generateStrategy();
  }

  // Simulación de la IA pensando una estrategia (o llamada real a Gemini)
  void _generateStrategy() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      // Usamos los datos reales del cliente para personalizar el consejo
      final name = widget.lead.nombreCompleto.split(' ')[0];
      final source = widget.lead.source.isEmpty ? "consulta" : widget.lead.source;
      
      setState(() {
        _salesStrategy = "💡 Tip: $name llegó por $source. Ofrécele una demostración o un descuento del 10% si reserva hoy. La velocidad es clave.";
      });
    }
  }

  // --- Helpers de Inteligencia de Catálogo ---
  String? get _catalogProduct {
    if (widget.lead.source.contains(':')) {
      return widget.lead.source.split(':').last.trim();
    }
    return null;
  }

  String _getFriendlySource(String? source) {
    if (source == null || source.isEmpty) return 'Consulta General';
    final s = source.toLowerCase();
    
    if (s.contains('whatsapp')) return 'WhatsApp';
    if (s.contains('view_product')) return 'Catálogo: Vio Producto';
    if (s.contains('phone')) return 'Llamada';
    if (s.contains('email')) return 'Email';
    
    return 'Consulta ($source)';
  }

  // --- Acciones de Contacto ---
  Future<void> _launchWhatsApp() async {
    final phone = widget.lead.telefono.replaceAll(RegExp(r'[^\d+]'), '');
    if (phone.isEmpty) {
      _showSnack('Este contacto no dejó un teléfono registrado.', isError: true);
      return;
    }
    
    final product = _catalogProduct;
    // Usamos nombreCompleto del modelo Cliente
    final baseMessage = product != null 
        ? "Hola ${widget.lead.nombreCompleto}, vi que te interesó el producto '$product'. ¿En qué puedo ayudarte?"
        : "Hola ${widget.lead.nombreCompleto}, vi tu interés en mis servicios. ¿Cómo puedo ayudarte?";

    final url = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(baseMessage)}");
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      _updateStatus(CrmEstado.contactado);
    } else {
      _showSnack('No se pudo abrir WhatsApp', isError: true);
    }
  }

  Future<void> _launchCall() async {
    final phone = widget.lead.telefono;
    if (phone.isEmpty) {
      _showSnack('Este contacto no tiene teléfono.', isError: true);
      return;
    }
    final url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  // --- Acción: Crear Cotización ---
  void _navigateToQuoteEditor() {
    final product = _catalogProduct;
    
    final requestAdapter = QuoteRequestModel(
      id: 'crm_lead_${widget.lead.id}',
      clientId: widget.lead.id,
      providerId: '', 
      clientName: widget.lead.nombreCompleto, // Mapeo correcto
      clientPhone: widget.lead.telefono,
      serviceType: _getFriendlySource(widget.lead.source),
      description: product != null 
          ? "Interés en producto: $product. ${widget.lead.comentario}"
          : (widget.lead.comentario.isNotEmpty ? widget.lead.comentario : "Generado desde CRM"),
      quantity: '1', 
      location: widget.lead.location ?? '',
      preferredDate: DateTime.now(),
      createdAt: DateTime.now(),
      status: 'pending',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuoteEditorScreen(
          isNew: true,
          sourceRequest: requestAdapter,
        ),
      ),
    );
  }

  // --- Gestión CRM ---
  Future<void> _updateStatus(CrmEstado newStatus) async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<CrmRepository>();
      await repo.updateLeadStatus(widget.lead.id, newStatus);
      _showSnack('Estado actualizado a: ${newStatus.name.toUpperCase()}');
    } catch (e) {
      _showSnack('Error al actualizar: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false, bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? Colors.red : (isSuccess ? Colors.green : Colors.blue),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = colorScheme.primary;

    final lead = widget.lead;
    final friendlySource = _getFriendlySource(lead.source);
    final product = _catalogProduct;
    final dateStr = DateFormat('dd/MM/yyyy - HH:mm').format(lead.fechaAlta);
    final isQuoteRelevant = product != null;

    // Lógica visual de estado
    Color statusColor = Colors.blueGrey;
    if (lead.estadoCRM == CrmEstado.leadNuevo) statusColor = Colors.blueAccent;
    if (lead.estadoCRM == CrmEstado.contactado) statusColor = Colors.orange;
    if (lead.estadoCRM == CrmEstado.clienteActivo) statusColor = Colors.green;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Detalle de Oportunidad'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 1. CONTENIDO DEL LEAD (Scrollable)
          _isLoading 
            ? Center(child: CircularProgressIndicator(color: accentColor))
            : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Padding extra abajo para el coach
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- TARJETA DE CABECERA ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor.withValues(alpha: 0.2)), 
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      children: [
                        SafeAvatar(
                          name: lead.nombreCompleto,
                          imageUrl: lead.logoUrl,
                          size: 70,
                          accentColor: accentColor,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lead.nombreCompleto,
                                style: TextStyle(color: colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              if (lead.location != null) ...[
                                const SizedBox(height: 4),
                                Row(children: [
                                  Icon(Icons.location_on, size: 14, color: accentColor),
                                  const SizedBox(width: 4),
                                  Text(lead.location!, style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)))
                                ])
                              ],
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _StatusBadge(text: friendlySource, color: Colors.blueAccent),
                                  _StatusBadge(text: lead.estadoCRM.name.toUpperCase(), color: statusColor, isOutline: true),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- SECCIÓN DE INTELIGENCIA DE CATÁLOGO ---
                  if (product != null) ...[
                    Text('Interés en Producto', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                            child: const Icon(Icons.shopping_bag, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product, style: TextStyle(color: colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
                                const Text('Visto en tu catálogo online', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  Text('Contactar Ahora', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      if (lead.telefono.isNotEmpty) ...[
                        Expanded(child: _ActionButton(icon: Icons.chat, label: 'WhatsApp', color: Colors.green, onTap: _launchWhatsApp, theme: theme)),
                        const SizedBox(width: 12),
                        Expanded(child: _ActionButton(icon: Icons.phone, label: 'Llamar', color: Colors.blue, onTap: _launchCall, theme: theme)),
                      ],
                    ],
                  ),

                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _navigateToQuoteEditor, 
                      icon: const Icon(Icons.request_quote),
                      label: Text(isQuoteRelevant ? "ENVIAR COTIZACIÓN DE PRODUCTO" : "CREAR COTIZACIÓN FORMAL"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isQuoteRelevant ? Colors.purple : accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: isQuoteRelevant ? 6 : 0,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  Text('Resumen y Notas', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detectado el día $dateStr.',
                          style: TextStyle(color: colorScheme.onSurface, fontSize: 15),
                        ),
                        if (lead.comentario.isNotEmpty || lead.notasInternas.isNotEmpty) ...[
                           const SizedBox(height: 12),
                           Divider(color: theme.dividerColor),
                           const SizedBox(height: 8),
                           Text(
                            lead.comentario.isNotEmpty ? lead.comentario : lead.notasInternas,
                            style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.8), fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // 2. SERVI COACH FLOTANTE (Capa superior)
          Positioned(
            bottom: 20,
            right: 20,
            child: ServiCoachWidget(
              title: "COACH DE VENTAS",
              message: _salesStrategy,
              autoPlay: true, // Habla apenas entras para dar el consejo
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGETS AUXILIARES ---

class SafeAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final Color accentColor;

  const SafeAvatar({
    super.key, 
    this.imageUrl, 
    required this.name, 
    this.size = 60, 
    this.accentColor = Colors.blue
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: accentColor.withValues(alpha: 0.1)),
      child: ClipOval(
        child: (imageUrl != null && imageUrl!.isNotEmpty)
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(child: Text(initial, style: TextStyle(fontSize: size * 0.4, color: accentColor, fontWeight: FontWeight.bold))),
              )
            : Center(child: Text(initial, style: TextStyle(fontSize: size * 0.4, color: accentColor, fontWeight: FontWeight.bold))),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final bool isOutline;
  const _StatusBadge({required this.text, required this.color, this.isOutline = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOutline ? Colors.transparent : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: isOutline ? Border.all(color: color.withValues(alpha: 0.4)) : null,
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final ThemeData theme;
  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap, required this.theme});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1), 
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(border: Border.all(color: color.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}