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

  // --- NUEVOS CAMPOS ---
  final String? logoUrl;
  final String? location;
  
  /// Campo comentario agregado para resolver errores de "undefined getter" en la UI.
  final String comentario;

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
    this.logoUrl,
    this.location,
    this.comentario = '',
  });

  // Constructor robusto para leer desde Firestore
  factory Cliente.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception("Documento de cliente nulo");
    }

    // Lógica de estado adaptada a tu enum (usa 'lead' por defecto si no se encuentra)
    final firestoreState = data['estadoCRM'] as String? ?? 'lead';
    final estadoStr = firestoreState.toLowerCase(); 

    CrmEstado estado = CrmEstado.values.first; 
    try {
        estado = CrmEstado.values.firstWhere(
            (e) => e.name.toLowerCase() == estadoStr || e.toString().split('.').last.toLowerCase() == estadoStr,
            orElse: () => CrmEstado.values.first,
        );
    } catch (e) {
        if (kDebugMode) debugPrint('Error parseando estado: $estadoStr');
    }

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
      ultimaInteraccion: (data['ultimaInteraccion'] as Timestamp?)?.toDate() ?? 
                         (data['fechaAlta'] as Timestamp?)?.toDate() ?? DateTime.now(),
      
      // Campos auxiliares
      source: data['source'] ?? '',
      displayName: data['displayName'] as String?,
      
      // Nuevos campos
      logoUrl: data['logoUrl'] as String?,
      location: data['location'] as String?,
      
      // Mapeamos 'comentario' desde Firestore o usamos 'notasInternas' como respaldo
      comentario: data['comentario'] ?? data['notasInternas'] ?? '',
    );
  }

  // Método para convertir a Mapa (útil para guardar en Firestore)
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
      'source': source,
      'displayName': displayName,
      'logoUrl': logoUrl,
      'location': location,
      'comentario': comentario,
    };
  }

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
    String? logoUrl,
    String? location,
    String? comentario,
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
      logoUrl: logoUrl ?? this.logoUrl,
      location: location ?? this.location,
      comentario: comentario ?? this.comentario,
    );
  }
}