/// lib/core/models/module_model.dart
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa el modelo de datos para un módulo funcional de la app.
///
/// Esta información se lee de la colección 'modules' en Firestore.
class ModuleModel {
  final String moduleId;
  final String name;
  final String description;
  final String icon;
  final bool isPremium;
  final int defaultOrder;

  ModuleModel({
    required this.moduleId,
    required this.name,
    required this.description,
    required this.icon,
    required this.isPremium,
    required this.defaultOrder,
  });

  /// Crea una instancia de ModuleModel a partir de un snapshot de Firestore.
  ///
  /// Este método de fábrica toma el documento crudo de Firestore y lo convierte
  /// en un objeto ModuleModel bien estructurado y seguro, con valores por defecto
  /// para prevenir errores si algún campo falta en la base de datos.
  factory ModuleModel.fromFirestore(DocumentSnapshot doc) {
    // Se convierte el 'data' del documento a un mapa para poder leerlo.
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return ModuleModel(
      moduleId: data['moduleId'] ?? doc.id, // Usa el ID del documento si el campo falta
      name: data['name'] ?? 'Módulo sin Nombre',
      description: data['description'] ?? '',
      icon: data['icon'] ?? 'help_outline', // Un ícono por defecto
      isPremium: data['isPremium'] ?? true, // Por seguridad, asume premium si falta
      defaultOrder: data['defaultOrder'] ?? 99,
    );
  }
}