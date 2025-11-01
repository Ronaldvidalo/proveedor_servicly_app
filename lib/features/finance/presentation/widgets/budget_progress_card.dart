import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/presupuesto_financiero_model.dart';

/// Un widget de tarjeta para visualizar el progreso de un presupuesto.
class BudgetProgressCard extends StatelessWidget {
  final PresupuestoFinancieroModel presupuesto;
  final double gastoActual;

  const BudgetProgressCard({
    super.key,
    required this.presupuesto,
    required this.gastoActual,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'es_CL',
      symbol: '\$',
      decimalDigits: 0,
    );

    double percentage = 0.0;
    if (presupuesto.montoMeta > 0) {
      percentage = gastoActual / presupuesto.montoMeta;
    }
    // Asegurarse que el porcentaje no sea negativo o infinito
    if (percentage.isNaN || percentage.isInfinite || percentage < 0) {
      percentage = 0;
    }

    // Determinar el color de la barra de progreso
    final Color progressColor;
    if (percentage > 1.0) {
      progressColor = Colors.red.shade700; // Superado
    } else if (percentage > 0.8) {
      progressColor = Colors.orange.shade600; // Advertencia
    } else {
      progressColor = Colors.blue.shade600; // Normal
    }

    final double displayPercentage = (percentage > 1.0) ? 1.0 : percentage;

    return Card(
      elevation: 1.0,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Categoría ---
            Text(
              presupuesto.categoria,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // --- Montos (Actual vs Meta) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currencyFormatter.format(gastoActual),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: progressColor,
                  ),
                ),
                Text(
                  "de ${currencyFormatter.format(presupuesto.montoMeta)}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // --- Barra de Progreso ---
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: displayPercentage,
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),

            // --- Mensaje de Estado ---
            if (percentage > 1.0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "¡Presupuesto superado!",
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else if (percentage > 0.8)
               Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Alerta: Límite de presupuesto (${(percentage * 100).toStringAsFixed(0)}%)",
                   style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}
