// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// Modelos y Servicios
import 'package:proveedor_servicly_app/core/models/portfolio_category_model.dart';
import 'package:proveedor_servicly_app/core/models/portfolio_item_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/core/services/storage_service.dart';

class CatalogPortfolioSectionEditor extends StatefulWidget {
  final String providerId;
  final Color brandColor;

  const CatalogPortfolioSectionEditor({
    super.key,
    required this.providerId,
    required this.brandColor,
  });

  @override
  State<CatalogPortfolioSectionEditor> createState() => _CatalogPortfolioSectionEditorState();
}

class _CatalogPortfolioSectionEditorState extends State<CatalogPortfolioSectionEditor> {
  String? _selectedCategoryId;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          
          // 1. FLUJO DE CATEGORÍAS (Carpetas de Obra)
          StreamBuilder<List<PortfolioCategoryModel>>(
            stream: firestore.getCatalogPortfolioCategoriesStream(widget.providerId),
            builder: (context, snapshot) {
              if (snapshot.hasError) return _buildStatusText("Error al cargar carpetas");
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState("Toca el icono de carpeta para crear tu primera galería técnica");
              }

              final categories = snapshot.data!;
              
              // Sincronización: Selecciona automáticamente la primera si no hay ninguna
              if (_selectedCategoryId == null || !categories.any((c) => c.id == _selectedCategoryId)) {
                _selectedCategoryId = categories.first.id;
              }

              return Column(
                children: [
                  _buildCategoryChips(categories),
                  const SizedBox(height: 16),
                  
                  // 2. GRILLA MULTIMEDIA (Fotos y Videos)
                  _buildMediaGrid(firestore),
                ],
              );
            },
          ),
          const Divider(color: Colors.white10, height: 40, indent: 20, endIndent: 20),
        ],
      ),
    );
  }

  Widget _buildMediaGrid(FirestoreService firestore) {
    return StreamBuilder<List<PortfolioItemModel>>(
      // Escucha solo los items de la categoría seleccionada actualmente
      stream: firestore.getCatalogPortfolioItemsStream(widget.providerId, _selectedCategoryId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildStatusText("Error al proyectar archivos");
        
        final items = snapshot.data ?? [];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, 
              mainAxisSpacing: 8, 
              crossAxisSpacing: 8
            ),
            // El +1 permite que el botón de añadir sea el primer cuadro de la grilla
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return _buildAddMediaButton();
              
              final item = items[index - 1];
              return _buildPortfolioCard(item);
            },
          ),
        );
      },
    );
  }

  // --- COMPONENTES DE INTERFAZ ---

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 10, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Evidencia de Trabajos", 
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          IconButton(
            onPressed: () => _showAddCategoryDialog(context),
            icon: const Icon(Icons.create_new_folder_outlined, color: Color(0xFF00B2B2), size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(List<PortfolioCategoryModel> categories) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSel = _selectedCategoryId == cat.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat.name, style: TextStyle(color: isSel ? Colors.white : Colors.white60, fontSize: 11)),
              selected: isSel,
              onSelected: (val) {
                if (val) setState(() => _selectedCategoryId = cat.id);
              },
              selectedColor: widget.brandColor.withOpacity(0.4),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPortfolioCard(PortfolioItemModel item) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            item.url, 
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) => 
              progress == null ? child : Container(color: Colors.white10, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
            errorBuilder: (_, __, ___) => Container(color: Colors.white10, child: const Icon(Icons.broken_image, color: Colors.white24)),
          ),
        ),
        if (item.type == PortfolioItemType.video)
          const Center(child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 30)),
        
        // Botón de eliminar sobre la imagen
        Positioned(
          top: 4, right: 4,
          child: GestureDetector(
            onTap: () => context.read<FirestoreService>().deleteCatalogPortfolioItem(widget.providerId, item.id),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), 
              child: const Icon(Icons.close, color: Colors.white, size: 12)
            ),
          ),
        )
      ],
    );
  }

  Widget _buildAddMediaButton() {
    return GestureDetector(
      onTap: _isUploading ? null : _showPickerOptions,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03), 
          borderRadius: BorderRadius.circular(10), 
          border: Border.all(color: Colors.white10)
        ),
        child: _isUploading 
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00B2B2)))
          : const Icon(Icons.add_a_photo_outlined, color: Colors.white24),
      ),
    );
  }

  // --- LÓGICA DE NEGOCIO Y DIÁLOGOS ---

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined, color: Colors.white),
              title: const Text("Subir Fotografía", style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(context); _handlePick(true); },
            ),
            ListTile(
              leading: const Icon(Icons.video_collection_outlined, color: Color(0xFF00B2B2)),
              title: const Text("Subir Clip de Video", style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(context); _handlePick(false); },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePick(bool isImage) async {
    if (_selectedCategoryId == null) return;
    
    final picker = ImagePicker();
    final XFile? file = isImage 
        ? await picker.pickImage(source: ImageSource.gallery, imageQuality: 70)
        : await picker.pickVideo(source: ImageSource.gallery);
    
    if (file == null) return;
    
    setState(() => _isUploading = true);
    
    try {
      final storage = context.read<StorageService>();
      final firestore = context.read<FirestoreService>();
      
      final String extension = isImage ? 'jpg' : 'mp4';
      final path = 'catalogs/${widget.providerId}/portfolio/${DateTime.now().millisecondsSinceEpoch}.$extension';
      
      final url = await storage.uploadFile(File(file.path), path);
      
      await firestore.addCatalogPortfolioItem(
        userId: widget.providerId,
        categoryId: _selectedCategoryId!,
        type: isImage ? PortfolioItemType.image : PortfolioItemType.video,
        url: url,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al subir: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showAddCategoryDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Nueva Carpeta de Obra", style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller, 
          style: const TextStyle(color: Colors.white), 
          autofocus: true,
          decoration: const InputDecoration(hintText: "Nombre (ej: Obras 2025)", hintStyle: TextStyle(color: Colors.white24))
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          FilledButton(onPressed: () async {
            if (controller.text.isNotEmpty) {
              await context.read<FirestoreService>().addCatalogPortfolioCategory(widget.providerId, controller.text.trim());
              Navigator.pop(context);
            }
          }, child: const Text("CREAR")),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) => Padding(padding: const EdgeInsets.all(30), child: Center(child: Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white38, fontSize: 12))));
  Widget _buildStatusText(String msg) => Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(msg, style: const TextStyle(color: Colors.white38, fontSize: 11))));
}