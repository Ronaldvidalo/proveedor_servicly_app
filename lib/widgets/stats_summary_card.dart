import 'package:flutter/material.dart';

/// Un widget reutilizable que muestra métricas clave (KPIs) al proveedor.
/// Muestra datos como visitas, seguidores y clientes.
class StatsSummaryCard extends StatelessWidget {
  // A futuro, aquí recibiríamos los streams de datos.
  // Por ahora, usaremos datos de ejemplo.
  final int profileViews;
  final int newFollowers;
  final int totalClients;

  const StatsSummaryCard({
    super.key,
    required this.profileViews,
    required this.newFollowers,
    required this.totalClients,
  });

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Color(0xFF2D2D5A);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha:0.8), // Ligeramente más sutil
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            value: profileViews.toString(),
            label: 'Visitas al Perfil',
            icon: Icons.visibility_outlined,
            color: Colors.lightBlueAccent.shade100,
          ),
          _StatItem(
            value: newFollowers.toString(),
            label: 'Seguidores',
            icon: Icons.person_add_alt_1_outlined,
            color: Colors.greenAccent.shade100,
          ),
          _StatItem(
            value: totalClients.toString(),
            label: 'Clientes (CRM)',
            icon: Icons.groups_outlined,
            color: Colors.purpleAccent.shade100,
          ),
        ],
      ),
    );
  }
}

/// Widget interno para cada item de estadística
class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}