import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint

class TransactionModel {
  final String? id;
  final String providerId; // ID del usuario proveedor
  final double amount;
  final String description; // Descripción cruda (la IA la leerá)
  final bool isExpense; // True para gasto, False para ingreso
  final DateTime date;
  
  // --- CAMPOS DE CLASIFICACIÓN (Actualizados por SERVI) ---
  final String category; // Categoría contable sugerida por SERVI
  final String status; // Estado (ej: 'pendiente', 'pagado', 'archivado')

  TransactionModel({
    this.id,
    required this.providerId,
    required this.amount,
    required this.description,
    required this.isExpense,
    required this.date,
    this.category = 'Pendiente', // Default antes de clasificar por IA
    this.status = 'pendiente',
  });

  // Método para crear una copia de la transacción, útil para actualizar la categoría
  TransactionModel copyWith({
    String? category,
    String? status,
  }) {
    return TransactionModel(
      id: id,
      providerId: providerId,
      amount: amount,
      description: description,
      isExpense: isExpense,
      date: date,
      category: category ?? this.category,
      status: status ?? this.status,
    );
  }

  // Conversión a Firestore (para guardar)
  Map<String, dynamic> toJson() {
    return {
      'providerId': providerId,
      'amount': amount,
      'description': description,
      'isExpense': isExpense,
      'date': Timestamp.fromDate(date),
      'category': category,
      'status': status,
    };
  }

  // Conversión desde Firestore (para leer)
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Mapeo robusto de fecha
    DateTime mappedDate;
    final dateData = data['date'];
    if (dateData is Timestamp) {
      mappedDate = dateData.toDate();
    } else {
      debugPrint('Aviso: Campo "date" no es Timestamp. Usando fecha actual.');
      mappedDate = DateTime.now();
    }
    
    return TransactionModel(
      id: doc.id,
      providerId: data['providerId'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] ?? 'Transacción sin descripción',
      isExpense: data['isExpense'] ?? true, // Asumimos gasto por defecto
      date: mappedDate,
      category: data['category'] ?? 'Pendiente',
      status: data['status'] ?? 'pendiente',
    );
  }
}