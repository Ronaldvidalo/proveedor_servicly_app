import 'dart:io'; // For File
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; // For picking files
// --- VERIFICA ESTE IMPORT ---
import 'package:proveedor_servicly_app/core/models/portfolio_item_model.dart'; // Asegúrate que la ruta sea correcta
import 'package:proveedor_servicly_app/core/models/portfolio_category_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/core/services/storage_service.dart';
// TODO: Import video_player package when implementing video playback
// import 'package:video_player/video_player.dart';

class ManagePortfolioItemsScreen extends StatefulWidget {
  final String userId;
  final PortfolioCategoryModel category;

  const ManagePortfolioItemsScreen({
    super.key,
    required this.userId,
    required this.category,
  });

  @override
  State<ManagePortfolioItemsScreen> createState() => _ManagePortfolioItemsScreenState();
}

class _ManagePortfolioItemsScreenState extends State<ManagePortfolioItemsScreen> {
  late final FirestoreService _firestoreService;
  late final StorageService _storageService;
  final ImagePicker _picker = ImagePicker();

  bool _isUploading = false;
  double? _uploadProgress;

  // Function to pick and upload IMAGE
  Future<void> _pickAndUploadImage() async {
    final XFile? imageFile = await _picker.pickImage(source: ImageSource.gallery);
    if (imageFile == null) return;
    _uploadFile(imageFile, PortfolioItemType.image); // Type should now be recognized
  }

  // Function to pick and upload VIDEO
  Future<void> _pickAndUploadVideo() async {
    final XFile? videoFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (videoFile == null) return;
    _uploadFile(videoFile, PortfolioItemType.video); // Type should now be recognized
  }

  // Generic file upload function
  Future<void> _uploadFile(XFile fileToUpload, PortfolioItemType type) async { // Type should now be recognized
    setState(() {
      _isUploading = true;
      _uploadProgress = null;
    });

    try {
      final File file = File(fileToUpload.path);
      final String fileExtension = fileToUpload.name.split('.').last;
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final String filePath = 'provider_assets/${widget.userId}/portfolio/${widget.category.id}/$fileName';

      final String downloadUrl = await _storageService.uploadFileWithProgress(
        file,
        filePath,
        (progress) {
          setState(() => _uploadProgress = progress);
        },
      );

      // Add item details to Firestore
      await _firestoreService.addPortfolioItem(
        userId: widget.userId,
        categoryId: widget.category.id,
        type: type, // Type should now be recognized
        url: downloadUrl,
        // caption: null, // Add caption later
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${type == PortfolioItemType.image ? "Imagen" : "Video"} subido con éxito.'), backgroundColor: Colors.green), // Type should now be recognized
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = null;
        });
      }
    }
  }

   // --- Dialog to confirm item deletion ---
  void _showDeleteItemConfirmation(PortfolioItemModel item) {
     showDialog(
      context: context,
      builder: (context) {
        bool isLoading = false;
        return StatefulBuilder(builder: (context, setDialogState) {
           return AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: Text('¿Seguro que quieres eliminar este ítem del portafolio?\n\n(El archivo ${item.type == PortfolioItemType.image ? "imagen" : "video"} será eliminado de forma permanente).'), // Type should now be recognized
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
                    // 1. Delete Firestore document
                    await _firestoreService.deletePortfolioItem(widget.userId, item.id);

                    // 2. Delete file from Storage using the NEW method
                    await _storageService.deleteFileByUrl(item.url); // Should now be found

                    if (context.mounted) Navigator.of(context).pop(); // Close dialog
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
        });
      },
    );
  }


  @override
  void initState() {
    super.initState();
    _firestoreService = context.read<FirestoreService>();
    _storageService = context.read<StorageService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Portafolio: ${widget.category.name}')),
      body: Column(
        children: [
          // --- Upload Progress Indicator ---
          if (_isUploading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                   LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 4),
                   Text(
                    _uploadProgress == null
                        ? 'Preparando...'
                        : 'Subiendo... ${(100 * _uploadProgress!).toStringAsFixed(0)}%',
                     style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          // --- Grid of Portfolio Items ---
          Expanded(
            child: StreamBuilder<List<PortfolioItemModel>>(
              stream: _firestoreService.getPortfolioItemsStream(widget.userId, widget.category.id),
              builder: (context, snapshot) {
                // ... (Código del builder sin cambios) ...
                 if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center( /* ... Empty state message ... */ );
                }
                final items = snapshot.data!;
                 return GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _PortfolioItemTile(
                      item: item,
                      onDelete: () => _showDeleteItemConfirmation(item),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // --- Action Buttons ---
      bottomNavigationBar: BottomAppBar(
         child: Padding(
           padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
           child: Row(
            // ... (Botones sin cambios) ...
                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Foto'),
                  onPressed: _isUploading ? null : _pickAndUploadImage,
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.video_call_outlined),
                  label: const Text('Video'),
                  onPressed: _isUploading ? null : _pickAndUploadVideo,
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            ],
           ),
         ),
      ),
    );
  }
}

// --- Widget for each Grid Tile ---
class _PortfolioItemTile extends StatelessWidget {
  final PortfolioItemModel item;
  final VoidCallback onDelete;

  const _PortfolioItemTile({
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GridTile(
      footer: GridTileBar(
        backgroundColor: Colors.black45,
         // --- CORRECCIÓN AQUÍ ---
         title: Text(item.caption ?? '', style: TextStyle(fontSize: 10)), // Usar item.caption
        trailing: IconButton(
          icon: const Icon(Icons.delete_forever, color: Colors.white, size: 18),
          tooltip: 'Eliminar',
          onPressed: onDelete,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.grey.shade300,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
           // --- CORRECCIÓN AQUÍ ---
          child: item.type == PortfolioItemType.image // Usar item.type
              ? Image.network(
                  item.url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.broken_image, color: Colors.grey);
                  },
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: Colors.black87),
                    const Center(child: Icon(Icons.play_circle_outline, color: Colors.white54, size: 40)),
                     // TODO: Implement video thumbnail or player initialization here
                  ],
                ),
        ),
      ),
    );
  }
}