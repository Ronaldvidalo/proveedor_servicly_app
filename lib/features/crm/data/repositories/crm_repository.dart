import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proveedor_servicly_app/features/crm/data/models/cliente_model.dart';
import 'package:proveedor_servicly_app/features/crm/core/crm_enums.dart';

// El Repositorio es responsable de toda la interacción con Firestore.
class CrmRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Asume que el usuario ya está autenticado y tenemos su UID
  // TODO: Manejar la inicialización asíncrona de FirebaseAuth correctamente.
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'default_user_id'; 

  // Referencia a la colección 'clientes' para el usuario actual
  CollectionReference get _clientesRef => 
    _firestore.collection('users').doc(_userId).collection('clientes');

  // Referencia al documento de configuración del usuario (para plan y límites)
  DocumentReference get _userDocRef => 
    _firestore.collection('users').doc(_userId);


  // Stream 1: Clientes Activos (Pestaña Clientes) - Usado por ClientListViewModel
  Stream<List<Cliente>> getClientesActivos({String? searchTerm, bool isPro = false}) {
    // 1. Filtrar solo por clientes activos
    Query query = _clientesRef.where('estadoCRM', isEqualTo: CrmEstado.clienteActivo.name);
    
    // 2. Obtener el snapshot en tiempo real y mapear a la lista de Clientes
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Cliente.fromFirestore(doc)).toList();
    });
  }

  // Stream 2: Leads (Pestaña Leads) - Usado por LeadListViewModel
  Stream<List<Cliente>> getLeadsStream({String? searchTerm, bool isPro = false}) {
    List<String> leadStates = isPro 
      ? [CrmEstado.leadNuevo.name, CrmEstado.contactado.name, CrmEstado.cotizado.name, CrmEstado.lead.name]
      : [CrmEstado.lead.name]; // Solo el estado básico en Free

    // Usamos whereIn para filtrar por múltiples estados de Lead
    Query query = _clientesRef.where('estadoCRM', whereIn: leadStates);
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Cliente.fromFirestore(doc)).toList();
    });
  }
  
  // Stream 3: Configuración del Usuario (Usado por ambos ViewModels para Free/Pro y límite)
  Stream<Map<String, dynamic>> getUserConfigStream() {
    // Escucha el documento de usuario para obtener el plan ('free'/'pro') y el contador
    return _userDocRef.snapshots().map((doc) => doc.data() as Map<String, dynamic>? ?? {});
  }


  // Método para convertir un Lead a Cliente (Conversión Manual)
  Future<void> convertLeadToClient(String leadId) async {
    final clientRef = _clientesRef.doc(leadId);

    // Actualiza el estado a CLIENTE_ACTIVO
    await clientRef.update({
      'estadoCRM': CrmEstado.clienteActivo.name,
      // Opcional: Registrar la fecha de conversión
      // 'fechaConversion': FieldValue.serverTimestamp(), 
    });
  }

  // Método para crear un nuevo Cliente o Lead (Implementación pendiente de la pantalla de Formulario)
  Future<void> createCliente(Map<String, dynamic> data) async {
    // Implementación sencilla para crear un nuevo documento
    await _clientesRef.add({
      ...data,
      'fechaAlta': FieldValue.serverTimestamp(),
      'ultimaInteraccion': FieldValue.serverTimestamp(),
      'montoTotalFacturado': 0.0,
      'etiquetas': [],
    });
  }

  // Método para obtener el conteo total de clientes y leads (necesario para el límite Free)
  Future<int> getClienteCount() async {
    final snapshot = await _clientesRef.count().get();
    // FIX: Usamos ?? 0 para convertir int? (nullable) a int, resolviendo el error.
    return snapshot.count ?? 0;
  }
}