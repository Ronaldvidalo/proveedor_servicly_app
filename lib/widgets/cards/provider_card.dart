import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/public_profile_screen.dart';

class ProviderCard extends StatelessWidget {
  final ProviderProfileModel provider;
  final String? distanceText; 

  const ProviderCard({
    super.key, 
    required this.provider, 
    this.distanceText,
  });

  // --- CHIP DE TIPO DE NEGOCIO (Tienda, Reserva, etc.) ---
  Widget _buildProfileTypeChip(BuildContext context) {
     IconData iconData;
     String label;
     Color color;
     const accentColorChip = Color(0xFF00BFFF);

     switch (provider.profileType) {
       case 'store':
         iconData = Icons.storefront_outlined;
         label = 'Tienda';
         color = accentColorChip;
         break;
       case 'booking':
         iconData = Icons.calendar_month_outlined;
         label = 'Reservas';
         color = Colors.greenAccent;
         break;
       case 'social':
         iconData = Icons.person_outline_rounded;
         label = 'Perfil';
         color = Colors.purpleAccent;
         break;
       default:
         iconData = Icons.business_rounded;
         label = 'Servicio';
         color = Colors.white70;
     }

     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
       decoration: BoxDecoration(
         color: const Color(0xFF2D2D5A).withOpacity(0.9),
         borderRadius: BorderRadius.circular(8),
         border: Border.all(color: color.withOpacity(0.3), width: 1),
       ),
       child: Row(
         mainAxisSize: MainAxisSize.min,
         children: [
           Icon(iconData, size: 12, color: color),
           const SizedBox(width: 4),
           Text(
             label, 
             style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)
           ),
         ],
       ),
     );
  }

  // --- CHIP DE VALORACIÓN (Rating) ---
  Widget _buildRatingChip() {
    if (provider.averageRating == null || provider.averageRating == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.amber, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 12),
          const SizedBox(width: 2),
          Text(
            provider.averageRating!.toStringAsFixed(1),
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Color(0xFF2D2D5A);
    final brandColor = provider.brandColor;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PublicProfileScreen(providerId: provider.providerId),
        ));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
          decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          // Borde sutil del color de la marca
          border: Border.all(color: brandColor.withOpacity(0.4), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 4))
          ]
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              // -----------------------------------------
              // CAPA 1: IMAGEN DE FONDO (LOGO)
              // -----------------------------------------
              Positioned.fill(
                child: provider.logoUrl.isNotEmpty
                    ? Image.network(
                        provider.logoUrl, 
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, loading) => loading == null 
                            ? child 
                            : Center(child: Container(color: surfaceColor)),
                        errorBuilder: (ctx, err, stack) => Container(
                          color: surfaceColor, 
                          child: Icon(Icons.store, color: brandColor.withOpacity(0.5), size: 40)
                        ),
                      )
                    : Container(
                        color: brandColor.withOpacity(0.2), 
                        child: Icon(Icons.store, color: brandColor.withOpacity(0.5), size: 40)
                      ),
              ),
              
              // -----------------------------------------
              // CAPA 2: GRADIENTE (Para legibilidad)
              // -----------------------------------------
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.9),
                      ],
                      stops: const [0.3, 0.6, 1.0],
                    )
                  ),
                ),
              ),

              // -----------------------------------------
              // CAPA 3: CONTENIDO
              // -----------------------------------------
              
              // --- Parte Superior (Badges) ---
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildProfileTypeChip(context),
                    _buildRatingChip(),
                  ],
                ),
              ),

              // --- Parte Inferior (Información) ---
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nombre del Negocio
                    Text(
                      provider.businessName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: Colors.white, 
                        fontSize: 15,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)]
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Categoría / Slogan
                    Text(
                      // Priorizamos el Slogan si es corto, sino la Categoría, sino 'Servicio'
                      (provider.slogan != null && provider.slogan!.isNotEmpty && provider.slogan!.length < 30)
                          ? provider.slogan!
                          : (provider.category ?? 'Servicio Profesional'), 
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 6),

                    // Fila: Ubicación y Distancia
                    Row(
                      children: [
                        // Icono Dirección
                        Icon(Icons.location_on_outlined, size: 12, color: Colors.white.withOpacity(0.7)),
                        const SizedBox(width: 2),
                        
                        // Texto Dirección (Ciudad/Barrio)
                        Expanded(
                          child: Text(
                            provider.address ?? 'Sin dirección',
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Chip de Distancia (Solo si existe)
                        if (distanceText != null) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: distanceText!.contains('km') || distanceText!.contains('m') 
                                  ? Colors.greenAccent 
                                  : Colors.amberAccent, 
                                width: 1
                              )
                            ),
                            child: Text(
                              distanceText!,
                              style: const TextStyle(
                                color: Colors.white, 
                                fontSize: 9, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ]
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
}