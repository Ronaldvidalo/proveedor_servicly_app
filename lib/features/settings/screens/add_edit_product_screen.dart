import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/category_model.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/category_service.dart';
import 'package:proveedor_servicly_app/core/services/product_service.dart';
import 'package:proveedor_servicly_app/core/services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Para Timestamp

class AddEditProductScreen extends StatefulWidget {
  final UserModel user;
  final ProductModel? productToEdit;
  // --- ¡CORRECCIÓN AÑADIDA! ---
  final CategoryModel? preselectedCategory; 

  const AddEditProductScreen({
    super.key,
    required this.user,
    this.productToEdit,
    this.preselectedCategory, // <-- ¡AÑADIDO!
  });

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _promoPriceController;
  late TextEditingController _promoTextController;
  late TextEditingController _quantityController;

  // Estado
  String? _selectedCategoryId;
  XFile? _selectedImageFile;
  String? _existingImageUrl;
  DateTime? _expiryDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final product = widget.productToEdit;

    _nameController = TextEditingController(text: product?.name);
    _descriptionController = TextEditingController(text: product?.description);
    _priceController = TextEditingController(text: product?.price.toStringAsFixed(2));
    _promoPriceController = TextEditingController(text: product?.promoPrice?.toStringAsFixed(2));
    _promoTextController = TextEditingController(text: product?.promoText);
    _quantityController = TextEditingController(text: product?.quantity?.toString());

    _existingImageUrl = product?.imageUrl;
    _expiryDate = product?.expiryDate?.toDate();
    
    // --- ¡LÓGICA DE CORRECCIÓN! ---
    // Si editamos, usamos el ID del producto.
    // Si creamos, usamos el ID de la categoría pre-seleccionada.
    _selectedCategoryId = product?.categoryId ?? widget.preselectedCategory?.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _promoPriceController.dispose();
    _promoTextController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        setState(() => _selectedImageFile = image);
      }
    } catch (e) {
      _showSnackbar('Error al seleccionar la imagen: $e', isError: true);
    }
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null && picked != _expiryDate) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      _showSnackbar('Por favor, selecciona una categoría.', isError: true);
      return;
    }
    if (widget.productToEdit == null && _selectedImageFile == null) {
      _showSnackbar('Por favor, añade una imagen principal.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final storageService = context.read<StorageService>();
    final productService = context.read<ProductService>();
    final navigator = Navigator.of(context);
    String? newImageUrl = _existingImageUrl;

    try {
      // 1. Subir/Actualizar Imagen
      if (_selectedImageFile != null) {
        final String storagePath = 'products/${widget.user.uid}/main_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        // Si estamos editando y ya había una foto, borrar la anterior
        if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
          try {
            await storageService.deleteFileByUrl(_existingImageUrl!);
          } catch (e) {
            debugPrint("No se pudo borrar la imagen anterior: $e");
          }
        }
        
        newImageUrl = await storageService.uploadFileWithProgress(
          File(_selectedImageFile!.path),
          storagePath,
          (progress) {},
        );
      }

      // 2. Preparar el Modelo
      final now = Timestamp.now();
      final double price = double.tryParse(_priceController.text) ?? 0.0;
      final double? promoPrice = _promoPriceController.text.isNotEmpty ? double.tryParse(_promoPriceController.text) : null;
      final int? quantity = _quantityController.text.isNotEmpty ? int.tryParse(_quantityController.text) : null;

      final ProductModel product = ProductModel(
        id: widget.productToEdit?.id ?? '', // El ID se ignora al crear
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        createdAt: widget.productToEdit?.createdAt ?? now,
        expiryDate: _expiryDate != null ? Timestamp.fromDate(_expiryDate!) : null,
        imageUrl: newImageUrl ?? '',
        promoPrice: promoPrice,
        promoText: _promoTextController.text.trim(),
        categoryId: _selectedCategoryId!,
        quantity: quantity,
        mediaGallery: widget.productToEdit?.mediaGallery ?? [], // Mantenemos la galería (aún no la editamos aquí)
      );

      // 3. Guardar en Firestore
      if (widget.productToEdit != null) {
        await productService.updateProduct(widget.user.uid, product);
      } else {
        await productService.addProduct(widget.user.uid, product);
      }

      _showSnackbar(
        'Producto ${widget.productToEdit != null ? 'actualizado' : 'creado'} con éxito.',
        isError: false
      );
      navigator.pop();

    } catch (e) {
      _showSnackbar('Error al guardar el producto: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
    ));
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accentColor, width: 2)),
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(widget.productToEdit != null ? 'Editar Producto' : 'Añadir Producto'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        actions: [
          if (widget.productToEdit != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _isLoading ? null : _deleteProduct,
            ),
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildImagePicker(),
                const SizedBox(height: 24),
                _buildSectionTitle('Información Básica'),
                _buildCategoryDropdown(surfaceColor),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration.copyWith(labelText: 'Nombre del Producto o Servicio'),
                  validator: (value) => (value == null || value.isEmpty) ? 'Ingresa un nombre' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration.copyWith(labelText: 'Descripción (Opcional)', alignLabelWithHint: true),
                  maxLines: 4,
                  minLines: 2,
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Precio e Inventario'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        style: const TextStyle(color: Colors.white),
                        decoration: inputDecoration.copyWith(labelText: 'Precio', prefixText: '\$ '),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                        validator: (value) => (value == null || value.isEmpty) ? 'Ingresa un precio' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        style: const TextStyle(color: Colors.white),
                        decoration: inputDecoration.copyWith(labelText: 'Cantidad (Opcional)', hintText: 'Infinito'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Promoción (Opcional)'),
                TextFormField(
                  controller: _promoPriceController,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration.copyWith(labelText: 'Precio de Promoción', prefixText: '\$ '),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _promoTextController,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration.copyWith(labelText: 'Texto de Promoción (ej: ¡Oferta!, 20% OFF)'),
                ),
                const SizedBox(height: 16),
                _buildExpiryDateSelector(context, surfaceColor),
                const SizedBox(height: 100),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator(color: accentColor)),
            ),
        ],
      ),
      bottomSheet: _buildSaveButton(backgroundColor, accentColor),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D5A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white38, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _selectedImageFile != null
                  ? Image.file(File(_selectedImageFile!.path), fit: BoxFit.cover)
                  : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                      ? Image.network(_existingImageUrl!, fit: BoxFit.cover,
                          errorBuilder: (c, o, s) => const Icon(Icons.image_not_supported, color: Colors.white38, size: 40))
                      : const Icon(Icons.image_outlined, color: Colors.white38, size: 60),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF00BFFF),
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(BorderSide(color: Color(0xFF1A1A2E), width: 2)),
                ),
                child: const Icon(Icons.edit, size: 18, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(Color surfaceColor) {
    final categoryService = context.watch<CategoryService>();
    return StreamBuilder<List<CategoryModel>>(
      stream: categoryService.getCategories(widget.user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) {
          return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
        }
        if (snapshot.hasError) {
          return const Text('Error al cargar categorías', style: TextStyle(color: Colors.redAccent));
        }
        final categories = snapshot.data ?? [];
        if (categories.isEmpty) {
          return Text('No hay categorías. Ve a "Gestionar Categorías" para crear una.', style: TextStyle(color: Colors.orangeAccent.shade100));
        }
        
        // Asegurarse de que el valor seleccionado sea válido
        if (_selectedCategoryId != null && !categories.any((c) => c.id == _selectedCategoryId)) {
          _selectedCategoryId = null;
        }

        return DropdownButtonFormField<String>(
          value: _selectedCategoryId,
          decoration: InputDecoration(
            filled: true,
            fillColor: surfaceColor,
            labelText: 'Categoría',
            labelStyle: const TextStyle(color: Colors.white70),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          dropdownColor: surfaceColor,
          style: const TextStyle(color: Colors.white),
          items: categories.map((category) {
            return DropdownMenuItem<String>(
              value: category.id,
              child: Text(category.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedCategoryId = value);
          },
          validator: (value) => (value == null) ? 'Selecciona una categoría' : null,
        );
      },
    );
  }

  Widget _buildExpiryDateSelector(BuildContext context, Color surfaceColor) {
    return InkWell(
      onTap: _selectExpiryDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fecha de Vencimiento', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text(
                  _expiryDate != null ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}' : 'No establecida',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Icon(Icons.calendar_today, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSaveButton(Color backgroundColor, Color accentColor) {
    return Container(
      width: double.infinity,
      color: backgroundColor.withOpacity(0.9),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _isLoading ? null : _saveProduct,
        child: Text(
          widget.productToEdit != null ? 'Guardar Cambios' : 'Crear Producto',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _deleteProduct() async {
    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D5A),
        title: const Text('Confirmar Eliminación', style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro de que quieres eliminar este producto? Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (didConfirm != true) return;

    setState(() => _isLoading = true);

    final storageService = context.read<StorageService>();
    final productService = context.read<ProductService>();
    final navigator = Navigator.of(context);

    try {
      // 1. Eliminar de Firestore
      await productService.deleteProduct(widget.user.uid, widget.productToEdit!.id);

      // 2. Eliminar imagen de Storage
      if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
        await storageService.deleteFileByUrl(_existingImageUrl!);
      }
      
      // TODO: Eliminar imágenes de la 'mediaGallery' de Storage

      _showSnackbar('Producto eliminado con éxito.', isError: false);
      navigator.pop(); 

    } catch (e) {
      _showSnackbar('Error al eliminar el producto: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}