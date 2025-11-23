import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proveedor_servicly_app/features/crm/data/models/cliente_model.dart';
import 'package:proveedor_servicly_app/features/crm/core/crm_enums.dart';

/// El Repositorio es responsable de toda la interacción con Firestore para el módulo CRM.
class CrmRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Asume que el usuario ya está autenticado y tenemos su UID
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'default_user_id'; 

  // Referencia a la colección 'clientes' para el usuario actual (Dueño del CRM)
  CollectionReference get _clientesRef => 
    _firestore.collection('users').doc(_userId).collection('clientes');

  // Referencia al documento de configuración del usuario (para plan y límites)
  DocumentReference get _userDocRef => 
    _firestore.collection('users').doc(_userId);

  // --- Stream 1: Clientes Activos (Pestaña Clientes) ---
  Stream<List<Cliente>> getClientesActivos({String? searchTerm, bool isPro = false}) {
    Query query = _clientesRef.where('estadoCRM', isEqualTo: CrmEstado.clienteActivo.name);
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Cliente.fromFirestore(doc)).toList();
    });
  }

  // --- Stream 2: Leads (Pestaña Leads) ---
  Stream<List<Cliente>> getLeadsStream({String? searchTerm, bool isPro = false}) {
    
    // CORRECCIÓN: 'leadNuevo' debe estar disponible para TODOS los planes.
    // Es el estado con el que entran los leads automáticos (tienda/perfil).
    List<String> leadStates = [
      CrmEstado.leadNuevo.name, // <-- ¡IMPORTANTE! Visible para Free y Pro
      CrmEstado.lead.name,      
    ];

    if (isPro) {
      // Los usuarios Pro ven los estados avanzados del pipeline también
      leadStates.addAll([
        CrmEstado.contactado.name,
        CrmEstado.cotizado.name
      ]);
    }

    // Debug: Confirmación en consola
    // print("🔍 CRM Query buscando estados: $leadStates");

    Query query = _clientesRef.where('estadoCRM', whereIn: leadStates);
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Cliente.fromFirestore(doc)).toList();
    });
  }
  
  // --- Stream 3: Configuración del Usuario ---
  Stream<Map<String, dynamic>> getUserConfigStream() {
    return _userDocRef.snapshots().map((doc) => doc.data() as Map<String, dynamic>? ?? {});
  }

  // --- MÉTODOS DE ACTUALIZACIÓN DEL PIPELINE ---

  // Método para convertir un Lead a Cliente
  Future<void> convertLeadToClient(String leadId) async {
    final clientRef = _clientesRef.doc(leadId);
    return clientRef.update({
      'estadoCRM': CrmEstado.clienteActivo.name,
    });
  }
  
  // Método para actualizar el estado del Lead en el pipeline
  Future<void> updateLeadStatus(String leadId, CrmEstado newStatus) async {
    return _clientesRef.doc(leadId).update({
      'estadoCRM': newStatus.name,
    });
  }
  
  // --- MÉTODOS DE CREACIÓN ---

  // Crea un Lead o Cliente manualmente (desde el formulario interno del proveedor)
  Future<void> createCliente(Map<String, dynamic> data) async {
    await _clientesRef.add({
      ...data,
      'fechaAlta': FieldValue.serverTimestamp(),
      'ultimaInteraccion': FieldValue.serverTimestamp(),
      'montoTotalFacturado': 0.0,
      'etiquetas': [],
      'notasInternas': '',
      
    });
  }
  
  /// Registra un Lead automáticamente desde una interacción pública.
  /// Este método escribe en la colección del PROVEEDOR especificado.
  Future<void> captureLeadFromPublicProfile({
    required String? email, 
    required String? nombreCompleto, 
    required String source, // e.g., 'tienda_whatsapp', 'catalogo_telefono'
    required String providerId, // ID del proveedor que recibe el lead
    String? telefono,
    String? logoUrl, 
    String? location,
  }) async {
    // 1. Determinar el estado inicial del Lead
    final estado = CrmEstado.leadNuevo.name;
    
    // CORRECCIÓN: Referencia a la colección del PROVEEDOR (dueño de la tienda), 
    // no del usuario logueado (cliente).
    final providerLeadsRef = _firestore
        .collection('users')
        .doc(providerId)
        .collection('clientes');

    // 2. Crear el documento del Lead
    await providerLeadsRef.add({
      'nombreCompleto': nombreCompleto ?? 'Visitante Anónimo',
      'email': email ?? '',
      'telefono': telefono ?? '',
      'estadoCRM': estado,
      'fechaAlta': FieldValue.serverTimestamp(),
      'ultimaInteraccion': FieldValue.serverTimestamp(),
      'source': source,
      'montoTotalFacturado': 0.0,
      'etiquetas': ['public_lead', source.split('_').first], // Tag automático
      'notasInternas': 'Capturado automáticamente el: ${DateTime.now()} desde $source.',
      'logoUrl': logoUrl,
      'location': location,
      
    });
  }

  // --- MÉTODOS DE DETALLE PRO ---
  
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
}