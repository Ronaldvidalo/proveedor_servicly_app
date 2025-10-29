import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/providers/catalog_editor_provider.dart';
import 'package:proveedor_servicly_app/widgets/modules/module_config.dart'; // Asumo esta ruta

class WelcomeModuleWidget extends StatelessWidget {
  final WelcomeModuleConfig config;
  
  const WelcomeModuleWidget({Key? key, required this.config}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Usamos el tipo de 'config' para decidir qué construir
    final cfg = config; // Para promoción de tipo
    
    if (cfg is WelcomeModuleViewConfig) {
      return _buildView(context, cfg);
    }
    
    if (cfg is WelcomeModuleEditConfig) {
      return _buildEdit(context, cfg);
    }
    
    return const SizedBox.shrink();
  }

  // --- MODO VISTA (Público) ---
  Widget _buildView(BuildContext context, WelcomeModuleViewConfig viewConfig) {
    // (Aquí puedes añadir tu lógica de VideoPlayer si viewConfig.videoUrl no es null)
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Text(
        viewConfig.welcomeText.isEmpty 
            ? "Aún no has escrito tu bienvenida." // Placeholder
            : viewConfig.welcomeText,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontStyle: viewConfig.welcomeText.isEmpty ? FontStyle.italic : FontStyle.normal,
          color: viewConfig.welcomeText.isEmpty ? Colors.grey : null,
        ),
      ),
    );
  }

  // --- MODO EDICIÓN (Proveedor) ---
  Widget _buildEdit(BuildContext context, WelcomeModuleEditConfig editConfig) {
    
    // ¡CORREGIDO! Leemos 'welcomeMessage' del borrador del provider
    final draftText = context.watch<CatalogEditorProvider>().profile.welcomeMessage;
    
    // Creamos un ViewConfig temporal usando los datos del BORRADOR
    final tempViewConfig = WelcomeModuleViewConfig(
      welcomeText: draftText, 
      videoUrl: context.watch<CatalogEditorProvider>().profile.welcomeVideoUrl,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showEditDialog(context, editConfig.editorProvider),
        splashColor: Colors.blue.withOpacity(0.1),
        highlightColor: Colors.blue.withOpacity(0.05),
        child: Stack(
          children: [
            // 1. Dibujamos el widget de "vista" para que se vea idéntico
            _buildView(context, tempViewConfig),
            
            // 2. Superponemos el ícono de edición
            Positioned(
              top: 8,
              right: 8,
              child: IgnorePointer( // Para que el InkWell principal capture el tap
                child: Icon(Icons.edit_note, color: Colors.blue.shade700, size: 28),
              ),
            ),
            
            // (Opcional) Un borde sutil para indicar que es editable
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1.5, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
  
  // Diálogo para editar
  void _showEditDialog(BuildContext context, CatalogEditorProvider provider) {
    // ¡CORREGIDO! Leemos 'welcomeMessage' del provider para el valor inicial
    final textController = TextEditingController(text: provider.profile.welcomeMessage);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Editar mensaje de bienvenida"),
        content: TextFormField(
          controller: textController,
          decoration: InputDecoration(labelText: "Mensaje"),
          maxLines: 7,
          minLines: 3,
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
              // 1. ¡CORREGIDO! Llamamos a 'updateWelcomeText'
              provider.updateWelcomeText(textController.text);
              
              // 2. Cierra el diálogo
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }
}