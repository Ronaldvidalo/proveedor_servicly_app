import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:proveedor_servicly_app/features/crm/core/crm_enums.dart';

/// La clase Cliente es el modelo de datos para Leads y Clientes
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
  
  // Campos auxiliares para la UI
  final String source; // Origen del lead
  final String? displayName;

  // --- ¡NUEVOS CAMPOS INYECTADOS! ---
  final String? logoUrl;
  final String? location;
  // ----------------------------------

  const Cliente({
    required this.id,
    required this.nombreCompleto,
    required this.email,
    required this.telefono,
    required this.estadoCRM,
    required this.fechaAlta,
    this.montoTotalFacturado = 0.0,
    this.notasInternas = '',
    this.etiquetas = const [],
    required this.ultimaInteraccion,
    this.source = '',
    this.displayName,
    // --- ¡NUEVO! ---
    this.logoUrl,
    this.location,
  });

  // Constructor robusto para leer desde Firestore
  factory Cliente.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception("Documento de cliente nulo");
    }

    // --- LECTURA ROBUSTA DEL ESTADO (Tu lógica original intacta) ---
    final firestoreState = data['estadoCRM'] as String? ?? 'lead';
    final estadoStr = firestoreState.toLowerCase(); 

    CrmEstado estado = CrmEstado.lead;
    try {
        estado = CrmEstado.values.firstWhere(
            (e) => e.name.toLowerCase() == estadoStr,
            orElse: () {
              if (kDebugMode) {
                debugPrint('Advertencia: Estado CRM desconocido "$estadoStr". Usando "lead".');
              }
              return CrmEstado.lead;
            },
        );
    } catch (e) {
        estado = CrmEstado.lead;
    }
    // --------------------------------------------------------------------------

    return Cliente(
      id: doc.id,
      nombreCompleto: data['nombreCompleto'] ?? 'Visitante Anónimo',
      email: data['email'] ?? '',
      telefono: data['telefono'] ?? '',
      estadoCRM: estado,
      fechaAlta: (data['fechaAlta'] as Timestamp?)?.toDate() ?? DateTime.now(),
      
      // Campos Pro
      montoTotalFacturado: (data['montoTotalFacturado'] as num?)?.toDouble() ?? 0.0,
      notasInternas: data['notasInternas'] ?? '',
      etiquetas: List<String>.from(data['etiquetas'] ?? []),
      ultimaInteraccion: (data['ultimaInteraccion'] as Timestamp?)?.toDate() ?? (data['fechaAlta'] as Timestamp?)?.toDate() ?? DateTime.now(),
      
      // Campos auxiliares
      source: data['source'] ?? '',
      displayName: data['displayName'] as String?,
      
      // --- ¡LECTURA DE NUEVOS CAMPOS! ---
      logoUrl: data['logoUrl'] as String?,
      location: data['location'] as String?,
    );
  }

  // Método de utilidad para simplificar la copia de objetos
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
    String? source,
    String? displayName,
    // --- ¡NUEVO! ---
    String? photoUrl,
    String? location,
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
      source: source ?? this.source,
      displayName: displayName ?? this.displayName,
      // --- ¡ASIGNACIÓN DE NUEVOS CAMPOS! ---
      logoUrl: logoUrl ?? logoUrl,
      location: location ?? this.location,
    );
  }
}