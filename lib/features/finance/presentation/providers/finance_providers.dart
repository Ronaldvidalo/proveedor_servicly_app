import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importar para la instanciación del repo

// --- IMPORTAR LOS REPOSITORIOS Y MODELOS ---
import '../../data/repositories/finance_repository.dart'; 
import '../../data/models/gasto_model.dart';
import '../../data/models/cobro_model.dart';
import '../../data/models/presupuesto_financiero_model.dart';
import '../../data/models/financial_summary_model.dart';

// ====================================================================
// --- ¡AQUÍ ESTÁ LA CORRECCIÓN DE ARQUITECTURA! ---
// Definimos el provider para el repositorio.
// Los demás providers (como gastosStreamProvider) pueden ahora leer este.
// ====================================================================
final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  // Instanciamos el repositorio, pasándole las dependencias que necesita
  return FinanceRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});


// --- STREAMS ---
// Estos providers ahora leen el 'financeRepositoryProvider'

final gastosStreamProvider = StreamProvider.autoDispose<List<GastoModel>>((ref) {
  final repository = ref.watch(financeRepositoryProvider);
  return repository.getGastosStream();
});

final cobrosStreamProvider = StreamProvider.autoDispose<List<CobroModel>>((ref) {
  final repository = ref.watch(financeRepositoryProvider);
  return repository.getCobrosStream();
});

final presupuestosStreamProvider = StreamProvider.autoDispose<List<PresupuestoFinancieroModel>>((ref) {
  final repository = ref.watch(financeRepositoryProvider);
  
  // --- CORRECCIÓN DE LÓGICA ---
  // Pasamos el mes actual al repositorio para filtrar en Firestore
  final currentMonthStr = DateFormat('yyyy-MM').format(DateTime.now());
  return repository.getPresupuestosStream(currentMonthStr);
});


// --- PROVIDER COMPUTADO PRINCIPAL ---

final financialSummaryProvider = Provider.autoDispose<AsyncValue<FinancialSummaryModel>>((ref) {
  
  // Observamos los 3 streams
  final gastosAsync = ref.watch(gastosStreamProvider);
  final cobrosAsync = ref.watch(cobrosStreamProvider);
  final presupuestosAsync = ref.watch(presupuestosStreamProvider);

  // --- Manejo de estados de carga ---
  // Si CUALQUIERA está cargando, nosotros estamos cargando.
  if (gastosAsync is AsyncLoading || cobrosAsync is AsyncLoading || presupuestosAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }

  // --- Manejo de estados de error ---
  // Si CUALQUIERA tiene un error, nosotros tenemos un error.
  final errors = [gastosAsync, cobrosAsync, presupuestosAsync].where((a) => a.hasError);
  if (errors.isNotEmpty) {
    return AsyncValue.error(
      errors.first.error!,
      errors.first.stackTrace ?? StackTrace.current,
    );
  }

  // --- Todos los datos están listos (AsyncData) ---
  try {
    final gastos = gastosAsync.value!;
    final cobros = cobrosAsync.value!;
    
    // --- CORRECCIÓN DE LÓGICA ---
    // El stream de presupuestos YA VIENE FILTRADO por mes.
    final presupuestos = presupuestosAsync.value!;
    
    // 1. Calcular KPIs Principales
    // ✅ CORRECCIÓN: Se eliminó la variable 'totalCobrado' que no se utilizaba.
    
    // Filtramos gastos solo del mes actual para el KPI de "Ingresos Netos"
    // (Esta es una decisión de negocio, asumimos que "Ingresos Netos" es mensual)
    final currentMonthStr = DateFormat('yyyy-MM').format(DateTime.now());
    final gastosDelMes = gastos.where((g) {
      return DateFormat('yyyy-MM').format(g.fecha) == currentMonthStr;
    }).toList();
    
    final totalGastadoMes = gastosDelMes.map((g) => g.monto).sum;
    // --- CORRECCIÓN DE LÓGICA KPI ---
    // Los "Ingresos Netos" (KPI principal) deben reflejar el mes actual.
    // Buscamos los cobros de ESTE MES.
    final totalCobradoMes = cobros
        .where((c) => c.estado == 'COBRADO' && 
                      c.fechaCobro != null &&
                      DateFormat('yyyy-MM').format(c.fechaCobro!) == currentMonthStr)
        .map((c) => c.monto)
        .sum;
    
    final ingresosNetos = totalCobradoMes - totalGastadoMes;
    
    final montoPendiente = cobros
        .where((c) => c.estado == 'PENDIENTE')
        .map((c) => c.monto)
        .sum;

    // 2. Calcular Alertas de Presupuesto
    // Le pasamos los gastos FILTRADOS del mes actual
    final List<BudgetAlert> alertas = _calculateBudgetAlerts(gastosDelMes, presupuestos);
    final bool alertaActiva = alertas.isNotEmpty;

    // 3. Calcular Datos de Gráficos (Usamos *todos* los cobros Y *todos* los gastos)
    // --- ¡CORRECCIÓN DE LÓGICA DE GRÁFICO! ---
    final datosGrafico6Meses = _calculateNetGrowthData(cobros, gastos, 6);
    // ------------------------------------------
    
    final datosGrafico3Meses = datosGrafico6Meses.take(3).toList(); // Tomamos los 3 más recientes

    // 4. Calcular % Crecimiento (comparando último mes con el anterior)
    final double porcentajeCrecimiento = _calculatePercentageGrowth(datosGrafico3Meses);

    // 5. Transacciones Recientes (Usamos *todos* los gastos y cobros)
    final List<RecentTransaction> transacciones = _calculateRecentTransactions(cobros, gastos, 5);
    
    // Construir y devolver el modelo de resumen
    return AsyncValue.data(FinancialSummaryModel(
      ingresosNetos: ingresosNetos,
      montoPendienteDeCobro: montoPendiente,
      porcentajeCrecimiento3Meses: porcentajeCrecimiento,
      alertaPresupuestoActiva: alertaActiva,
      alertasPresupuesto: alertas,
      datosCurvaCrecimiento3M: datosGrafico3Meses,
      datosGraficoIngresos6Meses: datosGrafico6Meses,
      transaccionesRecientes: transacciones,
    ));

  } catch (e, stack) {
    // Capturar cualquier error de cálculo
    return AsyncValue.error(e, stack);
  }
});


// --- FUNCIONES DE CÁLCULO PRIVADAS ---

List<BudgetAlert> _calculateBudgetAlerts(List<GastoModel> gastosDelMes, List<PresupuestoFinancieroModel> presupuestos) {
  if (presupuestos.isEmpty) return [];

  // Agrupar gastos del mes actual por categoría
  final gastosPorCategoria = groupBy(gastosDelMes, (g) => g.categoria);

  final List<BudgetAlert> alertas = [];

  for (final p in presupuestos) {
    // Ya no necesitamos filtrar gastos por mes, ya vienen filtrados
    final gastosDeCategoria = gastosPorCategoria[p.categoria]?.map((g) => g.monto).sum ?? 0.0;
    
    if (p.montoMeta > 0) { // Evitar división por cero
      final double porcentajeConsumido = gastosDeCategoria / p.montoMeta;
      
      if (porcentajeConsumido >= 0.8) { // Alerta al 80%
        alertas.add(BudgetAlert(
          categoria: p.categoria,
          porcentajeConsumido: porcentajeConsumido,
        ));
      }
    }
  }

  // Ordenar por la que más se ha pasado
  alertas.sort((a, b) => b.porcentajeConsumido.compareTo(a.porcentajeConsumido));
  return alertas;
}

// --- ¡FUNCIÓN CORREGIDA! ---
// Ahora se llama _calculateNetGrowthData y acepta gastos
List<MonthlyData> _calculateNetGrowthData(List<CobroModel> cobros, List<GastoModel> gastos, int numMeses) {
  final Map<int, double> ingresosPorMes = {};
  final Map<int, double> gastosPorMes = {};
  final now = DateTime.now();

  // Inicializar los últimos 'numMeses' a 0.0 para ambos mapas
  for (int i = 0; i < numMeses; i++) {
    final newDate = DateTime(now.year, now.month - i, 1);
    final monthKey = newDate.year * 100 + newDate.month;
    ingresosPorMes[monthKey] = 0.0;
    gastosPorMes[monthKey] = 0.0;
  }
  
  final primerDiaRango = DateTime(now.year, now.month - (numMeses - 1), 1);

  // Sumar los cobros
  for (final cobro in cobros.where((c) => c.estado == 'COBRADO' && c.fechaCobro != null)) {
    final fecha = cobro.fechaCobro!; 
    
    if (fecha.isAfter(primerDiaRango) || fecha.isAtSameMomentAs(primerDiaRango)) {
      final monthKey = fecha.year * 100 + fecha.month;
      if (ingresosPorMes.containsKey(monthKey)) {
        ingresosPorMes.update(monthKey, (value) => value + cobro.monto);
      }
    }
  }

  // --- AÑADIDO: Sumar los gastos ---
  for (final gasto in gastos) {
    final fecha = gasto.fecha; // 'fecha' ya es DateTime
    
    if (fecha.isAfter(primerDiaRango) || fecha.isAtSameMomentAs(primerDiaRango)) {
      final monthKey = fecha.year * 100 + fecha.month;
      if (gastosPorMes.containsKey(monthKey)) {
        gastosPorMes.update(monthKey, (value) => value + gasto.monto);
      }
    }
  }
  // --- FIN DE LO AÑADIDO ---


  // Convertir el mapa a lista de MonthlyData y ordenar
  final List<MonthlyData> datosGrafico = [];
  
  // --- AÑADIDO: Calcular el NETO ---
  for (final monthKey in ingresosPorMes.keys) {
    final ingresoMes = ingresosPorMes[monthKey] ?? 0.0;
    final gastoMes = gastosPorMes[monthKey] ?? 0.0;
    final netoMes = ingresoMes - gastoMes;
    
    final year = monthKey ~/ 100;
    final month = monthKey % 100;
    datosGrafico.add(MonthlyData(mes: DateTime(year, month), monto: netoMes));
  }

  // Ordenar de más antiguo a más nuevo (para el gráfico)
  datosGrafico.sort((a, b) => a.mes.compareTo(b.mes));
  
  return datosGrafico;
}

double _calculatePercentageGrowth(List<MonthlyData> datos3Meses) {
  if (datos3Meses.length < 2) return 0.0; // No hay suficientes datos para comparar
  
  // Datos ordenados de más antiguo a más nuevo
  final mesActual = datos3Meses.last.monto;
  final mesAnterior = datos3Meses[datos3Meses.length - 2].monto;

  if (mesAnterior == 0) {
    return (mesActual > 0) ? 1.0 : 0.0; // Crecimiento del 100% si antes era 0 y ahora no
  }
  
  return (mesActual - mesAnterior) / mesAnterior;
}


List<RecentTransaction> _calculateRecentTransactions(List<CobroModel> cobros, List<GastoModel> gastos, int limite) {
  
  final List<RecentTransaction> transacciones = [];

  // Añadir cobros (solo los cobrados)
  transacciones.addAll(cobros
      .where((c) => c.estado == 'COBRADO' && c.fechaCobro != null)
      .map((c) => RecentTransaction(
            concepto: c.concepto ?? 'Cobro de servicio',
            monto: c.monto,
            fecha: c.fechaCobro!,
            tipo: TransactionType.ingreso,
          )));

  // Añadir gastos
  transacciones.addAll(gastos
      .map((g) => RecentTransaction(
            concepto: g.concepto,
            monto: g.monto,
            fecha: g.fecha, // 'fecha' ya es DateTime
            tipo: TransactionType.gasto,
          )));

  // Ordenar por fecha, más reciente primero
  transacciones.sort((a, b) => b.fecha.compareTo(a.fecha));

  // Devolver solo el límite (ej. las 5 más recientes)
  return transacciones.take(limite).toList();
}