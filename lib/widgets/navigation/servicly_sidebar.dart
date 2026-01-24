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
    
    // Ancho dinámico
    final width = _isCollapsed ? 80.0 : 260.0;

    // Colores definidos manualmente para asegurar contraste en ambos modos
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300;
    final sidebarBg = theme.cardTheme.color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      width: width,
      height: double.infinity,
      decoration: BoxDecoration(
        color: sidebarBg, 
        border: Border(
          right: BorderSide(color: borderColor, width: 1),
        ),
      ),
      // Usamos ClipRect para evitar que el contenido se desborde visualmente mientras se anima el ancho
      child: ClipRect(
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
                      // SingleChildScrollView horizontal evita el error de overflow momentáneo
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: Text(
                          'Servicly',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_left, color: colors.onSurface.withValues(alpha: 0.5)),
                      onPressed: () => setState(() => _isCollapsed = true),
                      splashRadius: 20,
                    )
                  ],
                ],
              ),
            ),

            // Botón para expandir (Solo visible si está colapsado)
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
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
                    activeColor: Colors.amber.shade700, 
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

            // Separador visible
            Divider(color: borderColor, height: 1),

            // 3. TOGGLE DE TEMA (CORREGIDO)
            _ThemeToggleRow(isDark: isDark, colors: colors, isCollapsed: _isCollapsed),

            // 4. FOOTER (USUARIO)
            if (user != null)
              Container(
                margin: EdgeInsets.all(_isCollapsed ? 8 : 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor), // Borde sólido
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
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
                            ? Text(user.displayName?[0].toUpperCase() ?? 'U', style: TextStyle(fontSize: 12, color: colors.primary)) 
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
                              ? Text(user.displayName?[0].toUpperCase() ?? 'U', style: TextStyle(color: colors.primary)) 
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
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.onSurface),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Plan Gratuito',
                                style: TextStyle(color: colors.onSurface.withValues(alpha: 0.6), fontSize: 11),
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
    // Definimos colores específicos para que el botón resalte en modo claro
    final containerColor = isDark 
        ? colors.surfaceContainerHighest.withValues(alpha: 0.3) 
        : Colors.grey.shade200; // Gris sólido visible en modo claro
        
    final borderColor = isDark 
        ? colors.outlineVariant.withValues(alpha: 0.5) 
        : Colors.grey.shade300; // Borde sólido

    // Si está colapsado, mostramos el icono con fondo
    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: containerColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor),
            ),
            child: IconButton(
              icon: Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
              color: colors.onSurface.withValues(alpha: 0.8), // Más oscuro para contraste
              onPressed: () => context.read<ThemeProvider>().toggleTheme(),
              tooltip: 'Cambiar Tema',
              splashRadius: 24,
            ),
          ),
        ),
      );
    }

    // Si está expandido, mostramos la cápsula completa
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: containerColor, // Fondo sólido
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  size: 20,
                  color: colors.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  isDark ? "Modo Oscuro" : "Modo Claro",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700, // Negrita extra
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
            // Switch con pista visible
            SizedBox(
              height: 24,
              child: Switch(
                value: isDark,
                activeColor: colors.primary,
                // Colores para cuando está inactivo (Modo Claro)
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey.shade400, 
                onChanged: (value) => context.read<ThemeProvider>().toggleTheme(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarSectionLabel extends StatelessWidget {
  final String label;
  const _SidebarSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8, top: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800, // Extra Bold para que se lea en gris
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
    
    // Texto gris oscuro sólido si no está seleccionado, para que no se pierda en blanco
    final normalColor = colorScheme.onSurface.withValues(alpha: 0.8);
    final lockedColor = colorScheme.onSurface.withValues(alpha: 0.3);
    
    final foregroundColor = isLocked 
        ? lockedColor
        : (isSelected ? activeColor : normalColor);

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
              // Fondo sutil al seleccionar
              color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? activeColor.withValues(alpha: 0.2) : Colors.transparent,
              ),
            ),
            child: isCollapsed 
              ? Center( 
                  child: Icon(
                    icon,
                    size: 24,
                    color: foregroundColor,
                  ),
                )
              : Row( 
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: foregroundColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      // Flexible + Ellipsis evita el overflow horizontal
                      child: Text(
                        label,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: foregroundColor,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLocked)
                      Icon(Icons.lock_outline, size: 14, color: lockedColor),
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