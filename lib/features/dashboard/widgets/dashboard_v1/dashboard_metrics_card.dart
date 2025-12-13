import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Modelos y ViewModels
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/features/dashboard/models/dashboard_metrics_viewmodel.dart'; // Importación requerida

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
    
    final String? photoURL = userModel.personalization['logoUrl'] as String?;

    // CRÍTICO: Leer el ViewModel aquí para obtener métricas reactivas
    final metricsModel = context.watch<DashboardMetricsViewModel>();
    final String leadCount = metricsModel.leadCount.toString();
    // La métrica de Visitas se mantiene en hardcode hasta que se implemente el Stream en el VM.
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: colors.surface, // Fondo oscuro del tema
        borderRadius: BorderRadius.circular(16),
        // Borde sutil brillante
        border: Border.all(color: colors.primary.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // --- Encabezado de la Tarjeta ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar con borde brillante
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.primary.withOpacity(0.5), width: 1),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: colors.primary.withOpacity(0.1),
                  backgroundImage: photoURL != null && photoURL.isNotEmpty 
                      ? NetworkImage(photoURL) 
                      : null,
                  child: photoURL == null || photoURL.isEmpty 
                      ? Icon(Icons.person, color: colors.primary) 
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // Título
              Text(
                'Actividad Reciente',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Botón de Detalles
              SizedBox(
                height: 30,
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pantalla de métricas detalladas (Próximamente).'))
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: colors.primary,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Detalles', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, size: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          Divider(height: 24, color: colors.onSurface.withOpacity(0.1)),
          
          // --- Fila de Métricas ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Métrica 1: Visitas (Hardcodeado)
              const _MetricItem(
                icon: Icons.visibility_outlined, 
                label: 'Visitas', 
                value: '128' // Placeholder. Reemplazar con metricsModel.visitCount
              ),
              // Métrica 2: Contactos (Leads) -> Conectado al ViewModel
              _MetricItem(
                icon: Icons.person_add_alt_1_outlined, 
                label: 'Contactos', 
                value: leadCount // <- VALOR REACTIVO DEL CRM
              ),
              // Métrica 3: Rating (Hardcodeado)
              const _MetricItem(
                icon: Icons.star_border_rounded, 
                label: 'Rating', 
                value: '4.8' 
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Sub-widget privado para uso interno de la tarjeta
class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricItem({
    required this.icon, 
    required this.label, 
    required this.value
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: colors.primary.withOpacity(0.8), size: 24),
        const SizedBox(height: 4),
        Text(
          value, 
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.onSurface
          )
        ),
        Text(
          label, 
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurface.withOpacity(0.6)
          )
        ),
      ],
    );
  }
}
