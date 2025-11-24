import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

// Modelos y Servicios
import 'package:proveedor_servicly_app/features/crm/data/models/cliente_model.dart';
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart';
import 'package:proveedor_servicly_app/features/crm/core/crm_enums.dart';
import 'package:proveedor_servicly_app/features/crm/core/lead_access_helper.dart';

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
    if (s.contains('like')) return 'Le gustó un Producto'; // ❤️
    if (s.contains('telefono') || s.contains('phone')) return 'Llamada';
    if (s.contains('email') || s.contains('mail')) return 'Email';
    if (s.contains('presupuesto')) return 'Solicitó Presupuesto';
    
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
    const backgroundColor = Color(0xFF1A1A2E);
    const surfaceColor = Color(0xFF2D2D5A);
    const accentColor = Color(0xFF00BFFF);

    // 1. VERIFICACIÓN DE SEGURIDAD
    // TODO: Usar plan real del usuario (Provider)
    const String userPlan = 'free'; 
    
    if (!LeadAccessHelper.canAccessLead(userPlan, widget.lead.source ?? '')) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(title: const Text('Acceso Restringido'), backgroundColor: backgroundColor),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.amber),
              const SizedBox(height: 20),
              const Text('Contenido Exclusivo PRO', style: TextStyle(color: Colors.white, fontSize: 20)),
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
    
    final dateStr = lead.fechaAlta != null 
        ? DateFormat('dd/MM/yyyy - HH:mm').format(lead.fechaAlta!) 
        : '--/--';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Detalle del Interesado'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: accentColor))
        : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- TARJETA DE CABECERA ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accentColor.withAlpha(77)), 
                ),
                child: Row(
                  children: [
                    // FOTO DE PERFIL (USANDO SAFE AVATAR)
                    SafeAvatar(
                      imageUrl: lead.logoUrl, // Usamos el campo correcto
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
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          
                          // UBICACIÓN
                          if (lead.location != null && lead.location!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.white54),
                                const SizedBox(width: 4),
                                Text(
                                  lead.location!,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 8),
                          
                          // BADGES
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
              const Text('Responder Ahora', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (lead.telefono.isNotEmpty) ...[
                    Expanded(child: _ActionButton(icon: Icons.chat, label: 'WhatsApp', color: Colors.green, onTap: _launchWhatsApp)),
                    const SizedBox(width: 12),
                    Expanded(child: _ActionButton(icon: Icons.phone, label: 'Llamar', color: Colors.blue, onTap: _launchCall)),
                  ],
                  if (lead.email.isNotEmpty) ...[
                     const SizedBox(width: 12),
                     Expanded(child: _ActionButton(icon: Icons.email, label: 'Email', color: Colors.orange, onTap: _launchEmail)),
                  ]
                ],
              ),
              
              if (lead.telefono.isEmpty && lead.email.isEmpty)
                 const Padding(
                   padding: EdgeInsets.symmetric(vertical: 8.0),
                   child: Text('⚠️ El usuario no compartió datos de contacto directo.', style: TextStyle(color: Colors.orangeAccent)),
                 ),

              const SizedBox(height: 32),

              // --- HISTORIAL / CONTEXTO ---
              const Text('Resumen de Actividad', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Un contacto ${friendlySource.toLowerCase()} el día $dateStr.',
                      style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                    ),
                    
                    if (lead.notasInternas.isNotEmpty && !lead.notasInternas.startsWith('Capturado auto')) ...[
                       const SizedBox(height: 12),
                       const Divider(color: Colors.white12),
                       const SizedBox(height: 8),
                       const Text('Mensaje/Nota:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                       const SizedBox(height: 4),
                       Text(
                        lead.notasInternas,
                        style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // --- GESTIÓN DE EMBUDO ---
              const Text('Siguientes Pasos', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              if (lead.estadoCRM == CrmEstado.leadNuevo || lead.estadoCRM == CrmEstado.lead) 
                _PipelineButton(
                  label: 'Ya le respondí (Marcar Contactado)',
                  icon: Icons.check_circle_outline,
                  color: Colors.blue,
                  onTap: () => _updateStatus(CrmEstado.contactado),
                ),
              
              if (lead.estadoCRM == CrmEstado.contactado)
                 _PipelineButton(
                  label: 'Ya le envié precio (Marcar Cotizado)',
                  icon: Icons.attach_money,
                  color: Colors.purple,
                  onTap: () => _updateStatus(CrmEstado.cotizado),
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

/// WIDGET A PRUEBA DE FALLOS PARA EL AVATAR
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
        color: accentColor.withAlpha(51),
      ),
      child: ClipOval(
        child: (imageUrl != null && imageUrl!.isNotEmpty)
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                // Si la imagen falla, mostramos la inicial (evita pantalla roja)
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
        color: isOutline ? Colors.transparent : color.withAlpha(51),
        borderRadius: BorderRadius.circular(4),
        border: isOutline ? Border.all(color: color.withAlpha(128)) : null,
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

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(40), 
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: color.withAlpha(100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: color.withAlpha(100)), 
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
  
  const _PipelineButton({required this.label, required this.icon, required this.color, required this.onTap});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        tileColor: const Color(0xFF2D2D5A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withAlpha(50))
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            shape: BoxShape.circle
          ),
          child: Icon(icon, color: color, size: 20)
        ),
        title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
      ),
    );
  }
}