import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- TUS IMPORTS ORIGINALES (INTACTOS) ---
import '../models/cobro_model.dart';
import '../models/gasto_model.dart';
import '../models/presupuesto_financiero_model.dart';

// --- NUEVOS IMPORTS (Rutas Relativas Seguras) ---
// Salimos de finance/data/repositories (../../..) y entramos a cost_structure/data
import 'package:proveedor_servicly_app/features/cost_structure/data/models/business_config_model.dart';
import 'package:proveedor_servicly_app/features/cost_structure/data/models/fixed_cost_model.dart';

/// Clase que encapsula toda la lógica de acceso a datos (Firestore).
/// Es la única clase en toda la app que debe importar 'cloud_firestore'.
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
  //        TUS MÉTODOS ORIGINALES (INTACTOS)
  // =========================================================

  // --- MÉTODOS DE GASTOS (CRUD) ---

  /// Obtiene un Stream de la lista de gastos.
  Stream<List<GastoModel>> getGastosStream() {
    if (_userId == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('gastos')
        // Ordenamos por fecha descendente para mostrar los más nuevos primero
        .orderBy('fecha', descending: true) 
        .snapshots()
        .map((snapshot) {
      // CORREGIDO: de fromMap a fromFirestore
      return snapshot.docs.map((doc) => GastoModel.fromFirestore(doc)).toList();
    });
  }

  /// Añade un nuevo gasto a Firestore.
  Future<void> addGasto(GastoModel gasto) async {
    if (_userId == null) throw Exception('Usuario no autenticado');
    
    // Usamos .doc(gasto.id) para asegurarnos de que el ID que generamos
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('gastos')
        .doc(gasto.id)
        // CORREGIDO: de toMap a toFirestore
        .set(gasto.toFirestore());
  }

  /// Actualiza un gasto existente en Firestore.
  Future<void> updateGasto(GastoModel gasto) async {
    if (_userId == null) throw Exception('Usuario no autenticado');
    
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('gastos')
        .doc(gasto.id)
        // CORREGIDO: de toMap a toFirestore
        .update(gasto.toFirestore());
  }

  /// Elimina un gasto de Firestore.
  Future<void> deleteGasto(String gastoId) async {
    if (_userId == null) throw Exception('Usuario no autenticado');
    
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('gastos')
        .doc(gastoId)
        .delete();
  }

  // --- MÉTODOS DE COBROS ---

  /// Obtiene un Stream de la lista de cobros.
  Stream<List<CobroModel>> getCobrosStream() {
    if (_userId == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('cobros')
        // Añadido orden para que los cobros recientes aparezcan
        .orderBy('fechaCobro', descending: true) 
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CobroModel.fromFirestore(doc)).toList();
    });
  }

  // --- MÉTODOS DE PRESUPUESTOS ---

  /// Obtiene un Stream de la lista de presupuestos.
  Stream<List<PresupuestoFinancieroModel>> getPresupuestosStream(String mesYYYYMM) {
    if (_userId == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('presupuestos_financieros')
        // Filtrado eficiente en Firestore
        .where('mes', isEqualTo: mesYYYYMM)
        .where('activo', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PresupuestoFinancieroModel.fromFirestore(doc)).toList();
    });
  }

  /// Añade un nuevo presupuesto a Firestore.
  Future<void> addPresupuesto(PresupuestoFinancieroModel presupuesto) async {
    if (_userId == null) throw Exception('Usuario no autenticado');
    
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('presupuestos_financieros')
        .doc(presupuesto.id) 
        .set(presupuesto.toFirestore());
  }

  // =========================================================
  //        AQUÍ INICIA LO NUEVO (COST STRUCTURE)
  // =========================================================

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
}