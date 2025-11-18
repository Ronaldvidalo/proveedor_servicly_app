// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 27/10/2025
// Style: Cyber Glow
// Este es un widget de encabezado reutilizable.
// 1. Está refactorizado para leer TODOS los colores del ThemeService.
// 2. Soluciona el error de overflow de texto moviendo las acciones (Tema, Logout)
//    a un PopupMenu elegante dentro del CircleAvatar.
// 3. Se conecta a los campos correctos de `userModel.personalization`
//    (logoUrl, businessName, slogan) para mostrar la identidad de la marca.
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- Importaciones de Modelos y Servicios (Ajusta tus rutas) ---
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/theme_service.dart';
import 'package:proveedor_servicly_app/shared/theme/screens/theme_selection_screen.dart';

/// Encabezado reutilizable del Dashboard que muestra información del usuario
/// y contiene los botones globales de Tema y Cerrar Sesión.
class DashboardHeader extends StatelessWidget {
  final UserModel userModel;
  
  const DashboardHeader({super.key, required this.userModel}); 

  @override
  Widget build(BuildContext context) {
    
    // --- Lógica de Tema ---
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // --- Lógica de Datos ---
    final personalization = userModel.personalization;
    final businessName = personalization['businessName'] as String? ?? userModel.displayName ?? 'Mi Negocio';
    // Usa 'slogan' primero, y 'welcomeMessage' como fallback.
    final String slogan = personalization['slogan'] as String? ?? personalization['welcomeMessage'] as String? ?? '';
    final String displayName = userModel.displayName ?? 'bienvenido';

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Columna de texto (Nombre/Negocio y Slogan)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Hola, $displayName!',
                    style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface.withOpacity(0.7)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    businessName,
                    style: theme.textTheme.headlineSmall?.copyWith( 
                      color: colors.onBackground,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: colors.primary.withAlpha(128), blurRadius: 10),
                        Shadow(color: colors.primary.withAlpha(77), blurRadius: 20),
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
                        color: colors.onSurface.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 16),

            // 2. --- Menú de Acciones en el Avatar (Conectado) ---
            _UserActionsMenu(userModel: userModel),
          ],
        ),
      ),
    );
  }
}

/// Un widget que combina el Avatar del usuario con un PopupMenu
/// para las acciones de "Cambiar Tema" y "Cerrar Sesión".
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
    
    // Usamos Consumer para reaccionar a los cambios de tema
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {

        return PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'toggle_theme') {
              // Navegar a la pantalla de selección de tema
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ThemeSelectionScreen(), 
                ),
              );
            } else if (value == 'logout') {
              _confirmLogout(context, authService);
            }
          },
          color: colors.surface, // Fondo del menú
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            // Opción 1: Cambiar Apariencia
            PopupMenuItem<String>(
              value: 'toggle_theme',
              child: Row(
                children: [
                  Icon(
                    Icons.color_lens_outlined, 
                    color: colors.onSurface.withOpacity(0.7),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Cambiar Apariencia', 
                    style: TextStyle(color: colors.onSurface),
                  ),
                ],
              ),
            ),
            // Opción 2: Cerrar Sesión
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, color: colors.error),
                  const SizedBox(width: 12),
                  Text(
                    'Cerrar Sesión',
                    style: TextStyle(color: colors.error),
                  ),
                ],
              ),
            ),
          ],
          // El "botón" que el usuario toca: el Avatar
          child: CircleAvatar(
            radius: 24,
            backgroundColor: colors.surface,
            backgroundImage: logoUrl != null && logoUrl.isNotEmpty
                ? NetworkImage(logoUrl) // Usa el logo de la marca
                : null,
            child: logoUrl == null || logoUrl.isEmpty
                ? Icon(Icons.person_outline_rounded, // Fallback icon
                    size: 28, color: colors.primary) 
                : null,
          ),
        );
      },
    );
  }

  /// Muestra el diálogo de confirmación de "Cerrar Sesión"
  Future<void> _confirmLogout(BuildContext context, AuthService authService) async {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: colors.surface, 
            title: Text('Confirmar', style: TextStyle(color: colors.onSurface)), 
            content: Text('¿Seguro que quieres cerrar sesión?',
                style: TextStyle(color: colors.onSurface.withOpacity(0.7))), 
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar')
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                    backgroundColor: colors.error),
                child: const Text('Cerrar Sesión'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      if (context.mounted) {
        await authService.signOut();
      }
    }
  }
}