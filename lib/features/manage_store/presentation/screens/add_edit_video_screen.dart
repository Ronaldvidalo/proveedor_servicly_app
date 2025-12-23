import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/models/video_showcase_model.dart';
import 'package:proveedor_servicly_app/core/services/storage_service.dart';
import 'package:proveedor_servicly_app/core/services/video_service.dart';
import 'package:path/path.dart' as p;

/// Pantalla para que el proveedor suba un nuevo video o edite uno existente.
class AddEditVideoScreen extends StatefulWidget {
  final UserModel user;
  final VideoShowcaseModel? videoToEdit; // Para permitir la edición

  const AddEditVideoScreen({
    super.key,
    required this.user,
    this.videoToEdit,
  });

  @override
  State<AddEditVideoScreen> createState() => _AddEditVideoScreenState();
}

class _AddEditVideoScreenState extends State<AddEditVideoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  bool _isPromoted = false;
  bool _isLoading = false;
  double _uploadProgress = 0.0; // Progreso de subida (0.0 a 1.0)

  // Archivos locales seleccionados por el usuario
  XFile? _thumbnailFile;
  XFile? _videoFile;

  // URLs existentes (para el modo de edición)
  String? _existingThumbnailUrl;
  String? _existingVideoUrl;

  bool get _isEditing => widget.videoToEdit != null;

  @override
  void initState() {
    super.initState();
    final video = widget.videoToEdit;
    _titleController = TextEditingController(text: video?.title ?? '');
    _isPromoted = video?.isPromoted ?? false;
    _existingThumbnailUrl = video?.thumbnailUrl;
    _existingVideoUrl = video?.videoUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  /// 1. Lógica para seleccionar la MINIATURA
  Future<void> _pickThumbnail() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // Comprime la miniatura
    );
    if (image != null) {
      setState(() => _thumbnailFile = image);
    }
  }

  /// 2. Lógica para seleccionar el VIDEO
  Future<void> _pickVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    
    if (video != null) {
      // Validación de tamaño (Máx 50MB)
      final file = File(video.path);
      final sizeInBytes = await file.length();
      final sizeInMb = sizeInBytes / (1024 * 1024);

      if (sizeInMb > 50) {
        _showSnackbar('El video es demasiado pesado (Máx 50MB).', isError: true);
        return;
      }

      setState(() => _videoFile = video);
    }
  }

  /// 3. Lógica para GUARDAR
  Future<void> _saveVideo() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    // Validación de archivos
    if (_videoFile == null && _existingVideoUrl == null) {
      _showSnackbar('Debes seleccionar un archivo de video.', isError: true);
      return;
    }
    if (_thumbnailFile == null && _existingThumbnailUrl == null) {
      _showSnackbar('Debes seleccionar una imagen de miniatura.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
    });

    final storageService = context.read<StorageService>();
    final videoService = context.read<VideoService>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      String newThumbnailUrl = _existingThumbnailUrl ?? '';
      String newVideoUrl = _existingVideoUrl ?? '';

      // Paso 1: Subir la miniatura (si hay una nueva)
      if (_thumbnailFile != null) {
        final thumbName = '${DateTime.now().millisecondsSinceEpoch}${p.extension(_thumbnailFile!.name)}';
        final thumbPath = 'videoShowcases/${widget.user.uid}/thumbnails/$thumbName';
        newThumbnailUrl = await storageService.uploadFileWithProgress(
          File(_thumbnailFile!.path),
          thumbPath,
          (progress) {
             // Asignamos una pequeña parte del progreso total a la miniatura (ej. 10%)
             if (mounted) setState(() => _uploadProgress = progress * 0.1);
          }, 
        );
      }

      // Paso 2: Subir el video (si hay uno nuevo)
      if (_videoFile != null) {
        final videoName = '${DateTime.now().millisecondsSinceEpoch}${p.extension(_videoFile!.name)}';
        final videoPath = 'videoShowcases/${widget.user.uid}/videos/$videoName';
        newVideoUrl = await storageService.uploadFileWithProgress(
          File(_videoFile!.path),
          videoPath,
          (progress) {
             // El video representa el 90% restante del progreso
             if (mounted) setState(() => _uploadProgress = 0.1 + (progress * 0.9));
          }, 
        );
      }

      // Paso 3: Guardar en Firestore
      if (_isEditing) {
        // Modo Edición: Actualizar
        final dataToUpdate = {
          'title': _titleController.text.trim(),
          'thumbnailUrl': newThumbnailUrl,
          'videoUrl': newVideoUrl,
          'isPromoted': _isPromoted,
        };
        await videoService.updateVideoShowcase(widget.videoToEdit!.id, dataToUpdate);
        messenger.showSnackBar(const SnackBar(content: Text('Video actualizado con éxito.'), backgroundColor: Colors.green));
      } else {
        // Modo Creación: Añadir
        final newVideo = VideoShowcaseModel(
          id: '', // Firestore lo generará
          providerId: widget.user.uid,
          videoUrl: newVideoUrl,
          thumbnailUrl: newThumbnailUrl,
          title: _titleController.text.trim(),
          createdAt: Timestamp.now(),
          isActive: true,
          isPromoted: _isPromoted,
        );
        await videoService.addVideoShowcase(newVideo);
        messenger.showSnackBar(const SnackBar(content: Text('Video añadido con éxito.'), backgroundColor: Colors.green));
      }

      navigator.pop(); // Volver a ManageStoreScreen

    } catch (e) {
      _showSnackbar('Error al guardar el video: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
    ));
  }

  /// 4. Interfaz de Usuario (UI)
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
        title: Text(_isEditing ? 'Editar Video' : 'Añadir Video'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // --- Selector de Miniatura ---
            _buildThumbnailPicker(context, surfaceColor, accentColor),
            
            const SizedBox(height: 24),

            // --- Selector de Video ---
            _buildVideoPicker(context, surfaceColor, accentColor),

            const SizedBox(height: 32),

            // --- Campo de Título ---
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: inputDecoration.copyWith(
                labelText: 'Título del Video',
                hintText: 'Ej: ¡Nuevo Servicio de Plomería!',
              ),
              validator: (value) => (value == null || value.isEmpty) ? 'El título es obligatorio' : null,
            ),

            const SizedBox(height: 24),

            // --- ¡LÓGICA DE NEGOCIO! ---
            _buildPromoSwitch(surfaceColor, accentColor),

            const SizedBox(height: 48),

            // --- Barra de Progreso (si está cargando) ---
            if (_isLoading)
               Padding(
                 padding: const EdgeInsets.only(bottom: 16.0),
                 child: Column(
                   children: [
                     LinearProgressIndicator(
                       value: _uploadProgress,
                       backgroundColor: surfaceColor,
                       color: accentColor,
                       borderRadius: BorderRadius.circular(4),
                     ),
                     const SizedBox(height: 8),
                     Text(
                       "Subiendo... ${(_uploadProgress * 100).toInt()}%",
                       style: const TextStyle(color: Colors.white70, fontSize: 12),
                     )
                   ],
                 ),
               ),

            // --- Botón de Guardar ---
            FilledButton.icon(
              onPressed: _isLoading ? null : _saveVideo,
              icon: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                  : Icon(_isEditing ? Icons.save_alt_outlined : Icons.add_circle_outline),
              label: Text(_isEditing ? 'Guardar Cambios' : 'Subir Video'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget auxiliar para el interruptor de "Promocionar"
  Widget _buildPromoSwitch(Color surfaceColor, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile.adaptive(
        title: const Text(
          'Promocionar este video',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          _isPromoted
              ? 'Este video aparecerá en la sección "Descubrir". (Requiere pago)'
              : 'Solo tus seguidores lo verán en su feed.',
          style: TextStyle(color: _isPromoted ? accentColor.withValues(alpha: 200) : Colors.white70),
        ),
        value: _isPromoted,
        onChanged: (newValue) async {
          if (newValue) {
            // Mostrar diálogo de confirmación
            final bool? confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: surfaceColor,
                title: const Text("Confirmar Promoción", style: TextStyle(color: Colors.white)),
                content: const Text(
                  "Promocionar este video tiene un costo de \$5.00 USD. ¿Deseas continuar a la pasarela de pago?",
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("Cancelar", style: TextStyle(color: Colors.white54)),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: FilledButton.styleFrom(backgroundColor: accentColor),
                    child: const Text("Aceptar y Pagar", style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              setState(() => _isPromoted = true);
            }
          } else {
            setState(() => _isPromoted = false);
          }
        },
        activeTrackColor: accentColor,
      ),
    );
  }

  /// Widget auxiliar para el selector de video
  Widget _buildVideoPicker(BuildContext context, Color surfaceColor, Color accentColor) {
    bool hasVideo = _videoFile != null || (_existingVideoUrl != null && _existingVideoUrl!.isNotEmpty);
    
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Archivo de Video',
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
       focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accentColor, width: 2)),
      ),
      child: InkWell(
        onTap: _pickVideo,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  hasVideo
                      ? (_videoFile?.name ?? 'Video cargado')
                      : 'Toca para seleccionar un video (.mp4)',
                  style: TextStyle(color: hasVideo ? Colors.greenAccent : Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(hasVideo ? Icons.check_circle : Icons.video_call_rounded, color: hasVideo ? Colors.greenAccent : accentColor),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget auxiliar para el selector de miniatura
  Widget _buildThumbnailPicker(BuildContext context, Color surfaceColor, Color accentColor) {
    ImageProvider? image;
    if (_thumbnailFile != null) {
      image = FileImage(File(_thumbnailFile!.path));
    } else if (_existingThumbnailUrl != null && _existingThumbnailUrl!.isNotEmpty) {
      image = NetworkImage(_existingThumbnailUrl!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Miniatura del Video', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: _pickThumbnail,
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withValues(alpha: 150), width: 2),
                image: image != null ? DecorationImage(image: image, fit: BoxFit.cover) : null,
              ),
              child: image == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 48, color: accentColor),
                        const SizedBox(height: 12),
                        const Text('Añadir Miniatura (Requerido)', style: TextStyle(color: Colors.white70)),
                      ],
                    )
                  : Stack(
                    children: [
                      // Velo para el botón de editar
                      Container(decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12))),
                      const Center(
                        child: Icon(Icons.edit, color: Colors.white, size: 40),
                      ),
                    ],
                  ),
            ),
          ),
        ),
      ],
    );
  }
}