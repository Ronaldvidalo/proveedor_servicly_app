import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- TUS IMPORTS ORIGINALES (INTACTOS) ---
import '../models/cobro_model.dart';
import '../models/gasto_model.dart';
import '../models/presupuesto_financiero_model.dart';

// --- NUEVOS IMPORTS (Para Clasificación SERVI) ---
import '../models/transaction_model.dart'; // Importamos el nuevo modelo de transacción
import 'package:proveedor_servicly_app/features/cost_structure/data/models/business_config_model.dart';
import 'package:proveedor_servicly_app/features/cost_structure/data/models/fixed_cost_model.dart';

/// Clase que encapsula toda la lógica de acceso a datos (Firestore).
class FinanceRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FinanceRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  /// Obtiene el ID del usuario actual.
  String? get _userId => _auth.currentUser?.uid;

  // =========================================================
  //        TUS MÉTODOS ORIGINALES (CRUD)
  // =========================================================

  // --- MÉTODOS DE GASTOS (CRUD) ---
  Stream<List<GastoModel>> getGastosStream() {
    if (_userId == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('gastos')
        .orderBy('fecha', descending: true) 
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => GastoModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> addGasto(GastoModel gasto) async {
    if (_userId == null) throw Exception('Usuario no autenticado');
    
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('gastos')
        .doc(gasto.id)
        .set(gasto.toFirestore());
  }

  Future<void> updateGasto(GastoModel gasto) async {
    if (_userId == null) throw Exception('Usuario no autenticado');
    
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('gastos')
        .doc(gasto.id)
        .update(gasto.toFirestore());
  }

  Future<void> deleteGasto(String gastoId) async {
    if (_userId == null) throw Exception('Usuario no autenticado');
    
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('gastos')
        .doc(gastoId)
        .delete();
  }

  // --- MÉTODOS DE COBROS, PRESUPUESTOS y COSTOS FIJOS (Sin Cambios) ---

  Stream<List<CobroModel>> getCobrosStream() {
    if (_userId == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('cobros')
        .orderBy('fechaCobro', descending: true) 
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CobroModel.fromFirestore(doc)).toList();
    });
  }

  Stream<List<PresupuestoFinancieroModel>> getPresupuestosStream(String mesYYYYMM) {
    if (_userId == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('presupuestos_financieros')
        .where('mes', isEqualTo: mesYYYYMM)
        .where('activo', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PresupuestoFinancieroModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> addPresupuesto(PresupuestoFinancieroModel presupuesto) async {
    if (_userId == null) throw Exception('Usuario no autenticado');
    
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('presupuestos_financieros')
        .doc(presupuesto.id) 
        .set(presupuesto.toFirestore());
  }

  // --- MÉTODOS DE COSTOS FIJOS ---

  Stream<List<FixedCostModel>> getFixedCostsStream() {
    if (_userId == null) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('fixed_costs')
        .where('activo', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => FixedCostModel.fromFirestore(doc)).toList());
  }

  Future<void> saveFixedCost(FixedCostModel cost) async {
    if (_userId == null) throw Exception('Usuario no autenticado');
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('fixed_costs')
        .doc(cost.id)
        .set(cost.toFirestore());
  }

  Future<void> deleteFixedCost(String costId) async {
    if (_userId == null) throw Exception('Usuario no autenticado');
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('fixed_costs')
        .doc(costId)
        .delete();
  }

  // --- MÉTODOS DE CONFIGURACIÓN DE NEGOCIO ---

  Stream<BusinessConfigModel> getBusinessConfigStream() {
    if (_userId == null) return Stream.value(BusinessConfigModel.empty());
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('settings')
        .doc('financial_config')
        .snapshots()
        .map((doc) => BusinessConfigModel.fromFirestore(doc));
  }

  Future<void> updateBusinessConfig(BusinessConfigModel config) async {
    if (_userId == null) throw Exception('Usuario no autenticado');
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('settings')
        .doc('financial_config')
        .set(config.toFirestore(), SetOptions(merge: true));
  }

  // =========================================================
  //        NUEVOS MÉTODOS (MVP 1.4: CLASIFICACIÓN SERVI)
  // =========================================================

  /// Obtiene una lista de todas las categorías contables definidas por el usuario.
  /// Esta lista alimenta a SERVI para clasificar las transacciones.
  Future<List<String>> getUserExpenseCategories(String userId) async {
    if (userId.isEmpty) return [];

    try {
        // Asumimos una colección para las categorías contables.
        // NOTA: Aquí se podría usar la colección de GastoModel para extraer categorías únicas,
        // pero usar una colección de referencia es más seguro y rápido.
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('expense_categories') // Colección de referencia asumida
            .get();

        if (snapshot.docs.isEmpty) {
            // Si no hay categorías definidas, proveemos un contexto básico a la IA.
            return ['Gasto General', 'Ingreso General', 'Nómina', 'Marketing', 'Suministros'];
        }

        // Asumimos que cada documento de categoría tiene un campo 'name'
        return snapshot.docs
            .map((doc) => doc.data()['name'] as String? ?? 'Otro')
            .where((name) => name.isNotEmpty)
            .toList();

    } catch (e) {
        // Esto es solo un debug print en un entorno real
        print('Error al obtener categorías contables para SERVI: $e'); 
        return ['Gasto General', 'Ingreso General'];
    }
  }
  
  /// Guarda una nueva transacción clasificada por SERVI (Gasto o Ingreso)
  Future<void> addTransaction(TransactionModel transaction) async {
    if (_userId == null) throw Exception('Usuario no autenticado');
    
    // Decidimos en qué subcolección guardar (gastos o ingresos/cobros)
    final collectionName = transaction.isExpense ? 'gastos' : 'cobros';
    
    // El modelo de Transacción debe ser compatible con GastoModel y CobroModel o se necesita mapeo.
    // Asumiendo que la estructura de TransactionModel es compatible para simplificar:
    
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection(collectionName)
        .add(transaction.toJson());
        
    // NOTA: Si GastoModel/CobroModel tienen más campos requeridos,
    // se necesitará una función de mapeo aquí: transaction.toGastoModel().toFirestore()
  }
}
