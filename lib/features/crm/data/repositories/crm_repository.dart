import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/crm_enums.dart';
import '../models/cliente_model.dart';

// Clase que encapsula todas las interacciones con Firestore para el módulo CRM.
class CrmRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Usamos un ID de usuario por defecto si no está autenticado (para la demostración)
  // En producción, se garantizaría la autenticación antes de acceder al repositorio.
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'demo_user_id'; 

  CollectionReference get _clientesRef => 
    _firestore.collection('users').doc(_userId).collection('clientes');
  
  // Asume que esta colección existe y tiene el plan
  DocumentReference get _userDocRef => 
    _firestore.collection('users').doc(_userId);


  // --- STREAMS DE DATOS EN TIEMPO REAL ---

  // Obtiene todos los clientes activos (Free/Pro)
  Stream<List<Cliente>> getClientesActivos() {
    // Solo mostramos CLIENTE_ACTIVO en la pestaña "Clientes"
    final query = _clientesRef.where('estadoCRM', isEqualTo: CrmEstado.clienteActivo.name);
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Cliente.fromFirestore(doc)).toList();
    });
  }

  // Obtiene los leads (filtrado por estados LEAD, LEAD_NUEVO, CONTACTADO, COTIZADO)
  Stream<List<Cliente>> getLeads(bool isPro) {
    // Free: solo 'lead'
    // Pro: todos los estados de lead
    final List<String> leadStates = isPro 
      ? [CrmEstado.lead.name, CrmEstado.leadNuevo.name, CrmEstado.contactado.name, CrmEstado.cotizado.name]
      : [CrmEstado.lead.name];
      
    // Firestore requiere consultas separadas para un array de 'where' si el array tiene más de 10 elementos, 
    // pero aquí usamos 'whereIn' con hasta 10, lo que es suficiente.
    final query = _clientesRef.where('estadoCRM', whereIn: leadStates);

    return query.snapshots().map((snapshot) {
      // Ordenamos por fecha de alta para ver los más nuevos primero
      final leads = snapshot.docs.map((doc) => Cliente.fromFirestore(doc)).toList();
      leads.sort((a, b) => b.fechaAlta.compareTo(a.fechaAlta));
      return leads;
    });
  }
  
  // Stream del documento de configuración del usuario (para plan y límites)
  Stream<Map<String, dynamic>> getUserConfigStream() {
    return _userDocRef.snapshots().map((doc) => doc.data() as Map<String, dynamic>? ?? {});
  }


  // --- MÉTODOS DE ESCRITURA ---

  // Crea un nuevo contacto (Lead)
  Future<void> createCliente(Cliente cliente) async {
    await _clientesRef.add(cliente.toMap());
  }
  
  // Actualiza un cliente existente
  Future<void> updateCliente(Cliente cliente) async {
    await _clientesRef.doc(cliente.id).update(cliente.toMap());
  }

  // Ejemplo: Conversión manual de Lead a Cliente (para versión Free o flujo manual)
  Future<void> convertLeadToClient(String clienteId) async {
    await _clientesRef.doc(clienteId).update({
      'estadoCRM': CrmEstado.clienteActivo.name,
      'ultimaInteraccion': Timestamp.now(),
    });
  }
}
