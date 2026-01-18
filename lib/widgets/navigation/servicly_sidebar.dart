import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/providers/theme_provider.dart';

class ServiclySidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const ServiclySidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  State<ServiclySidebar> createState() => _ServiclySidebarState();
}

class _ServiclySidebarState extends State<ServiclySidebar> {
  // Estado para controlar si el menú está colapsado
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final user = context.watch<UserModel?>();
    
    final isDark = theme.brightness == Brightness.dark;
    
    // Ancho dinámico: 260px expandido, 80px colapsado
    final width = _isCollapsed ? 80.0 : 260.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      width: width,
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardTheme.color, 
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
          // 1. HEADER (LOGO + TOGGLE)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _isCollapsed ? 12 : 24, 
              vertical: 24
            ),
            child: Row(
              mainAxisAlignment: _isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                // Logo Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.hub, color: colors.primary, size: 24),
                ),
                
                // Texto (Solo si expandido)
                if (!_isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Servicly',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Botón para colapsar (Flecha izquierda)
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: colors.onSurface.withValues(alpha: 0.5)),
                    onPressed: () => setState(() => _isCollapsed = true),
                    splashRadius: 20,
                  )
                ],
              ],
            ),
          ),

          // Botón para expandir (Solo visible si está colapsado y arriba)
          if (_isCollapsed)
            Center(
              child: IconButton(
                icon: Icon(Icons.chevron_right, color: colors.onSurface.withValues(alpha: 0.5)),
                onPressed: () => setState(() => _isCollapsed = false),
              ),
            ),

          // 2. MENÚ DE NAVEGACIÓN
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12), // Padding reducido
              children: [
                if (!_isCollapsed) const _SidebarSectionLabel(label: "GENERAL"),
                _SidebarItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Panel Principal',
                  isSelected: widget.selectedIndex == 0,
                  isCollapsed: _isCollapsed,
                  onTap: () => widget.onDestinationSelected(0),
                  activeColor: colors.primary,
                ),
                _SidebarItem(
                  icon: Icons.storefront_rounded,
                  label: 'Explorar Tiendas',
                  isSelected: widget.selectedIndex == 1,
                  isCollapsed: _isCollapsed,
                  onTap: () => widget.onDestinationSelected(1),
                  activeColor: colors.primary,
                ),
                
                const SizedBox(height: 24),
                if (!_isCollapsed) const _SidebarSectionLabel(label: "CRECIMIENTO"),
                _SidebarItem(
                  icon: Icons.lightbulb_outline_rounded,
                  label: 'Marketing',
                  isSelected: widget.selectedIndex == 2,
                  isCollapsed: _isCollapsed,
                  onTap: () => widget.onDestinationSelected(2),
                  activeColor: Colors.amber[700]!,
                ),
                 _SidebarItem(
                  icon: Icons.analytics_outlined,
                  label: 'Reportes',
                  isSelected: false,
                  isCollapsed: _isCollapsed,
                  onTap: () {},
                  activeColor: colors.primary,
                  isLocked: true,
                ),

                const SizedBox(height: 24),
                if (!_isCollapsed) const _SidebarSectionLabel(label: "CONFIGURACIÓN"),
                _SidebarItem(
                  icon: Icons.settings_outlined,
                  label: 'Ajustes',
                  isSelected: widget.selectedIndex == 3,
                  isCollapsed: _isCollapsed,
                  onTap: () => widget.onDestinationSelected(3),
                  activeColor: colors.primary,
                ),
              ],
            ),
          ),

          // Separador
          Divider(color: theme.dividerColor.withValues(alpha: 0.1), height: 1),

          // 3. TOGGLE DE TEMA
          _ThemeToggleRow(isDark: isDark, colors: colors, isCollapsed: _isCollapsed),

          // 4. FOOTER (USUARIO)
          if (user != null)
            Container(
              margin: EdgeInsets.all(_isCollapsed ? 8 : 16),
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
              child: _isCollapsed 
                ? Center(
                    child: CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(user.photoUrl ?? ''),
                      backgroundColor: colors.primary.withValues(alpha: 0.1),
                      child: user.photoUrl == null 
                          ? Text(user.displayName?[0].toUpperCase() ?? 'U', style: const TextStyle(fontSize: 12)) 
                          : null,
                    ),
                  )
                : Row(
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
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Plan Gratuito',
                              style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5), fontSize: 11),
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

// --- WIDGETS INTERNOS ADAPTADOS ---

class _ThemeToggleRow extends StatelessWidget {
  final bool isDark;
  final ColorScheme colors;
  final bool isCollapsed;

  const _ThemeToggleRow({required this.isDark, required this.colors, required this.isCollapsed});

  @override
  Widget build(BuildContext context) {
    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: IconButton(
            icon: Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
            color: colors.onSurface.withValues(alpha: 0.6),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
            tooltip: 'Cambiar Tema',
          ),
        ),
      );
    }

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
          SizedBox(
            height: 24,
            child: Switch(
              value: isDark,
              activeColor: colors.primary,
              onChanged: (value) => context.read<ThemeProvider>().toggleTheme(),
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
  final bool isCollapsed;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.activeColor,
    this.isLocked = false,
    required this.isCollapsed,
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
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 0 : 16, 
              vertical: 12
            ),
            decoration: BoxDecoration(
              color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? activeColor.withValues(alpha: 0.2) : Colors.transparent,
              ),
            ),
            child: isCollapsed 
              ? Center( // MODO COLAPSADO: Solo Icono centrado
                  child: Icon(
                    icon,
                    size: 24,
                    color: isLocked 
                        ? colorScheme.onSurface.withValues(alpha: 0.3)
                        : (isSelected ? activeColor : colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                )
              : Row( // MODO EXPANDIDO: Icono + Texto
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
                        overflow: TextOverflow.ellipsis,
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