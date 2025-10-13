import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/product_service.dart';
import 'package:proveedor_servicly_app/core/services/storage_service.dart';

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
  DateTime? _expiryDate;

  // --- NUEVOS ESTADOS ---
  XFile? _imageFile; // Archivo de imagen seleccionado
  bool _isUploading = false; // Estado para mostrar el loading

  bool get _isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.productToEdit?.name);
    _descriptionController =
        TextEditingController(text: widget.productToEdit?.description);
    _priceController =
        TextEditingController(text: widget.productToEdit?.price.toString());
    _expiryDate = widget.productToEdit?.expiryDate?.toDate();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }
  
  /// Abre la galería para seleccionar una imagen y la comprime.
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // --- MODIFICACIÓN CLAVE ---
    // Se añade 'imageQuality: 70' para comprimir la imagen al 70%
    // de su calidad original, reduciendo significativamente su tamaño.
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() { _isUploading = true; });

    final storageService = context.read<StorageService>();
    final productService = context.read<ProductService>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      String imageUrl = widget.productToEdit?.imageUrl ?? '';

      // Si se seleccionó una nueva imagen, súbela primero.
      if (_imageFile != null) {
        imageUrl = await storageService.uploadProductImage(
          imageFile: _imageFile!,
          userId: widget.user.uid,
        );
      }

      final product = ProductModel(
        id: widget.productToEdit?.id ?? '',
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        expiryDate: _expiryDate != null ? Timestamp.fromDate(_expiryDate!) : null,
        createdAt: widget.productToEdit?.createdAt ?? Timestamp.now(),
        imageUrl: imageUrl, // Guarda la URL de la imagen
      );

      if (_isEditing) {
        await productService.updateProduct(widget.user.uid, product);
        messenger.showSnackBar(const SnackBar(content: Text('Producto actualizado con éxito.')));
      } else {
        await productService.addProduct(widget.user.uid, product);
        messenger.showSnackBar(const SnackBar(content: Text('Producto añadido con éxito.')));
      }

      if (navigator.canPop()) {
        navigator.pop();
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error al guardar el producto: $e')),
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
        title: const Text('Confirmar Borrado'),
        content:
            const Text('¿Estás seguro de que quieres eliminar este producto?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
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
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Producto' : 'Añadir Producto'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteProduct,
              tooltip: 'Eliminar Producto',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- NUEVO WIDGET DE IMAGEN ---
            _ImagePickerWidget(
              onTap: _pickImage,
              imageFile: _imageFile,
              existingImageUrl: widget.productToEdit?.imageUrl,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre del Producto'),
              validator: (value) =>
                  value!.isEmpty ? 'Este campo es requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration:
                  const InputDecoration(labelText: 'Precio', prefixText: '\$'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value!.isEmpty) return 'Este campo es requerido';
                if (double.tryParse(value) == null) {
                  return 'Por favor, introduce un número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Fecha de Vencimiento (Opcional)',
                border: OutlineInputBorder(),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_expiryDate == null
                      ? 'No establecida'
                      : _formatDate(_expiryDate!)),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _expiryDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365 * 10)),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _expiryDate = pickedDate;
                        });
                      }
                    },
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _saveProduct,
              icon: _isUploading
                  ? Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(2.0),
                      child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                    )
                  : Icon(_isEditing ? Icons.save_alt_outlined : Icons.add_circle_outline),
              label: Text(_isEditing ? 'Guardar Cambios' : 'Añadir Producto'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un widget para seleccionar y previsualizar la imagen del producto.
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
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: _buildImage(),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (imageFile != null) {
      return Image.file(File(imageFile!.path), fit: BoxFit.cover);
    }
    if (existingImageUrl != null && existingImageUrl!.isNotEmpty) {
      return Image.network(existingImageUrl!, fit: BoxFit.cover);
    }
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey),
        SizedBox(height: 8),
        Text('Añadir Imagen', style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}

