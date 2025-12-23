// --- UX/UI Enhancement Comment ---
// Pantalla: LeadDetailScreen
// Actualización: Integración con el Módulo de Cotizaciones.
// Corrección: Errores de tipado, null safety y mapeo de modelos solucionados.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:ui'; // Necesario para ImageFilter

// Modelos y Servicios CRM
import 'package:proveedor_servicly_app/features/crm/data/models/cliente_model.dart';
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart';
import 'package:proveedor_servicly_app/features/crm/core/crm_enums.dart';
import 'package:proveedor_servicly_app/features/crm/core/lead_access_helper.dart';

// --- NUEVOS IMPORTS: MÓDULO DE PRESUPUESTOS ---
import 'package:proveedor_servicly_app/features/budget/screens/quote_editor_screen.dart';
import 'package:proveedor_servicly_app/features/budget/models/quote_request_model.dart'; 

class LeadDetailScreen extends StatefulWidget {
  final Cliente lead;

  const LeadDetailScreen({super.key, required this.lead});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> {
  bool _isLoading = false;

  // --- Helpers de Traducción (UI Amigable) ---
  String _getFriendlySource(String? source) {
    if (source == null) return 'Consulta general';
    final s = source.toLowerCase();
    
    if (s.contains('whatsapp')) return 'WhatsApp';
    if (s.contains('view_product')) return 'Vio un Producto';
    if (s.contains('cart')) return 'Carrito Abandonado';
    if (s.contains('like')) return 'Le gustó un Producto'; 
    if (s.contains('telefono') || s.contains('phone')) return 'Llamada';
    if (s.contains('email') || s.contains('mail')) return 'Email';
    // Unificación de términos
    if (s.contains('presupuesto') || s.contains('quote') || s.contains('cotiz')) return 'Solicitó Cotización';
    
    return 'Consulta';
  }

  String _getFriendlyName(String originalName) {
    if (originalName.startsWith('Visitante') || originalName == 'Usuario Registrado') {
      return 'Nuevo Interesado';
    }
    return originalName;
  }

  // --- Acciones de Contacto ---
  Future<void> _launchWhatsApp() async {
    final phone = widget.lead.telefono.replaceAll(RegExp(r'[^\d+]'), '');
    if (phone.isEmpty) {
      _showSnack('Este contacto no dejó un teléfono registrado.', isError: true);
      return;
    }
    
    final message = Uri.encodeComponent("Hola, vi tu interés en mis servicios. ¿Cómo puedo ayudarte?");
    final url = Uri.parse("https://wa.me/$phone?text=$message");
    
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
      _updateStatus(CrmEstado.contactado);
    }
  }

  Future<void> _launchEmail() async {
    if (widget.lead.email.isEmpty) {
      _showSnack('Este contacto no tiene email.', isError: true);
      return;
    }
    final url = Uri.parse("mailto:${widget.lead.email}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  // --- NUEVA ACCIÓN: CREAR COTIZACIÓN ---
  void _navigateToQuoteEditor() {
    // CORRECCIÓN: Adaptador de datos.
    // Convertimos el modelo 'Cliente' (CRM) en un 'QuoteRequestModel' temporal 
    // para que el editor de cotizaciones pueda pre-llenar los campos.
    
    final requestAdapter = QuoteRequestModel(
      id: 'crm_lead_${widget.lead.id}', // ID temporal para referencia
      clientId: widget.lead.id, // CORRECCIÓN: Usamos .id en lugar de .userId que no existía
      providerId: '', // Se llenará automáticamente en el provider
      clientName: widget.lead.nombreCompleto,
      clientPhone: widget.lead.telefono,
      
      // Inferimos el servicio según la fuente o notas
      serviceType: _getFriendlySource(widget.lead.source),
      description: widget.lead.notasInternas.isNotEmpty 
          ? widget.lead.notasInternas 
          : "Generado desde CRM (Cliente existente)",
      quantity: '1', 
      location: widget.lead.location ?? '', // CORRECCIÓN: Verificamos nulo explícitamente solo si location es nullable
      preferredDate: DateTime.now(),
      createdAt: DateTime.now(),
      status: 'pending',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuoteEditorScreen(
          isNew: true,
          sourceRequest: requestAdapter, // Pasamos el adaptador
        ),
      ),
    ).then((_) {
      // Opcional: Podríamos actualizar el estado del lead a 'cotizado' al volver
    });
  }

  // --- Gestión CRM ---
  Future<void> _updateStatus(CrmEstado newStatus) async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<CrmRepository>();
      
      if (newStatus == CrmEstado.clienteActivo) {
        await repo.convertLeadToClient(widget.lead.id);
        _showSnack('¡Excelente! Has ganado un nuevo Cliente.', isSuccess: true);
        if (mounted) Navigator.pop(context);
      } else {
        await repo.updateLeadStatus(widget.lead.id, newStatus);
        _showSnack('Estado actualizado a: ${newStatus.name}');
      }
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
      backgroundColor: isError ? Colors.red : (isSuccess ? Colors.green : Colors.blue),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = colorScheme.primary;

    // 1. VERIFICACIÓN DE SEGURIDAD
    const String userPlan = 'free'; 
    
    // ✅ CORRECCIÓN: Se eliminó el operador ?? '' ya que widget.lead.source no es nullable
    if (!LeadAccessHelper.canAccessLead(userPlan, widget.lead.source)) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Acceso Restringido'), backgroundColor: theme.scaffoldBackgroundColor, foregroundColor: colorScheme.onSurface),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.amber),
              const SizedBox(height: 20),
              Text('Contenido Exclusivo PRO', style: TextStyle(color: colorScheme.onSurface, fontSize: 20)),
              const SizedBox(height: 20),
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Volver'))
            ],
          ),
        ),
      );
    }

    final lead = widget.lead;
    final friendlySource = _getFriendlySource(lead.source);
    final friendlyName = _getFriendlyName(lead.nombreCompleto);
    
    // ✅ CORRECCIÓN: Se eliminó el operador ! ya que lead.fechaAlta no es nullable
    final dateStr = DateFormat('dd/MM/yyyy - HH:mm').format(lead.fechaAlta);

    // CORRECCIÓN: Variable 'isQuoteRelevant' eliminada si no se usa, o usada para lógica visual.
    // Aquí la usamos para darle prioridad visual al botón.
    final isQuoteRelevant = friendlySource.contains('Cotización') || friendlySource.contains('Presupuesto');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Detalle del Interesado'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: accentColor))
        : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- TARJETA DE CABECERA ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)), 
                ),
                child: Row(
                  children: [
                    SafeAvatar(
                      imageUrl: lead.logoUrl, 
                      name: friendlyName,
                      size: 70,
                      accentColor: accentColor,
                    ),
                    const SizedBox(width: 16),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friendlyName,
                            style: TextStyle(color: colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          
                          // CORRECCIÓN: Validamos si location existe y no está vacía de forma segura
                          if (lead.location != null && lead.location!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                                const SizedBox(width: 4),
                                Text(
                                  lead.location!, 
                                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 8),
                          
                          Wrap(
                            spacing: 8,
                            children: [
                              _StatusBadge(text: friendlySource, color: Colors.blueAccent),
                              _StatusBadge(text: lead.estadoCRM.name.toUpperCase(), color: Colors.orangeAccent, isOutline: true),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              
              // --- ACCIONES DE CONTACTO ---
              Text('Responder Ahora', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              // Fila Principal de Botones
              Row(
                children: [
                  if (lead.telefono.isNotEmpty) ...[
                    Expanded(child: _ActionButton(icon: Icons.chat, label: 'WhatsApp', color: Colors.green, onTap: _launchWhatsApp, theme: theme)),
                    const SizedBox(width: 12),
                    Expanded(child: _ActionButton(icon: Icons.phone, label: 'Llamar', color: Colors.blue, onTap: _launchCall, theme: theme)),
                  ],
                  if (lead.email.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(child: _ActionButton(icon: Icons.email, label: 'Email', color: Colors.orange, onTap: _launchEmail, theme: theme)),
                  ]
                ],
              ),

              // --- BOTÓN GRANDE: CREAR COTIZACIÓN (INTEGRACIÓN) ---
              // Usamos isQuoteRelevant para cambiar el estilo del botón (Visual Cue)
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _navigateToQuoteEditor, 
                  icon: const Icon(Icons.request_quote),
                  label: Text(isQuoteRelevant ? "CREAR COTIZACIÓN (PRIORIDAD)" : "CREAR COTIZACIÓN FORMAL"),
                  style: ElevatedButton.styleFrom(
                    // Si es relevante, lo hacemos más llamativo
                    backgroundColor: isQuoteRelevant ? Colors.purple : theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: isQuoteRelevant ? 6 : 2,
                  ),
                ),
              ),
              
              if (lead.telefono.isEmpty && lead.email.isEmpty)
                 const Padding(
                   padding: EdgeInsets.symmetric(vertical: 8.0),
                   child: Text('⚠️ El usuario no compartió datos de contacto directo.', style: TextStyle(color: Colors.orangeAccent)),
                 ),

              const SizedBox(height: 32),

              // --- HISTORIAL / CONTEXTO ---
              Text('Resumen de Actividad', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Un contacto ${friendlySource.toLowerCase()} el día $dateStr.',
                      style: TextStyle(color: colorScheme.onSurface, fontSize: 15, height: 1.4),
                    ),
                    
                    if (lead.notasInternas.isNotEmpty && !lead.notasInternas.startsWith('Capturado auto')) ...[
                       const SizedBox(height: 12),
                       Divider(color: theme.dividerColor),
                       const SizedBox(height: 8),
                       Text('Mensaje/Nota:', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
                       const SizedBox(height: 4),
                       Text(
                        lead.notasInternas,
                        style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.8), fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // --- GESTIÓN DE EMBUDO ---
              Text('Siguientes Pasos', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              if (lead.estadoCRM == CrmEstado.leadNuevo || lead.estadoCRM == CrmEstado.lead) 
                _PipelineButton(
                  label: 'Ya le respondí (Marcar Contactado)',
                  icon: Icons.check_circle_outline,
                  color: Colors.blue,
                  onTap: () => _updateStatus(CrmEstado.contactado),
                  theme: theme,
                ),
              
              if (lead.estadoCRM == CrmEstado.contactado)
                 _PipelineButton(
                  label: 'Ya le envié precio (Marcar Cotizado)',
                  icon: Icons.attach_money,
                  color: Colors.purple,
                  onTap: () => _updateStatus(CrmEstado.cotizado),
                  theme: theme,
                ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _updateStatus(CrmEstado.clienteActivo),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('CONVERTIR A CLIENTE'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white, 
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
    );
  }
}

// =====================================================
// WIDGETS AUXILIARES
// =====================================================

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
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accentColor.withValues(alpha: 0.2),
      ),
      child: ClipOval(
        child: (imageUrl != null && imageUrl!.isNotEmpty)
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(initial, style: TextStyle(fontSize: size * 0.4, color: accentColor, fontWeight: FontWeight.bold)),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(child: CircularProgressIndicator(strokeWidth: 2, color: accentColor));
                },
              )
            : Center(
                child: Text(initial, style: TextStyle(fontSize: size * 0.4, color: accentColor, fontWeight: FontWeight.bold)),
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isOutline ? Colors.transparent : color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: isOutline ? Border.all(color: color.withValues(alpha: 0.5)) : null,
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
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
      color: color.withValues(alpha: 0.15), 
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: color.withValues(alpha: 0.4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.4)), 
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PipelineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final ThemeData theme;
  
  const _PipelineButton({required this.label, required this.icon, required this.color, required this.onTap, required this.theme});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        tileColor: theme.cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.2))
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle
          ),
          child: Icon(icon, color: color, size: 20)
        ),
        title: Text(label, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.arrow_forward_ios, color: theme.colorScheme.onSurface.withValues(alpha: 0.3), size: 14),
      ),
    );
  }
}