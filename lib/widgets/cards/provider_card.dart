import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/public_profile_screen.dart';

class ProviderCard extends StatefulWidget {
  final ProviderProfileModel provider;
  final String? distanceText;

  const ProviderCard({
    super.key,
    required this.provider,
    this.distanceText,
  });

  @override
  State<ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<ProviderCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColor = widget.provider.brandColor;

    // Usamos el logoUrl como imagen principal. Si no hay, un fallback.
    final String displayImage = widget.provider.logoUrl;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Detectar si estamos en un grid ancho (Web) para activar la animación
        final isWebGrid = constraints.maxWidth > 200;

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              if (widget.provider.providerId.isNotEmpty) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PublicProfileScreen(providerId: widget.provider.providerId),
                  ),
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              // Efecto de elevación al hacer hover
              transform: Matrix4.translationValues(0.0, _isHovered ? -4.0 : 0.0, 0.0),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isHovered ? brandColor.withValues(alpha: 0.5) : theme.dividerColor.withValues(alpha: 0.1),
                  width: _isHovered ? 2 : 1
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isHovered 
                        ? brandColor.withValues(alpha: 0.15) 
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: _isHovered ? 20 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    // --- 1. FONDO: IMAGEN CON ZOOM ---
                    Positioned.fill(
                      child: AnimatedScale(
                        scale: _isHovered && isWebGrid ? 1.1 : 1.0, 
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        child: _buildImageArea(displayImage, theme, brandColor),
                      ),
                    ),

                    // --- 2. GRADIENTE OSCURO (Legibilidad) ---
                    // Siempre visible abajo para que el texto blanco se lea sobre cualquier foto
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      height: 150,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.9),
                              Colors.black.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // --- 3. BADGES SUPERIORES ---
                    Positioned(
                      top: 12, left: 12,
                      child: _buildProfileTypeChip(widget.provider.publicProfileTemplate ?? widget.provider.profileType),
                    ),

                    // --- 4. PANEL DE INFORMACIÓN ---
                    // Si es Web -> Animación Reveal. Si es Móvil -> Estático.
                    isWebGrid 
                      ? _buildWebRevealContent(brandColor)
                      : _buildMobileContent(brandColor),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- CONTENIDO WEB (REVEAL ANIMATION) ---
  // El contenido sube y muestra el botón al pasar el mouse
  Widget _buildWebRevealContent(Color brandColor) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rating (Equivalente al precio en productos)
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  widget.provider.ratingAvg > 0 
                      ? widget.provider.ratingAvg.toStringAsFixed(1) 
                      : "Nuevo",
                  style: const TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.w900, // Extra bold como el precio
                    fontSize: 16,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)]
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            // Nombre del Negocio
            Text(
              widget.provider.businessName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
              maxLines: _isHovered ? 2 : 1, 
              overflow: TextOverflow.ellipsis,
            ),

            // Elementos Reveal (Fade In + Slide Up)
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 8), // Espacio mínimo
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  
                  // Ubicación
                  if ((widget.provider.address ?? '').isNotEmpty)
                    Text(
                      widget.provider.address!,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  const SizedBox(height: 12),
                  
                  // Botón de Acción (Visitar)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                         Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PublicProfileScreen(providerId: widget.provider.providerId),
                            ),
                          );
                      }, 
                      style: FilledButton.styleFrom(
                        backgroundColor: brandColor,
                        foregroundColor: Colors.white, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Visitar Tienda"),
                    ),
                  )
                ],
              ),
              crossFadeState: _isHovered ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }

  // --- CONTENIDO MÓVIL (ESTÁTICO) ---
  Widget _buildMobileContent(Color brandColor) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.all(12),
        // Fondo semitransparente para leer bien en móvil
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.provider.businessName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      widget.provider.ratingAvg > 0 ? widget.provider.ratingAvg.toStringAsFixed(1) : "Nuevo",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
                Icon(Icons.arrow_forward_rounded, color: brandColor, size: 18),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---

  Widget _buildImageArea(String imageUrl, ThemeData theme, Color brandColor) {
    if (imageUrl.isEmpty) {
      return Container(
        color: brandColor.withValues(alpha: 0.1),
        child: Center(
          child: Icon(Icons.store, size: 40, color: brandColor.withValues(alpha: 0.4)),
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: brandColor.withValues(alpha: 0.1),
          child: Center(
            child: Icon(Icons.broken_image_outlined, size: 40, color: brandColor.withValues(alpha: 0.4)),
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(color: theme.cardColor);
      },
    );
  }

  Widget _buildProfileTypeChip(String? typeInput) {
    final type = (typeInput ?? 'cv').trim().toLowerCase();

    IconData icon;
    String label;
    Color color;

    switch (type) {
      case 'store':
        icon = Icons.shopping_bag_outlined;
        label = 'TIENDA';
        color = const Color(0xFF00BFFF); // Cyan Neon
        break;
      case 'catalog':
        icon = Icons.menu_book_rounded;
        label = 'CATÁLOGO';
        color = const Color(0xFFFFA500); // Naranja
        break;
      case 'cv':
        icon = Icons.person_outline;
        label = 'PROFESIONAL';
        color = const Color(0xFF6A5ACD); // Slate Blue
        break;
      case 'booking':
        icon = Icons.calendar_today_outlined;
        label = 'RESERVAS';
        color = Colors.greenAccent; 
        break;
      default:
        icon = Icons.verified_user_outlined;
        label = 'PERFIL';
        color = Colors.purpleAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6), // Fondo oscuro para el badge
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
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
}