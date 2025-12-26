import 'package:flutter/material.dart';

class CatalogTrustSignals extends StatelessWidget {
  const CatalogTrustSignals({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título sutil
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Garantía y Calidad",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6), // Más sutil para jerarquía
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // --- DISTRIBUCIÓN EQUIDISTANTE ---
            // Usamos Row en lugar de ListView para ocupar todo el ancho
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  _TrustBadge(icon: Icons.verified_user_outlined, label: "Certificado"),
                  _TrustBadge(icon: Icons.workspace_premium_outlined, label: "Premium"),
                  _TrustBadge(icon: Icons.history_edu_outlined, label: "10+ Años"),
                  _TrustBadge(icon: Icons.health_and_safety_outlined, label: "Bioseguro"),
                ],
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Divider(color: Colors.white10, thickness: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    // Ya no necesitamos un ancho fijo (width), el Row se encarga del espacio
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Contenedor Circular Minimalista (Salon Chic Style)
        Container(
          padding: const EdgeInsets.all(12), // Espacio interno del círculo
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.04), // Fondo muy ligero
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Icon(
            icon, 
            color: Colors.amber.shade300, 
            size: 20,
            shadows: [
              Shadow(
                color: Colors.amber.withOpacity(0.2), 
                blurRadius: 8
              )
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70, 
            fontSize: 10, 
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}