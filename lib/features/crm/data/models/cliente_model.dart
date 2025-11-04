// Imports de Flutter y paquetes
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// --- ENUMS ---

/// Define los posibles estados de un contacto dentro del flujo CRM (Lead-to-Client).
enum EstadoCRM {
  // Estados para la versión PRO
  leadNuevo('LEAD_NUEVO'), // Lead recién capturado o creado
  contactado('CONTACTADO'), // Se ha iniciado el primer contacto
  cotizado('COTIZADO'), // Se ha enviado una cotización/presupuesto

  // Estados compartidos (Free/Pro)
  lead('LEAD'), // Estado genérico de Lead (usado por Free)
  clienteActivo('CLIENTE_ACTIVO'), // Cliente que ha realizado al menos 1 cobro
  clienteInactivo('CLIENTE_INACTIVO'); // Cliente inactivo (solo Pro)

  const EstadoCRM(this.value);
  final String value;

  // Conversión de String a Enum para Firestore
  static EstadoCRM fromString(String value) {
    return EstadoCRM.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EstadoCRM.lead, // Valor por defecto si no se encuentra
    );
  }
}

// --- MODELO DE DATOS ---

class ClienteModel extends Equatable {
  final String id;
  final String nombreCompleto;
  final String email;
  final String telefono;
  final EstadoCRM estadoCRM;
  final DateTime fechaAlta;
  final String creadoPor;

  // Campos Exclusivos PRO
  final double montoTotalFacturado; // LTV
  final DateTime? ultimaInteraccion;
  final String notasInternas;
  final List<String> etiquetas; // Para segmentación de marketing

  const ClienteModel({
    required this.id,
    required this.nombreCompleto,
    this.email = '',
    this.telefono = '',
    required this.estadoCRM,
    required this.fechaAlta,
    this.creadoPor = 'manual',
    // Valores por defecto para campos Pro
    this.montoTotalFacturado = 0.0,
    this.ultimaInteraccion,
    this.notasInternas = '',
    this.etiquetas = const [],
  });

  // Constructor para crear ClienteModel desde un Map (Firestore)
  factory ClienteModel.fromMap(Map<String, dynamic> data, String id) {
    return ClienteModel(
      id: id,
      nombreCompleto: data['nombreCompleto'] ?? '',
      email: data['email'] ?? '',
      telefono: data['telefono'] ?? '',
      estadoCRM: EstadoCRM.fromString(data['estadoCRM'] ?? 'LEAD'),
      fechaAlta: (data['fechaAlta'] as Timestamp).toDate(),
      creadoPor: data['creadoPor'] ?? 'manual',
      // Campos Pro
      montoTotalFacturado: (data['montoTotalFacturado'] as num?)?.toDouble() ?? 0.0,
      ultimaInteraccion: (data['ultimaInteraccion'] as Timestamp?)?.toDate(),
      notasInternas: data['notasInternas'] ?? '',
      etiquetas: List<String>.from(data['etiquetas'] ?? []),
    );
  }

  // Conversión del modelo a Map para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'nombreCompleto': nombreCompleto,
      'email': email,
      'telefono': telefono,
      'estadoCRM': estadoCRM.value,
      'fechaAlta': Timestamp.fromDate(fechaAlta),
      'creadoPor': creadoPor,
      // Campos Pro
      'montoTotalFacturado': montoTotalFacturado,
      'ultimaInteraccion': ultimaInteraccion != null
          ? Timestamp.fromDate(ultimaInteraccion!)
          : null,
      'notasInternas': notasInternas,
      'etiquetas': etiquetas,
    };
  }

  // Implementación de Equatable para comparación de objetos
  @override
  List<Object?> get props => [
        id,
        nombreCompleto,
        email,
        telefono,
        estadoCRM,
        fechaAlta,
        creadoPor,
        montoTotalFacturado,
        ultimaInteraccion,
        notasInternas,
        etiquetas,
      ];
}
