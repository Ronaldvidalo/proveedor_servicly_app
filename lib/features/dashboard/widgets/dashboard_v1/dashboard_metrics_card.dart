import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Modelos y ViewModels
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/features/dashboard/models/dashboard_metrics_viewmodel.dart';

/// Tarjeta de métricas reactiva que muestra el pulso del negocio.
/// Diseñada para vivir en la parte superior del Dashboard, antes del Grid de Módulos.
class DashboardMetricsCard extends StatelessWidget {
  final UserModel userModel;

  const DashboardMetricsCard({
    super.key,
    required this.userModel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    // Obtenemos el logo/avatar desde la personalización del usuario
    final String? photoURL = userModel.personalization['logoUrl'] as String?;

    // Suscripción al ViewModel para obtener cambios en tiempo real (Visitas, Leads, etc.)
    final metricsModel = context.watch<DashboardMetricsViewModel>();
    final String leadCount = metricsModel.leadCount.toString();
    final String visitCount = metricsModel.visitCount.toString();
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20), // Un poco más redondeado para el look moderno
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.2), 
          width: 1.5
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // --- Encabezado: Identidad y Acceso a Detalles ---
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.primary.withValues(alpha: 0.4), width: 1),
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: colors.primary.withValues(alpha: 0.1),
                  backgroundImage: (photoURL != null && photoURL.isNotEmpty)
                      ? NetworkImage(photoURL)
                      : null,
                  child: (photoURL == null || photoURL.isEmpty)
                      ? Icon(Icons.person, color: colors.primary)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actividad Reciente',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Últimos 30 días',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Botón de expansión a métricas detalladas
              IconButton.filledTonal(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Métricas detalladas próximamente'),
                      behavior: SnackBarBehavior.floating,
                    )
                  );
                },
                icon: const Icon(Icons.analytics_outlined, size: 20),
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: colors.onSurface.withValues(alpha: 0.05)),
          ),
          
          // --- Fila de Métricas Clave ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MetricItem(
                icon: Icons.visibility_outlined, 
                label: 'Visitas', 
                value: visitCount,
                color: Colors.blueAccent,
              ),
              _MetricItem(
                icon: Icons.bolt_rounded, 
                label: 'Leads', 
                value: leadCount,
                color: Colors.orangeAccent,
              ),
              const _MetricItem(
                icon: Icons.auto_graph_rounded, 
                label: 'Rating', 
                value: '4.8',
                color: Colors.greenAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricItem({
    required this.icon, 
    required this.label, 
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value, 
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: colors.onSurface,
            letterSpacing: -1,
          )
        ),
        Text(
          label.toUpperCase(), 
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: colors.onSurface.withValues(alpha: 0.4)
          )
        ),
      ],
    );
  }
}