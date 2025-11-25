import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 1. Importamos el Repositorio que acabamos de crear
import '../data/inventory_repository.dart';
// 2. Importamos el Modelo
import 'package:proveedor_servicly_app/core/models/product_model.dart';
// 3. Importamos el Provider de Costos (Para leer el Costo Fijo Unitario)
import 'package:proveedor_servicly_app/features/cost_structure/core/providers/cost_providers.dart';

// --- PROVIDER DEL REPOSITORIO ---
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

// --- STREAM DE PRODUCTOS (LA LISTA VIVA) ---
final productsStreamProvider = StreamProvider.autoDispose<List<ProductModel>>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getProductsStream();
});

// --- PROVIDER CALCULADORA INTELIGENTE ---
// Este provider escucha el Costo Fijo Unitario y ayuda a calcular precios
final smartPricingProvider = Provider.autoDispose<double>((ref) {
  // Leemos la configuración de negocio del otro módulo
  final businessConfigAsync = ref.watch(businessConfigStreamProvider);
  
  return businessConfigAsync.maybeWhen(
    data: (config) => config.costoFijoUnitarioCalculado,
    orElse: () => 0.0,
  );
});