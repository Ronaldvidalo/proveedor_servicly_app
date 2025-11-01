import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de datos para un Cobro.
///
/// Representa un documento en la colección 'cobros' de Firestore.
class CobroModel {
  final String id;
  final double monto;
  final String estado; // PENDIENTE, COBRADO, CANCELADO
  final DateTime? fechaCobro; // Fecha en que se marcó como cobrado
  final DateTime? fechaVencimiento; // Fecha límite de pago

  CobroModel({
    required this.id,
    required this.monto,
    required this.estado,
    this.fechaCobro,
    this.fechaVencimiento,
  });

  /// Factory constructor para crear una instancia desde un DocumentSnapshot de Firestore.
  /// ESTE ES EL MÉTODO QUE FALTABA (Error 1)
  factory CobroModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CobroModel(
      id: doc.id,
      monto: (data['monto'] as num? ?? 0.0).toDouble(),
      estado: data['estado'] ?? 'PENDIENTE',
      // Manejar Timestamps nulos
      fechaCobro: data['fechaCobro'] != null
          ? (data['fechaCobro'] as Timestamp).toDate()
          : null,
      fechaVencimiento: data['fechaVencimiento'] != null
          ? (data['fechaVencimiento'] as Timestamp).toDate()
          : null,
    );
  }

  /// Método para convertir la instancia a un Map, listo para Firestore.
  /// (Aunque el repo no lo usa aún, es buena práctica tenerlo)
  Map<String, dynamic> toFirestore() {
    return {
      'monto': monto,
      'estado': estado,
      'fechaCobro':
          fechaCobro != null ? Timestamp.fromDate(fechaCobro!) : null,
      'fechaVencimiento': fechaVencimiento != null
          ? Timestamp.fromDate(fechaVencimiento!)
          : null,
    };
  }

  /// Crea una copia de la instancia actual, reemplazando los campos proporcionados.
  /// (Proactivamente añadido para futuras ediciones)
  CobroModel copyWith({
    String? id,
    double? monto,
    String? estado,
    DateTime? fechaCobro,
    DateTime? fechaVencimiento,
  }) {
    return CobroModel(
      id: id ?? this.id,
      monto: monto ?? this.monto,
      estado: estado ?? this.estado,
      // Manejar valores nulos explícitamente
      fechaCobro: fechaCobro ?? this.fechaCobro,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
    );
  }
}

