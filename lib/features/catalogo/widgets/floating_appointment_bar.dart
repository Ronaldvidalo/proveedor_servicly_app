// lib/features/catalogo/widgets/floating_appointment_bar.dart

import 'package:flutter/material.dart';

class FloatingAppointmentBar extends StatelessWidget {
  final int count;
  final double total;
  final VoidCallback onTap;

  const FloatingAppointmentBar({
    super.key, 
    required this.count, 
    required this.total, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF00B2B2), // Color turquesa de tu marca
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$count servicios seleccionados",
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                "Total: \$${total.toStringAsFixed(2)}",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF00B2B2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: onTap,
            child: const Text("VER REPORTE"),
          ),
        ],
      ),
    );
  }
}