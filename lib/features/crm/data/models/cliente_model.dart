import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/crm_enums.dart';

// La clase Cliente será la representación de la fuente de verdad de Firestore
class Cliente {
  final String id;
  final String nombreCompleto;
  final String email;
  final String telefono;
  final CrmEstado estadoCRM;
  final DateTime fechaAlta;

  // --- Campos Pro ---
  final double montoTotalFacturado; // LTV
  final String notasInternas;
  final List<String> etiquetas;
  final DateTime ultimaInteraccion;

  Cliente({
    required this.id,
    required this.nombreCompleto,
    required this.email,
    required this.telefono,
    required this.estadoCRM,
    required this.fechaAlta,
    // Valores por defecto seguros para campos Pro (aunque se lean desde Firestore)
    this.montoTotalFacturado = 0.0,
    this.notasInternas = '',
    this.etiquetas = const [],
    required this.ultimaInteraccion,
  });

  // Factory para crear desde un DocumentSnapshot de Firestore
  factory Cliente.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception("Documento de cliente nulo");
    }

    // Mapeo seguro y robusto del estado CRM
    CrmEstado estado = CrmEstado.lead; // Default seguro
    try {
      final estadoStr = (data['estadoCRM'] as String? ?? 'lead').toLowerCase();
      estado = CrmEstado.values.firstWhere(
        (e) => e.name.toLowerCase() == estadoStr,
        orElse: () => CrmEstado.lead,
      );
    } catch (_) {
      // Si falla la conversión del enum, se mantiene el default
    }

    return Cliente(
      id: doc.id,
      nombreCompleto: data['nombreCompleto'] ?? 'Cliente sin nombre',
      email: data['email'] ?? '',
      telefono: data['telefono'] ?? '',
      estadoCRM: estado,
      // Conversión de Timestamp a DateTime
      fechaAlta: (data['fechaAlta'] as Timestamp?)?.toDate() ?? DateTime.now(),
      
      // Campos Pro
      montoTotalFacturado: (data['montoTotalFacturado'] as num?)?.toDouble() ?? 0.0,
      notasInternas: data['notasInternas'] ?? '',
      etiquetas: List<String>.from(data['etiquetas'] ?? []),
      ultimaInteraccion: (data['ultimaInteraccion'] as Timestamp?)?.toDate() ?? (data['fechaAlta'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Método para crear el mapa de datos para enviar a Firestore
  Map<String, dynamic> toMap() {
    return {
      'nombreCompleto': nombreCompleto,
      'email': email,
      'telefono': telefono,
      'estadoCRM': estadoCRM.name,
      'fechaAlta': Timestamp.fromDate(fechaAlta),
      'montoTotalFacturado': montoTotalFacturado,
      'notasInternas': notasInternas,
      'etiquetas': etiquetas,
      'ultimaInteraccion': Timestamp.fromDate(ultimaInteraccion),
    };
  }

  // Helper para verificar el plan de forma segura
  bool get isProState => [CrmEstado.leadNuevo, CrmEstado.contactado, CrmEstado.cotizado, CrmEstado.clienteInactivo].contains(estadoCRM);
  bool get isLead => estadoCRM.name.contains('lead') || estadoCRM == CrmEstado.contactado || estadoCRM == CrmEstado.cotizado;

  Cliente copyWith({
    String? id,
    String? nombreCompleto,
    String? email,
    String? telefono,
    CrmEstado? estadoCRM,
    DateTime? fechaAlta,
    double? montoTotalFacturado,
    String? notasInternas,
    List<String>? etiquetas,
    DateTime? ultimaInteraccion,
  }) {
    return Cliente(
      id: id ?? this.id,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      estadoCRM: estadoCRM ?? this.estadoCRM,
      fechaAlta: fechaAlta ?? this.fechaAlta,
      montoTotalFacturado: montoTotalFacturado ?? this.montoTotalFacturado,
      notasInternas: notasInternas ?? this.notasInternas,
      etiquetas: etiquetas ?? this.etiquetas,
      ultimaInteraccion: ultimaInteraccion ?? this.ultimaInteraccion,
    );
  }
}
