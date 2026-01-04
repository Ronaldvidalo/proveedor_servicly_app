import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FloatingAppointmentBar extends StatelessWidget {
  final int count;
  final double total;
  final VoidCallback onTap;
  final bool isAgenda; // ✅ DETERMINA EL MODO: true = Agenda, false = Presupuesto

  const FloatingAppointmentBar({
    super.key, 
    required this.count, 
    required this.total, 
    required this.onTap,
    required this.isAgenda, // ✅ Requerido para la uniformidad técnica
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    // Lógica de etiquetas dinámicas basada en la elección del editor
    final String labelHeader = isAgenda 
        ? "$count servicios para agendar" 
        : "$count servicios para presupuesto";
    
    final String buttonLabel = isAgenda 
        ? "AGENDAR" 
        : "PEDIR VISITA";

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF00B2B2), // Color turquesa de tu marca
        borderRadius: BorderRadius.circular(20), // Ajustado a 20 para mayor modernidad
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // INFO DE SELECCIÓN
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  labelHeader,
                  style: const TextStyle(color: Colors.white, fontSize: 11, letterSpacing: 0.3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Total: \$${NumberFormat("#,##0").format(total)}",
                  style: const TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.w900, 
                    fontSize: 18
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // BOTÓN DE ACCIÓN DINÁMICO
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF00B2B2),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onTap,
            child: Row(
              children: [
                Text(
                  buttonLabel, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios, size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}