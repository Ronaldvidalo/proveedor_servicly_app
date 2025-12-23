import 'package:flutter/material.dart';

/// Tarjeta simple que muestra las 3 métricas principales (Visitas, Contactos, Rating).
/// Diseñada para ser el primer elemento dentro del carrusel de resúmenes.
class DashboardMetricsItem extends StatelessWidget {
  final String visitas;
  final String contactos;
  final String rating;
  final bool isLoading; // Para manejar estados de carga

  const DashboardMetricsItem({
    super.key,
    required this.visitas,
    required this.contactos,
    required this.rating,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    // Si está cargando, podemos mostrar un esqueleto simple
    if (isLoading) {
      return _LoadingMetricsItem(colors: colors);
    }

    return Padding(
      // Padding lateral para el efecto de carrusel (vista parcial)
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        height: 160, // Altura fija para consistencia en el carrusel
        decoration: BoxDecoration(
          color: colors.surface, 
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.primary.withValues(alpha:0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Actividad en Vivo', // Título centralizado y claro
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MetricValue(
                  icon: Icons.visibility_outlined, 
                  label: 'Visitas', 
                  value: visitas, 
                  color: colors.primary,
                ),
                _MetricValue(
                  icon: Icons.person_add_alt_1_outlined, 
                  label: 'Contactos', 
                  value: contactos,
                  color: colors.primary,
                ),
                _MetricValue(
                  icon: Icons.star_border_rounded, 
                  label: 'Rating', 
                  value: rating,
                  color: colors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Sub-widget para mostrar un valor de métrica individual
class _MetricValue extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricValue({
    required this.icon, 
    required this.label, 
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color.withValues(alpha: 0.8), size: 24),
        const SizedBox(height: 4),
        Text(
          value, 
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface
          )
        ),
        Text(
          label, 
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6)
          )
        ),
      ],
    );
  }
}

// Sub-widget para estado de carga (Shimmer effect)
class _LoadingMetricsItem extends StatelessWidget {
  final ColorScheme colors;
  const _LoadingMetricsItem({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: CircularProgressIndicator(color: colors.primary),
        ),
      ),
    );
  }
}