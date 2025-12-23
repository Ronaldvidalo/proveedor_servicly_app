import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Una tarjeta de alto impacto visual para mostrar un Key Performance Indicator (KPI).
///
/// Es un componente reutilizable para la pestaña de "Resumen Ejecutivo".
class KpiCard extends StatelessWidget {
  /// El título de la tarjeta (ej. "Ingresos Netos").
  final String title;

  /// El valor numérico a mostrar.
  final double value;

  /// El color principal del texto del valor y el ícono (ej. Colors.green).
  final Color color;

  /// Callback que se ejecuta al tocar la tarjeta.
  /// Si es nulo, la tarjeta no será interactiva.
  final VoidCallback? onTap;

  /// Indica si el valor debe ser formateado como moneda.
  final bool isCurrency;

  /// Formateador de moneda. Ajusta el 'locale' según tu país (ej. 'es_MX', 'es_CO').
  static final _currencyFormatter = NumberFormat.currency(
    locale: 'es_CL', // Ejemplo: pesos chilenos
    symbol: '\$',
    decimalDigits: 0,
  );

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    this.onTap,
    this.isCurrency = false,
  });

  @override
  Widget build(BuildContext context) {
    final String formattedValue = isCurrency
        ? _currencyFormatter.format(value)
        : value.toStringAsFixed(2); // Muestra 2 decimales si no es moneda

    return Card(
      elevation: 2.0,
      clipBehavior: Clip.antiAlias, // Para que el ripple del InkWell respete los bordes
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título del KPI
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8.0),
              
              // Valor y Flecha (si es accionable)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Valor del KPI
                  Expanded(
                    child: Text(
                      formattedValue,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Ícono de "accionable"
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 18.0,
                      color: color.withValues(alpha: 0.8),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
