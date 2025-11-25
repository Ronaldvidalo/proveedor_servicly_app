import 'package:cloud_firestore/cloud_firestore.dart';

class FixedCostModel {
  final String id;
  final String concepto;
  final double montoMensual; // Este SIEMPRE será el valor normalizado al mes
  final String categoria;
  final String frecuencia; // Nuevo campo: 'Mensual', 'Anual', etc.
  final bool activo;

  FixedCostModel({
    required this.id,
    required this.concepto,
    required this.montoMensual,
    required this.categoria,
    this.frecuencia = 'Mensual', // Valor por defecto
    this.activo = true,
  });

  factory FixedCostModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FixedCostModel(
      id: doc.id,
      concepto: data['concepto'] ?? '',
      montoMensual: (data['montoMensual'] as num? ?? 0.0).toDouble(),
      categoria: data['categoria'] ?? 'Operativo',
      frecuencia: data['frecuencia'] ?? 'Mensual', // Leemos el nuevo campo
      activo: data['activo'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'concepto': concepto,
      'montoMensual': montoMensual,
      'categoria': categoria,
      'frecuencia': frecuencia, // Guardamos el nuevo campo
      'activo': activo,
    };
  }
}