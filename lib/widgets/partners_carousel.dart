import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

/// Un widget de carrusel reutilizable que muestra logos de partners
/// en un bucle automático infinito.
class PartnersCarousel extends StatelessWidget {
  final List<Map<String, dynamic>> partners;
  final double height;

  const PartnersCarousel({
    super.key,
    required this.partners,
    this.height = 60.0, // Altura por defecto para los logos
  });

  @override
  Widget build(BuildContext context) {
    // Si no hay partners, no muestra nada.
    if (partners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      // Fondo sutil para separar la sección del resto
      color: Colors.black.withAlpha(20),
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: CarouselSlider.builder(
        itemCount: partners.length,
        itemBuilder: (context, index, realIndex) {
          final partner = partners[index];
          return _PartnerLogo(
            logoUrl: partner['logoUrl'] ?? '',
            name: partner['name'] ?? 'Partner',
          );
        },
        options: CarouselOptions(
          height: height,
          autoPlay: true, // Reproducción automática
          
          // --- ¡CORRECCIÓN AQUÍ! ---
          // 'infiniteScroll' se renombró a 'enableInfiniteScroll'
          enableInfiniteScroll: true, // Bucle infinito
          // --- FIN DE LA CORRECCIÓN ---

          autoPlayInterval: const Duration(seconds: 3), // Tiempo entre logos
          autoPlayAnimationDuration: const Duration(milliseconds: 1200), // Duración de la animación
          autoPlayCurve: Curves.linear, // Movimiento constante
          viewportFraction: 0.33, // Cuántos logos se ven (aprox. 3)
          pauseAutoPlayOnTouch: false, // No pausar al tocar
          enlargeCenterPage: false, // No agrandar el logo central
        ),
      ),
    );
  }
}

/// Widget auxiliar privado para mostrar un solo logo de partner.
/// Aplica un filtro gris para mantener la consistencia visual.
class _PartnerLogo extends StatelessWidget {
  final String logoUrl;
  final String name;
  
  const _PartnerLogo({required this.logoUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Image.network(
        logoUrl,
        height: 60,
        semanticLabel: name,
        // Filtro de color para "neutralizar" los logos
        color: Colors.white.withAlpha(200),
        colorBlendMode: BlendMode.modulate,
        // Loader mientras carga
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        // En caso de error, muestra el nombre
        errorBuilder: (context, error, stackTrace) => Center(
          child: Text(
            name,
            style: const TextStyle(color: Colors.white30, fontSize: 10),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}