import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint

/// Un servicio para manejar las operaciones de subida y borrado de archivos a Firebase Storage.
class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Sube un archivo a Firebase Storage y reporta el progreso.
  Future<String> uploadFileWithProgress(
    File file,
    String path,
    Function(double) onProgress,
  ) async {
    // ... (Código existente sin cambios) ...
        try {
      final ref = _storage.ref(path);
      final uploadTask = ref.putFile(file);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });

      final taskSnapshot = await uploadTask;
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;

    } catch (e) {
      if (kDebugMode) debugPrint('[StorageService] Error al subir archivo con progreso: $e');
      rethrow;
    }
  }

  /// Sube la imagen de un producto a Firebase Storage.
  Future<String> uploadProductImage(
      {required XFile imageFile, required String userId}) async {
    // ... (Código existente sin cambios) ...
        try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      final path = 'users/$userId/products/$fileName';
      final ref = _storage.ref(path);
      final uploadTask = await ref.putFile(File(imageFile.path));
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) debugPrint('[StorageService] Error al subir la imagen del producto: $e');
      rethrow;
    }
  }

  // --- ¡NUEVO MÉTODO AÑADIDO! ---
  /// Elimina un archivo de Firebase Storage usando su URL de descarga.
  Future<void> deleteFileByUrl(String fileUrl) async {
    // Evita intentar borrar si la URL está vacía
    if (fileUrl.isEmpty) {
       if (kDebugMode) debugPrint("[StorageService] deleteFileByUrl: URL vacía, no se intenta borrar.");
      return;
    }
    try {
      // Obtiene la referencia al archivo a partir de su URL
      final Reference ref = _storage.refFromURL(fileUrl);
      // Intenta eliminar el archivo
      await ref.delete();
       if (kDebugMode) debugPrint("[StorageService] Archivo eliminado exitosamente: $fileUrl");
    } on FirebaseException catch (e) {
      // Manejar errores comunes como 'object-not-found' (el archivo ya no existe)
      if (e.code == 'object-not-found') {
         if (kDebugMode) debugPrint("[StorageService] deleteFileByUrl: Archivo no encontrado (puede que ya estuviera borrado): $fileUrl");
      } else {
        // Otros errores (permisos, etc.)
         if (kDebugMode) debugPrint("[StorageService] !! ERROR al eliminar archivo por URL $fileUrl: $e");
         // Decide si quieres relanzar el error o solo registrarlo
         // rethrow;
      }
    } catch (e) {
        // Captura cualquier otro error inesperado
       if (kDebugMode) debugPrint("[StorageService] !! ERROR inesperado al eliminar archivo por URL $fileUrl: $e");
       // rethrow;
    }
  }
}