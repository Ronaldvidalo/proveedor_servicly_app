import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import './module_config.dart'; // Importación local
import '../../../providers/catalog_editor_provider.dart'; 

class ContactModuleWidget extends StatelessWidget {
  final ContactModuleConfig config;

  const ContactModuleWidget({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final cfg = config;

    if (cfg is ContactModuleViewConfig) {
      return _buildView(context, cfg, isEditable: false); // Modo solo vista
    }
    if (cfg is ContactModuleEditConfig) {
      return _buildEdit(context, cfg);
    }
    debugPrint("Error: Tipo de ContactModuleConfig desconocido: ${cfg.runtimeType}");
    return const SizedBox.shrink();
  }

  // --- MODO VISTA (Público) ---
  // Ahora se parece a la Imagen 2 y acepta un flag 'isEditable'
  Widget _buildView(BuildContext context, ContactModuleViewConfig viewConfig, {bool isEditable = false}) {
    final theme = Theme.of(context);
    final List<Widget> contactItems = [];

    // Horario (si existe)
    if (viewConfig.openingHours != null && viewConfig.openingHours!.isNotEmpty) {
      contactItems.add(_buildContactRow(context, Icons.access_time_rounded, viewConfig.openingHours!));
    }

    // Teléfono (si existe)
    if (viewConfig.phone != null && viewConfig.phone!.isNotEmpty) {
      contactItems.add(_buildContactRow(context, Icons.phone_outlined, viewConfig.phone!, 
        onTap: isEditable ? null : () => _launchURL('tel:${viewConfig.phone!}') // Deshabilita link en modo edición
      ));
    }

    // Email
    contactItems.add(_buildContactRow(context, Icons.email_outlined, viewConfig.contactEmail, 
      onTap: isEditable ? null : () => _launchURL('mailto:${viewConfig.contactEmail}') // Deshabilita link en modo edición
    ));
    
    // WhatsApp (si existe)
    if (viewConfig.whatsapp != null && viewConfig.whatsapp!.isNotEmpty) {
      final whatsappNumber = viewConfig.whatsapp!.replaceAll(RegExp(r'[^0-9]'), ''); 
      contactItems.add(_buildContactRow(context, Icons.message_outlined, viewConfig.whatsapp!, 
        onTap: isEditable ? null : () => _launchURL('https://wa.me/$whatsappNumber}') // Deshabilita link en modo edición
      ));
    }
    
    // Slogan (si existe)
    if (viewConfig.slogan != null && viewConfig.slogan!.isNotEmpty) {
       contactItems.add(const Divider(height: 32, thickness: 0.5)); // Separador
       contactItems.add(
         Text(
            viewConfig.slogan!,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic, 
              color: Colors.grey[400] // Color más claro
            ),
            textAlign: TextAlign.center,
          ),
       );
    }

    return Padding(
      // Padding para alinear con "Información"
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, 
        children: contactItems,
      ),
    );
  }

  // Helper para construir una fila de contacto en modo vista
  Widget _buildContactRow(BuildContext context, IconData icon, String text, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final bool isLink = onTap != null;
    
    if (text.isEmpty) {
       return const SizedBox.shrink(); 
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0), // Más espacio
      child: InkWell( 
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[500], size: 22), // Color de icono
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isLink ? Colors.blue.shade400 : Colors.grey[300], // Colores claros
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
         debugPrint('Could not launch $urlString (launchUrl failed)');
      }
    } else {
       debugPrint('Could not launch $urlString (canLaunchUrl failed)');
    }
  }

  // --- MODO EDICIÓN (Proveedor) ---
  Widget _buildEdit(BuildContext context, ContactModuleEditConfig editConfig) {
    final provider = context.watch<CatalogEditorProvider>();
    final tempViewConfig = ContactModuleViewConfig.fromProfile(provider.profile);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 1. Dibujamos el widget de "vista"
          // Le pasamos isEditable: true para que no se activen los links
          _buildView(context, tempViewConfig, isEditable: true), 

          // 2. Superponemos el botón de edición
          Positioned(
            top: 0, 
            right: 12,
            child: IconButton(
              icon: Icon(Icons.edit, color: Colors.blue.shade400, size: 24),
              tooltip: "Editar información de contacto",
              onPressed: () => _showEditDialog(context, provider),
            ),
          ),
        ],
      ),
    );
  }

  // Diálogo genérico para editar TODOS los campos de contacto
  void _showEditDialog(BuildContext context, CatalogEditorProvider provider) {
    final sloganController = TextEditingController(text: provider.profile.slogan);
    final hoursController = TextEditingController(text: provider.profile.openingHours);
    final emailController = TextEditingController(text: provider.profile.contactEmail);
    final phoneController = TextEditingController(text: provider.profile.phone);
    final whatsappController = TextEditingController(text: provider.profile.whatsapp);
    // (Añadir 'address' si también quieres editar "prueba" de la Imagen 2)

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Editar Información de Contacto"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: sloganController, decoration: const InputDecoration(labelText: "Slogan", border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextFormField(controller: hoursController, decoration: const InputDecoration(labelText: "Horario", border: OutlineInputBorder()), maxLines: 2),
              const SizedBox(height: 12),
              TextFormField(controller: emailController, decoration: const InputDecoration(labelText: "Email de Contacto", border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              TextFormField(controller: phoneController, decoration: const InputDecoration(labelText: "Teléfono", border: OutlineInputBorder()), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TextFormField(controller: whatsappController, decoration: const InputDecoration(labelText: "WhatsApp", hintText: "Ej: 54911...", border: OutlineInputBorder()), keyboardType: TextInputType.phone),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text("Aplicar Cambios"),
            onPressed: () {
              provider.updateSlogan(sloganController.text.trim().isEmpty ? null : sloganController.text.trim());
              provider.updateOpeningHours(hoursController.text.trim().isEmpty ? null : hoursController.text.trim());
              provider.updateContactEmail(emailController.text.trim());
              provider.updatePhone(phoneController.text.trim().isEmpty ? null : phoneController.text.trim());
              provider.updateWhatsapp(whatsappController.text.trim().isEmpty ? null : whatsappController.text.trim());
              
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }
}