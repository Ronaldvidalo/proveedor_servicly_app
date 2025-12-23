import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/public_profile_screen.dart';

/// Una tarjeta estilizada ("Cyber Glow") para mostrar una vista previa de un proveedor.
class ProviderCard extends StatelessWidget {
  final ProviderProfileModel provider;
  final String? distanceText;

  const ProviderCard({
    super.key,
    required this.provider,
    this.distanceText,
  });

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Color(0xFF2D2D5A);
    final brandColor = provider.brandColor;

    return InkWell(
      onTap: () {
        if (provider.providerId.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PublicProfileScreen(providerId: provider.providerId),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            // ✅ CORRECCIÓN: withValues en lugar de withOpacity
            color: brandColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              // ✅ CORRECCIÓN: withValues en lugar de withOpacity
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14.5),
          child: Stack(
            children: [
              // --- FOTO DE FONDO ---
              Positioned.fill(
                child: (provider.logoUrl.isNotEmpty && provider.logoUrl.startsWith('http'))
                    ? Image.network(
                        provider.logoUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(color: surfaceColor);
                        },
                        errorBuilder: (context, error, stackTrace) => _buildImageError(brandColor, surfaceColor),
                      )
                    : _buildImageError(brandColor, surfaceColor),
              ),

              // --- GRADIENTE ---
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        // ✅ CORRECCIÓN: withValues en lugar de withOpacity
                        Colors.black.withValues(alpha: 0.1),
                        // ✅ CORRECCIÓN: withValues en lugar de withOpacity
                        Colors.black.withValues(alpha: 0.4),
                        // ✅ CORRECCIÓN: withValues en lugar de withOpacity
                        Colors.black.withValues(alpha: 0.95),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // --- BADGE SUPERIOR (TIPO DE PERFIL) ---
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // AQUI SE LLAMA AL CONSTRUCTOR DE ETIQUETAS MEJORADO
                    _buildProfileTypeChip(provider.publicProfileTemplate ?? provider.profileType),
                    const SizedBox.shrink(), 
                  ],
                ),
              ),

              // --- INFO INFERIOR ---
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      provider.businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      provider.welcomeMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      // ✅ CORRECCIÓN: withValues en lugar de withOpacity
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // ✅ CORRECCIÓN: withValues en lugar de withOpacity
                        Icon(Icons.location_on_rounded, size: 12, color: brandColor.withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            provider.address ?? 'Sin dirección',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            // ✅ CORRECCIÓN: withValues en lugar de withOpacity
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10),
                          ),
                        ),
                        if (distanceText != null) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              // ✅ CORRECCIÓN: withValues en lugar de withOpacity
                              color: brandColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              // ✅ CORRECCIÓN: withValues en lugar de withOpacity
                              border: Border.all(color: brandColor.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              distanceText!,
                              style: TextStyle(color: brandColor, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- LOGICA DE ETIQUETAS MEJORADA ---
  Widget _buildProfileTypeChip(String? typeInput) {
    // Normalizamos el string (minusculas y sin espacios)
    final type = (typeInput ?? 'cv').trim().toLowerCase();

    IconData icon;
    String label;
    Color color;

    switch (type) {
      case 'store':
        icon = Icons.shopping_cart_rounded;
        label = 'TIENDA';
        color = const Color(0xFF00BFFF); // Cyan Neon
        break;
        
      case 'catalog':
        icon = Icons.collections_bookmark_rounded;
        label = 'CATÁLOGO';
        color = const Color(0xFFFFA500); // Naranja
        break;
        
      case 'cv':
        icon = Icons.work_rounded;
        label = 'PROFESIONAL';
        color = const Color(0xFF6A5ACD); // Slate Blue
        break;
        
      case 'booking':
        icon = Icons.calendar_today_rounded;
        label = 'RESERVAS';
        color = Colors.greenAccent; // Verde
        break;
        
      default:
        icon = Icons.person_rounded;
        label = 'PERFIL';
        color = Colors.purpleAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        // ✅ CORRECCIÓN: withValues en lugar de withOpacity
        color: const Color(0xFF1A1A2E).withValues(alpha: 0.9), // Fondo oscuro para legibilidad
        borderRadius: BorderRadius.circular(8),
        // ✅ CORRECCIÓN: withValues en lugar de withOpacity
        border: Border.all(color: color.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageError(Color brandColor, Color surfaceColor) {
    return Container(
      color: surfaceColor,
      child: Center(
        child: Icon(
          Icons.storefront_rounded,
          size: 48,
          // ✅ CORRECCIÓN: withValues en lugar de withOpacity
          color: brandColor.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}