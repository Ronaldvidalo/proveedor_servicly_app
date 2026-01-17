import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ✅ IMPORTACIÓN CORRECTA: Apunta al archivo que acabamos de asegurar en el Paso 1
import 'package:proveedor_servicly_app/providers/theme_provider.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos al ThemeProvider
    final themeProvider = context.watch<ThemeProvider>();
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
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),

          // Opción 1: Azul
          _PaletteOptionTile(
            palette: AppPalette.blue,
            title: 'Cyber Glow',
            subtitle: 'El azul neón clásico.',
            isSelected: themeProvider.currentPalette == AppPalette.blue,
            onTap: () => context.read<ThemeProvider>().changePalette(AppPalette.blue),
          ),
          
          const SizedBox(height: 12),

          // Opción 2: Verde
          _PaletteOptionTile(
            palette: AppPalette.green,
            title: 'Cyber Mint',
            subtitle: 'Un estilo fresco y enérgico.',
            isSelected: themeProvider.currentPalette == AppPalette.green,
            onTap: () => context.read<ThemeProvider>().changePalette(AppPalette.green),
          ),

          const SizedBox(height: 12),

          // Opción 3: Rosa
          _PaletteOptionTile(
            palette: AppPalette.pink,
            title: 'Cyber Pink',
            subtitle: 'Una paleta vibrante y audaz.',
            isSelected: themeProvider.currentPalette == AppPalette.pink,
            onTap: () => context.read<ThemeProvider>().changePalette(AppPalette.pink),
          ),

          const SizedBox(height: 12),

          // Opción 4: Naranja
          _PaletteOptionTile(
            palette: AppPalette.orange,
            title: 'Cyber Warm',
            subtitle: 'Una paleta cálida y llamativa.',
            isSelected: themeProvider.currentPalette == AppPalette.orange,
            onTap: () => context.read<ThemeProvider>().changePalette(AppPalette.orange),
          ),

          const Divider(height: 40),

          // Toggle Modo Claro/Oscuro
          ListTile(
            leading: Icon(
              Icons.brightness_6_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            title: Text(
              'Modo Claro y Oscuro',
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface)
            ),
            subtitle: Text(
              'Alternar manualmente entre modo claro y oscuro.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              )
            ),
            trailing: Switch(
              value: themeProvider.isDarkMode,
              activeColor: theme.colorScheme.primary,
              onChanged: (val) => themeProvider.toggleTheme(),
            ),
          ),
        ],
      ),
    );
  }
}

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
    // Accedemos a los temas estáticos definidos en theme_provider.dart
    final darkTheme = AppThemes.darkThemes[palette]!;
    final lightTheme = AppThemes.lightThemes[palette]!;
    
    final currentTheme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: currentTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? currentTheme.colorScheme.primary : currentTheme.dividerColor.withValues(alpha: 0.5),
          width: isSelected ? 2.5 : 1,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: currentTheme.colorScheme.primary.withValues(alpha: 0.4),
            blurRadius: 8,
          )
        ] : [
           BoxShadow(
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
                        color: currentTheme.colorScheme.onSurface.withValues(alpha: 0.7)
                      )),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
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