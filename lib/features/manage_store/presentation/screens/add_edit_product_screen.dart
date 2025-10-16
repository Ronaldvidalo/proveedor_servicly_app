import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/category_model.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/category_service.dart';
import 'package:proveedor_servicly_app/core/services/product_service.dart';
import 'package:proveedor_servicly_app/core/services/storage_service.dart';

// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 14/10/2025
// Style: Cyber Glow
// This screen was refactored to use a responsive GridView layout,
// custom product cards, and an enhanced loading/empty state experience,
// aligning with the "Cyber Glow" design philosophy.
// ---------------------------------

/// Un formulario para crear un nuevo producto o editar uno existente,
/// con capacidad para subir imágenes.
class AddEditProductScreen extends StatefulWidget {
  final UserModel user;
  final ProductModel? productToEdit;

  const AddEditProductScreen({
    super.key,
    required this.user,
    this.productToEdit,
  });

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _promoPriceController;
  late final TextEditingController _promoTextController;
  DateTime? _expiryDate;
  XFile? _imageFile;
  bool _isUploading = false;
  String? _selectedCategoryId;

  bool get _isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    final product = widget.productToEdit;
    _nameController = TextEditingController(text: product?.name);
    _descriptionController = TextEditingController(text: product?.description);
    _priceController = TextEditingController(text: product?.price.toString());
    _promoPriceController = TextEditingController(text: product?.promoPrice?.toString() ?? '');
    _promoTextController = TextEditingController(text: product?.promoText ?? '');
    _expiryDate = product?.expiryDate?.toDate();
    _selectedCategoryId = product?.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _promoPriceController.dispose();
    _promoTextController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate() || _isUploading) {
      return;
    }

    setState(() { _isUploading = true; });

    final storageService = context.read<StorageService>();
    final productService = context.read<ProductService>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      String imageUrl = widget.productToEdit?.imageUrl ?? '';

      if (_imageFile != null) {
        imageUrl = await storageService.uploadProductImage(
          imageFile: _imageFile!,
          userId: widget.user.uid,
        );
      }

      final product = ProductModel(
        id: widget.productToEdit?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0.0,
        expiryDate: _expiryDate != null ? Timestamp.fromDate(_expiryDate!) : null,
        createdAt: widget.productToEdit?.createdAt ?? Timestamp.now(),
        imageUrl: imageUrl,
        promoPrice: double.tryParse(_promoPriceController.text),
        promoText: _promoTextController.text.trim().isNotEmpty ? _promoTextController.text.trim() : null,
        categoryId: _selectedCategoryId,
      );

      if (_isEditing) {
        await productService.updateProduct(widget.user.uid, product);
        messenger.showSnackBar(const SnackBar(content: Text('Producto actualizado con éxito.'), backgroundColor: Colors.green));
      } else {
        await productService.addProduct(widget.user.uid, product);
        messenger.showSnackBar(const SnackBar(content: Text('Producto añadido con éxito.'), backgroundColor: Colors.green));
      }

      if (navigator.canPop()) {
        navigator.pop();
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error al guardar el producto: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if(mounted) {
        setState(() { _isUploading = false; });
      }
    }
  }

  Future<void> _deleteProduct() async {
    final productService = context.read<ProductService>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D5A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar Eliminación', style: TextStyle(color: Colors.white)),
        content:
            const Text('¿Estás seguro de que quieres eliminar este producto? Esta acción no se puede deshacer.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await productService.deleteProduct(widget.user.uid, widget.productToEdit!.id);
         if (navigator.canPop()) {
          navigator.pop();
        }
        messenger.showSnackBar(const SnackBar(content: Text('Producto eliminado.'), backgroundColor: Colors.orange));
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }


  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);
    
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: surfaceColor,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white38),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentColor, width: 2),
      ),
      prefixStyle: const TextStyle(color: Colors.white, fontSize: 16)
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Producto' : 'Añadir Producto'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              onPressed: _deleteProduct,
              tooltip: 'Eliminar Producto',
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                _ImagePickerWidget(
                  onTap: _pickImage,
                  imageFile: _imageFile,
                  existingImageUrl: widget.productToEdit?.imageUrl,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration.copyWith(labelText: 'Nombre del Producto'),
                  validator: (value) =>
                      value!.isEmpty ? 'Este campo es requerido' : null,
                ),
                const SizedBox(height: 16),
                _CategorySelector(
                  user: widget.user,
                  initialCategoryId: _selectedCategoryId,
                  onChanged: (newId) {
                    setState(() {
                      _selectedCategoryId = newId;
                    });
                  },
                  inputDecoration: inputDecoration,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration.copyWith(labelText: 'Descripción'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration.copyWith(labelText: 'Precio Original', prefixText: '\$ '),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value!.isEmpty) return 'Este campo es requerido';
                    if (double.tryParse(value) == null) return 'Por favor, introduce un número válido';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                Text('Promoción (Opcional)', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _promoPriceController,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration.copyWith(labelText: 'Precio de Promoción', prefixText: '\$ '),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                      return 'Si se añade, debe ser un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _promoTextController,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration.copyWith(labelText: 'Texto de Promoción (ej: ¡Oferta!, 20% OFF)'),
                ),
                const SizedBox(height: 24),
                
                InputDecorator(
                  decoration: inputDecoration.copyWith(labelText: 'Fecha de Vencimiento (Opcional)'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _expiryDate == null
                            ? 'No establecida'
                            : _formatDate(_expiryDate!),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today_rounded, color: accentColor),
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _expiryDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                          );
                          if (pickedDate != null) {
                            setState(() => _expiryDate = pickedDate);
                          }
                        },
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isUploading ? null : _saveProduct,
                    icon: _isUploading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: const CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
                          )
                        : Icon(_isEditing ? Icons.save_alt_outlined : Icons.add_circle_outline),
                    label: Text(_isEditing ? 'Guardar Cambios' : 'Añadir Producto'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      backgroundColor: accentColor,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget de selector de imagen rediseñado con estilo "Cyber Glow".
class _ImagePickerWidget extends StatelessWidget {
  final VoidCallback onTap;
  final XFile? imageFile;
  final String? existingImageUrl;

  const _ImagePickerWidget({
    required this.onTap,
    this.imageFile,
    this.existingImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);
    
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accentColor.withAlpha(150), width: 2),
            boxShadow: [
              BoxShadow(color: accentColor.withAlpha(80), blurRadius: 15, spreadRadius: 2)
            ]
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: _buildImage(accentColor),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(Color iconColor) {
    if (imageFile != null) {
      return Image.file(File(imageFile!.path), fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    }
    if (existingImageUrl != null && existingImageUrl!.isNotEmpty) {
      return Image.network(existingImageUrl!, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined, size: 48, color: iconColor),
        const SizedBox(height: 12),
        const Text('Añadir Imagen', style: TextStyle(color: Colors.white70)),
      ],
    );
  }
}

/// Un widget que muestra un Dropdown para seleccionar una categoría de producto.
class _CategorySelector extends StatelessWidget {
  final UserModel user;
  final String? initialCategoryId;
  final ValueChanged<String?> onChanged;
  final InputDecoration inputDecoration;

  const _CategorySelector({
    required this.user,
    required this.initialCategoryId,
    required this.onChanged,
    required this.inputDecoration,
  });

  @override
  Widget build(BuildContext context) {
    final categoryService = context.read<CategoryService>();

    return StreamBuilder<List<CategoryModel>>(
      stream: categoryService.getCategories(user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Muestra un placeholder mientras cargan las categorías
          return InputDecorator(
            decoration: inputDecoration.copyWith(labelText: 'Categoría'),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cargando categorías...', style: TextStyle(color: Colors.white70)),
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
          );
        }

        final categories = snapshot.data!;
        
        final validInitialValue = categories.any((c) => c.id == initialCategoryId)
            ? initialCategoryId
            : null;

        return DropdownButtonFormField<String>(
          initialValue: validInitialValue,
          onChanged: onChanged,
          decoration: inputDecoration.copyWith(labelText: 'Categoría (Opcional)'),
          style: const TextStyle(color: Colors.white),
          dropdownColor: const Color(0xFF2D2D5A),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Sin Categoría', style: TextStyle(fontStyle: FontStyle.italic)),
            ),
            ...categories.map((category) {
              return DropdownMenuItem(
                value: category.id,
                child: Text(category.name),
              );
            }),
          ],
        );
      },
    );
  }
}

