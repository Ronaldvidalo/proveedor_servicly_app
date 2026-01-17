import 'dart:io';
import 'dart:typed_data'; // Necesario para Uint8List (Web)
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint y kIsWeb
import 'package:path/path.dart' as p;

/// Un servicio para manejar las operaciones de subida y borrado de archivos a Firebase Storage.
class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  // --- NUEVO MÉTODO PARA WEB (SOLUCIÓN AL ERROR DE PANTALLA ROJA) ---
  /// Sube datos crudos (bytes) a una ruta específica. 
  /// Esencial para Flutter Web donde no existen los "Files" tradicionales.
  Future<String> uploadBytes(Uint8List data, String path) async {
    try {
      final ref = _storage.ref(path);
      // En Web usamos putData en lugar de putFile
      final uploadTask = await ref.putData(data);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) debugPrint('[StorageService] Error al subir bytes (Web): $e');
      rethrow;
    }
  }

  // --- NUEVO: MÉTODO PARA WEB CON PROGRESO (Requerido para Checkout) ---
  Future<String> uploadBytesWithProgress(Uint8List data, String path, Function(double) onProgress) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putData(data); // putData es clave para Web

      uploadTask.snapshotEvents.listen((event) {
        // Evitamos división por cero
        if (event.totalBytes > 0) {
           final progress = event.bytesTransferred / event.totalBytes;
           onProgress(progress);
        }
      });

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) debugPrint("[StorageService] Error subiendo bytes con progreso: $e");
      return "";
    }
  }
  // --------------------------------------------------------------------

  // --- MÉTODO PARA COMPROBANTE DE PAGO (MOBILE) ---
  /// Sube un archivo simple (ej. comprobante de pago) a una ruta específica.
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

  /// Sube un archivo a Firebase Storage y reporta el progreso (MOBILE).
  Future<String> uploadFileWithProgress(
    File file,
    String path,
    Function(double) onProgress,
  ) async {
    try {
      final ref = _storage.ref(path);
      final uploadTask = ref.putFile(file);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (snapshot.totalBytes > 0) {
          final double progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
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
  /// (ACTUALIZADO PARA SOPORTAR WEB AUTOMÁTICAMENTE)
  Future<String> uploadProductImage(
      {required XFile imageFile, required String userId}) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(imageFile.path)}';
      final path = 'products/$userId/main_images/$fileName';

      final ref = _storage.ref(path);
      
      // --- LÓGICA HÍBRIDA (WEB vs MOBILE) ---
      UploadTask uploadTask;
      
      if (kIsWeb) {
        // En web, leemos los bytes directamente del XFile
        final bytes = await imageFile.readAsBytes();
        uploadTask = ref.putData(bytes);
      } else {
        // En móvil, usamos el path del sistema de archivos
        uploadTask = ref.putFile(File(imageFile.path));
      }
      // --------------------------------------

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) debugPrint('[StorageService] Error al subir la imagen del producto: $e');
      rethrow;
    }
  }

  /// Sube un archivo (imagen o video) a la galería de un producto.
  /// (ACTUALIZADO PARA SOPORTAR WEB AUTOMÁTICAMENTE)
  Future<String> uploadGalleryMedia({
    required XFile file,
    required String userId,
    required String type, // 'image' o 'video'
  }) async {
    try {
      // 1. Crear un nombre de archivo único
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}';
      
      // 2. Definir la ruta en Storage
      final String folderType = type == 'video' ? 'videos' : 'images';
      final String storagePath = 'products/$userId/gallery/$folderType/$fileName';
      final ref = _storage.ref(storagePath);

      // 3. Subir el archivo (Híbrido)
      UploadTask uploadTask;

      if (kIsWeb) {
          // Web: Bytes
          final bytes = await file.readAsBytes();
          uploadTask = ref.putData(bytes);
      } else {
          // Móvil: File
          uploadTask = ref.putFile(File(file.path));
      }

      // 4. Obtener la URL de descarga
      final snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;

    } on FirebaseException catch (e) {
      debugPrint('[StorageService] Error subiendo a galería ($type): $e');
      rethrow;
    }
  }

  /// Elimina un archivo de Firebase Storage usando su URL de descarga.
  Future<void> deleteFileByUrl(String fileUrl) async {
    if (fileUrl.isEmpty) {
      if (kDebugMode) debugPrint("[StorageService] deleteFileByUrl: URL vacía, no se intenta borrar.");
      return;
    }
    try {
      final Reference ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      if (kDebugMode) debugPrint("[StorageService] Archivo eliminado exitosamente: $fileUrl");
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        if (kDebugMode) debugPrint("[StorageService] deleteFileByUrl: Archivo no encontrado (puede que ya estuviera borrado): $fileUrl");
      } else {
        if (kDebugMode) debugPrint("[StorageService] !! ERROR al eliminar archivo por URL $fileUrl: $e");
      }
    } catch (e) {
      if (kDebugMode) debugPrint("[StorageService] !! ERROR inesperado al eliminar archivo por URL $fileUrl: $e");
    }
  }
}