import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/models/portfolio_category_model.dart'; // Importar modelo
import 'package:proveedor_servicly_app/core/services/firestore_service.dart'; // Importar servicio
import 'package:proveedor_servicly_app/core/services/permissions_service.dart'; // Para límites
// --- IMPORT PANTALLA DE ÍTEMS ---
// Asegúrate que la ruta a tu pantalla de ítems sea correcta
import 'manage_portfolio_items_screen.dart';

class ManagePortfolioScreen extends StatefulWidget {
  final UserModel user;
  const ManagePortfolioScreen({super.key, required this.user});

  @override
  State<ManagePortfolioScreen> createState() => _ManagePortfolioScreenState();
}

class _ManagePortfolioScreenState extends State<ManagePortfolioScreen> {
  late final FirestoreService _firestoreService;

  @override
  void initState() {
    super.initState();
    _firestoreService = context.read<FirestoreService>();
  }

  // --- Diálogo para Añadir/Editar Categoría ---
  void _showCategoryDialog({PortfolioCategoryModel? categoryToEdit}) {
    final TextEditingController nameController =
        TextEditingController(text: categoryToEdit?.name ?? '');
    final bool isEditing = categoryToEdit != null;
    final permissions = context.read<PermissionsService>();

    showDialog(
      context: context,
      builder: (context) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Editar Categoría' : 'Nueva Categoría'),
              content: TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre de la categoría'),
                autofocus: true,
                enabled: !isLoading,
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: isLoading ? null : () async {
                    final String name = nameController.text.trim();
                    if (name.isEmpty) return;

                    setDialogState(() => isLoading = true);

                    try {
                      if (isEditing) {
                        await _firestoreService.updatePortfolioCategory(
                            widget.user.uid, categoryToEdit!.id, name);
                      } else {
                        final stream = _firestoreService.getPortfolioCategoriesStream(widget.user.uid);
                        final currentCategories = await stream.first;

                        // --- CORRECCIÓN AQUÍ ---
                        // Usar el método correcto para categorías de PORTAFOLIO
                        if (!permissions.canAddPortfolioCategory(currentCategories.length)) {
                           if (!context.mounted) return;
                           Navigator.of(context).pop();
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(
                               content: Text(
                                   // --- CORRECCIÓN AQUÍ ---
                                   'Alcanzaste el límite de ${permissions.maxPortfolioCategories} categorías para tu plan.'),
                               backgroundColor: Colors.orange,
                             ),
                           );
                           setDialogState(() => isLoading = false);
                           return;
                        }
                        await _firestoreService.addPortfolioCategory(
                            widget.user.uid, name);
                      }
                      if (context.mounted) Navigator.of(context).pop();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red),
                        );
                      }
                       setDialogState(() => isLoading = false);
                    }
                  },
                  child: isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Guardar'),
                ),
              ],
            );
          }
        );
      },
    );
  }

    // --- Diálogo de Confirmación para Eliminar ---
  void _showDeleteConfirmationDialog(PortfolioCategoryModel category) {
    showDialog(
      context: context,
      builder: (context) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Confirmar Eliminación'),
              content: Text('¿Seguro que quieres eliminar la categoría "${category.name}"?\n\nAdvertencia: Los ítems dentro de esta categoría no serán eliminados.'),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: isLoading ? null : () async {
                    setDialogState(() => isLoading = true);
                    try {
                      await _firestoreService.deletePortfolioCategory(widget.user.uid, category.id);
                      if (context.mounted) Navigator.of(context).pop();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
                        );
                      }
                       setDialogState(() => isLoading = false);
                    }
                  },
                  child: isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Eliminar'),
                ),
              ],
            );
          }
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final permissions = context.watch<PermissionsService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar Portafolio - Categorías')),
      body: StreamBuilder<List<PortfolioCategoryModel>>(
        stream: _firestoreService.getPortfolioCategoriesStream(widget.user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                     Icon(Icons.folder_off_outlined, size: 60, color: Colors.grey),
                     SizedBox(height: 16),
                    Text(
                      'Aún no tienes categorías en tu portafolio.',
                       textAlign: TextAlign.center,
                       style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Presiona "+" para añadir la primera.',
                       textAlign: TextAlign.center,
                       style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          final categories = snapshot.data!;

          // --- Lista de Categorías Reordenable ---
          return ReorderableListView.builder(
            itemCount: categories.length,
            header: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Text(
                'Arrastra para reordenar. Toca una categoría para ver sus ítems.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                key: ValueKey(category.id),
                title: Text(category.name),
                leading: const Icon(Icons.drag_handle), // Icono para arrastrar
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                      tooltip: 'Editar nombre',
                      onPressed: () => _showCategoryDialog(categoryToEdit: category),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      tooltip: 'Eliminar categoría',
                      onPressed: () => _showDeleteConfirmationDialog(category),
                    ),
                  ],
                ),
                // --- NAVEGACIÓN IMPLEMENTADA ---
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ManagePortfolioItemsScreen(
                        userId: widget.user.uid, // Pasar el userId
                        category: category,      // Pasar el objeto categoría completo
                      ),
                    ),
                  );
                },
                // --- FIN ---
              );
            },
            // Lógica de Reordenamiento
            onReorder: (int oldIndex, int newIndex) async {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final Map<String, int> newOrderMap = {};
              final List<PortfolioCategoryModel> currentList = List.from(snapshot.data!); // Usar lista del snapshot
              final PortfolioCategoryModel movedItem = currentList.removeAt(oldIndex);
              currentList.insert(newIndex, movedItem);

              for (int i = 0; i < currentList.length; i++) {
                newOrderMap[currentList[i].id] = i;
              }

              try {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Guardando nuevo orden...'), duration: Duration(seconds: 1)),
                 );
                await _firestoreService.updatePortfolioCategoriesOrder(widget.user.uid, newOrderMap);
              } catch (e) {
                 if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text('Error al reordenar: $e'), backgroundColor: Colors.red),
                   );
                 }
              }
            },
          );
        },
      ),
      // Botón Flotante para Añadir
      floatingActionButton: StreamBuilder<List<PortfolioCategoryModel>>(
        stream: _firestoreService.getPortfolioCategoriesStream(widget.user.uid),
        builder: (context, snapshot) {
          final currentCount = snapshot.data?.length ?? 0;
          // --- CORRECCIÓN AQUÍ ---
          final bool canAdd = permissions.canAddPortfolioCategory(currentCount);

          return FloatingActionButton(
            onPressed: canAdd ? () => _showCategoryDialog() : null,
            // --- CORRECCIÓN AQUÍ ---
            tooltip: canAdd ? 'Añadir Categoría' : 'Límite de categorías alcanzado (${permissions.maxPortfolioCategories})',
            backgroundColor: canAdd ? Theme.of(context).colorScheme.primary : Colors.grey,
            foregroundColor: canAdd ? Theme.of(context).colorScheme.onPrimary: Colors.white70,
            child: const Icon(Icons.add),
          );
        }
      ),
    );
  }
}