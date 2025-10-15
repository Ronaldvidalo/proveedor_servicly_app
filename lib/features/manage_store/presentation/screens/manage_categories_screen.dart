// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 14/10/2025
// Style: Cyber Glow
// This screen was refactored to align with the "Cyber Glow" design philosophy.
// It features a styled list of category cards, redesigned dialogs for all CRUD
// operations, and an improved empty state for a cohesive user experience.
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/category_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/category_service.dart';

/// Una pantalla para que los proveedores gestionen sus categorías de productos.
class ManageCategoriesScreen extends StatelessWidget {
  final UserModel user;

  const ManageCategoriesScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);
    final categoryService = context.read<CategoryService>();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Gestionar Categorías'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: StreamBuilder<List<CategoryModel>>(
            stream: categoryService.getCategories(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: accentColor));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const _EmptyState();
              }

              final categories = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return _CategoryTile(
                    category: category,
                    user: user,
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditCategoryDialog(context, user: user),
        backgroundColor: accentColor,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Tarjeta de categoría rediseñada para la lista.
class _CategoryTile extends StatelessWidget {
  final CategoryModel category;
  final UserModel user;

  const _CategoryTile({required this.category, required this.user});

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Color(0xFF2D2D5A);
    const accentColor = Color(0xFF00BFFF);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: const Icon(Icons.folder_open_rounded, color: accentColor),
        title: Text(category.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white70),
              tooltip: 'Editar',
              onPressed: () => _showAddEditCategoryDialog(context, user: user, categoryToEdit: category),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Eliminar',
              onPressed: () => _showDeleteConfirmationDialog(context, user: user, category: category),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado vacío rediseñado.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 80, color: Colors.white24),
            SizedBox(height: 24),
            Text(
              'Sin Categorías',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Toca el botón "+" para crear tu primera categoría y organizar tus productos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}


/// Diálogo rediseñado para añadir o editar una categoría.
void _showAddEditCategoryDialog(BuildContext context, {required UserModel user, CategoryModel? categoryToEdit}) {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: categoryToEdit?.name);
  final isEditing = categoryToEdit != null;

  const accentColor = Color(0xFF00BFFF);
  const surfaceColor = Color(0xFF2D2D5A);

  showDialog(
    context: context,
    builder: (dialogContext) {
      final categoryService = dialogContext.read<CategoryService>();
      return AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEditing ? 'Editar Categoría' : 'Nueva Categoría', style: const TextStyle(color: Colors.white)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Nombre de la categoría',
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: const Color(0xFF1A1A2E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accentColor, width: 2)),
            ),
            validator: (value) => (value == null || value.trim().isEmpty) ? 'El nombre es obligatorio' : null,
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.black),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final categoryName = nameController.text.trim();
                try {
                  if (isEditing) {
                    await categoryService.updateCategory(user.uid, categoryToEdit.id, categoryName);
                  } else {
                    await categoryService.addCategory(user.uid, categoryName);
                  }
                  Navigator.of(dialogContext).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: Text(isEditing ? 'Guardar' : 'Crear'),
          ),
        ],
      );
    },
  );
}

/// Diálogo de confirmación de eliminación (estilo consistente).
void _showDeleteConfirmationDialog(BuildContext context, {required UserModel user, required CategoryModel category}) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      final categoryService = dialogContext.read<CategoryService>();
      return AlertDialog(
        backgroundColor: const Color(0xFF2D2D5A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar Eliminación', style: TextStyle(color: Colors.white)),
        content: Text('¿Seguro que quieres eliminar la categoría "${category.name}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await categoryService.deleteCategory(user.uid, category.id);
                Navigator.of(dialogContext).pop();
              } catch (e) {
                 ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                  );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      );
    },
  );
}
