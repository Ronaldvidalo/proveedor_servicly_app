import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/services/follow_service.dart';
// ¡Importante! Necesitamos una forma de navegar al Login si no está logueado
// import 'package:proveedor_servicly_app/features/auth/screens/auth_screen.dart'; 

/// Un botón inteligente y reutilizable que maneja su propio estado de "Seguir".
///
/// Se conecta a FollowService para saber si el [clientId] actual
/// está siguiendo al [providerId].
class FollowButton extends StatelessWidget {
  /// El ID del proveedor (el perfil que se está viendo).
  final String providerId;
  
  /// El ID del cliente (el usuario que está usando la app).
  /// Si es 'null', el usuario no está logueado.
  final String? clientId;

  const FollowButton({
    super.key,
    required this.providerId,
    this.clientId,
  });

  @override
  Widget build(BuildContext context) {
    final followService = context.read<FollowService>();
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);

    // --- CASO 1: El usuario NO está logueado (visitante) ---
    if (clientId == null) {
      return FilledButton.icon(
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Seguir'),
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: () {
          // TODO: Navegar a la pantalla de Login/Registro
          // Navigator.of(context).push(MaterialPageRoute(
          //   builder: (_) => const AuthScreen(),
          // ));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Inicia sesión para seguir a este proveedor.'),
            backgroundColor: Colors.orange,
          ));
        },
      );
    }

    // --- CASO 2: El usuario SÍ está logueado ---
    // Usamos un StreamBuilder para que el botón reaccione en tiempo real.
    return StreamBuilder<bool>(
      stream: followService.isFollowing(clientId!, providerId),
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;

        if (isFollowing) {
          // --- Botón de "Siguiendo" (Estilo Secundario) ---
          return OutlinedButton.icon(
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Siguiendo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: accentColor,
              backgroundColor: surfaceColor, // Fondo oscuro
              side: BorderSide(color: accentColor.withAlpha(100)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () {
              // Acción: Dejar de Seguir
              followService.unfollowProvider(clientId!, providerId);
            },
          );
        } else {
          // --- Botón de "Seguir" (Estilo Primario) ---
          return FilledButton.icon(
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Seguir'),
            style: FilledButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () {
              // Acción: Seguir
              followService.followProvider(clientId!, providerId);
            },
          );
        }
      },
    );
  }
}