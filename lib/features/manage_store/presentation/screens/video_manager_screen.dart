import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/models/video_showcase_model.dart';
import 'package:proveedor_servicly_app/core/services/storage_service.dart';
import 'package:proveedor_servicly_app/core/services/video_service.dart';
import 'package:proveedor_servicly_app/features/manage_store/presentation/screens/add_edit_video_screen.dart';

class VideoManagerScreen extends StatefulWidget {
  final UserModel user;

  const VideoManagerScreen({super.key, required this.user});

  @override
  State<VideoManagerScreen> createState() => _VideoManagerScreenState();
}

class _VideoManagerScreenState extends State<VideoManagerScreen> {
  bool _isDeleting = false; // Para mostrar un loader global al borrar

  /// Lógica para eliminar un video
  Future<void> _deleteVideo(VideoShowcaseModel video) async {
    // 1. Pedir confirmación
    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D5A),
        title: const Text('Confirmar Eliminación', style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro de que quieres eliminar este video? Esta acción no se puede deshacer.',
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

    if (didConfirm != true) return; // El usuario canceló

    // ✅ CORRECCIÓN: Verificar mounted después del await del diálogo
    if (!mounted) return;

    // 2. Mostrar loader
    setState(() => _isDeleting = true);

    // Capturamos los servicios y el messenger ANTES del await para evitar usar el context en un gap asíncrono
    final videoService = context.read<VideoService>();
    final storageService = context.read<StorageService>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      // 3. Eliminar de Firestore
      await videoService.deleteVideoShowcase(video.id);

      // 4. Eliminar archivos de Storage (¡Importante!)
      // Si la URL es válida, intenta borrarla.
      if (video.thumbnailUrl.isNotEmpty) {
        try {
          await storageService.deleteFileByUrl(video.thumbnailUrl);
        } catch (e) {
          debugPrint('No se pudo borrar la miniatura (quizás ya estaba borrada): $e');
        }
      }
      if (video.videoUrl.isNotEmpty) {
         try {
           await storageService.deleteFileByUrl(video.videoUrl);
         } catch (e) {
            debugPrint('No se pudo borrar el video (quizás ya estaba borrado): $e');
         }
      }

      if (mounted) {
        messenger.showSnackBar(const SnackBar(
          content: Text('Video eliminado con éxito.'),
          backgroundColor: Colors.green,
        ));
      }

    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('Error al eliminar el video: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  /// Lógica para editar un video
  void _editVideo(VideoShowcaseModel video) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddEditVideoScreen(
        user: widget.user,
        videoToEdit: video,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);
    final videoService = context.read<VideoService>();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Gestionar Videos'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Mensaje de cabecera
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Aquí puedes ver todos tus videos. Toca el botón "..." en cada video para editarlo o eliminarlo permanentemente.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: StreamBuilder<List<VideoShowcaseModel>>(
                  stream: videoService.getVideoShowcasesByProvider(widget.user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: accentColor));
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
                      );
                    }

                    final videos = snapshot.data ?? [];

                    if (videos.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.video_library_outlined, size: 80, color: Colors.white24),
                            SizedBox(height: 16),
                            Text('Aún no has subido videos.', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          ],
                        ),
                      );
                    }

                    // --- La Grilla de Videos ---
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 columnas
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.6, // Reducimos el alto, antes era 9/16=0.5625, ahora 0.6 es un poco más ancho. Probamos con 0.6 (o incluso 0.7 si queremos más compactos)
                      ),
                      itemCount: videos.length,
                      itemBuilder: (context, index) {
                        final video = videos[index];
                        return _VideoManagerCard(
                          video: video,
                          onEdit: () => _editVideo(video),
                          onDelete: () => _deleteVideo(video),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // Loader global de borrado
          if (_isDeleting)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: accentColor),
                    SizedBox(height: 16),
                    Text('Eliminando video...', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
           Navigator.of(context).push(MaterialPageRoute(
             builder: (_) => AddEditVideoScreen(user: widget.user),
           ));
        },
        backgroundColor: accentColor,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }
}


/// Tarjeta individual para la grilla de gestión de videos
class _VideoManagerCard extends StatelessWidget {
  final VideoShowcaseModel video;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VideoManagerCard({
    required this.video,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Color(0xFF2D2D5A);
    const accentColor = Color(0xFF00BFFF);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        image: video.thumbnailUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(video.thumbnailUrl),
                fit: BoxFit.cover,
                opacity: 0.8,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Gradiente inferior para legibilidad
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(150),
                    Colors.black.withAlpha(220)
                  ],
                  stops: const [0.5, 0.8, 1.0],
                ),
              ),
            ),

            // Título
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Text(
                video.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14, // Fuente un poco más pequeña
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Etiqueta de Promocionado
            if (video.isPromoted)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PROMO',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Menú de Opciones (Editar/Borrar)
            Positioned(
              top: 4,
              right: 4,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                color: surfaceColor,
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, color: Colors.white70),
                        SizedBox(width: 12),
                        Text('Editar', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.redAccent),
                        SizedBox(width: 12),
                        Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}