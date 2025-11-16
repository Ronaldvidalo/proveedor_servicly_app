import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint
import 'package:path/path.dart' as p;

/// Un servicio para manejar las operaciones de subida y borrado de archivos a Firebase Storage.
class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  // --- MÉTODO AÑADIDO PARA EL COMPROBANTE DE PAGO ---
  /// Sube un archivo simple (ej. comprobante de pago) a una ruta específica.
  /// 
  /// Este es el método que faltaba y es invocado por CheckoutScreen.
  Future<String> uploadFile(File file, String path) async {
    try {
      final ref = _storage.ref(path);
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) debugPrint('[StorageService] Error al subir archivo simple: $e');
      rethrow;
    }
  }
  // --- FIN DEL MÉTODO AÑADIDO ---

  /// Sube un archivo a Firebase Storage y reporta el progreso.
  Future<String> uploadFileWithProgress(
    File file,
    String path,
    Function(double) onProgress,
  ) async {
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

  /// Sube la imagen principal de un producto a Firebase Storage.
  Future<String> uploadProductImage(
      {required XFile imageFile, required String userId}) async {
    try {
      // --- RUTA MODIFICADA ---
      // Ahora guarda los productos en una carpeta raíz 'products'
      // para mantenerlos separados de la data del usuario.
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(imageFile.path)}';
      final path = 'products/$userId/main_images/$fileName';
      // --- FIN DE MODIFICACIÓN ---

      final ref = _storage.ref(path);
      final uploadTask = await ref.putFile(File(imageFile.path));
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) debugPrint('[StorageService] Error al subir la imagen del producto: $e');
      rethrow;
    }
  }

  /// Sube un archivo (imagen o video) a la galería de un producto.
  Future<String> uploadGalleryMedia({
    required XFile file,
    required String userId,
    required String type, // 'image' o 'video'
  }) async {
    try {
      // 1. Crear un nombre de archivo único
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}';
      
      // 2. Definir la ruta en Storage (coherente con uploadProductImage)
      final String folderType = type == 'video' ? 'videos' : 'images';
      final String storagePath = 'products/$userId/gallery/$folderType/$fileName';
      final ref = _storage.ref(storagePath);

      // 3. Subir el archivo
      final uploadTask = await ref.putFile(File(file.path));

      // 4. Obtener la URL de descarga
      final String downloadUrl = await uploadTask.ref.getDownloadURL();
      
      return downloadUrl;

    } on FirebaseException catch (e) {
      // Manejar el error
      debugPrint('[StorageService] Error subiendo a galería ($type): $e');
      rethrow; // Relanzar para que _saveProduct lo atrape
    }
  }

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