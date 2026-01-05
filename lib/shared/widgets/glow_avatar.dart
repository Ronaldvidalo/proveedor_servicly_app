import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../theme/cyber_theme.dart';

class GlowAvatar extends StatelessWidget {
  final UserModel? user;
  final double radius;
  final VoidCallback? onTap;

  const GlowAvatar({
    super.key,
    required this.user,
    this.radius = 24,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Normalizamos el plan (minusculas para evitar errores)
    final String planType = (user?.planType ?? 'free').toLowerCase();

    // 2. Definimos variables de estilo según el plan
    Color borderColor;
    String badgeText;
    bool hasGlow; // Para decidir si lleva sombra neón o solo borde plano

    switch (planType) {
      case 'corporate':
      case 'enterprise': // Por si usas este nombre en el futuro
        borderColor = const Color(0xFFFFD700); // 🟡 Dorado (Gold)
        badgeText = "CORP";
        hasGlow = true; // Brilla mucho
        break;

      case 'pro':
      case 'business':
        borderColor = const Color(0xFF00E5FF); // 🔵 Cyan (Cyber Blue)
        badgeText = "PRO";
        hasGlow = true; // Brilla
        break;

      case 'free':
      default:
        borderColor = const Color(0xFF00FF7F); // 🟢 Verde Primavera (SpringGreen)
        badgeText = "FREE";
        // Decisión de diseño: El Free tiene borde y etiqueta para que se sepa su rol,
        // pero NO tiene "Glow" (sombra) para que los Pro destaquen más.
        // Si quieres que el Free también brille, cambia esto a true.
        hasGlow = false; 
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // --- CONTENEDOR PRINCIPAL ---
          Container(
            padding: const EdgeInsets.all(3.0), // Espacio para el borde
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // El borde siempre existe, cambia de color
              border: Border.all(color: borderColor, width: 2),
              // La sombra (Glow) solo si hasGlow es true
              boxShadow: hasGlow 
                  ? CyberStyles.getGlow(context, color: borderColor, isFocused: true)
                  : null,
            ),
            child: CircleAvatar(
              radius: radius,
              backgroundColor: Colors.grey.shade800,
              backgroundImage: (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                  ? NetworkImage(user!.photoUrl!)
                  : null,
              child: (user?.photoUrl == null || user!.photoUrl!.isEmpty)
                  ? Text(
                      user?.displayName?.substring(0, 1).toUpperCase() ?? "U",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: radius * 0.8,
                      ),
                    )
                  : null,
            ),
          ),

          // --- ETIQUETA DEL PLAN (BADGE) ---
          Positioned(
            bottom: -2, // Ajustado para que no tape tanto la foto
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: borderColor, // Fondo del color del plan
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black, width: 1.5), // Borde negro para contraste
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Colors.black, // Texto negro sobre color neón se lee mejor
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}