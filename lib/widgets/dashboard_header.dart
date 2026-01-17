// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 19/11/2025
// Style: Cyber Glow
//
// (FIX) Agregado botón de Ayuda (onHelpTap) directamente en el Header.
// Esto reemplaza el FAB flotante que no se veía en el Dashboard.
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- Importaciones de Modelos y Servicios ---
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/auth_service.dart';
// CAMBIO 1: Importamos ThemeProvider en lugar de ThemeService
import 'package:proveedor_servicly_app/providers/theme_provider.dart';
import 'package:proveedor_servicly_app/shared/theme/screens/theme_selection_screen.dart';

/// Encabezado reutilizable del Dashboard que muestra información del usuario
/// y contiene los botones globales de Tema, Ayuda y Cerrar Sesión.
class DashboardHeader extends StatelessWidget {
  final UserModel userModel;
  final VoidCallback? onHelpTap; 
  
  const DashboardHeader({
    super.key, 
    required this.userModel,
    this.onHelpTap, 
  }); 

  @override
  Widget build(BuildContext context) {
    
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final personalization = userModel.personalization;
    final businessName = personalization['businessName'] as String? ?? userModel.displayName ?? 'Mi Negocio';
    final String slogan = personalization['slogan'] as String? ?? personalization['welcomeMessage'] as String? ?? '';
    final String displayName = userModel.displayName ?? 'Bienvenido';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Columna de texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, $displayName!',
                  style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface.withValues(alpha: 0.7)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  businessName,
                  style: theme.textTheme.headlineSmall?.copyWith( 
                    color: colors.onSurface,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: colors.primary.withValues(alpha: 0.5), blurRadius: 10),
                      Shadow(color: colors.primary.withValues(alpha: 0.3), blurRadius: 20),
                    ],
                  ),
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis, 
                ),
                if (slogan.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    slogan,
                    style: theme.textTheme.bodyMedium?.copyWith( 
                      color: colors.onSurface.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // 2. Botón de Ayuda (Si se provee la función)
          if (onHelpTap != null)
            IconButton(
              onPressed: onHelpTap,
              icon: const Icon(Icons.help_outline_rounded),
              tooltip: 'Ver Tutorial',
              style: IconButton.styleFrom(
                foregroundColor: colors.primary,
                backgroundColor: colors.primary.withValues(alpha: 0.1),
              ),
            ),
          
          const SizedBox(width: 8),

          // 3. Menú de Usuario
          _UserActionsMenu(userModel: userModel),
        ],
      ),
    );
  }
}

/// Un widget que combina el Avatar del usuario con un PopupMenu
class _UserActionsMenu extends StatelessWidget {
  final UserModel userModel;
  
  const _UserActionsMenu({required this.userModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final authService = context.read<AuthService>();
    final personalization = userModel.personalization;
    final String? logoUrl = personalization['logoUrl'] as String?;
    
    // CAMBIO 2: Escuchamos ThemeProvider en lugar de ThemeService
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'toggle_theme') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ThemeSelectionScreen()),
              );
            } else if (value == 'logout') {
              _confirmLogout(context, authService);
            }
          },
          color: colors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'toggle_theme',
              child: Row(
                children: [
                  Icon(Icons.color_lens_outlined, color: colors.onSurface.withValues(alpha: 0.7)),
                  const SizedBox(width: 12),
                  Text('Cambiar Apariencia', style: TextStyle(color: colors.onSurface)),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, color: colors.error),
                  const SizedBox(width: 12),
                  Text('Cerrar Sesión', style: TextStyle(color: colors.error)),
                ],
              ),
            ),
          ],
          child: CircleAvatar(
            radius: 24,
            backgroundColor: colors.surface,
            backgroundImage: logoUrl != null && logoUrl.isNotEmpty
                ? NetworkImage(logoUrl)
                : null,
            child: logoUrl == null || logoUrl.isEmpty
                ? Icon(Icons.person_outline_rounded, size: 28, color: colors.primary) 
                : null,
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context, AuthService authService) async {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: colors.surface, 
            title: Text('Confirmar', style: TextStyle(color: colors.onSurface)), 
            content: Text('¿Seguro que quieres cerrar sesión?',
                style: TextStyle(color: colors.onSurface.withValues(alpha: 0.7))), 
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar')
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(backgroundColor: colors.error),
                child: const Text('Cerrar Sesión'),
              ),
            ],
          ),
        ) ?? false;

    if (confirm && context.mounted) {
        await authService.signOut();
    }
  }
}