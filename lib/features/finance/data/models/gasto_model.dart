import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de datos para un Gasto.
///
/// Representa un documento en la colección 'gastos' de Firestore.
class GastoModel {
  final String id;
  final double monto;
  final String concepto;
  final DateTime fecha;
  final String categoria;
  final String tipo; // 'FIJO' o 'VARIABLE'

  GastoModel({
    required this.id,
    required this.monto,
    required this.concepto,
    required this.fecha,
    required this.categoria,
    required this.tipo,
  });

  /// Factory constructor para crear una instancia desde un DocumentSnapshot de Firestore.
  factory GastoModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return GastoModel(
      id: doc.id,
      monto: (data['monto'] as num).toDouble(),
      concepto: data['concepto'] ?? '',
      // Convertir Timestamp de Firestore a DateTime de Dart
      fecha: (data['fecha'] as Timestamp).toDate(),
      categoria: data['categoria'] ?? 'Otros',
      tipo: data['tipo'] ?? 'VARIABLE',
    );
  }

  /// Método para convertir la instancia a un Map, listo para Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'monto': monto,
      'concepto': concepto,
      // Convertir DateTime de Dart a Timestamp de Firestore
      'fecha': Timestamp.fromDate(fecha),
      'categoria': categoria,
      'tipo': tipo,
    };
  }

  /// Crea una copia de la instancia actual, reemplazando los campos proporcionados.
  /// Esto es crucial para la inmutabilidad y para el modo "Editar".
  GastoModel copyWith({
    String? id,
    double? monto,
    String? concepto,
    DateTime? fecha,
    String? categoria,
    String? tipo,
  }) {
    return GastoModel(
      id: id ?? this.id,
      monto: monto ?? this.monto,
      concepto: concepto ?? this.concepto,
      fecha: fecha ?? this.fecha,
      categoria: categoria ?? this.categoria,
      tipo: tipo ?? this.tipo,
    );
  }
}

