import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

// --- CORRECCIÓN DE RUTA --- (Importación local)
import './module_config.dart'; // Importa desde la misma carpeta

// Asegúrate que la ruta al provider sea correcta (sube 3 niveles)
import '../../../providers/catalog_editor_provider.dart';

class ContactModuleWidget extends StatelessWidget {
  // Ahora debería encontrar ContactModuleConfig correctamente
  final ContactModuleConfig config;

  const ContactModuleWidget({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final cfg = config;

    // Ahora los 'is' deberían funcionar
    if (cfg is ContactModuleViewConfig) {
      return _buildView(context, cfg);
    }

    if (cfg is ContactModuleEditConfig) {
      return _buildEdit(context, cfg);
    }

    debugPrint("Error: Tipo de ContactModuleConfig desconocido o importación fallida: ${cfg.runtimeType}");
    return const SizedBox.shrink();
  }

  // --- MODO VISTA (Público) ---
  Widget _buildView(BuildContext context, ContactModuleViewConfig viewConfig) {
    final theme = Theme.of(context);
    final List<Widget> contactItems = [];

    // Slogan
    if (viewConfig.slogan != null && viewConfig.slogan!.isNotEmpty) {
      contactItems.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            viewConfig.slogan!,
            style: theme.textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Horario
    if (viewConfig.openingHours != null && viewConfig.openingHours!.isNotEmpty) {
      contactItems.add(_buildContactRow(context, Icons.access_time_rounded, viewConfig.openingHours!));
    }

    // Email
    contactItems.add(_buildContactRow(context, Icons.email_outlined, viewConfig.contactEmail, onTap: () => _launchURL('mailto:${viewConfig.contactEmail}')));

    // Teléfono
    if (viewConfig.phone != null && viewConfig.phone!.isNotEmpty) {
      contactItems.add(_buildContactRow(context, Icons.phone_outlined, viewConfig.phone!, onTap: () => _launchURL('tel:${viewConfig.phone!}')));
    }

    // WhatsApp
    if (viewConfig.whatsapp != null && viewConfig.whatsapp!.isNotEmpty) {
      final whatsappNumber = viewConfig.whatsapp!.replaceAll(RegExp(r'[^0-9]'), '');
      contactItems.add(_buildContactRow(context, Icons.message_outlined, viewConfig.whatsapp!, onTap: () => _launchURL('https://wa.me/$whatsappNumber')));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isLink ? Colors.blue.shade700 : null,
                  decoration: isLink ? TextDecoration.underline : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper para lanzar URLs
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
    final draftProfile = provider.profile;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEditableField(
            context: context,
            label: "Slogan",
            value: draftProfile.slogan,
            icon: Icons.lightbulb_outline,
            onEdit: (newValue) => provider.updateSlogan(newValue),
            maxLines: 2,
          ),
          _buildEditableField(
            context: context,
            label: "Horario",
            value: draftProfile.openingHours,
            icon: Icons.access_time_rounded,
            onEdit: (newValue) => provider.updateOpeningHours(newValue),
            maxLines: 3,
          ),
           _buildEditableField(
            context: context,
            label: "Email de Contacto",
            value: draftProfile.contactEmail,
            icon: Icons.email_outlined,
            onEdit: (newValue) => provider.updateContactEmail(newValue ?? draftProfile.contactEmail),
            keyboardType: TextInputType.emailAddress,
          ),
          _buildEditableField(
            context: context,
            label: "Teléfono",
            value: draftProfile.phone,
            icon: Icons.phone_outlined,
            onEdit: (newValue) => provider.updatePhone(newValue),
            keyboardType: TextInputType.phone,
          ),
           _buildEditableField(
            context: context,
            label: "WhatsApp",
            value: draftProfile.whatsapp,
            icon: Icons.message_outlined,
            onEdit: (newValue) => provider.updateWhatsapp(newValue),
            keyboardType: TextInputType.phone,
            hintText: 'Ej: 54911xxxxxxxx',
          ),
        ],
      ),
    );
  }

  // Widget helper para construir cada campo editable
  Widget _buildEditableField({
    required BuildContext context,
    required String label,
    required String? value,
    required IconData icon,
    required Function(String?) onEdit,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    final displayValue = (value == null || value.isEmpty) ? 'No establecido' : value;
    final isEmpty = (value == null || value.isEmpty);

    return InkWell(
      onTap: () => _showEditDialog(context, label, value, onEdit, maxLines, keyboardType, hintText),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Icon(icon, color: Colors.grey[600], size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                  const SizedBox(height: 2),
                  Text(
                    displayValue,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                          color: isEmpty ? Colors.grey : null,
                        ),
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.edit_note, color: Colors.blue.shade700, size: 24),
          ],
        ),
      ),
    );
  }

  // Diálogo genérico para editar un campo de texto
  void _showEditDialog(
      BuildContext context,
      String label,
      String? currentValue,
      Function(String?) onSave,
      int maxLines,
      TextInputType keyboardType,
      String? hintText,
     ) {
    final textController = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Editar $label"),
        content: TextFormField(
          controller: textController,
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            border: OutlineInputBorder(),
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
          autofocus: true,
        ),
        actions: [
          TextButton(
            child: Text("Cancelar"),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: Text("Aplicar"),
            onPressed: () {
              final newValue = textController.text.trim();
              onSave(newValue.isEmpty ? null : newValue);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }
}