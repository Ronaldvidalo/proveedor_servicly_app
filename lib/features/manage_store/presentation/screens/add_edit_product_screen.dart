// ignore_for_file: deprecated_member_use, use_build_context_synchronously, dead_code
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart'; 
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
  final UserModel? user; 
  final ProductModel? product; 
  final CategoryModel? preselectedCategory;
  
  // --- PARÁMETROS IA SERVI ---
  final String? initialName;
  final double? initialPrice;
  final double? initialStock;
  final String? aiDescription;

  const AddEditProductScreen({
    super.key,
    this.user, 
    this.product, 
    this.preselectedCategory,
    this.initialName,
    this.initialPrice,
    this.initialStock,
    this.aiDescription,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = user ?? context.read<UserModel?>();
    
    if (currentUser == null) {
        return const Scaffold(body: Center(child: Text("Error: Usuario no identificado")));
    }

    return ShowCaseWidget(
      builder: (context) => _AddEditProductContent(
        user: currentUser,
        product: product,
        preselectedCategory: preselectedCategory,
        initialName: initialName,
        initialPrice: initialPrice,
        initialStock: initialStock,
        aiDescription: aiDescription,
      ),
    );
  }
}

class _AddEditProductContent extends StatefulWidget {
  final UserModel user;
  final ProductModel? product;
  final CategoryModel? preselectedCategory;
  
  // Parámetros IA
  final String? initialName;
  final double? initialPrice;
  final double? initialStock;
  final String? aiDescription;

  const _AddEditProductContent({
    required this.user,
    this.product,
    this.preselectedCategory,
    this.initialName,
    this.initialPrice,
    this.initialStock,
    this.aiDescription,
  });

  @override
  State<_AddEditProductContent> createState() => _AddEditProductContentState();
}

class _AddEditProductContentState extends State<_AddEditProductContent> {
  final _formKey = GlobalKey<FormState>();
  
  // --- KEYS PARA EL TOUR (SHOWCASE) ---
  final GlobalKey _oneKey = GlobalKey(); 
  final GlobalKey _twoKey = GlobalKey(); 
  final GlobalKey _threeKey = GlobalKey(); 
  final GlobalKey _fourKey = GlobalKey(); 
  final GlobalKey _fiveKey = GlobalKey(); 

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

  // --- VARIABLES DE ESTRUCTURA DE COSTOS ---
  double _costMaterials = 0;
  double _costLabor = 0;
  double _costOverhead = 0;

  DateTime? _expiryDate;
  XFile? _mainImageFile;
  bool _isUploading = false;
  bool _isGeneratingAI = false; 
  String? _selectedCategoryId;

  List<Map<String, dynamic>> _galleryItems = [];

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndStartShowCase();
        if (widget.aiDescription != null && widget.aiDescription!.isNotEmpty) {
             ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Row(children: [
                        const Icon(Icons.auto_awesome, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(child: Text("Servi: ${widget.aiDescription}")),
                    ]),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 5),
                )
             );
        }
    });
  }

  void _initializeControllers() {
    final product = widget.product;
    
    _nameController = TextEditingController(text: product?.name ?? widget.initialName);
    
    String desc = product?.description ?? '';
    _descriptionController = TextEditingController(text: desc);
    
    String priceText = product?.price.toString() ?? '';
    if (priceText.isEmpty && widget.initialPrice != null && widget.initialPrice! > 0) {
        priceText = widget.initialPrice.toString();
    }
    _priceController = TextEditingController(text: priceText);
    
    _promoPriceController = TextEditingController(text: product?.promoPrice?.toString() ?? '');
    _promoTextController = TextEditingController(text: product?.promoText ?? '');
    
    String stockText = product?.quantity?.toString() ?? '';
    if (stockText.isEmpty && widget.initialStock != null && widget.initialStock! > 0) {
        stockText = widget.initialStock!.toInt().toString(); 
    }
    _quantityController = TextEditingController(text: stockText);
    
    _costController = TextEditingController(text: product?.cost.toString() ?? '0.0'); 
    _skuController = TextEditingController(text: product?.sku ?? '');
    _inventoryCategoryController = TextEditingController(text: product?.category ?? 'General');
    _expiryDate = product?.expiryDate?.toDate(); 
    _selectedCategoryId = product?.categoryId ?? widget.preselectedCategory?.id;
    _galleryItems = List<Map<String, dynamic>>.from(product?.mediaGallery ?? []);
  }

  // --- LÓGICA DE ESTRUCTURA DE COSTOS ---
  void _updateTotalCost() {
    final total = _costMaterials + _costLabor + _costOverhead;
    setState(() {
      _costController.text = total.toStringAsFixed(2);
    });
  }

  void _showCostCalculator(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.calculate_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Text("Estructura de Costos", style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCostInputField("Materiales / Insumos", (v) => _costMaterials = v, theme),
            _buildCostInputField("Mano de Obra", (v) => _costLabor = v, theme),
            _buildCostInputField("Gastos Operativos", (v) => _costOverhead = v, theme),
            Divider(color: theme.dividerColor, height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Costo Total:", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                Text("\$${(_costMaterials + _costLabor + _costOverhead).toStringAsFixed(2)}", 
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCELAR", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
          ),
          FilledButton(
            onPressed: () {
              _updateTotalCost();
              Navigator.pop(context);
            },
            child: const Text("APLICAR"),
          ),
        ],
      ),
    );
  }

  Widget _buildCostInputField(String label, Function(double) onChanged, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
          prefixText: "\$ ",
          isDense: true,
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.dividerColor)),
        ),
        onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
      ),
    );
  }

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

  Future<void> _generateAIDescription() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escribe un nombre primero para que la IA tenga contexto.')));
      return;
    }

    setState(() => _isGeneratingAI = true);
    await Future.delayed(const Duration(seconds: 2)); 
    
    final productName = _nameController.text;
    final generatedText = "✨ ¡Descubre el nuevo $productName! Diseñado para ofrecerte la mejor calidad y estilo. Ideal para quienes buscan durabilidad y confort en su día a día. ¡No te quedes sin el tuyo!";

    setState(() {
      _descriptionController.text = generatedText;
      _isGeneratingAI = false;
    });
  }

  void _generateAutoSKU() {
    String prefix = _nameController.text.length >= 3 
        ? _nameController.text.substring(0, 3).toUpperCase() 
        : 'PRO';
    String uniqueId = const Uuid().v4().substring(0, 6).toUpperCase();
    setState(() {
      _skuController.text = "$prefix-$uniqueId";
    });
  }

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
      final tempDir = await getTemporaryDirectory();
      final String? thumbPath = await VideoThumbnail.thumbnailFile(
        video: video.path,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 128,
        quality: 75,
      );

      setState(() {
        _galleryItems.add({
          'type': 'video', 
          'file': video,
          'thumbnailPath': thumbPath
        });
      });
    }
  }

  void _removeGalleryItem(int index) {
    setState(() => _galleryItems.removeAt(index));
  }

  Future<void> _saveProduct() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _isUploading) return;
    setState(() => _isUploading = true);

    final storageService = context.read<StorageService>();
    final productService = context.read<ProductService>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      String imageUrl = widget.product?.imageUrl ?? '';
      if (_mainImageFile != null) {
        imageUrl = await storageService.uploadProductImage(
          imageFile: _mainImageFile!,
          userId: widget.user.uid,
        );
      }

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
          finalGalleryList.add({'type': fileType, 'url': url, 'thumbnailUrl': ''});
        } else if (item.containsKey('url')) {
          finalGalleryList.add(item);
        }
      }

      double parsePrice(String value) {
        if (value.isEmpty) return 0.0;
        return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
      }

      final product = ProductModel(
        id: widget.product?.id ?? '',
        providerId: widget.user.uid,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: parsePrice(_priceController.text),
        promoPrice: parsePrice(_promoPriceController.text),
        cost: parsePrice(_costController.text),
        quantity: int.tryParse(_quantityController.text.trim()) ?? 0,
        categoryId: _selectedCategoryId,
        imageUrl: imageUrl,
        mediaGallery: finalGalleryList,
        promoText: _promoTextController.text.trim().isNotEmpty ? _promoTextController.text.trim() : null,
        expiryDate: _expiryDate != null ? cloud_firestore.Timestamp.fromDate(_expiryDate!) : null,
        createdAt: widget.product?.createdAt ?? cloud_firestore.Timestamp.now(),
        sku: _skuController.text.trim(),
        category: _inventoryCategoryController.text.trim(),
        fixedCostSnapshot: widget.product?.fixedCostSnapshot ?? 0.0,
        wholesalePrice: 0.0, 
        ambassadorPrice: 0.0, 
        minStock: 5,
      );

      if (_isEditing) {
        await productService.updateProduct(widget.user.uid, product);
        messenger.showSnackBar(const SnackBar(content: Text('Producto actualizado exitosamente'), backgroundColor: Colors.green));
      } else {
        await productService.addProduct(widget.user.uid, product);
        messenger.showSnackBar(const SnackBar(content: Text('Producto creado exitosamente'), backgroundColor: Colors.green));
      }

      if (navigator.canPop()) navigator.pop();

    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error al guardar: ${e.toString()}'), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Producto' : 'Añadir Producto'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // --- WEB LAYOUT (2 COLUMNAS) ---
          if (constraints.maxWidth > 900) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Columna Izquierda: Visuales y Datos Principales
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: _buildLeftColumn(theme, isDark),
                  ),
                ),
                // Columna Derecha: Configuración y Gestión
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
                      color: theme.cardColor.withOpacity(0.3),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: _buildRightColumn(theme, isDark),
                    ),
                  ),
                ),
              ],
            );
          }
          
          // --- MOBILE LAYOUT (1 COLUMNA) ---
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildLeftColumn(theme, isDark),
                  const SizedBox(height: 24),
                  _buildRightColumn(theme, isDark),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // SUB-WIDGETS PARA LAYOUT
  // ===========================================================================

  Widget _buildLeftColumn(ThemeData theme, bool isDark) {
    final onSurfaceColor = theme.colorScheme.onSurface;
    final inputDecoration = _getInputDecoration(theme);

    // En Web, usamos Form separado si es 2 columnas, pero aquí 
    // asumimos que el padre maneja el form en móvil. 
    // En web, envolvemos en Form solo si es necesario, 
    // pero para simplicidad usaremos un solo Form global key.
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Showcase(
          key: _oneKey,
          title: 'Foto de Portada',
          description: 'Sube la mejor foto de tu producto.',
          child: _ImagePickerWidget(
            title: 'Imagen Principal',
            onTap: _pickMainImage,
            imageFile: _mainImageFile,
            existingImageUrl: widget.product?.imageUrl,
            theme: theme,
          ),
        ),
        
        const SizedBox(height: 32),
        Text('Galería Multimedia', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildGalleryGrid(),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Fotos'),
                onPressed: _isUploading ? null : _pickGalleryImages,
                style: OutlinedButton.styleFrom(
                  foregroundColor: onSurfaceColor, 
                  side: BorderSide(color: theme.dividerColor)
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.video_call_outlined),
                label: const Text('Video'),
                onPressed: _isUploading ? null : _pickGalleryVideo,
                style: OutlinedButton.styleFrom(
                  foregroundColor: onSurfaceColor, 
                  side: BorderSide(color: theme.dividerColor)
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),
        Text('Información Básica', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        
        Showcase(
          key: _twoKey,
          title: 'Nombre Claro',
          description: 'Usa un nombre descriptivo.',
          child: TextFormField(
            controller: _nameController,
            style: TextStyle(color: onSurfaceColor),
            decoration: inputDecoration.copyWith(labelText: 'Nombre del Producto'),
            validator: (v) => v!.isEmpty ? 'Requerido' : null,
          ),
        ),
        const SizedBox(height: 16),
        
        Showcase(
          key: _threeKey,
          title: 'IA Mágica',
          description: 'Genera descripciones automáticas.',
          child: TextFormField(
            controller: _descriptionController,
            style: TextStyle(color: onSurfaceColor),
            maxLines: 6,
            decoration: inputDecoration.copyWith(
              labelText: 'Descripción Detallada',
              alignLabelWithHint: true,
              suffixIcon: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: _isGeneratingAI 
                  ? const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton(icon: Icon(Icons.auto_awesome, color: theme.colorScheme.primary), onPressed: _generateAIDescription),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRightColumn(ThemeData theme, bool isDark) {
    final onSurfaceColor = theme.colorScheme.onSurface;
    final inputDecoration = _getInputDecoration(theme);
    final primaryColor = theme.colorScheme.primary;
    
    // Lógica visual de rentabilidad
    final double currentPrice = double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0;
    final double currentCost = double.tryParse(_costController.text.replaceAll(',', '.')) ?? 0;
    final bool isLosingMoney = currentPrice < currentCost && currentCost > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Configuración y Precios', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        _CategorySelector(
          user: widget.user,
          initialCategoryId: _selectedCategoryId,
          onChanged: (id) => setState(() => _selectedCategoryId = id),
          inputDecoration: inputDecoration,
          theme: theme,
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _priceController,
                style: TextStyle(color: onSurfaceColor),
                decoration: inputDecoration.copyWith(labelText: 'Precio', prefixText: '\$ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _quantityController,
                style: TextStyle(color: onSurfaceColor),
                decoration: inputDecoration.copyWith(labelText: 'Stock'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // --- SECCIÓN DE COSTOS ---
        Showcase(
          key: _fourKey,
          title: 'Análisis de Costos',
          description: 'Define tu estructura de costos.',
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isLosingMoney ? Colors.red.withOpacity(0.1) : theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isLosingMoney ? Colors.redAccent : theme.dividerColor.withOpacity(0.1))
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text('Estructura de Costos', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    if (isLosingMoney) const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _costController,
                  style: TextStyle(color: onSurfaceColor),
                  decoration: inputDecoration.copyWith(
                    labelText: 'Costo Unitario', 
                    prefixText: '\$ ',
                    fillColor: theme.scaffoldBackgroundColor,
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calculate_outlined, color: primaryColor),
                      onPressed: () => _showCostCalculator(context),
                      tooltip: 'Abrir Calculadora',
                    )
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                ),
                if (isLosingMoney) Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text("¡Alerta! Estás perdiendo dinero.", style: TextStyle(color: Colors.redAccent.withOpacity(0.8), fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
                child: TextFormField(
                  controller: _skuController,
                  style: TextStyle(color: onSurfaceColor),
                  decoration: inputDecoration.copyWith(
                    labelText: 'SKU / Código',
                    suffixIcon: IconButton(icon: Icon(Icons.qr_code_2, color: primaryColor), onPressed: _generateAutoSKU),
                  ),
                ),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: TextFormField(
                  controller: _inventoryCategoryController,
                  style: TextStyle(color: onSurfaceColor),
                  decoration: inputDecoration.copyWith(labelText: 'Ubicación'),
                ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        TextFormField(
          controller: _promoPriceController,
          style: TextStyle(color: onSurfaceColor),
          decoration: inputDecoration.copyWith(labelText: 'Precio Promo (Opcional)', prefixText: '\$ '),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),

        const SizedBox(height: 32),
        
        Showcase(
          key: _fiveKey,
          title: 'Finalizar',
          description: 'Guarda los cambios.',
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isUploading ? null : _saveProduct,
              icon: _isUploading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : const Icon(Icons.save),
              label: Text(_isEditing ? 'Guardar Cambios' : 'Crear Producto'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _getInputDecoration(ThemeData theme) {
    return InputDecoration(
        filled: true,
        fillColor: theme.cardColor,
        labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.1))
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)
        ), 
        prefixStyle: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16)
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
          } else if (item.containsKey('url')) {
            img = NetworkImage(item['url'] as String);
          }
        } else if (item['type'] == 'video') {
          if (item.containsKey('thumbnailPath') && item['thumbnailPath'] != null) {
            img = FileImage(File(item['thumbnailPath'] as String));
          } else if (item.containsKey('thumbnailUrl') && item['thumbnailUrl'].toString().isNotEmpty) {
            img = NetworkImage(item['thumbnailUrl'] as String);
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
              child: item['type'] == 'video' ? const Center(child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 30)) : null,
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
  final ThemeData theme;

  const _ImagePickerWidget({required this.onTap, required this.title, this.imageFile, this.existingImageUrl, required this.theme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: 150, height: 150,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16), 
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5))
          ),
          child: _buildImage(theme),
        )
      ]),
    );
  }
  
  Widget _buildImage(ThemeData theme) {
      if (imageFile != null) return ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(File(imageFile!.path), fit: BoxFit.cover));
      if (existingImageUrl != null && existingImageUrl!.isNotEmpty) return ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(existingImageUrl!, fit: BoxFit.cover));
      return Icon(Icons.add_a_photo, color: theme.colorScheme.onSurface.withOpacity(0.5), size: 40);
  }
}

class _CategorySelector extends StatelessWidget {
  final UserModel user;
  final String? initialCategoryId;
  final ValueChanged<String?> onChanged;
  final InputDecoration inputDecoration;
  final ThemeData theme;

  const _CategorySelector({
    required this.user, 
    required this.initialCategoryId, 
    required this.onChanged, 
    required this.inputDecoration,
    required this.theme,
  });

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
          dropdownColor: theme.cardColor,
          style: TextStyle(color: theme.colorScheme.onSurface),
          items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
        );
      },
    );
  }
}