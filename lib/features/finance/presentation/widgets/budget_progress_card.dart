import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/presupuesto_financiero_model.dart';

/// Un widget de tarjeta para visualizar el progreso de un presupuesto.
/// QA FIX: Implementado manejo de "Big Numbers" y restricciones de layout.
class BudgetProgressCard extends StatelessWidget {
  final PresupuestoFinancieroModel presupuesto;
  final double gastoActual;

  const BudgetProgressCard({
    super.key,
    required this.presupuesto,
    required this.gastoActual,
  });

  // --- QA FIX: Formateadores estáticos para reutilización y limpieza ---
  
  // 1. Formateador estándar para montos "normales"
  static final _standardFormatter = NumberFormat.currency(
    locale: 'es_CL',
    symbol: '\$',
    decimalDigits: 0,
  );

  // 2. Formateador compacto para montos grandes (> 1 millón)
  // Ej: 1.5M, 10B, 92T (Trillones)
  static final _compactFormatter = NumberFormat.compactCurrency(
    locale: 'es_US', 
    symbol: '\$',
    decimalDigits: 1,
  );

  /// Helper para formatear dinámicamente según la magnitud del número
  String _formatSmartMoney(double amount) {
    if (amount.abs() >= 1000000) {
      return _compactFormatter.format(amount);
    }
    return _standardFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // --- Lógica de Negocio ---
    double percentage = 0.0;
    if (presupuesto.montoMeta > 0) {
      percentage = gastoActual / presupuesto.montoMeta;
    }
    
    // Validación de integridad de datos (NaN / Infinity)
    if (percentage.isNaN || percentage.isInfinite || percentage < 0) {
      percentage = 0;
    }

    // --- Lógica de Colores (Style: Cyber Glow Compatible) ---
    // Usamos colores vibrantes que resaltan sobre fondo oscuro si es necesario
    final Color progressColor;
    final Color textColor;
    
    if (percentage > 1.0) {
      progressColor = Colors.redAccent.shade200; // Superado (Rojo neón)
      textColor = Colors.redAccent;
    } else if (percentage > 0.8) {
      progressColor = Colors.orangeAccent.shade200; // Advertencia
      textColor = Colors.orangeAccent;
    } else {
      progressColor = const Color(0xFF00BFFF); // Normal (Azul neón)
      textColor = const Color(0xFF00BFFF);
    }

    final double displayPercentage = (percentage > 1.0) ? 1.0 : percentage;

    // --- Construcción de UI ---
    return Card(
      elevation: 2.0,
      // QA FIX: Color de fondo ajustado para consistencia (opcional, ajusta según tu tema)
      color: const Color(0xFF2D2D5A), 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                color: Colors.white, // Texto blanco para contraste
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            
            // --- QA FIX: Fila Blindada contra Desbordamiento ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end, // Alinear base del texto
              children: [
                // 1. Lado Izquierdo: Gasto Actual (El dato más importante)
                Expanded(
                  flex: 5, // Le damos un poco más de peso visual
                  child: FittedBox(
                    fit: BoxFit.scaleDown, // Reduce la letra si no cabe
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formatSmartMoney(gastoActual),
                      style: TextStyle(
                        fontSize: 18, // Fuente base un poco más grande
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 8), // Separador seguro
                
                // 2. Lado Derecho: Meta (Contexto)
                Expanded(
                  flex: 4,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      "de ${_formatSmartMoney(presupuesto.montoMeta)}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white60, // Gris claro para fondo oscuro
                        fontWeight: FontWeight.w500
                      ),
                    ),
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
                minHeight: 10,
                backgroundColor: Colors.black26, // Fondo de barra más sutil
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),

            // --- Mensaje de Estado ---
            if (percentage > 1.0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: textColor),
                    const SizedBox(width: 4),
                    Text(
                      "¡Presupuesto superado!",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else if (percentage > 0.8)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Alerta: Al ${(percentage * 100).toStringAsFixed(0)}% del límite",
                  style: TextStyle(
                    color: textColor,
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