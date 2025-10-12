// lib/core/models/module_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ModuleModel {
  final String moduleId;
  final String name;
  final String description;
  // CORRECCIÓN: El ícono es un String (su nombre), no un int.
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

  factory ModuleModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return ModuleModel(
      moduleId: data['moduleId'] ?? doc.id,
      name: data['name'] ?? 'Módulo sin Nombre',
      description: data['description'] ?? '',
      // CORRECCIÓN: Leer como String, con un valor por defecto.
      icon: data['icon'] as String? ?? 'help_outline', 
      isPremium: data['isPremium'] ?? true,
      defaultOrder: data['defaultOrder'] ?? 99,
    );
  }
}