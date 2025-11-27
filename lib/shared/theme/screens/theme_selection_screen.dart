import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/theme_service.dart';
import 'package:proveedor_servicly_app/shared/theme/app_themes.dart';

// (Error 3 Solucionado: Eliminada la importación recursiva innecesaria)

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos 'watch' para que la UI se actualice cuando cambie el tema
    final themeService = context.watch<ThemeService>();
    final theme = Theme.of(context); 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalizar Apariencia'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            "Elige tu paleta de colores",
            style: theme.textTheme.titleMedium?.copyWith(
              // (Error 2 Solucionado: withOpacity -> withValues)
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),

          // Opción 1: Azul (Cyber Glow)
          _PaletteOptionTile(
            palette: AppPalette.blue,
            title: 'Cyber Glow',
            subtitle: 'El azul neón clásico.',
            isSelected: themeService.currentPalette == AppPalette.blue,
            // (Error 1 Solucionado: setPalette -> updatePalette)
            onTap: () => context.read<ThemeService>().updatePalette(AppPalette.blue),
          ),
          
          const SizedBox(height: 12),

          // Opción 2: Verde (Cyber Mint)
          _PaletteOptionTile(
            palette: AppPalette.green,
            title: 'Cyber Mint',
            subtitle: 'Un estilo fresco y enérgico.',
            isSelected: themeService.currentPalette == AppPalette.green,
            // (Error 1 Solucionado)
            onTap: () => context.read<ThemeService>().updatePalette(AppPalette.green),
          ),

          const SizedBox(height: 12),

          // Opción 3: Rosa (Cyber Pink)
          _PaletteOptionTile(
            palette: AppPalette.pink,
            title: 'Cyber Pink',
            subtitle: 'Una paleta vibrante y audaz.',
            isSelected: themeService.currentPalette == AppPalette.pink,
            // (Error 1 Solucionado)
            onTap: () => context.read<ThemeService>().updatePalette(AppPalette.pink),
          ),

          const SizedBox(height: 12),

          // Opción 4: Naranja (Cyber Warm)
          _PaletteOptionTile(
            palette: AppPalette.orange,
            title: 'Cyber Warm',
            subtitle: 'Una paleta cálida y llamativa.',
            isSelected: themeService.currentPalette == AppPalette.orange,
            // (Error 1 Solucionado)
            onTap: () => context.read<ThemeService>().updatePalette(AppPalette.orange),
          ),

          const Divider(height: 40),

          // Info sobre modo claro/oscuro
          ListTile(
            leading: Icon(
              Icons.brightness_6_rounded,
              // (Error 2 Solucionado: withOpacity -> withValues)
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            title: Text(
              'Modo Claro y Oscuro',
              // (Error 2 Solucionado: onBackground -> onSurface)
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface)
            ),
            subtitle: Text(
              'La aplicación se adaptará automáticamente al modo claro u oscuro de tu teléfono.',
               style: theme.textTheme.bodyMedium?.copyWith(
                 // (Error 2 Solucionado)
                 color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
               )
            ),
          ),
        ],
      ),
    );
  }
}

/// Un widget para mostrar la opción de paleta
class _PaletteOptionTile extends StatelessWidget {
  final AppPalette palette;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaletteOptionTile({
    required this.palette,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Obtenemos los colores específicos de esta paleta
    final darkTheme = AppThemes.darkThemes[palette]!;
    final lightTheme = AppThemes.lightThemes[palette]!;
    
    // Usamos el tema actual del sistema para el fondo de la tarjeta
    final currentTheme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: currentTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        // Borde de acento si está seleccionado
        border: Border.all(
          // (Error 2 Solucionado)
          color: isSelected ? currentTheme.colorScheme.primary : currentTheme.dividerColor.withValues(alpha: 0.5),
          width: isSelected ? 2.5 : 1,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            // (Error 2 Solucionado: withAlpha -> withValues)
            // 100/255 ~= 0.4
            color: currentTheme.colorScheme.primary.withValues(alpha: 0.4),
            blurRadius: 8,
          )
        ] : [
           BoxShadow(
            // (Error 2 Solucionado: 0.05)
            color: currentTheme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2)
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: currentTheme.textTheme.titleLarge?.copyWith(
                        color: currentTheme.colorScheme.onSurface
                      )),
                      Text(subtitle, style: currentTheme.textTheme.bodyMedium?.copyWith(
                        // (Error 2 Solucionado)
                        color: currentTheme.colorScheme.onSurface.withValues(alpha: 0.7)
                      )),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Muestra los colores de la paleta
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ColorDot(color: darkTheme.colorScheme.surface),
                    _ColorDot(color: lightTheme.colorScheme.surface),
                    _ColorDot(color: lightTheme.colorScheme.primary),
                  ],
                ),
                const SizedBox(width: 8),
                if (isSelected)
                  Icon(Icons.check_circle, color: currentTheme.colorScheme.primary)
                else
                  Icon(Icons.circle_outlined, color: currentTheme.dividerColor)
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
    );
  }
}