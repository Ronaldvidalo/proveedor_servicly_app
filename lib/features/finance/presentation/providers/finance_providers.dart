import 'dart:async';
import 'package:collection/collection.dart'; // ¡Recuerda añadir 'collection' a tu pubspec.yaml!
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/cobro_model.dart';
import '../../data/models/gasto_model.dart';
import '../../data/models/presupuesto_financiero_model.dart';
// ¡Este import ahora traerá las clases que faltan!
import '../../data/models/financial_summary_model.dart'; 
import '../../data/repositories/finance_repository.dart';

// --- Parte 1: Providers de Datos Crudos (Streams) ---

/// Provider que expone el stream de Gastos desde el repositorio.
final gastosStreamProvider = StreamProvider.autoDispose<List<GastoModel>>((ref) {
  final repository = ref.watch(financeRepositoryProvider);
  return repository.getGastosStream();
});

/// Provider que expone el stream de Cobros desde el repositorio.
final cobrosStreamProvider = StreamProvider.autoDispose<List<CobroModel>>((ref) {
  final repository = ref.watch(financeRepositoryProvider);
  return repository.getCobrosStream();
});

/// Provider que expone el stream de Presupuestos desde el repositorio.
final presupuestosStreamProvider =
    StreamProvider.autoDispose<List<PresupuestoFinancieroModel>>((ref) {
  final repository = ref.watch(financeRepositoryProvider);
  return repository.getPresupuestosStream();
});

// --- Parte 2: Provider Computado Principal (El "Copiloto") ---

/// Este es el "cerebro". Combina los 3 streams de datos crudos
/// y los transforma en el 'FinancialSummaryModel' que la UI necesita.
final financialSummaryProvider =
    Provider.autoDispose<AsyncValue<FinancialSummaryModel>>((ref) {
  // Observa los 3 streams
  final gastosAsync = ref.watch(gastosStreamProvider);
  final cobrosAsync = ref.watch(cobrosStreamProvider);
  final presupuestosAsync = ref.watch(presupuestosStreamProvider);

  // --- Manejo de Estados de Carga ---
  // Si alguno de los streams sigue cargando, el provider entero está cargando.
  if (gastosAsync.isLoading ||
      cobrosAsync.isLoading ||
      presupuestosAsync.isLoading) {
    return const AsyncValue.loading();
  }

  // --- Manejo de Estados de Error ---
  // Si alguno de los streams tiene un error, el provider entero falla.
  // Aquí agrupamos los errores para mostrarlos.
  final errors = [
    if (gastosAsync.hasError) gastosAsync.error,
    if (cobrosAsync.hasError) cobrosAsync.error,
    if (presupuestosAsync.hasError) presupuestosAsync.error,
  ].where((e) => e != null).toList();

  if (errors.isNotEmpty) {
    return AsyncValue.error(
      "Error al cargar datos: ${errors.join(', ')}",
      StackTrace.current,
    );
  }

  // --- Estado de Éxito (Datos Disponibles) ---
  // Si llegamos aquí, los 3 streams tienen datos.
  final gastos = gastosAsync.value!;
  final cobros = cobrosAsync.value!;
  final presupuestos = presupuestosAsync.value!;

  try {
    // --- Iniciar Cálculos ---
    final now = DateTime.now();

    // 1. KPIs Principales
    final (ingresosNetos, montoPendiente) =
        _calculateMainKPIs(gastos, cobros);

    // 2. Alertas de Presupuesto
    final (alertas, haSuperadoPresupuesto) =
        _calculateBudgetAlerts(gastos, presupuestos, now);

    // 3. Mini Gráfico de Crecimiento (3 meses)
    final (miniCurva, crecimiento) =
        _calculateGrowthData(gastos, cobros, now, 3);

    // 4. Gráfico de Ingresos (6 meses)
    final (curvaIngresos, _) =
        _calculateGrowthData(gastos, cobros, now, 6);

    // 5. Transacciones Recientes
    final transaccionesRecientes =
        _calculateRecentTransactions(gastos, cobros);

    // Construir y devolver el modelo de resumen
    // *** CORRECCIÓN DE NOMBRES DE PARÁMETROS AQUÍ ***
    return AsyncValue.data(FinancialSummaryModel(
      ingresosNetos: ingresosNetos,
      montoPendienteDeCobro: montoPendiente,
      porcentajeCrecimiento3Meses: crecimiento, // CORREGIDO
      alertaPresupuestoActiva: haSuperadoPresupuesto, // CORREGIDO
      alertasPresupuesto: alertas,
      datosCurvaCrecimiento3M: miniCurva,
      datosGraficoIngresos6Meses: curvaIngresos, // CORREGIDO
      transaccionesRecientes: transaccionesRecientes,
    ));
  } catch (e, stack) {
    // Capturar cualquier error durante el cálculo
    return AsyncValue.error(
        "Error al procesar datos financieros: $e", stack);
  }
});

// --- Parte 3: Funciones Auxiliares de Cálculo (Lógica Pura) ---
// (Estas funciones son privadas y solo son usadas por el provider)

/// Calcula los KPIs de Ingresos Netos y Monto Pendiente.
(double, double) _calculateMainKPIs(
    List<GastoModel> gastos, List<CobroModel> cobros) {
  // Ingresos Netos = (Cobros 'COBRADO') - (Todos los Gastos)
  final ingresosTotales = cobros
      .where((c) => c.estado == 'COBRADO')
      .map((c) => c.monto)
      .sum;

  final gastosTotales = gastos.map((g) => g.monto).sum;

  final ingresosNetos = ingresosTotales - gastosTotales;

  // Monto Pendiente = (Cobros 'PENDIENTE')
  final montoPendiente = cobros
      .where((c) => c.estado == 'PENDIENTE')
      .map((c) => c.monto)
      .sum;

  return (ingresosNetos, montoPendiente);
}

/// Calcula las alertas de presupuesto.
(List<BudgetAlert>, bool) _calculateBudgetAlerts(
    List<GastoModel> gastos, List<PresupuestoFinancieroModel> presupuestos, DateTime now) {
  
  final currentMonthStr = DateFormat('yyyy-MM').format(now);

  // 1. Filtrar presupuestos activos para el mes actual
  final presupuestosMesActual = presupuestos.where((p) {
    return p.mes == currentMonthStr && p.activo;
  }).toList();

  if (presupuestosMesActual.isEmpty) {
    return ([], false); // No hay presupuestos, no hay alertas.
  }

  // 2. Filtrar gastos del mes actual y agruparlos por categoría
  final gastosMesActual = gastos.where((g) {
    return DateFormat('yyyy-MM').format(g.fecha) == currentMonthStr;
  });

  final gastosPorCategoria =
      groupBy(gastosMesActual, (GastoModel g) => g.categoria);

  // 3. Comparar gastos vs presupuestos
  List<BudgetAlert> alertas = [];
  bool haSuperado = false;

  for (final presupuesto in presupuestosMesActual) {
    final gastosDeCategoria =
        gastosPorCategoria[presupuesto.categoria]?.map((g) => g.monto).sum ??
            0.0;

    if (gastosDeCategoria > 0 && presupuesto.montoMeta > 0) {
      final porcentaje = (gastosDeCategoria / presupuesto.montoMeta);
      if (porcentaje >= 0.8) {
        alertas.add(BudgetAlert( // Esto dará error hasta que actualicemos el otro archivo
          categoria: presupuesto.categoria,
          porcentajeConsumido: porcentaje,
        ));
        if (porcentaje >= 1.0) {
          haSuperado = true;
        }
      }
    }
  }

  // Ordenar alertas de más grave a menos grave
  alertas.sort((a, b) => b.porcentajeConsumido.compareTo(a.porcentajeConsumido));

  return (alertas, haSuperado);
}

/// Calcula los datos para los gráficos de líneas (crecimiento e ingresos).
// *** CORRECCIÓN DE TIPO AQUÍ ***
(List<MonthlyData>, double) _calculateGrowthData(
    List<GastoModel> gastos, List<CobroModel> cobros, DateTime now, int numMeses) { // CORREGIDO
      
  // *** CORRECCIÓN DE LÓGICA AQUÍ ***
  // Queremos 'numMeses' atrás desde el *inicio* del mes actual.
  final primerDiaMesActual = DateTime(now.year, now.month, 1);
  final mesesAtras = DateTime(primerDiaMesActual.year, primerDiaMesActual.month - (numMeses - 1), 1);


  // 1. Filtrar cobros 'COBRADO' y gastos relevantes
  final cobrosRelevantes = cobros.where((c) =>
      c.estado == 'COBRADO' &&
      c.fechaCobro != null &&
      !c.fechaCobro!.isBefore(mesesAtras)); // Usar !isBefore para incluir el primer día

  final gastosRelevantes = gastos.where((g) => !g.fecha.isBefore(mesesAtras));

  // 2. Agrupar por mes
  final ingresosPorMes = groupBy(
    cobrosRelevantes,
    (CobroModel c) => DateFormat('yyyy-MM').format(c.fechaCobro!),
  );

  final gastosPorMes = groupBy(
    gastosRelevantes,
    (GastoModel g) => DateFormat('yyyy-MM').format(g.fecha),
  );

  // 3. Calcular datos mensuales (Ingreso Neto por mes)
  List<MonthlyData> datosCurva = [];
  Map<String, double> ingresosNetosPorMes = {};

  // Sumar ingresos
  for (final mes in ingresosPorMes.keys) {
    ingresosNetosPorMes[mes] =
        (ingresosNetosPorMes[mes] ?? 0.0) + ingresosPorMes[mes]!.map((c) => c.monto).sum;
  }

  // Restar gastos
  for (final mes in gastosPorMes.keys) {
    ingresosNetosPorMes[mes] =
        (ingresosNetosPorMes[mes] ?? 0.0) - gastosPorMes[mes]!.map((g) => g.monto).sum;
  }

  // 4. Llenar los meses que faltan con 0.0
  for (int i = 0; i < numMeses; i++) {
    // Iterar hacia atrás desde el mes actual
    final mesActual = DateTime(now.year, now.month - i, 1);
    final mesKey = DateFormat('yyyy-MM').format(mesActual);
    
    final monto = ingresosNetosPorMes[mesKey] ?? 0.0;
    datosCurva.add(MonthlyData(mes: mesActual, monto: monto)); // Error hasta actualizar
  }
  
  // Invertir para que sea cronológico
  datosCurva = datosCurva.reversed.toList(); 

  // 5. Calcular porcentaje de crecimiento (para el mini-gráfico)
  double porcentajeCrecimiento = 0.0;
  if (numMeses == 3 && datosCurva.length >= 2) {
    final mesActual = datosCurva.last.monto;
    // Usamos el penúltimo mes, que sería el "mes anterior"
    final mesAnterior = datosCurva[datosCurva.length - 2].monto; 

    if (mesAnterior != 0) {
      porcentajeCrecimiento = ((mesActual - mesAnterior) / mesAnterior);
    } else if (mesActual > 0) {
      porcentajeCrecimiento = 1.0; // Crecimiento infinito (mostramos 100%)
    }
  }

  return (datosCurva, porcentajeCrecimiento);
}

/// Combina y ordena los últimos 5 gastos y 5 cobros.
List<RecentTransaction> _calculateRecentTransactions(
    List<GastoModel> gastos, List<CobroModel> cobros) {
      
  // Ordenar gastos por fecha descendente PRIMERO
  final gastosOrdenados = List<GastoModel>.from(gastos)
    ..sort((a, b) => b.fecha.compareTo(a.fecha));

  // Convertir gastos a 'RecentTransaction'
  final ultimosGastos = gastosOrdenados.take(5).map((g) {
    return RecentTransaction( // Error hasta actualizar
      concepto: g.concepto,
      monto: -g.monto, // Negativo porque es un gasto
      fecha: g.fecha,
      tipo: TransactionType.gasto, // Error hasta actualizar
    );
  }).toList();

  // Convertir cobros 'COBRADO' a 'RecentTransaction'
  final ultimosCobros = cobros
      .where((c) => c.estado == 'COBRADO' && c.fechaCobro != null)
      .toList()
    // Ordenamos por fecha de cobro descendente
    ..sort((a, b) => b.fechaCobro!.compareTo(a.fechaCobro!)); 
    
  final ultimos5Cobros = ultimosCobros.take(5).map((c) {
    return RecentTransaction( // Error hasta actualizar
      // Asumimos que el 'CobroModel' tiene un campo 'concepto' o 'descripcion'
      // Si no, adaptamos esto. Usaremos el ID por ahora.
      concepto: 'Cobro #${c.id.substring(0, 6)}', 
      monto: c.monto,
      fecha: c.fechaCobro!,
      tipo: TransactionType.ingreso, // Error hasta actualizar
    );
  }).toList();

  // Combinar y ordenar
  final transacciones = [...ultimosGastos, ...ultimos5Cobros];
  transacciones.sort((a, b) => b.fecha.compareTo(a.fecha));

  return transacciones.take(10).toList(); // Tomamos los 10 más recientes de la mezcla
}

