// import 'dart:async'; // ¡Error 4! Eliminado (no se usa StreamBuilder directamente aquí)
import 'dart:io'; // Para File
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; // Para XFile y PortfolioItemType
// import 'package:flutter/foundation.dart'; // ¡Error 5! Eliminado (debugPrint está en material.dart)

// Modelos y Servicios
import 'package:proveedor_servicly_app/core/models/portfolio_category_model.dart';
import 'package:proveedor_servicly_app/core/models/portfolio_item_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/core/services/permissions_service.dart'; 

// Provider y Configuración
// ¡Rutas verificadas! (Asumiendo que están en carpetas paralelas)
import '../../../providers/catalog_editor_provider.dart'; 
import './module_config.dart'; // Importación local (misma carpeta)

// Widgets Auxiliares
import './_portfolio_item_card.dart'; 
import './_category_chip.dart';      

class PortfolioModuleWidget extends StatelessWidget {
  final PortfolioModuleConfig config;

  const PortfolioModuleWidget({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final cfg = config; 

    if (cfg is PortfolioModuleViewConfig) {
      return _PortfolioView(providerId: cfg.providerId); 
    }

    if (cfg is PortfolioModuleEditConfig) {
      return _PortfolioEdit(
        userId: cfg.userId,
        editorProvider: cfg.editorProvider,
      );
    }

    debugPrint("Error: Tipo de PortfolioModuleConfig desconocido o importación fallida: ${cfg.runtimeType}");
    return const SizedBox.shrink(); 
  }
}

// ===========================================
// === MODO VISTA (Público - StatefulWidget) ===
// ===========================================
class _PortfolioView extends StatefulWidget {
  final String providerId;

  const _PortfolioView({required this.providerId});

  @override
  State<_PortfolioView> createState() => _PortfolioViewState();
}

class _PortfolioViewState extends State<_PortfolioView> {
  String? _selectedCategoryId; 

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Portafolio",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 16),

          // --- Selector de Categorías (StreamBuilder) ---
          StreamBuilder<List<PortfolioCategoryModel>>(
            stream: firestoreService.getPortfolioCategoriesStream(widget.providerId),
            builder: (context, categorySnapshot) {
              if (categorySnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              }
              if (categorySnapshot.hasError || !categorySnapshot.hasData || categorySnapshot.data!.isEmpty) {
                return const SizedBox(height: 40); 
              }

              final categories = categorySnapshot.data!;

              if (_selectedCategoryId == null || !categories.any((c) => c.id == _selectedCategoryId)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) { 
                           setState(() {
                              _selectedCategoryId = categories.isNotEmpty ? categories.first.id : null; 
                           });
                      }
                  });
                   if (_selectedCategoryId == null && categories.isNotEmpty) {
                     _selectedCategoryId = categories.first.id;
                  }
              }
              
              if (categories.isEmpty) {
                  return const SizedBox(height: 40);
              }
              
              if (_selectedCategoryId == null && categories.isNotEmpty) {
                 _selectedCategoryId = categories.first.id;
              }


              return SizedBox(
                height: 40, 
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = category.id == _selectedCategoryId;
                    return CategoryChip( 
                      label: category.name,
                      isSelected: isSelected,
                      onTap: () {
                         if (!isSelected) { 
                            setState(() {
                               _selectedCategoryId = category.id;
                            });
                         }
                      },
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // --- Grid de Ítems (StreamBuilder anidado) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _selectedCategoryId == null
              ? const Center(child: Text("Cargando ítems...", style: TextStyle(color: Colors.grey))) 
              : StreamBuilder<List<PortfolioItemModel>>(
                  stream: firestoreService.getPortfolioItemsStream(widget.providerId, _selectedCategoryId!),
                  builder: (context, itemSnapshot) {
                    if (itemSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (itemSnapshot.hasError) {
                      return Center(child: Text("Error al cargar ítems: ${itemSnapshot.error}"));
                    }
                    if (!itemSnapshot.hasData || itemSnapshot.data!.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: Text("No hay ítems en esta categoría.", style: TextStyle(color: Colors.grey)),
                        ),
                      );
                    }

                    final items = itemSnapshot.data!;

                    final screenWidth = MediaQuery.of(context).size.width;
                    final crossAxisCount = (screenWidth / 180).floor().clamp(2, 4);

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(), 
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount, 
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.0, 
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return PortfolioItemCard(item: item, isEditable: false); 
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}


// ==========================================
// === MODO EDICIÓN (StatefulWidget) ===
// ==========================================
class _PortfolioEdit extends StatefulWidget {
  final String userId;
  final CatalogEditorProvider editorProvider;

  const _PortfolioEdit({required this.userId, required this.editorProvider});

  @override
  State<_PortfolioEdit> createState() => _PortfolioEditState();
}

class _PortfolioEditState extends State<_PortfolioEdit> {

  @override
  void initState() {
    super.initState();
     WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) { 
           widget.editorProvider.loadInitialCategories(widget.userId);
        }
     });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CatalogEditorProvider>();
    final permissions = context.read<PermissionsService>(); 
    final firestoreService = context.read<FirestoreService>(); 

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Sección de Gestión de Categorías ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Gestionar Categorías",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                  tooltip: "Añadir categoría",
                  onPressed: permissions.canAddPortfolioCategory(provider.localCategories.length)
                    ? () => _showAddCategoryDialog(context, provider, widget.userId)
                    : null, 
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Lista Reordenable de Categorías
          provider.isLoadingCategories
              ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
              : provider.localCategories.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                      child: Center(child: Text("Aún no tienes categorías. ¡Añade una!", style: TextStyle(color: Colors.grey))),
                    )
                  : ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(), 
                      itemCount: provider.localCategories.length,
                      itemBuilder: (context, index) {
                        final category = provider.localCategories[index];
                        final isSelected = category.id == provider.selectedCategoryId;
                        return ListTile(
                          key: ValueKey(category.id), 
                          title: Text(category.name),
                          selected: isSelected,
                          selectedTileColor: Colors.blue.withAlpha((255 * 0.1).round()), 
                          onTap: () => provider.selectCategory(category.id),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey),
                                tooltip: "Editar nombre",
                                onPressed: () => _showEditCategoryDialog(context, provider, widget.userId, category),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                tooltip: "Eliminar categoría",
                                onPressed: () => _showDeleteCategoryDialog(context, provider, widget.userId, category),
                              ),
                               ReorderableDragStartListener( index: index, child: const Icon(Icons.drag_handle)),
                            ],
                          ),
                        );
                      },
                      onReorder: (oldIndex, newIndex) {
                        provider.reorderPortfolioCategories(widget.userId, oldIndex, newIndex);
                      },
                    ),

          const Divider(height: 32, indent: 16, endIndent: 16),

          // --- Sección de Gestión de Ítems ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    provider.selectedCategoryId == null
                      ? "Ítems del Portafolio"
                      : "Ítems en: ${provider.localCategories.firstWhere((c) => c.id == provider.selectedCategoryId, orElse: () => PortfolioCategoryModel(id: '', name: '...', order: -1)).name}",
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (provider.selectedCategoryId != null) ...[
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.blue),
                    tooltip: "Añadir Foto",
                    // TODO: Añadir chequeo de permisos canAddPortfolioItem
                    onPressed: provider.isUploadingItem 
                      ? null 
                      : () async { 
                          // --- CORRECCIÓN use_build_context_synchronously ---
                          // Guardamos el context (para el diálogo) ANTES del await
                          final buildContext = context; 
                          final file = await provider.pickPortfolioItem(PortfolioItemType.image);
                          // Verificamos mounted ANTES de usar el context
                          if (file != null && mounted) { 
                            _showAddCaptionDialog(buildContext, provider, widget.userId, file, PortfolioItemType.image);
                          }
                        },
                  ),
                  IconButton(
                    icon: const Icon(Icons.video_call_outlined, color: Colors.orange),
                    tooltip: "Añadir Video",
                    // TODO: Añadir chequeo de permisos canAddPortfolioItem
                    onPressed: provider.isUploadingItem 
                      ? null 
                      : () async { 
                          // --- CORRECCIÓN use_build_context_synchronously ---
                          final buildContext = context;
                          final file = await provider.pickPortfolioItem(PortfolioItemType.video);
                           if (file != null && mounted) {
                            _showAddCaptionDialog(buildContext, provider, widget.userId, file, PortfolioItemType.video);
                          }
                        },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Grid de Ítems (StreamBuilder)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: provider.selectedCategoryId == null
              ? const Center(child: Text("Selecciona o crea una categoría para añadir ítems.", style: TextStyle(color: Colors.grey)))
              : StreamBuilder<List<PortfolioItemModel>>(
                  stream: firestoreService.getPortfolioItemsStream(widget.userId, provider.selectedCategoryId!),
                  builder: (context, itemSnapshot) {
                    if (itemSnapshot.connectionState == ConnectionState.waiting && !provider.isUploadingItem) {
                      return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
                    }
                    if (itemSnapshot.hasError) {
                      return Center(child: Text("Error al cargar ítems: ${itemSnapshot.error}"));
                    }

                    final items = itemSnapshot.data ?? [];

                    final screenWidth = MediaQuery.of(context).size.width;
                    final crossAxisCount = (screenWidth / 150).floor().clamp(2, 4);

                    return Column(
                      children: [
                        if (provider.isUploadingItem && provider.uploadingItemId != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Column(
                              children: [
                                LinearProgressIndicator(value: provider.uploadProgress, minHeight: 6),
                                const SizedBox(height: 4),
                                Text(
                                  "Subiendo ítem... (${(provider.uploadProgress * 100).toStringAsFixed(0)}%)",
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),

                       (items.isEmpty && !provider.isUploadingItem)
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 40.0),
                                child: Text("Añade fotos o videos a esta categoría.", style: TextStyle(color: Colors.grey)),
                              ),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 1.0,
                              ),
                              itemCount: items.length + (provider.isUploadingItem ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (provider.isUploadingItem && index == items.length) {
                                  return _buildUploadingPlaceholder();
                                }
                                final item = items[index];
                                return PortfolioItemCard( 
                                  item: item,
                                  isEditable: true,
                                  onDelete: () => _showDeleteItemDialog(context, provider, widget.userId, item),
                                );
                              },
                            ),
                      ],
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  // --- Diálogos Helper ---

  /// Muestra un diálogo para añadir un título (caption) antes de subir.
  void _showAddCaptionDialog(
    BuildContext context, 
    CatalogEditorProvider provider, 
    String userId, 
    XFile file, 
    PortfolioItemType type
  ) {
    final captionController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (ctx) {
         // Usamos un StatefulBuilder (o Consumer) para que el diálogo se actualice
         // si el estado de 'isUploading' cambia
         return Consumer<CatalogEditorProvider>(
           builder: (context, provider, child) {
             return AlertDialog(
                title: Text(type == PortfolioItemType.image ? "Añadir Foto" : "Añadir Video"),
                // --- CORRECCIÓN LINT --- (sort_child_properties_last)
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 150,
                      width: 150,
                      child: type == PortfolioItemType.image
                          ? Image.file(File(file.path), fit: BoxFit.cover)
                          : Container(color: Colors.black, child: const Center(child: Icon(Icons.videocam, color: Colors.white, size: 50))),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: captionController,
                      decoration: const InputDecoration(
                        labelText: "Título (Opcional)",
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: provider.isUploadingItem ? null : () => Navigator.of(ctx).pop(), 
                    child: const Text("Cancelar")
                  ),
                  ElevatedButton(
                    onPressed: provider.isUploadingItem 
                      ? null 
                      : () async {
                          final navigator = Navigator.of(ctx); 
                          final caption = captionController.text.trim();
                          
                          await provider.uploadAndSavePortfolioItem(
                            userId, 
                            file, 
                            caption.isEmpty ? null : caption, 
                            type
                          );
                          
                          // Usamos 'mounted' del State, no del context del diálogo
                          if (!mounted) return; 
                          navigator.pop(); 
                        },
                     child: provider.isUploadingItem 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                        : const Text("Guardar y Subir"),
                  ),
                ],
              );
           },
         );
      }
    );
  }


  void _showAddCategoryDialog(BuildContext context, CatalogEditorProvider provider, String userId) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nueva Categoría"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "Nombre de la categoría"),
            autofocus: true,
            validator: (value) => (value == null || value.trim().isEmpty) ? 'El nombre es requerido' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                 final scaffoldMessenger = ScaffoldMessenger.of(ctx); 
                 final navigator = Navigator.of(ctx); 
                final success = await provider.addPortfolioCategory(userId, nameController.text.trim());
                 if (!mounted) return; 
                if (success) { 
                  navigator.pop(); 
                } else {
                    if (!navigator.mounted) return; 
                    scaffoldMessenger.showSnackBar( 
                       const SnackBar(content: Text('Error al añadir categoría o límite alcanzado.'), backgroundColor: Colors.orange)
                    );
                }
              }
            },
            child: const Text("Añadir"),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, CatalogEditorProvider provider, String userId, PortfolioCategoryModel category) {
     final nameController = TextEditingController(text: category.name);
     final formKey = GlobalKey<FormState>();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Editar Categoría"),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nuevo nombre"),
              autofocus: true,
              validator: (value) => (value == null || value.trim().isEmpty) ? 'El nombre es requerido' : null,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () async {
                 if (formKey.currentState?.validate() ?? false) {
                   final navigator = Navigator.of(ctx); 
                   await provider.updatePortfolioCategoryName(userId, category.id, nameController.text.trim());
                    if (!mounted) return; 
                    navigator.pop(); 
                 }
              },
              child: const Text("Guardar"),
            ),
          ],
        ),
      );
  }

   void _showDeleteCategoryDialog(BuildContext context, CatalogEditorProvider provider, String userId, PortfolioCategoryModel category) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Eliminar Categoría"),
          content: Text("¿Seguro que quieres eliminar la categoría '${category.name}'?\n\n¡Esto también eliminará permanentemente todas las fotos y videos dentro de ella!"),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancelar")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                  final navigator = Navigator.of(ctx); 
                  await provider.deletePortfolioCategory(userId, category.id);
                   if (!mounted) return; 
                   navigator.pop(); 
              },
              child: const Text("Eliminar Todo"),
            ),
          ],
        ),
      );
  }

  void _showDeleteItemDialog(BuildContext context, CatalogEditorProvider provider, String userId, PortfolioItemModel item) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Eliminar Ítem"),
          content: const Text("¿Seguro que quieres eliminar este ítem del portafolio?\nLa acción no se puede deshacer."),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancelar")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                  final navigator = Navigator.of(ctx); 
                  await provider.deletePortfolioItem(userId, item);
                   if (!mounted) return; 
                   navigator.pop();
              },
              child: const Text("Eliminar"),
            ),
          ],
        ),
      );
  }

  /// Placeholder visual mientras se sube un ítem.
  Widget _buildUploadingPlaceholder() {
    return Card(
      color: Colors.grey.shade300,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             CircularProgressIndicator(strokeWidth: 2),
             SizedBox(height: 8),
             Text("Subiendo...", style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
} // Fin de _PortfolioEditState