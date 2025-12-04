// ignore_for_file: deprecated_member_use, use_build_context_synchronously, dead_code
import 'dart:io';
// Eliminamos el import duplicado de cloud_firestore aquí
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart'; // Versión 3.0.0
import 'package:video_thumbnail/video_thumbnail.dart'; 
import 'package:path_provider/path_provider.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:uuid/uuid.dart'; 

// --- Modelos y Servicios ---
import 'package:proveedor_servicly_app/core/models/category_model.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/category_service.dart';
import 'package:proveedor_servicly_app/core/services/product_service.dart';
import 'package:proveedor_servicly_app/core/services/storage_service.dart';
// Usamos el alias para diferenciar tipos de datos
import 'package:cloud_firestore/cloud_firestore.dart' as cloud_firestore; 

class AddEditProductScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // CORRECCIÓN 1: En la versión 3.0.0+, builder recibe directamente (context)
    return ShowCaseWidget(
      builder: (context) => _AddEditProductContent(
        user: user,
        productToEdit: productToEdit,
        preselectedCategory: preselectedCategory,
      ),
    );
  }
}

class _AddEditProductContent extends StatefulWidget {
  final UserModel user;
  final ProductModel? productToEdit;
  final CategoryModel? preselectedCategory;

  const _AddEditProductContent({
    required this.user,
    this.productToEdit,
    this.preselectedCategory,
  });

  @override
  State<_AddEditProductContent> createState() => _AddEditProductContentState();
}

class _AddEditProductContentState extends State<_AddEditProductContent> {
  final _formKey = GlobalKey<FormState>();
  
  // --- KEYS PARA EL TOUR (SHOWCASE) ---
  final GlobalKey _oneKey = GlobalKey(); // Imagen principal
  final GlobalKey _twoKey = GlobalKey(); // Nombre
  final GlobalKey _threeKey = GlobalKey(); // IA Descripción
  final GlobalKey _fourKey = GlobalKey(); // Inventario/Costos
  final GlobalKey _fiveKey = GlobalKey(); // Botón Guardar

  // Controladores
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _promoPriceController;
  late final TextEditingController _promoTextController;
  late final TextEditingController _quantityController; 
  late final TextEditingController _costController;
  late final TextEditingController _skuController;
  late final TextEditingController _inventoryCategoryController;

  DateTime? _expiryDate;
  XFile? _mainImageFile;
  bool _isUploading = false;
  bool _isGeneratingAI = false; 
  String? _selectedCategoryId;

  List<Map<String, dynamic>> _galleryItems = [];

  bool get _isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    
    // Iniciar el tour si es la primera vez
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndStartShowCase());
  }

  void _initializeControllers() {
    final product = widget.productToEdit;
    _nameController = TextEditingController(text: product?.name);
    _descriptionController = TextEditingController(text: product?.description);
    _priceController = TextEditingController(text: product?.price.toString());
    _promoPriceController = TextEditingController(text: product?.promoPrice?.toString() ?? '');
    _promoTextController = TextEditingController(text: product?.promoText ?? '');
    _quantityController = TextEditingController(text: product?.quantity?.toString() ?? '');
    _costController = TextEditingController(text: product?.cost.toString() ?? '0.0'); 
    _skuController = TextEditingController(text: product?.sku ?? '');
    _inventoryCategoryController = TextEditingController(text: product?.category ?? 'General');
    _expiryDate = product?.expiryDate?.toDate(); 
    _selectedCategoryId = product?.categoryId ?? widget.preselectedCategory?.id;
    _galleryItems = List<Map<String, dynamic>>.from(product?.mediaGallery ?? []);
  }

  // --- LÓGICA DEL TOUR ---
  Future<void> _checkAndStartShowCase() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenTutorial = prefs.getBool('hasSeenAddProductTutorial') ?? false;

    if (!hasSeenTutorial) {
      ShowCaseWidget.of(context).startShowCase([_oneKey, _twoKey, _threeKey, _fourKey, _fiveKey]);
      prefs.setBool('hasSeenAddProductTutorial', true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _promoPriceController.dispose();
    _promoTextController.dispose();
    _quantityController.dispose();
    _costController.dispose();
    _skuController.dispose();
    _inventoryCategoryController.dispose();
    super.dispose();
  }

  // --- IA GENERADOR DE DESCRIPCIÓN ---
  Future<void> _generateAIDescription() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escribe un nombre primero para que la IA tenga contexto.')));
      return;
    }

    setState(() => _isGeneratingAI = true);
    
    // SIMULACIÓN
    await Future.delayed(const Duration(seconds: 2)); 
    
    final productName = _nameController.text;
    final generatedText = "✨ ¡Descubre el nuevo $productName! Diseñado para ofrecerte la mejor calidad y estilo. Ideal para quienes buscan durabilidad y confort en su día a día. ¡No te quedes sin el tuyo!";

    setState(() {
      _descriptionController.text = generatedText;
      _isGeneratingAI = false;
    });
  }

  // --- SKU AUTOMÁTICO ---
  void _generateAutoSKU() {
    String prefix = _nameController.text.length >= 3 
        ? _nameController.text.substring(0, 3).toUpperCase() 
        : 'PRO';
    String uniqueId = const Uuid().v4().substring(0, 6).toUpperCase();
    setState(() {
      _skuController.text = "$prefix-$uniqueId";
    });
  }

  // --- IMÁGENES Y VIDEO CON MINIATURA ---
  Future<void> _pickMainImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) setState(() => _mainImageFile = image);
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
      // Obtenemos el directorio temporal
      final tempDir = await getTemporaryDirectory();
      
      // Generamos el archivo de la miniatura directamente
      final String? thumbPath = await VideoThumbnail.thumbnailFile(
        video: video.path,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 128, // Tamaño pequeño para que cargue rápido
        quality: 75,
      );

      setState(() {
        _galleryItems.add({
          'type': 'video', 
          'file': video,
          'thumbnailPath': thumbPath // Ahora esto es una ruta de archivo segura
        });
      });
    }
  }

  void _removeGalleryItem(int index) {
    setState(() => _galleryItems.removeAt(index));
  }

  // --- GUARDAR PRODUCTO ---
  Future<void> _saveProduct() async {
    // 1. Ocultar teclado para evitar errores de foco
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate() || _isUploading) return;
    
    setState(() => _isUploading = true);

    // 2. Guardar referencias al inicio (Contexto Seguro)
    final storageService = context.read<StorageService>();
    final productService = context.read<ProductService>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      // --- SUBIDA DE IMÁGENES ---
      
      // A. Imagen Principal
      String imageUrl = widget.productToEdit?.imageUrl ?? '';
      if (_mainImageFile != null) {
        imageUrl = await storageService.uploadProductImage(
          imageFile: _mainImageFile!,
          userId: widget.user.uid,
        );
      }

      // B. Galería
      List<Map<String, dynamic>> finalGalleryList = [];
      for (var item in _galleryItems) {
        if (item.containsKey('file')) {
          XFile file = item['file'];
          String fileType = item['type'];
          
          // Subimos el archivo
          String url = await storageService.uploadGalleryMedia(
            file: file, 
            userId: widget.user.uid, 
            type: fileType
          );
          
          finalGalleryList.add({
            'type': fileType, 
            'url': url, 
            // Si hay miniatura local, idealmente la subiríamos, 
            // por ahora dejamos vacío para no bloquear
            'thumbnailUrl': '' 
          });
        } else if (item.containsKey('url')) {
          // Si ya existía (edición), lo mantenemos
          finalGalleryList.add(item);
        }
      }

      // --- CREACIÓN DEL MODELO ---
      
      // Función auxiliar para limpiar precios (cambiar coma por punto y evitar crash)
      double parsePrice(String value) {
        if (value.isEmpty) return 0.0;
        return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
      }

      final product = ProductModel(
        id: widget.productToEdit?.id ?? '',
        providerId: widget.user.uid,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        
        // Usamos la función segura para números
        price: parsePrice(_priceController.text),
        promoPrice: parsePrice(_promoPriceController.text),
        cost: parsePrice(_costController.text),
        
        quantity: int.tryParse(_quantityController.text.trim()) ?? 0,
        
        categoryId: _selectedCategoryId,
        imageUrl: imageUrl,
        mediaGallery: finalGalleryList,
        
        promoText: _promoTextController.text.trim().isNotEmpty ? _promoTextController.text.trim() : null,
        expiryDate: _expiryDate != null ? cloud_firestore.Timestamp.fromDate(_expiryDate!) : null,
        createdAt: widget.productToEdit?.createdAt ?? cloud_firestore.Timestamp.now(),
        
        sku: _skuController.text.trim(),
        category: _inventoryCategoryController.text.trim(),
        
        fixedCostSnapshot: widget.productToEdit?.fixedCostSnapshot ?? 0.0,
        wholesalePrice: 0.0, 
        ambassadorPrice: 0.0, 
        minStock: 5,
      );

      // --- GUARDADO EN FIRESTORE ---
      if (_isEditing) {
        await productService.updateProduct(widget.user.uid, product);
        messenger.showSnackBar(const SnackBar(content: Text('Producto actualizado exitosamente'), backgroundColor: Colors.green));
      } else {
        await productService.addProduct(widget.user.uid, product);
        messenger.showSnackBar(const SnackBar(content: Text('Producto creado exitosamente'), backgroundColor: Colors.green));
      }

      // Cerrar pantalla si es posible
      if (navigator.canPop()) navigator.pop();

    } catch (e, stackTrace) {
      // Logueamos el error real en consola
      debugPrint("Error guardando producto: $e");
      debugPrint("Stacktrace: $stackTrace");
      
      messenger.showSnackBar(SnackBar(
        content: Text('Error al guardar: ${e.toString()}'), 
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ));
    } finally {
      if(mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);
    final isProPlan = true; 
    
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
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                // CORRECCIÓN 2: ShowCase -> Showcase (c minúscula)
                Showcase(
                  key: _oneKey,
                  title: 'Foto de Portada',
                  description: 'Sube la mejor foto de tu producto. ¡Es lo primero que verán!',
                  child: _ImagePickerWidget(
                    title: 'Imagen Principal',
                    onTap: _pickMainImage,
                    imageFile: _mainImageFile,
                    existingImageUrl: widget.productToEdit?.imageUrl,
                  ),
                ),
                
                const SizedBox(height: 32),
                Text('Galería Multimedia', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildGalleryGrid(),
                const SizedBox(height: 16),
                
                // Botones Galería (Fotos / Video)
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
                        // isProPlan es true, pero flutter avisa dead code porque está hardcoded. Lo ignoramos.
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
                
                // CORRECCIÓN 2: ShowCase -> Showcase
                Showcase(
                  key: _twoKey,
                  title: 'Nombre Claro',
                  description: 'Usa un nombre corto y descriptivo.',
                  child: TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: inputDecoration.copyWith(labelText: 'Nombre'),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(height: 16),
                
                _CategorySelector(
                  user: widget.user,
                  initialCategoryId: _selectedCategoryId,
                  onChanged: (id) => setState(() => _selectedCategoryId = id),
                  inputDecoration: inputDecoration,
                ),
                const SizedBox(height: 16),
                
                // CORRECCIÓN 2: ShowCase -> Showcase
                Showcase(
                  key: _threeKey,
                  title: 'IA Mágica',
                  description: 'Toca la varita mágica y la IA escribirá una descripción vendedora por ti.',
                  child: TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 4,
                    decoration: inputDecoration.copyWith(
                      labelText: 'Descripción',
                      alignLabelWithHint: true,
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: _isGeneratingAI 
                          ? const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2))
                          : IconButton(
                              icon: const Icon(Icons.auto_awesome, color: accentColor),
                              tooltip: 'Generar con IA',
                              onPressed: _generateAIDescription,
                            ),
                      ),
                    ),
                  ),
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
                
                // CORRECCIÓN 2: ShowCase -> Showcase
                Showcase(
                  key: _fourKey,
                  title: 'Control Total',
                  description: 'Gestiona tus costos y genera códigos SKU automáticamente.',
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10)
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined, color: accentColor, size: 20),
                            const SizedBox(width: 8),
                            Text('Datos de Costos e Inventario', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _costController,
                          style: const TextStyle(color: Colors.white),
                          decoration: inputDecoration.copyWith(
                            labelText: 'Costo Unitario', 
                            prefixText: '\$ ',
                            fillColor: const Color(0xFF1A1A2E) 
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                                child: TextFormField(
                                  controller: _skuController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: inputDecoration.copyWith(
                                    labelText: 'SKU / Código',
                                    fillColor: const Color(0xFF1A1A2E),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.qr_code_2, color: accentColor),
                                      onPressed: _generateAutoSKU,
                                      tooltip: 'Generar SKU Automático',
                                    )
                                  ),
                                ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                                child: TextFormField(
                                  controller: _inventoryCategoryController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: inputDecoration.copyWith(
                                    labelText: 'Ubicación / Cat.',
                                    fillColor: const Color(0xFF1A1A2E)
                                  ),
                                ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                TextFormField(
                  controller: _promoPriceController,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration.copyWith(labelText: 'Precio Promo (Opcional)', prefixText: '\$ '),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 32),
                
                // CORRECCIÓN 2: ShowCase -> Showcase
                Showcase(
                  key: _fiveKey,
                  title: '¡Todo listo!',
                  description: 'Guarda tu producto para publicarlo en la tienda.',
                  child: SizedBox(
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryGrid() {
    if (_galleryItems.isEmpty) return const SizedBox.shrink();
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _galleryItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemBuilder: (context, index) {
        final item = _galleryItems[index];
        ImageProvider? img;
        
        if (item['type'] == 'image') {
          if (item.containsKey('file')) {
             img = FileImage(File((item['file'] as XFile).path));
          } else {
             img = NetworkImage(item['url']);
          }
        } else if (item['type'] == 'video') {
          if (item.containsKey('thumbnailPath') && item['thumbnailPath'] != null) {
            img = FileImage(File(item['thumbnailPath']));
          } else if (item.containsKey('thumbnailUrl') && item['thumbnailUrl'].toString().isNotEmpty) {
            img = NetworkImage(item['thumbnailUrl']);
          } else {
             img = null; 
          }
        }
        
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
                image: img != null ? DecorationImage(image: img, fit: BoxFit.cover) : null,
              ),
              child: item['type'] == 'video' 
                ? const Center(child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 30)) 
                : null,
            ),
            Positioned(
              top: 2, right: 2,
              child: GestureDetector(
                onTap: () => _removeGalleryItem(index),
                child: Container(
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 18)
                ),
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
     if (imageFile != null) return ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(File(imageFile!.path), fit: BoxFit.cover));
     if (existingImageUrl != null && existingImageUrl!.isNotEmpty) return ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(existingImageUrl!, fit: BoxFit.cover));
     return const Icon(Icons.add_a_photo, color: Colors.white54, size: 40);
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