import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Un servicio para manejar las operaciones de subida de archivos a Firebase Storage.
class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Sube la imagen de un producto a Firebase Storage.
  ///
  /// La imagen se guarda en una ruta específica para cada usuario y producto,
  /// asegurando que no haya colisiones de nombres.
  ///
  /// Devuelve la URL de descarga de la imagen subida.
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
