import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/category_model.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart'; // Modelo ya está actualizado
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/category_service.dart';
import 'package:proveedor_servicly_app/core/services/product_service.dart';
import 'package:proveedor_servicly_app/core/services/storage_service.dart';
import 'package:proveedor_servicly_app/core/models/category_model.dart';

// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 14/10/2025
// Style: Cyber Glow
// This screen was refactored to use a responsive GridView layout,
// custom product cards, and an enhanced loading/empty state experience,
// aligning with the "Cyber Glow" design philosophy.
// --- MODIFICACIÓN: Añadido soporte para 'quantity' y 'mediaGallery' ---
// ---------------------------------

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
  late final TextEditingController _quantityController; // --- NUEVO ---
  

  DateTime? _expiryDate;
  XFile? _mainImageFile; // --- MODIFICADO: Renombrado para claridad
  bool _isUploading = false;
  String? _selectedCategoryId;
  

  // --- NUEVO: Estado para la galería multimedia ---
  // Esta lista contendrá mapas que representan los medios.
  // Mapas de archivos nuevos: { 'type': 'image', 'file': XFile(...) }
  // Mapas de medios existentes: { 'type': 'image', 'url': 'https://...' }
  List<Map<String, dynamic>> _galleryItems = [];
  // --- FIN NUEVO ---

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
    _selectedCategoryId = product?.categoryId ?? widget.preselectedCategory?.id;

    // --- NUEVO ---
    _quantityController = TextEditingController(text: product?.quantity?.toString() ?? '');
    // Clonamos la lista para poder modificarla sin afectar el modelo original
    _galleryItems = List<Map<String, dynamic>>.from(product?.mediaGallery ?? []);
    // --- FIN NUEVO ---
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _promoPriceController.dispose();
    _promoTextController.dispose();
    _quantityController.dispose(); // --- NUEVO ---
    super.dispose();
  }

  // --- MODIFICADO: Renombrado para claridad ---
  Future<void> _pickMainImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70); // Comprime la imagen principal
    if (image != null) {
      setState(() {
        _mainImageFile = image;
      });
    }
  }

  // --- NUEVO: Lógica para la galería ---
  Future<void> _pickGalleryImages() async {
    final ImagePicker picker = ImagePicker();
    // Permite seleccionar múltiples imágenes
    final List<XFile> images = await picker.pickMultiImage(imageQuality: 50); // Comprime más las imágenes de galería
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
      // Validar tamaño del video (lógica futura en StorageService)
      setState(() {
        _galleryItems.add({'type': 'video', 'file': video});
      });
    }
  }

  void _removeGalleryItem(int index) {
    setState(() {
      _galleryItems.removeAt(index);
    });
    // OJO: Si el item removido tenía un 'url', deberíamos guardarlo
    // en una lista `_itemsToDeleteFromStorage` para borrarlo
    // de Firebase Storage al guardar y ahorrar costos.
  }
  // --- FIN NUEVO ---

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
      // --- LÓGICA DE SUBIDA MODIFICADA ---
      
      // 1. Subir la Imagen Principal (si cambió)
      String imageUrl = widget.productToEdit?.imageUrl ?? '';
      if (_mainImageFile != null) {
        // Asumimos que tu servicio comprime (imageQuality: 70 ya lo hizo)
        imageUrl = await storageService.uploadProductImage(
          imageFile: _mainImageFile!,
          userId: widget.user.uid,
        );
      }

      // 2. Subir la Galería Multimedia (¡NUEVO!)
      List<Map<String, dynamic>> finalGalleryList = [];
      for (var item in _galleryItems) {
        if (item.containsKey('file')) {
          // Es un archivo nuevo, hay que subirlo
          XFile file = item['file'];
          String fileType = item['type'];
          String url;
          
          if (fileType == 'image') {
            // Aquí llamarías a tu servicio de compresión y subida
            // (Asumimos que imageQuality: 50 ya comprimió)
            url = await storageService.uploadGalleryMedia(
              file: file,
              userId: widget.user.uid,
              type: 'image',
            );
            finalGalleryList.add({'type': 'image', 'url': url});
          } else if (fileType == 'video') {
            // Aquí llamarías a tu servicio de compresión y subida de video
            url = await storageService.uploadGalleryMedia(
              file: file,
              userId: widget.user.uid,
              type: 'video',
            );
            // Los videos necesitan una miniatura (thumbnail)
            // Tu 'StorageService' debería generar una y devolverla.
            // Por ahora, simulamos una miniatura vacía.
            finalGalleryList.add({'type': 'video', 'url': url, 'thumbnailUrl': ''});
          }
        } else if (item.containsKey('url')) {
          // Es un archivo existente, solo conservamos el mapa
          finalGalleryList.add(item);
        }
      }
      // --- FIN LÓGICA DE SUBIDA MODIFICADA ---

      // 3. Construir el Modelo de Producto
      final product = ProductModel(
        id: widget.productToEdit?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0.0,
        expiryDate: _expiryDate != null ? Timestamp.fromDate(_expiryDate!) : null,
        createdAt: widget.productToEdit?.createdAt ?? Timestamp.now(),
        imageUrl: imageUrl, // La imagen principal
        promoPrice: double.tryParse(_promoPriceController.text),
        promoText: _promoTextController.text.trim().isNotEmpty ? _promoTextController.text.trim() : null,
        categoryId: _selectedCategoryId,
        quantity: int.tryParse(_quantityController.text.trim()), // --- NUEVO ---
        mediaGallery: finalGalleryList, // --- NUEVO ---
      );

      // 4. Guardar en Firestore
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
    // ... (Esta función no necesita cambios)
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
        // OJO: Aquí deberías también borrar todos los archivos de
        // Storage (imagen principal, galería) para ahorrar costos.
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
    
    // --- NUEVO: Lógica de Plan ---
    // Simulación del plan del usuario. En tu app real,
    // obtendrías esto del UserModel (ej: widget.user.planType == 'pro')
    final bool isProPlan = widget.user.planType == 'pro'; // O 'premium', etc.
    // --- FIN NUEVO ---
    
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
                  title: 'Imagen Principal', // --- NUEVO ---
                  onTap: _pickMainImage, // --- MODIFICADO ---
                  imageFile: _mainImageFile,
                  existingImageUrl: widget.productToEdit?.imageUrl,
                ),
                const SizedBox(height: 32),
                
                // --- SECCIÓN DE GALERÍA MULTIMEDIA (NUEVA) ---
                Text('Galería Multimedia (Opcional)', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Añade un carrusel de fotos o un video corto. Los videos son solo para planes PRO.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                const SizedBox(height: 16),
                _buildGalleryGrid(isProPlan),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Añadir Fotos'),
                        onPressed: _isUploading ? null : _pickGalleryImages,
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: surfaceColor)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(isProPlan ? Icons.video_call_outlined : Icons.lock_outline),
                        label: const Text('Añadir Video'),
                        onPressed: _isUploading || !isProPlan ? null : _pickGalleryVideo,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isProPlan ? Colors.white : Colors.grey,
                          side: BorderSide(color: isProPlan ? surfaceColor : Colors.grey.withOpacity(0.5))
                        ),
                      ),
                    ),
                  ],
                ),
                // --- FIN DE SECCIÓN DE GALERÍA ---

                const SizedBox(height: 32),
                Text('Detalles del Producto', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
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
                Row( // --- NUEVO: Fila para Precio y Cantidad ---
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _priceController,
                        style: const TextStyle(color: Colors.white),
                        decoration: inputDecoration.copyWith(labelText: 'Precio Original', prefixText: '\$ '),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value!.isEmpty) return 'Este campo es requerido';
                          if (double.tryParse(value) == null) return 'Número inválido';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: TextFormField( // --- NUEVO: Campo de Cantidad ---
                        controller: _quantityController,
                        style: const TextStyle(color: Colors.white),
                        decoration: inputDecoration.copyWith(labelText: 'Cantidad', hintText: 'Stock'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
                            return 'Inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text('Promoción (Opcional)', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _promoPriceController,
                  // ... (resto del campo de promoción no cambia)
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
                  // ... (resto del campo de texto de promoción no cambia)
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration.copyWith(labelText: 'Texto de Promoción (ej: ¡Oferta!, 20% OFF)'),
                ),
                const SizedBox(height: 24),
                
                InputDecorator(
                  // ... (resto del selector de fecha no cambia)
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
                    // ... (resto del botón de guardar no cambia)
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

  // --- NUEVO: Widget para la grilla de la galería ---
  Widget _buildGalleryGrid(bool isProPlan) {
    if (_galleryItems.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text('Añade fotos o un video a tu galería.', style: TextStyle(color: Colors.white38)),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _galleryItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final item = _galleryItems[index];
        final bool isVideo = item['type'] == 'video';
        
        ImageProvider? imageProvider;
        if (item.containsKey('file')) {
          // Es un XFile nuevo
          if (!isVideo) {
            imageProvider = FileImage(File(item['file'].path));
          }
        } else if (item.containsKey('url')) {
          // Es un URL existente
          String url = isVideo ? item['thumbnailUrl'] : item['url'];
          if (url.isNotEmpty) {
            imageProvider = NetworkImage(url);
          }
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Contenedor de la imagen
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF2D2D5A),
                image: imageProvider != null 
                    ? DecorationImage(image: imageProvider, fit: BoxFit.cover) 
                    : null,
              ),
              // Icono para videos o si la imagen falla
              child: (isVideo || imageProvider == null) 
                  ? Center(child: Icon(isVideo ? Icons.play_circle_fill : Icons.image_not_supported, color: Colors.white70, size: 30))
                  : null,
            ),
            // Botón de eliminar
            Positioned(
              top: -8,
              right: -8,
              child: GestureDetector(
                onTap: () => _removeGalleryItem(index),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  // --- FIN NUEVO ---
}

/// Widget de selector de imagen rediseñado con estilo "Cyber Glow".
class _ImagePickerWidget extends StatelessWidget {
  final VoidCallback onTap;
  final XFile? imageFile;
  final String? existingImageUrl;
  final String title; // --- NUEVO ---

  const _ImagePickerWidget({
    required this.onTap,
    required this.title, // --- NUEVO ---
    this.imageFile,
    this.existingImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);
    
    return Column( // --- MODIFICADO: Envuelto en Column ---
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Center(
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
        ),
      ],
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
  // ... (Este widget no necesita cambios)
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