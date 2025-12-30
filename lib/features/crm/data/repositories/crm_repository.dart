import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// Importaciones de tu proyecto
import 'package:proveedor_servicly_app/features/crm/data/models/cliente_model.dart';
import 'package:proveedor_servicly_app/features/crm/core/crm_enums.dart';

/// El Repositorio es responsable de toda la interacción con Firestore para el módulo CRM.
/// Se ha optimizado para manejar correctamente el mapeo de la clase Cliente y la trazabilidad de Leads.
class CrmRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener el ID del usuario actual de forma dinámica
  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? 'default_user_id';

  // --- REFERENCIAS DE COLECCIÓN ---

  /// Referencia a la colección 'clientes'. 
  /// Usamos Map<String, dynamic> para mayor compatibilidad en operaciones de escritura.
  CollectionReference<Map<String, dynamic>> get _clientesRef => _firestore
      .collection('users')
      .doc(_userId)
      .collection('clientes');

  /// Referencia al documento de configuración del usuario.
  DocumentReference<Map<String, dynamic>> get _userDocRef =>
      _firestore.collection('users').doc(_userId);

  // --- STREAMS DE DATOS EN TIEMPO REAL ---

  /// Obtiene los Clientes Activos (Pestaña Clientes).
  Stream<List<Cliente>> getClientesActivos({String? searchTerm, bool isPro = false}) {
    Query<Map<String, dynamic>> query = _clientesRef.where('estadoCRM', isEqualTo: CrmEstado.clienteActivo.name);
    
    return query.snapshots().map((snapshot) {
      List<Cliente> results = snapshot.docs.map((doc) => Cliente.fromFirestore(doc)).toList();
      
      if (searchTerm != null && searchTerm.isNotEmpty) {
        final term = searchTerm.toLowerCase();
        return results.where((c) => 
          c.nombreCompleto.toLowerCase().contains(term) || 
          c.email.toLowerCase().contains(term)
        ).toList();
      }
      return results;
    });
  }

  /// Obtiene los Leads (Pestaña Leads) según el nivel de plan (Free/Pro).
  /// Incluye todos los leads, independientemente de si vienen del catálogo o creación manual.
  Stream<List<Cliente>> getLeadsStream({String? searchTerm, bool isPro = false}) {
    List<String> leadStates = [
      CrmEstado.leadNuevo.name,
      CrmEstado.lead.name,
    ];

    if (isPro) {
      leadStates.addAll([
        CrmEstado.contactado.name,
        CrmEstado.cotizado.name
      ]);
    }

    Query<Map<String, dynamic>> query = _clientesRef.where('estadoCRM', whereIn: leadStates);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Cliente.fromFirestore(doc)).toList();
    });
  }

  /// Stream específico para filtrar Leads provenientes del Catálogo.
  Stream<List<Cliente>> getCatalogLeadsStream() {
    return _clientesRef
        .where('source', isGreaterThanOrEqualTo: 'catalog')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Cliente.fromFirestore(doc)).toList());
  }

  /// Configuración del Usuario (Plan y Límites).
  Stream<Map<String, dynamic>> getUserConfigStream() {
    return _userDocRef.snapshots().map((doc) => doc.data() ?? {});
  }

  /// Conteo en tiempo real de Leads activos para el Dashboard.
  Stream<int> getLeadCountStream() {
    List<String> leadStates = [
      CrmEstado.leadNuevo.name,
      CrmEstado.lead.name,
      CrmEstado.contactado.name,
      CrmEstado.cotizado.name,
    ];

    return _clientesRef
        .where('estadoCRM', whereIn: leadStates)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // --- MÉTODOS DE ACTUALIZACIÓN DEL PIPELINE ---

  /// Convierte un Lead a Cliente Activo.
  Future<void> convertLeadToClient(String leadId) async {
    return _clientesRef.doc(leadId).update({
      'estadoCRM': CrmEstado.clienteActivo.name,
      'ultimaInteraccion': FieldValue.serverTimestamp(),
    });
  }

  /// Actualiza manualmente el estado de un Lead en el embudo.
  Future<void> updateLeadStatus(String leadId, CrmEstado newStatus) async {
    return _clientesRef.doc(leadId).update({
      'estadoCRM': newStatus.name,
      'ultimaInteraccion': FieldValue.serverTimestamp(),
    });
  }

  /// Actualiza un cliente completo usando el modelo (Necesario para LeadDetailScreen).
  Future<void> updateClient(Cliente cliente) async {
    return _clientesRef.doc(cliente.id).update(cliente.toMap());
  }

  /// Elimina un cliente/lead de la base de datos.
  Future<void> deleteCliente(String clientId) async {
    return _clientesRef.doc(clientId).delete();
  }

  // --- MÉTODOS DE CREACIÓN Y CAPTURA ---

  /// Crea un nuevo contacto manualmente desde el formulario interno del proveedor.
  Future<void> createCliente(Map<String, dynamic> data) async {
    await _clientesRef.add({
      ...data,
      'fechaAlta': FieldValue.serverTimestamp(),
      'ultimaInteraccion': FieldValue.serverTimestamp(),
      'montoTotalFacturado': 0.0,
      'etiquetas': [],
      'notasInternas': '',
      'source': 'manual_admin', // Identificador de creación interna
    });
  }

  /// Registra un Lead automáticamente desde una interacción pública (Catálogo/Tienda).
  /// Escribe en la colección del PROVEEDOR especificado.
  Future<void> captureLeadFromPublicProfile({
    required String? email,
    required String? nombreCompleto,
    required String source, // e.g., 'catalog_whatsapp', 'catalog_appointment'
    required String providerId,
    String? telefono,
    String? logoUrl,
    String? location,
  }) async {
    final estado = CrmEstado.leadNuevo.name;

    final providerLeadsRef = _firestore
        .collection('users')
        .doc(providerId)
        .collection('clientes');

    await providerLeadsRef.add({
      'nombreCompleto': nombreCompleto ?? 'Visitante Catálogo',
      'email': email ?? '',
      'telefono': telefono ?? '',
      'estadoCRM': estado,
      'fechaAlta': FieldValue.serverTimestamp(),
      'ultimaInteraccion': FieldValue.serverTimestamp(),
      'source': source,
      'montoTotalFacturado': 0.0,
      'etiquetas': ['public_lead', source.split('_').last],
      'notasInternas': 'Lead automático generado desde: $source.',
      'logoUrl': logoUrl,
      'location': location,
    });
    
    debugPrint("Lead capturado para el proveedor $providerId desde fuente: $source");
  }

  // --- GESTIÓN PRO Y ETIQUETAS ---

  Future<int> getClienteCount() async {
    final snapshot = await _clientesRef.count().get();
    return snapshot.count ?? 0;
  }

  Future<void> updateClientTags(String clientId, List<String> tags) async {
    await _clientesRef.doc(clientId).update({
      'etiquetas': tags,
    });
  }

  Future<void> updateClientNotes(String clientId, String notes) async {
    await _clientesRef.doc(clientId).update({
      'notasInternas': notes,
    });
  }

  // --- AUDITORÍA DE PRECISIÓN DE SERVI (IA) ---

  /// Registra una interacción con las recomendaciones de IA.
  Future<void> recordServiRecommendation(
    String clientId,
    String suggestedProduct,
    bool wasSuccessful,
    String? relatedOrderId,
  ) async {
    final auditRef = _clientesRef.doc(clientId).collection('servi_audit');

    await auditRef.add({
      'timestamp': FieldValue.serverTimestamp(),
      'feature': 'product_recommendation',
      'suggested_product': suggestedProduct,
      'was_successful': wasSuccessful,
      'status': wasSuccessful ? 'Accepted' : 'Ignored',
      'related_order_id': relatedOrderId,
    });

    if (wasSuccessful) {
      await _clientesRef.doc(clientId).update({
        'etiquetas': FieldValue.arrayUnion(['servi_win', 'recom_${suggestedProduct.toLowerCase()}']),
        'ultimaInteraccion': FieldValue.serverTimestamp(),
      });
    }
  }
}