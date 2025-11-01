/// Modelo de "ViewModel" que agrupa todos los KPIs calculados
/// para ser consumidos por la 'SummaryTab'.
class FinancialSummaryModel {
  final double ingresosNetos;
  final double montoPendienteDeCobro;
  final double porcentajeCrecimiento3Meses;
  final bool alertaPresupuestoActiva;
  final List<BudgetAlert> alertasPresupuesto;
  final List<MonthlyData> datosCurvaCrecimiento3M;
  final List<MonthlyData> datosGraficoIngresos6Meses;
  final List<RecentTransaction> transaccionesRecientes;

  FinancialSummaryModel({
    required this.ingresosNetos,
    required this.montoPendienteDeCobro,
    required this.porcentajeCrecimiento3Meses,
    required this.alertaPresupuestoActiva,
    required this.alertasPresupuesto,
    required this.datosCurvaCrecimiento3M,
    required this.datosGraficoIngresos6Meses,
    required this.transaccionesRecientes,
  });
}

// --- CLASES AUXILIARES (DEFINICIONES QUE FALTABAN) ---

/// Representa una alerta de presupuesto para la UI.
class BudgetAlert {
  final String categoria;
  final double porcentajeConsumido; // ej. 0.85 para 85%

  BudgetAlert({
    required this.categoria,
    required this.porcentajeConsumido,
  });
}

/// Representa un punto de datos en un gráfico mensual (Ingreso/Gasto).
class MonthlyData {
  final DateTime mes;
  final double monto;

  MonthlyData({
    required this.mes,
    required this.monto,
  });
}

/// Enum para el tipo de transacción reciente.
enum TransactionType { ingreso, gasto }

/// Representa una transacción unificada para la lista de "Recientes".
class RecentTransaction {
  final String concepto;
  final double monto; // Positivo para ingresos, negativo para gastos
  final DateTime fecha;
  final TransactionType tipo;

  RecentTransaction({
    required this.concepto,
    required this.monto,
    required this.fecha,
    required this.tipo,
  });
}

