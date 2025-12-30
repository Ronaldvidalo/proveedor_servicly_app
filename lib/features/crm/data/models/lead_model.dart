import 'package:cloud_firestore/cloud_firestore.dart';

class LeadModel {
  final String id;
  final String clientName;
  final String serviceName;
  final String status; // 'new', 'contacted', 'closed', 'lost'
  final String source; // 'App', 'Instagram', 'Manual'
  final String? phoneNumber;
  final String? email;
  final String? notes;
  final bool iaAnalyzed; // Flag para que Servi sepa si ya lo revisó
  final DateTime createdAt;

  LeadModel({
    required this.id,
    required this.clientName,
    required this.serviceName,
    required this.status,
    required this.source,
    this.phoneNumber,
    this.email,
    this.notes,
    this.iaAnalyzed = false,
    required this.createdAt,
  });

  // Factory para crear el modelo desde Firestore
  factory LeadModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return LeadModel(
      id: doc.id,
      clientName: data['clientName'] ?? 'Cliente Desconocido',
      serviceName: data['serviceName'] ?? 'Servicio General',
      status: data['status'] ?? 'new',
      source: data['source'] ?? 'App',
      phoneNumber: data['phoneNumber'],
      email: data['email'],
      notes: data['notes'],
      iaAnalyzed: data['ia_analyzed'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Método para convertir a Mapa (útil para guardar)
  Map<String, dynamic> toMap() {
    return {
      'clientName': clientName,
      'serviceName': serviceName,
      'status': status,
      'source': source,
      'phoneNumber': phoneNumber,
      'email': email,
      'notes': notes,
      'ia_analyzed': iaAnalyzed,
      'createdAt': createdAt,
    };
  }
}