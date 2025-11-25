// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// --- Modelos ---
import 'package:proveedor_servicly_app/core/models/category_model.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';

// --- Servicios ---
import 'package:proveedor_servicly_app/core/services/category_service.dart';
import 'package:proveedor_servicly_app/core/services/product_service.dart';
import 'package:proveedor_servicly_app/core/services/storage_service.dart';

class AddEditProductScreen extends StatefulWidget {
  final UserModel user;
  final ProductModel? productToEdit;
  final CategoryModel? preselectedCategory;

  const AddEditProductScreen({
    super.key,
    required this.user,
    this.productToEdit,
    this.preselectedCategory,
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
  late final TextEditingController _quantityController; 

  DateTime? _expiryDate;
  XFile? _mainImageFile;
  bool _isUploading = false;
  String? _selectedCategoryId;

  // Estado para galería
  List<Map<String, dynamic>> _galleryItems = [];

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
    _quantityController = TextEditingController(text: product?.quantity?.toString() ?? '');
    
    _expiryDate = product?.expiryDate?.toDate();
    _selectedCategoryId = product?.categoryId ?? widget.preselectedCategory?.id;

    // Clonamos la galería
    _galleryItems = List<Map<String, dynamic>>.from(product?.mediaGallery ?? []);
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

  // --- SELECTORES DE IMAGEN ---
  Future<void> _pickMainImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _mainImageFile = image);
    }
  }

  Future<void> _pickGalleryImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(imageQuality: 50);
    if (images.isNotEmpty) {
      setState(() {
        for (var image in images) {
          _galleryItems.add({'type': 'image', 'file': image});
        }
      });
    }
  }

  Future<void> _pickGalleryVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _galleryItems.add({'type': 'video', 'file': video});
      });
    }
  }

  void _removeGalleryItem(int index) {
    setState(() {
      _galleryItems.removeAt(index);
    });
  }

  // --- GUARDADO CON LÓGICA FINANCIERA ---
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate() || _isUploading) return;

    setState(() => _isUploading = true);

    final storageService = context.read<StorageService>();
    final productService = context.read<ProductService>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      // 1. Subir Imagen Principal
      String imageUrl = widget.productToEdit?.imageUrl ?? '';
      if (_mainImageFile != null) {
        imageUrl = await storageService.uploadProductImage(
          imageFile: _mainImageFile!,
          userId: widget.user.uid,
        );
      }

      // 2. Subir Galería
      List<Map<String, dynamic>> finalGalleryList = [];
      for (var item in _galleryItems) {
        if (item.containsKey('file')) {
          XFile file = item['file'];
          String fileType = item['type'];
          String url = await storageService.uploadGalleryMedia(
            file: file, 
            userId: widget.user.uid, 
            type: fileType
          ); 
          finalGalleryList.add({
            'type': fileType, 
            'url': url, 
            'thumbnailUrl': '' 
          });
        } else if (item.containsKey('url')) {
          finalGalleryList.add(item);
        }
      }

      // --- 3. LECTURA DEL CEREBRO FINANCIERO (NUEVO) ---
      double currentFixedCost = 0.0;
      try {
        // Leemos directamente de Firestore para asegurar el dato más reciente
        final configSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.uid)
            .collection('settings')
            .doc('financial_config')
            .get();

        if (configSnapshot.exists && configSnapshot.data() != null) {
          currentFixedCost = (configSnapshot.data()!['costoFijoUnitarioCalculado'] as num?)?.toDouble() ?? 0.0;
        }
      } catch (e) {
        debugPrint("Aviso: No se pudo leer la estructura de costos: $e");
        // No bloqueamos el guardado, solo asumimos costo 0
      }
      // --------------------------------------------------

      // 4. Construir Modelo
      final product = ProductModel(
        id: widget.productToEdit?.id ?? '',
        providerId: widget.user.uid,
        
        // Datos Editables
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0.0,
        quantity: int.tryParse(_quantityController.text.trim()),
        categoryId: _selectedCategoryId,
        imageUrl: imageUrl,
        mediaGallery: finalGalleryList,
        promoPrice: double.tryParse(_promoPriceController.text),
        promoText: _promoTextController.text.trim().isNotEmpty ? _promoTextController.text.trim() : null,
        expiryDate: _expiryDate != null ? Timestamp.fromDate(_expiryDate!) : null,
        createdAt: widget.productToEdit?.createdAt ?? Timestamp.now(),
        
        // --- ASIGNACIÓN INTELIGENTE DE COSTOS ---
        costPrice: widget.productToEdit?.costPrice ?? 0.0, // Por ahora 0, lo editaremos en Inventario
        
        // Si editamos, conservamos el histórico. Si es nuevo, estampamos el costo de hoy.
        fixedCostSnapshot: _isEditing 
            ? (widget.productToEdit?.fixedCostSnapshot ?? 0.0) 
            : currentFixedCost,
            
        wholesalePrice: widget.productToEdit?.wholesalePrice ?? 0.0,
        ambassadorPrice: widget.productToEdit?.ambassadorPrice ?? 0.0,
        minStock: widget.productToEdit?.minStock ?? 5,
      );

      // 5. Guardar
      if (_isEditing) {
        await productService.updateProduct(widget.user.uid, product);
        messenger.showSnackBar(const SnackBar(content: Text('Producto actualizado.'), backgroundColor: Colors.green));
      } else {
        await productService.addProduct(widget.user.uid, product);
        messenger.showSnackBar(const SnackBar(content: Text('Producto creado.'), backgroundColor: Colors.green));
      }

      if (navigator.canPop()) navigator.pop();

    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isUploading = false);
    }
  }

  // --- ELIMINACIÓN ---
  Future<void> _deleteProduct() async {
    final productService = context.read<ProductService>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D5A),
        title: const Text('Eliminar Producto', style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro? No se puede deshacer.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await productService.deleteProduct(widget.user.uid, widget.productToEdit!.id);
        if (navigator.canPop()) navigator.pop();
        messenger.showSnackBar(const SnackBar(content: Text('Eliminado.'), backgroundColor: Colors.orange));
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
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
    
    // Verificar null safety si user.planType no existe en tu modelo actual
    final bool isProPlan = true; // Cambiar a widget.user.planType == 'pro' si aplica
    
    final inputDecoration = InputDecoration(
        filled: true,
        fillColor: surfaceColor,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accentColor, width: 2)), 
        prefixStyle: const TextStyle(color: Colors.white, fontSize: 16));

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
                  title: 'Imagen Principal',
                  onTap: _pickMainImage,
                  imageFile: _mainImageFile,
                  existingImageUrl: widget.productToEdit?.imageUrl,
                ),
                const SizedBox(height: 32),
                
                Text('Galería Multimedia', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildGalleryGrid(isProPlan),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Fotos'),
                        onPressed: _isUploading ? null : _pickGalleryImages,
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: surfaceColor)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(isProPlan ? Icons.video_call_outlined : Icons.lock_outline),
                        label: const Text('Video'),
                        onPressed: _isUploading || !isProPlan ? null : _pickGalleryVideo,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isProPlan ? Colors.white : Colors.grey,
                          side: BorderSide(color: isProPlan ? surfaceColor : Colors.grey.withAlpha(128))
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                Text('Detalles', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration.copyWith(labelText: 'Nombre'),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                
                _CategorySelector(
                  user: widget.user,
                  initialCategoryId: _selectedCategoryId,
                  onChanged: (id) => setState(() => _selectedCategoryId = id),
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
                
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _priceController,
                        style: const TextStyle(color: Colors.white),
                        decoration: inputDecoration.copyWith(labelText: 'Precio', prefixText: '\$ '),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _quantityController,
                        style: const TextStyle(color: Colors.white),
                        decoration: inputDecoration.copyWith(labelText: 'Stock'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                TextFormField(
                  controller: _promoPriceController,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration.copyWith(labelText: 'Precio Promo (Opcional)', prefixText: '\$ '),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isUploading ? null : _saveProduct,
                    icon: _isUploading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                      : const Icon(Icons.save),
                    label: Text(_isEditing ? 'Guardar Cambios' : 'Crear Producto'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildGalleryGrid(bool isProPlan) {
    if (_galleryItems.isEmpty) return const SizedBox.shrink();
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _galleryItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemBuilder: (context, index) {
        final item = _galleryItems[index];
        ImageProvider? img;
        if (item.containsKey('file') && item['type'] == 'image') img = FileImage(File(item['file'].path));
        else if (item.containsKey('url')) img = NetworkImage(item['type'] == 'video' ? (item['thumbnailUrl'] ?? '') : item['url']);
        
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
                image: img != null ? DecorationImage(image: img, fit: BoxFit.cover) : null,
              ),
              child: item['type'] == 'video' ? const Center(child: Icon(Icons.play_circle, color: Colors.white)) : null,
            ),
            Positioned(
              top: 0, right: 0,
              child: GestureDetector(
                onTap: () => _removeGalleryItem(index),
                child: const Icon(Icons.cancel, color: Colors.red),
              ),
            )
          ],
        );
      },
    );
  }
}

class _ImagePickerWidget extends StatelessWidget {
  final VoidCallback onTap;
  final XFile? imageFile;
  final String? existingImageUrl;
  final String title;

  const _ImagePickerWidget({required this.onTap, required this.title, this.imageFile, this.existingImageUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: 150, height: 150,
          decoration: BoxDecoration(color: const Color(0xFF2D2D5A), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue)),
          child: _buildImage(),
        )
      ]),
    );
  }
  
  Widget _buildImage() {
     if (imageFile != null) return Image.file(File(imageFile!.path), fit: BoxFit.cover);
     if (existingImageUrl != null) return Image.network(existingImageUrl!, fit: BoxFit.cover);
     return const Icon(Icons.add_a_photo, color: Colors.white54);
  }
}

class _CategorySelector extends StatelessWidget {
  final UserModel user;
  final String? initialCategoryId;
  final ValueChanged<String?> onChanged;
  final InputDecoration inputDecoration;

  const _CategorySelector({required this.user, required this.initialCategoryId, required this.onChanged, required this.inputDecoration});

  @override
  Widget build(BuildContext context) {
    final categoryService = context.read<CategoryService>();
    return StreamBuilder<List<CategoryModel>>(
      stream: categoryService.getCategories(user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final categories = snapshot.data!;
        return DropdownButtonFormField<String>(
          value: categories.any((c) => c.id == initialCategoryId) ? initialCategoryId : null,
          onChanged: onChanged,
          decoration: inputDecoration.copyWith(labelText: 'Categoría'),
          dropdownColor: const Color(0xFF2D2D5A),
          style: const TextStyle(color: Colors.white),
          items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
        );
      },
    );
  }
}