import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/theme_service.dart';
import 'package:proveedor_servicly_app/shared/theme/app_themes.dart';
import 'package:proveedor_servicly_app/shared/theme/screens/theme_selection_screen.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos 'watch' para que la UI se actualice cuando cambie el tema
    final themeService = context.watch<ThemeService>();
    final theme = Theme.of(context); // Obtiene el tema actual (claro u oscuro)

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
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),

          // Opción 1: Azul (Cyber Glow)
          _PaletteOptionTile(
            palette: AppPalette.blue,
            title: 'Cyber Glow',
            subtitle: 'El azul neón clásico.',
            isSelected: themeService.currentPalette == AppPalette.blue,
            onTap: () => context.read<ThemeService>().setPalette(AppPalette.blue),
          ),
          
          const SizedBox(height: 12),

          // Opción 2: Verde (Cyber Mint)
          _PaletteOptionTile(
            palette: AppPalette.green,
            title: 'Cyber Mint',
            subtitle: 'Un estilo fresco y enérgico.',
            isSelected: themeService.currentPalette == AppPalette.green,
            onTap: () => context.read<ThemeService>().setPalette(AppPalette.green),
          ),

          const SizedBox(height: 12),

          // Opción 3: Rosa (Cyber Pink)
          _PaletteOptionTile(
            palette: AppPalette.pink,
            title: 'Cyber Pink',
            subtitle: 'Una paleta vibrante y audaz.',
            isSelected: themeService.currentPalette == AppPalette.pink,
            onTap: () => context.read<ThemeService>().setPalette(AppPalette.pink),
          ),

          const SizedBox(height: 12),

          // Opción 4: Naranja (Cyber Warm)
          _PaletteOptionTile(
            palette: AppPalette.orange,
            title: 'Cyber Warm',
            subtitle: 'Una paleta cálida y llamativa.',
            isSelected: themeService.currentPalette == AppPalette.orange,
            onTap: () => context.read<ThemeService>().setPalette(AppPalette.orange),
          ),

          const Divider(height: 40),

          // Info sobre modo claro/oscuro
          ListTile(
            leading: Icon(
              Icons.brightness_6_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            title: Text(
              'Modo Claro y Oscuro',
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onBackground)
            ),
            subtitle: Text(
              'La aplicación se adaptará automáticamente al modo claro u oscuro de tu teléfono.',
               style: theme.textTheme.bodyMedium?.copyWith(
                 color: theme.colorScheme.onSurface.withOpacity(0.7),
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
          color: isSelected ? currentTheme.colorScheme.primary : currentTheme.dividerColor.withOpacity(0.5),
          width: isSelected ? 2.5 : 1,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: currentTheme.colorScheme.primary.withAlpha(100),
            blurRadius: 8,
          )
        ] : [
           BoxShadow(
            color: currentTheme.shadowColor.withOpacity(0.05),
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
                        color: currentTheme.colorScheme.onSurface.withOpacity(0.7)
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