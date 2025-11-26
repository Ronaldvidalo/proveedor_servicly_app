import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proveedor_servicly_app/core/models/order_model.dart';
import '../data/sales_repository.dart';

// Provider del Repositorio
final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

// Stream de Ventas en Tiempo Real
final salesStreamProvider = StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final repo = ref.watch(salesRepositoryProvider);
  return repo.getSalesStream();
});