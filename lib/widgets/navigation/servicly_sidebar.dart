import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
// CAMBIO 1: Importar el ThemeProvider
import 'package:proveedor_servicly_app/providers/theme_provider.dart';

class ServiclySidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const ServiclySidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final user = context.watch<UserModel?>();
    
    // Detectar si el tema actual es oscuro
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 260, // Ancho estándar para sidebar web
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor, 
        border: Border(
          right: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER (LOGO)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.hub, color: colors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'Servicly',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PRO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                )
              ],
            ),
          ),

          // 2. MENÚ DE NAVEGACIÓN
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const _SidebarSectionLabel(label: "GENERAL"),
                _SidebarItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Panel Principal',
                  isSelected: selectedIndex == 0,
                  onTap: () => onDestinationSelected(0),
                  activeColor: colors.primary,
                ),
                _SidebarItem(
                  icon: Icons.storefront_rounded,
                  label: 'Explorar Tiendas',
                  isSelected: selectedIndex == 1,
                  onTap: () => onDestinationSelected(1),
                  activeColor: colors.primary,
                ),
                
                const SizedBox(height: 24),
                const _SidebarSectionLabel(label: "CRECIMIENTO"),
                _SidebarItem(
                  icon: Icons.lightbulb_outline_rounded,
                  label: 'Marketing & Ideas',
                  isSelected: selectedIndex == 2,
                  onTap: () => onDestinationSelected(2),
                  activeColor: Colors.amber[700]!,
                ),
                 _SidebarItem(
                  icon: Icons.analytics_outlined,
                  label: 'Reportes (Pronto)',
                  isSelected: false,
                  onTap: () {},
                  activeColor: colors.primary,
                  isLocked: true,
                ),

                const SizedBox(height: 24),
                const _SidebarSectionLabel(label: "CONFIGURACIÓN"),
                _SidebarItem(
                  icon: Icons.settings_outlined,
                  label: 'Ajustes',
                  isSelected: selectedIndex == 3,
                  onTap: () => onDestinationSelected(3),
                  activeColor: colors.primary,
                ),
              ],
            ),
          ),

          // Separador sutil antes de los controles inferiores
          Divider(color: theme.dividerColor.withValues(alpha: 0.1), height: 1),

          // 3. TOGGLE DE TEMA (NUEVO)
          _ThemeToggleRow(isDark: isDark, colors: colors),

          // 4. FOOTER (USUARIO)
          if (user != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(user.photoUrl ?? ''),
                    backgroundColor: colors.primary.withValues(alpha: 0.1),
                    child: user.photoUrl == null 
                        ? Text(user.displayName?[0].toUpperCase() ?? 'U') 
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.displayName ?? 'Usuario',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Plan Gratuito',
                          style: TextStyle(
                            color: colors.onSurface.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.more_vert, size: 18, color: colors.onSurface.withValues(alpha: 0.5)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// --- WIDGETS INTERNOS DE ESTILO ---

class _ThemeToggleRow extends StatelessWidget {
  final bool isDark;
  final ColorScheme colors;

  const _ThemeToggleRow({required this.isDark, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Icon(
            isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            size: 20,
            color: colors.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 12),
          Text(
            isDark ? "Modo Oscuro" : "Modo Claro",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const Spacer(),
          // Switch compacto
          SizedBox(
            height: 24,
            child: Switch(
              value: isDark,
              activeColor: colors.primary,
              onChanged: (value) {
                // CAMBIO 2: Conectar con ThemeProvider
                context.read<ThemeProvider>().toggleTheme();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarSectionLabel extends StatelessWidget {
  final String label;
  const _SidebarSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;
  final bool isLocked;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.activeColor,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLocked ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: activeColor.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? activeColor.withValues(alpha: 0.2) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isLocked 
                      ? colorScheme.onSurface.withValues(alpha: 0.3)
                      : (isSelected ? activeColor : colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isLocked 
                          ? colorScheme.onSurface.withValues(alpha: 0.3)
                          : (isSelected ? activeColor : colorScheme.onSurface.withValues(alpha: 0.8)),
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isLocked)
                  Icon(Icons.lock_outline, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                if (isSelected && !isLocked)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}