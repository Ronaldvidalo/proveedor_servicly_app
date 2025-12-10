// --- UX/UI Enhancement Comment ---
// Modelo: QuoteRequestModel
// Responsabilidad: Estructurar la solicitud inicial del cliente (Formulario).

import 'package:cloud_firestore/cloud_firestore.dart';

class QuoteRequestModel {
  final String id;
  final String clientId;      // Quién pide
  final String providerId;    // A quién le piden
  final String clientName;    // Para mostrar rápido
  final String clientPhone;   // Contacto
  
  // --- DATOS DEL PEDIDO ---
  final String serviceType;   // Ej: "Instalación", "Producto", "Mantenimiento"
  final String description;   // "Necesito pintar la fachada..."
  final String quantity;      // "50 m2", "3 unidades"
  final String location;      // "Calle 123, Centro"
  final DateTime preferredDate; // Cuándo lo necesita
  
  final DateTime createdAt;
  final String status;        // 'pending', 'quoted', 'rejected'

  QuoteRequestModel({
    required this.id,
    required this.clientId,
    required this.providerId,
    required this.clientName,
    required this.clientPhone,
    required this.serviceType,
    required this.description,
    required this.quantity,
    required this.location,
    required this.preferredDate,
    required this.createdAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'providerId': providerId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'serviceType': serviceType,
      'description': description,
      'quantity': quantity,
      'location': location,
      'preferredDate': Timestamp.fromDate(preferredDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }

  factory QuoteRequestModel.fromMap(Map<String, dynamic> map) {
    return QuoteRequestModel(
      id: map['id'] ?? '',
      clientId: map['clientId'] ?? '',
      providerId: map['providerId'] ?? '',
      clientName: map['clientName'] ?? '',
      clientPhone: map['clientPhone'] ?? '',
      serviceType: map['serviceType'] ?? 'General',
      description: map['description'] ?? '',
      quantity: map['quantity'] ?? '',
      location: map['location'] ?? '',
      preferredDate: (map['preferredDate'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
    );
  }
}