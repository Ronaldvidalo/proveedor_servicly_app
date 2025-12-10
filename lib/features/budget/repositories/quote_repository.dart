// --- UX/UI Enhancement Comment ---
// Repositorio: QuoteRepository
// Responsabilidad: Gestionar todas las operaciones CRUD con Firestore.
// Ubicación: lib/features/budget/repositories/quote_repository.dart
// Path de Firestore: artifacts/{appId}/users/{userId}/quotes/{quoteId}

import 'package:cloud_firestore/cloud_firestore.dart';

// --- IMPORTS CORREGIDOS ---
// 1. Importamos el modelo principal 'Quote' (Esto solucionará los errores de "Undefined class Quote")
import 'package:proveedor_servicly_app/features/budget/models/quote_model.dart';
// 2. Importamos los ítems (ya lo tenías, lo mantenemos)
import 'package:proveedor_servicly_app/features/budget/models/quote_item_model.dart';

class QuoteRepository {
  final FirebaseFirestore _firestore;
  final String _appId; // ID global de la app (generalmente 'default-app-id' o similar)

  QuoteRepository({
    FirebaseFirestore? firestore, 
    String appId = 'default-app-id' // Ajusta según tu configuración global
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _appId = appId;

  // Referencia a la colección de un usuario específico
  CollectionReference _getCollection(String userId) {
    return _firestore
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(userId)
        .collection('quotes');
  }

  // 1. OBTENER LISTA (STREAM)
  // Escucha en tiempo real para actualizar la UI automáticamente
  Stream<List<Quote>> getQuotesStream(String userId) {
    return _getCollection(userId)
        .orderBy('createdAt', descending: true) // Las más recientes primero
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Quote.fromFirestore(doc);
      }).toList();
    });
  }

  // 2. GUARDAR (CREAR O ACTUALIZAR)
  Future<void> saveQuote(String userId, Quote quote) async {
    final docRef = _getCollection(userId).doc(quote.id.isEmpty ? null : quote.id);
    
    // Si es nueva, aseguramos que tenga fecha de creación
    final quoteToSave = quote.copyWith(
      id: docRef.id, // Asignamos el ID generado si era nueva
      createdAt: quote.id.isEmpty ? DateTime.now() : quote.createdAt,
    );

    await docRef.set(quoteToSave.toMap(), SetOptions(merge: true));
  }

  // 3. ELIMINAR
  Future<void> deleteQuote(String userId, String quoteId) async {
    await _getCollection(userId).doc(quoteId).delete();
  }

  // 4. CAMBIAR ESTADO (Ej. de Borrador a Enviada)
  Future<void> updateStatus(String userId, String quoteId, String newStatus) async {
    await _getCollection(userId).doc(quoteId).update({
      'status': newStatus,
    });
  }
}