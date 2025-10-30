import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/providers/catalog_editor_provider.dart';
import './module_config.dart'; // Importación local

class WelcomeModuleWidget extends StatelessWidget {
  final WelcomeModuleConfig config;

  const WelcomeModuleWidget({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final cfg = config;

    if (cfg is WelcomeModuleViewConfig) {
      return _buildView(context, cfg);
    }
    if (cfg is WelcomeModuleEditConfig) {
      return _buildEdit(context, cfg);
    }
    return const SizedBox.shrink();
  }

  // --- MODO VISTA (Público) ---
  // Esto ahora coincide con la sección "Información" de la Imagen 2
  Widget _buildView(BuildContext context, WelcomeModuleViewConfig viewConfig) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0), // Padding ajustado
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Información", 
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              // Asumiendo un color oscuro para el fondo del editor
              color: Colors.white 
            )
          ),
          const SizedBox(height: 16),
          // El mensaje de bienvenida
          Text(
            viewConfig.welcomeText.isEmpty 
                ? "Aún no has escrito tu bienvenida." // Placeholder
                : viewConfig.welcomeText,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontStyle: viewConfig.welcomeText.isEmpty ? FontStyle.italic : FontStyle.normal,
              color: viewConfig.welcomeText.isEmpty ? Colors.grey[500] : Colors.grey[300], // Colores más claros
              height: 1.5 // Interlineado
            ),
          ),
        ],
      ),
    );
  }

  // --- MODO EDICIÓN (Proveedor) ---
  // Ahora es un STACK sobre el _buildView
  Widget _buildEdit(BuildContext context, WelcomeModuleEditConfig editConfig) {
    final draftText = context.watch<CatalogEditorProvider>().profile.welcomeMessage;
    
    final tempViewConfig = WelcomeModuleViewConfig(
      welcomeText: draftText, 
      videoUrl: context.watch<CatalogEditorProvider>().profile.welcomeVideoUrl,
    );

    return Material(
      color: Colors.transparent, // El fondo lo da el CustomScrollView
      child: Stack(
        children: [
          // 1. Dibujamos el widget de "vista" idéntico al público
          _buildView(context, tempViewConfig),
          
          // 2. Superponemos el botón de edición
          Positioned(
            top: 20, 
            right: 12, 
            child: IconButton(
              icon: Icon(Icons.edit, color: Colors.blue.shade400, size: 24), // Icono más sutil
              tooltip: "Editar mensaje de bienvenida",
              onPressed: () => _showEditDialog(context, editConfig.editorProvider),
            ),
          ),
        ],
      ),
    );
  }
  
  // Diálogo para editar (Sin cambios)
  void _showEditDialog(BuildContext context, CatalogEditorProvider provider) {
    final textController = TextEditingController(text: provider.profile.welcomeMessage);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Editar mensaje de bienvenida"),
        content: TextFormField(
          controller: textController,
          decoration: const InputDecoration(labelText: "Mensaje"),
          maxLines: 7,
          minLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text("Aplicar"),
            onPressed: () {
              provider.updateWelcomeText(textController.text);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }
}