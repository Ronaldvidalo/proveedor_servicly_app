import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importamos los modelos
import 'package:proveedor_servicly_app/features/cost_structure/data/models/business_config_model.dart';
import 'package:proveedor_servicly_app/features/cost_structure/data/models/fixed_cost_model.dart';

// Importamos el repositorio
import 'package:proveedor_servicly_app/features/finance/data/repositories/finance_repository.dart';
// Importamos el provider del repositorio
import 'package:proveedor_servicly_app/features/finance/presentation/providers/finance_providers.dart';

// Stream de Costos Fijos
final fixedCostsStreamProvider = StreamProvider.autoDispose<List<FixedCostModel>>((ref) {
  final repository = ref.watch(financeRepositoryProvider);
  return repository.getFixedCostsStream();
});

// Stream de Configuración de Negocio
final businessConfigStreamProvider = StreamProvider.autoDispose<BusinessConfigModel>((ref) {
  final repository = ref.watch(financeRepositoryProvider);
  return repository.getBusinessConfigStream();
});

// Provider Computado: Total de Gastos Fijos
final totalFixedCostsProvider = Provider.autoDispose<double>((ref) {
  final costsAsync = ref.watch(fixedCostsStreamProvider);
  return costsAsync.maybeWhen(
    data: (costs) => costs.fold(0.0, (sum, item) => sum + item.montoMensual),
    orElse: () => 0.0,
  );
});