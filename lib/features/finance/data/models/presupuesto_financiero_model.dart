import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de datos para un Presupuesto Financiero.
///
/// Representa un documento en la colección 'presupuestos_financieros'.
class PresupuestoFinancieroModel {
  final String id;
  final String mes; // Formato 'YYYY-MM'
  final String categoria;
  final double montoMeta;
  final bool activo;

  PresupuestoFinancieroModel({
    required this.id,
    required this.mes,
    required this.categoria,
    required this.montoMeta,
    required this.activo,
  });

  /// Factory constructor para crear una instancia desde un DocumentSnapshot de Firestore.
  /// ESTE ES EL MÉTODO QUE FALTABA (Error 2)
  factory PresupuestoFinancieroModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PresupuestoFinancieroModel(
      id: doc.id,
      mes: data['mes'] ?? '',
      categoria: data['categoria'] ?? 'Otros',
      montoMeta: (data['montoMeta'] as num? ?? 0.0).toDouble(),
      activo: data['activo'] ?? true,
    );
  }

  /// Método para convertir la instancia a un Map, listo para Firestore.
  /// ESTE ES EL MÉTODO QUE FALTABA (Error 3)
  Map<String, dynamic> toFirestore() {
    return {
      'mes': mes,
      'categoria': categoria,
      'montoMeta': montoMeta,
      'activo': activo,
    };
  }

  /// Crea una copia de la instancia actual, reemplazando los campos proporcionados.
  /// (Proactivamente añadido para futuras ediciones)
  PresupuestoFinancieroModel copyWith({
    String? id,
    String? mes,
    String? categoria,
    double? montoMeta,
    bool? activo,
  }) {
    return PresupuestoFinancieroModel(
      id: id ?? this.id,
      mes: mes ?? this.mes,
      categoria: categoria ?? this.categoria,
      montoMeta: montoMeta ?? this.montoMeta,
      activo: activo ?? this.activo,
    );
  }
}

