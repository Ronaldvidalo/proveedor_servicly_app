// /lib/services/image_picker_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickAndEncodeImage() async {
    // 1. Obtener la imagen
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50, // Reducir calidad para reducir el tamaño de la carga (optimización)
    );

    if (image == null) {
      return null; // El usuario canceló
    }

    // 2. Leer los bytes del archivo
    final bytes = await File(image.path).readAsBytes();

    // 3. Codificar los bytes a Base64 String
    // Este string es el que se enviará al Cloud Function
    return base64Encode(bytes);
  }
}
