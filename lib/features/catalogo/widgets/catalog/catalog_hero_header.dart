import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/features/booking/screens/booking_screen.dart';

// ✅ Importamos los widgets compartidos para mantener la consistencia técnica
import 'package:proveedor_servicly_app/features/reviews/widgets/provider_rating_badge.dart';

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
    
    // ✅ Lógica dinámica del botón principal según la configuración del editor
    final bool isAgenda = profile.bookingActionType == 'agenda';
    final String buttonLabel = profile.bookingButtonText ?? (isAgenda ? "Agendar Cita" : "Pedir Presupuesto");
    
    // Altura extendida para contener toda la información sin scroll inicial
    const double headerHeight = 480.0;

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
            // 1. IMAGEN DE FONDO (COVER)
            // ✅ Ahora utiliza coverImageUrl como prioridad, igual que en el editor
            _buildBackgroundImage(brandColor),

            // 2. GRADIENTES DE CONTRASTE (Protección de lectura)
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black54, // Sombra para botones superiores
                      Colors.transparent,
                      Colors.black,   // Negro profundo para la info inferior
                    ],
                    stops: [0.0, 0.3, 0.85],
                  ),
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
                  // Avatar con borde nítido vinculado a logoUrl
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

            // 4. SECCIÓN INFERIOR: Rating, Info y CTA principal
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // ✅ WIDGET REUTILIZABLE DE RATING (Espejo del editor)
                  ProviderRatingBadge(
                    profile: profile,
                    starSize: 20,
                    textStyle: const TextStyle(
                      color: Colors.white, 
                      fontSize: 26, 
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black45)]
                    ),
                  ),
                  
                  const SizedBox(height: 14),

                  // Filas de Información basadas en address
                  _buildInfoRow(Icons.location_on_outlined, profile.address ?? "Consultar ubicación"),
                  _buildInfoRow(Icons.access_time_rounded, profile.openingHours ?? "Consultar horario"),
                  
                  const SizedBox(height: 20),

                  // Barra de Acción Directa
                  Row(
                    children: [
                      // Botones de contacto flotantes
                      if (profile.whatsapp != null && profile.whatsapp!.isNotEmpty)
                        _buildContactIcon(Icons.chat_bubble_outline, const Color(0xFF00B2B2), "whatsapp"),
                      const SizedBox(width: 12),
                      if (profile.phone != null && profile.phone!.isNotEmpty)
                        _buildContactIcon(Icons.phone_outlined, Colors.white70, "tel"),
                      
                      const SizedBox(width: 16),
                      
                      // ✅ Botón Dinámico: Refleja la elección del editor
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF00B2B2),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 4,
                              shadowColor: const Color(0xFF00B2B2).withValues(alpha: 0.3),
                            ),
                            onPressed: () {
                              if (isAgenda) {
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(builder: (_) => BookingScreen(providerId: profile.providerId))
                                );
                              } else {
                                // Lógica para Pedir Presupuesto (WhatsApp o Formulario)
                                _handleQuoteAction();
                              }
                            },
                            child: Text(
                              buttonLabel.toUpperCase(), 
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.8)
                            ),
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

  // --- MÉTODOS DE CONSTRUCCIÓN TÉCNICA ---

  Widget _buildBackgroundImage(Color brandColor) {
    // ✅ Prioridad: coverImageUrl -> logoUrl -> brandColor
    if (profile.coverImageUrl != null && profile.coverImageUrl!.isNotEmpty) {
      return Image.network(profile.coverImageUrl!, fit: BoxFit.cover);
    } else if (profile.logoUrl.isNotEmpty) {
      return Image.network(profile.logoUrl, fit: BoxFit.cover);
    } else {
      return Container(color: brandColor.withValues(alpha: 0.6));
    }
  }

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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00B2B2), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text, 
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 14, 
                shadows: [Shadow(blurRadius: 6, color: Colors.black)]
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          ),
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
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _buildTopAction(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isEditor ? const Color(0xFF00B2B2) : Colors.white10,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: isEditor 
        ? const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
            child: Text("EDITOR", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
          )
        : IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20), 
            onPressed: () {},
            tooltip: 'Compartir',
          ),
    );
  }

  void _handleQuoteAction() {
    // Lógica para disparar el flujo de presupuesto/whatsapp
    debugPrint("Acción de Presupuesto disparada");
  }
}