import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa el modelo de datos para un país.
class CountryModel {
  /// El código ISO de 2 letras del país (ej: 'AR').
  final String id;
  /// El nombre completo del país (ej: 'Argentina').
  final String name;
  /// El emoji de la bandera del país (ej: '🇦🇷').
  final String flag;

  CountryModel({
    required this.id,
    required this.name,
    required this.flag,
  });

  /// Crea una instancia de [CountryModel] desde un documento de Firestore.
  factory CountryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CountryModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Desconocido',
      flag: data['flag'] as String? ?? '🏳️',
    );
  }
}

