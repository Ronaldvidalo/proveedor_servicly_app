import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/features/booking/screens/booking_screen.dart';

class CatalogHeroHeader extends StatelessWidget {
  final ProviderProfileModel profile;
  final bool isEditor;
  final Function(Uri url, String source)? onContactTap;
  
  // --- PROPIEDADES DE SEGUIMIENTO ---
  final bool isFollowing;
  final VoidCallback? onFollowTap;

  const CatalogHeroHeader({
    super.key, 
    required this.profile, 
    this.isEditor = false,
    this.onContactTap,
    this.isFollowing = false,
    this.onFollowTap,
  });

  @override
  Widget build(BuildContext context) {
    // Definimos el color de marca (fallback a un color oscuro si es nulo)
    final brandColor = profile.brandColor ?? const Color(0xFF1A1A2E);
    
    // Lógica para el texto del Rating (ej: "4.8")
    final double ratingValue = profile.averageRating ?? 5.0;
    final String ratingText = ratingValue.toStringAsFixed(1);
    final int reviewCount = profile.reviewCount ?? 0;
    
    // Altura extendida para contener toda la información sin scroll inicial
    const double headerHeight = 460.0;

    return SliverAppBar(
      expandedHeight: headerHeight,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF1A1A2E),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 1. IMAGEN DE FONDO
            if (profile.logoUrl.isNotEmpty)
              Image.network(profile.logoUrl, fit: BoxFit.cover)
            else
              Container(color: brandColor.withAlpha(150)),

            // 2. GRADIENTES DE CONTRASTE (Protección de lectura)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black54, // Sombra para botones superiores
                    Colors.transparent,
                    Colors.black,   // Negro profundo para la info inferior
                  ],
                  stops: [0.0, 0.3, 0.82],
                ),
              ),
            ),

            // 3. SECCIÓN SUPERIOR: Identidad y Acciones Rápidas
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  // Avatar con borde nítido
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white24),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundImage: profile.logoUrl.isNotEmpty ? NetworkImage(profile.logoUrl) : null,
                      backgroundColor: Colors.white10,
                      child: profile.logoUrl.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      profile.businessName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Botón Seguir / Siguiendo (Solo si no es editor)
                  if (!isEditor) ...[
                    _buildFollowButton(),
                    const SizedBox(width: 8),
                  ],

                  // Acción secundaria (Compartir o Guardar)
                  _buildTopAction(context),
                ],
              ),
            ),

            // 4. SECCIÓN INFERIOR: Rating, Contacto y CTA principal
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // --- BLOQUE DE CALIFICACIÓN (INTEGRADO AQUÍ) ---
                  Row(
                    children: [
                      Text(
                        ratingText, 
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 26, 
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black45)]
                        )
                      ),
                      const SizedBox(width: 8),
                      // Generación dinámica de estrellas
                      ...List.generate(5, (index) {
                        IconData icon;
                        if (index < ratingValue.floor()) {
                          icon = Icons.star; // Estrella llena
                        } else if (index < ratingValue) {
                          icon = Icons.star_half; // Media estrella
                        } else {
                          icon = Icons.star_border; // Estrella vacía
                        }
                        return Icon(
                          icon,
                          color: Colors.amber,
                          size: 20,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        '($reviewCount Reviews)', 
                        style: const TextStyle(
                          color: Colors.white70, 
                          fontSize: 13,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black45)]
                        )
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // ----------------------------------------------

                  // Filas de Información sutiles
                  _buildInfoRow(Icons.location_on_outlined, profile.address ?? "Consultar ubicación"),
                  _buildInfoRow(Icons.access_time_rounded, profile.openingHours ?? "Consultar horario"),
                  
                  const SizedBox(height: 20),

                  // Barra de Acción Directa
                  Row(
                    children: [
                      // Botones de contacto flotantes
                      if (profile.whatsapp != null)
                        _buildContactIcon(Icons.chat_bubble_outline, Colors.greenAccent, "whatsapp"),
                      const SizedBox(width: 12),
                      if (profile.phone != null)
                        _buildContactIcon(Icons.phone_outlined, Colors.blueAccent, "tel"),
                      
                      const SizedBox(width: 16),
                      
                      // Botón Agendar: Fuerte contraste y jerarquía
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF00B2B2),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                              shadowColor: const Color(0xFF00B2B2).withAlpha(100),
                            ),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(providerId: profile.providerId))),
                            child: const Text("Agendar Cita Ahora", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildFollowButton() {
    return InkWell(
      onTap: onFollowTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.white10 : const Color(0xFF00B2B2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isFollowing ? Colors.white38 : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(isFollowing ? Icons.check : Icons.add, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              isFollowing ? "Siguiendo" : "Seguir",
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, shadows: [Shadow(blurRadius: 6, color: Colors.black)]))),
        ],
      ),
    );
  }

  Widget _buildContactIcon(IconData icon, Color color, String type) {
    return InkWell(
      onTap: () {
        if (onContactTap == null) return;
        final uri = type == "whatsapp" 
          ? Uri.parse("https://wa.me/${profile.whatsapp?.replaceAll(RegExp(r'[^\d]'), '')}")
          : Uri.parse("tel:${profile.phone}");
        onContactTap!(uri, "catalogo_$type");
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(120),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildTopAction(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isEditor ? const Color(0xFF00B2B2) : Colors.white10,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: isEditor 
        ? const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
            child: Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          )
        : IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20), 
            onPressed: () {},
            tooltip: 'Compartir',
          ),
    );
  }
}