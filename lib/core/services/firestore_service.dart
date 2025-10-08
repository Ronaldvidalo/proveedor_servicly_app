/// lib/core/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Un servicio para gestionar todas las operaciones de lectura y escritura
/// con la base de datos de Cloud Firestore.
class FirestoreService {
  /// La instancia de FirebaseFirestore.
  final FirebaseFirestore _db;

  // Colección principal de usuarios.
  late final CollectionReference<Map<String, dynamic>> _usersCollection;

  /// Constructor que permite inyectar una instancia de Firestore para pruebas,
  /// o utiliza la instancia por defecto.
  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance {
    _usersCollection = _db.collection('users');
  }

  /// Crea un nuevo documento de usuario en Firestore.
  ///
  /// Se utiliza típicamente durante el registro de un nuevo usuario.
  /// El documento se crea usando el [user.uid] como ID.
  Future<void> createUser(UserModel user) async {
    try {
      // Usamos .set() para crear el documento con el ID que ya tenemos.
      await _usersCollection.doc(user.uid).set(user.toJson());
    } catch (e) {
      // En una app real, aquí podrías registrar el error en un servicio de logging.
      print('Error al crear el usuario en Firestore: $e');
      rethrow; // Relanza el error para que la capa superior pueda manejarlo.
    }
  }

  /// Obtiene un stream con los datos del perfil de un usuario en tiempo real.
  ///
  /// Devuelve un stream de [UserModel] que se actualiza automáticamente
  /// cada vez que los datos del usuario cambian en la base de datos.
  /// Si el usuario no existe, el stream emitirá `null`.
  Stream<UserModel?> getUserStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        // Si el documento existe, lo convertimos a un objeto UserModel.
        return UserModel.fromJson(snapshot.data()!);
      } else {
        // Si el documento no existe, emitimos null.
        return null;
      }
    });
  }

  /// Actualiza los datos de un documento de usuario existente.
  ///
  /// Acepta un mapa de datos que se fusionará con los datos existentes.
  /// Esto es ideal para actualizar solo ciertos campos, como el nombre,
  /// la profesión, o cambiar `isProfileComplete` a `true`.
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(uid).update(data);
    } catch (e) {
      print('Error al actualizar el usuario en Firestore: $e');
      rethrow;
    }
  }
}