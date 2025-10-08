/// lib/core/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa el modelo de datos para un usuario en la aplicación.
///
/// Este modelo se almacena en la colección 'users' en Firestore.
class UserModel {
  /// El ID único del usuario, que coincide con el UID de Firebase Auth.
  final String uid;

  /// El correo electrónico del usuario.
  final String? email;

  /// El nombre a mostrar del usuario, que puede ser editado en su perfil.
  final String? displayName;

  /// La profesión o el rubro principal del proveedor de servicios.
  final String? profession;

  /// La fecha y hora en que se creó la cuenta del usuario.
  final Timestamp? createdAt;

  /// Un indicador booleano para saber si el usuario ha completado
  /// la información esencial de su perfil.
  final bool isProfileComplete;

  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.profession,
    this.createdAt,
    this.isProfileComplete = false, // Por defecto, el perfil está incompleto.
  });

  /// Convierte una instancia de [UserModel] en un mapa de clave-valor.
  ///
  /// Este método es utilizado para escribir datos en Firestore.
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'profession': profession,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(), // Usa la hora del servidor si es nulo.
      'isProfileComplete': isProfileComplete,
    };
  }

  /// Crea una instancia de [UserModel] a partir de un mapa de clave-valor.
  ///
  /// Este factory constructor es utilizado para leer datos desde Firestore.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      profession: json['profession'] as String?,
      createdAt: json['createdAt'] as Timestamp?,
      // Asegura que el valor por defecto sea 'false' si el campo no existe en Firestore.
      isProfileComplete: json['isProfileComplete'] as bool? ?? false,
    );
  }
}