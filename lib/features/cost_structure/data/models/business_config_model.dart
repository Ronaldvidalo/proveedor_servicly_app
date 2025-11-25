import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessConfigModel {
  final double margenDeseado;
  final int unidadesProyectadasMes;
  final bool usarInventarioReal;
  final double costoFijoUnitarioCalculado; 
  final DateTime lastUpdated;

  BusinessConfigModel({
    required this.margenDeseado,
    required this.unidadesProyectadasMes,
    required this.usarInventarioReal,
    required this.costoFijoUnitarioCalculado,
    required this.lastUpdated,
  });

  factory BusinessConfigModel.empty() {
    return BusinessConfigModel(
      margenDeseado: 0.30,
      unidadesProyectadasMes: 100,
      usarInventarioReal: false,
      costoFijoUnitarioCalculado: 0.0,
      lastUpdated: DateTime.now(),
    );
  }

  factory BusinessConfigModel.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists || doc.data() == null) return BusinessConfigModel.empty();
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return BusinessConfigModel(
      margenDeseado: (data['margenDeseado'] as num? ?? 0.30).toDouble(),
      unidadesProyectadasMes: (data['unidadesProyectadasMes'] as num? ?? 100).toInt(),
      usarInventarioReal: data['usarInventarioReal'] ?? false,
      costoFijoUnitarioCalculado: (data['costoFijoUnitarioCalculado'] as num? ?? 0.0).toDouble(),
      lastUpdated: data['lastUpdated'] != null 
          ? (data['lastUpdated'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'margenDeseado': margenDeseado,
      'unidadesProyectadasMes': unidadesProyectadasMes,
      'usarInventarioReal': usarInventarioReal,
      'costoFijoUnitarioCalculado': costoFijoUnitarioCalculado,
      'lastUpdated': Timestamp.now(),
    };
  }
  
  BusinessConfigModel copyWith({
    double? margenDeseado,
    int? unidadesProyectadasMes,
    bool? usarInventarioReal,
    double? costoFijoUnitarioCalculado,
  }) {
    return BusinessConfigModel(
      margenDeseado: margenDeseado ?? this.margenDeseado,
      unidadesProyectadasMes: unidadesProyectadasMes ?? this.unidadesProyectadasMes,
      usarInventarioReal: usarInventarioReal ?? this.usarInventarioReal,
      costoFijoUnitarioCalculado: costoFijoUnitarioCalculado ?? this.costoFijoUnitarioCalculado,
      lastUpdated: DateTime.now(),
    );
  }
}