import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Un servicio para manejar las operaciones de subida de archivos a Firebase Storage.
class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  // --- NUEVO MÉTODO GENÉRICO CON PROGRESO ---
  /// Sube un archivo a Firebase Storage y reporta el progreso.
  ///
  /// [file] El archivo a subir.
  /// [path] La ruta completa en Storage (ej: 'users/uid/videos/video.mp4').
  /// [onProgress] Un callback que recibe el progreso de 0.0 a 1.0.
  Future<String> uploadFileWithProgress(
    File file,
    String path,
    Function(double) onProgress,
  ) async {
    try {
      final ref = _storage.ref(path);
      // Sube el archivo y escucha los eventos
      final uploadTask = ref.putFile(file);

      // Escuchar los eventos de estado para el progreso
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });

      // Esperar a que la tarea se complete
      final taskSnapshot = await uploadTask;
      
      // Obtener la URL de descarga
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;

    } catch (e) {
      print('Error al subir archivo con progreso: $e');
      rethrow;
    }
  }
  // ------------------------------------------

  /// Sube la imagen de un producto a Firebase Storage.
  /// (Este es tu método antiguo, lo mantenemos por compatibilidad)
  Future<String> uploadProductImage(
      {required XFile imageFile, required String userId}) async {
    try {
      // Crea un nombre de archivo único usando la fecha y hora actual.
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      
      // Define la ruta en Firebase Storage.
      final path = 'users/$userId/products/$fileName';

      // Sube el archivo.
      final ref = _storage.ref(path);
      final uploadTask = await ref.putFile(File(imageFile.path));

      // Obtiene la URL de descarga.
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      // En una app real, aquí se registraría el error.
      print('Error al subir la imagen del producto: $e');
      rethrow;
    }
  }
}