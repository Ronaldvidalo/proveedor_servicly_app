import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Modelos y Servicios Existentes
import 'package:proveedor_servicly_app/core/models/category_model.dart'; // Para servicios
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/services/category_service.dart'; // Para servicios
import 'package:proveedor_servicly_app/core/services/product_service.dart';
// --- NUEVOS IMPORTS ---
import 'package:proveedor_servicly_app/core/services/firestore_service.dart'; // Para portafolio
import 'package:proveedor_servicly_app/core/models/portfolio_category_model.dart'; // Para portafolio
import 'package:proveedor_servicly_app/core/models/portfolio_item_model.dart'; // Para portafolio

import 'package:proveedor_servicly_app/features/booking/screens/booking_screen.dart'; // Para botón Agendar

// TODO: Importar 'package:url_launcher/url_launcher.dart' para botones de contacto
// import 'package:url_launcher/url_launcher.dart';


/// Layout "Landing Page" de un proveedor.
/// Actúa como el perfil público centralizado, combinando información,
/// portafolio, servicios y reseñas en una sola vista optimizada para la conversión.
class CatalogLayout extends StatefulWidget {
  final String providerId;
  final ProviderProfileModel profile;

  const CatalogLayout({
    super.key,
    required this.providerId,
    required this.profile,
  });

  @override
  State<CatalogLayout> createState() => _CatalogLayoutState();
}

class _CatalogLayoutState extends State<CatalogLayout> {
  // Estado para el filtro de SERVICIOS
  String? _selectedServiceCategoryId;
  // Estado para el filtro de PORTAFOLIO
  String? _selectedPortfolioCategoryId;

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1A1A2E);

    // Determinar si algún módulo debe ocultarse
    final showWelcome = widget.profile.showWelcomeModule;
    final showPortfolio = widget.profile.showPortfolioModule;
    final showReviews = widget.profile.showReviewsModule;
    final showPromotions = widget.profile.showPromotionsModule;
    final showGiftCards = widget.profile.showGiftCardModule;


    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // --- MÓDULO 1: Cabecera y Credibilidad ---
          _buildSliverAppBar(context, widget.profile),

          // --- MÓDULO 1.5: CTA Principal (Botón "Agendar Cita") ---
          _buildPrimaryCtaModule(context, widget.profile),

          // --- MÓDULO 2: Información y Contacto ---
          // Incluye el módulo de bienvenida (texto/video) si está activo
          _buildInfoModule(context, widget.profile, showWelcome),

          // --- MÓDULO Promociones (Placeholder) ---
           if (showPromotions) _buildPromotionsModule(context, widget.profile),

          // --- MÓDULO Portafolio ---
          if (showPortfolio) _buildPortfolioModule(context, widget.profile),

          // --- MÓDULO Gift Cards (Placeholder) ---
           if (showGiftCards) _buildGiftCardModule(context, widget.profile),

          // --- MÓDULO Catálogo de Servicios ---
          _buildServicesModule(context, widget.profile),

          // --- MÓDULO Reseñas ---
          if (showReviews) _buildReviewsModule(context, widget.profile),

          // Espacio extra al final para que no quede pegado al borde inferior
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // --- MÓDULO 1: Cabecera ---
  Widget _buildSliverAppBar(BuildContext context, ProviderProfileModel profile) {
    final brandColor = profile.brandColor;
    return SliverAppBar(
      expandedHeight: 280.0,
      pinned: true,
      backgroundColor: const Color(0xFF1A1A2E), // Fondo oscuro base
      foregroundColor: Colors.white, // Color de iconos y texto del AppBar
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 72, bottom: 16, end: 72), // Ajustar padding del título
        title: Text(
          profile.businessName,
          style: TextStyle(
            color: ThemeData.estimateBrightnessForColor(brandColor) == Brightness.dark
                ? Colors.white // Texto blanco si el color de marca es oscuro
                : Colors.black, // Texto negro si el color de marca es claro
            fontWeight: FontWeight.bold,
            fontSize: 16, // Tamaño estándar para AppBar colapsado
            shadows: const [Shadow(color: Colors.black54, blurRadius: 4)], // Sombra más sutil
          ),
          overflow: TextOverflow.ellipsis, // Evitar overflow
          maxLines: 1,
        ),
        centerTitle: true,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen de fondo (logo/banner)
            if (profile.logoUrl.isNotEmpty)
              Image.network(
                profile.logoUrl,
                fit: BoxFit.cover,
                // Placeholder mientras carga o si hay error
                loadingBuilder: (context, child, loadingProgress) {
                   if (loadingProgress == null) return child;
                   return Container(color: brandColor.withOpacity(0.5)); // Color base mientras carga
                 },
                errorBuilder: (_, __, ___) => Container(color: brandColor), // Color base si falla
              )
            else // Si no hay logo, usar el color de marca como fondo
              Container(color: brandColor),

            // Filtro de desenfoque y gradiente oscuro para legibilidad del título
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3), // Desenfoque más sutil
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3), // Menos opaco arriba
                      Colors.black.withOpacity(0.7), // Más opaco abajo para el título
                    ],
                    stops: const [0.0, 0.8], // Controlar dónde empieza el gradiente más oscuro
                  ),
                ),
              ),
            ),
             // Eslogan opcional sobre la imagen de fondo (si se define)
            if (profile.slogan != null && profile.slogan!.isNotEmpty)
              Positioned(
                bottom: 60, // Posición estimada sobre el título
                left: 16,
                right: 16,
                child: Text(
                  profile.slogan!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    shadows: const [Shadow(color: Colors.black87, blurRadius: 6)],
                  ),
                   maxLines: 2,
                   overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- MÓDULO 1.5: CTA Principal ---
  Widget _buildPrimaryCtaModule(BuildContext context, ProviderProfileModel profile) {
    // Formatear el ranking y número de reseñas
    final String ratingText = profile.averageRating != null
        ? profile.averageRating!.toStringAsFixed(1)
        : '-.-';
    final String reviewCountText = profile.reviewCount != null
        ? '(${profile.reviewCount} Reseñas)'
        : '(Sin Reseñas)';

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ranking
            Row(
              children: [
                Icon(Icons.star, color: Colors.yellow[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  "$ratingText $reviewCountText", // Mostrar datos reales o placeholders
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Botón Principal
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: profile.brandColor,
                  foregroundColor:
                      ThemeData.estimateBrightnessForColor(profile.brandColor) == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Bordes redondeados
                ),
                onPressed: () {
                  // Navegar a la pantalla de Booking
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => BookingScreen(providerId: profile.providerId),
                  ));
                },
                child: const Text('Agendar Cita Ahora'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MÓDULO 2: Información y Contacto ---
  Widget _buildInfoModule(BuildContext context, ProviderProfileModel profile, bool showWelcome) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), // Ajustar padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 16),

            // --- Módulo de Bienvenida (Texto o Video) ---
            // Se muestra aquí si está habilitado
            if (showWelcome) ...[
               _buildWelcomeContent(context, profile),
               const SizedBox(height: 24), // Espacio después del módulo de bienvenida
               const Divider(color: Colors.white24),
               const SizedBox(height: 24),
            ],

            // --- Datos de Contacto (Horario, Dirección, Botones) ---
            if (profile.openingHours != null && profile.openingHours!.isNotEmpty) ...[
              _InfoRow(
                icon: Icons.access_time_outlined,
                text: profile.openingHours!,
              ),
              const SizedBox(height: 12),
            ],
            if (profile.address != null && profile.address!.isNotEmpty) ...[
              _InfoRow(
                icon: Icons.location_on_outlined,
                text: profile.address!,
                // TODO: Hacer que al tocar abra el mapa?
              ),
              const SizedBox(height: 24),
            ],

            // Botones de Contacto (Teléfono, WhatsApp)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (profile.phone != null && profile.phone!.isNotEmpty) ...[
                  IconButton.filled(
                    onPressed: () async {
                      final Uri launchUri = Uri(scheme: 'tel', path: profile.phone!);
                      // TODO: Importar url_launcher y descomentar
                      // if (await canLaunchUrl(launchUri)) {
                      //   await launchUrl(launchUri);
                      // } else {
                      //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo llamar a ${profile.phone}')));
                      // }
                    },
                    icon: const Icon(Icons.phone_outlined),
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFF2D2D5A), foregroundColor: Colors.white),
                    tooltip: 'Llamar',
                  ),
                  const SizedBox(width: 16),
                ],
                if (profile.whatsapp != null && profile.whatsapp!.isNotEmpty) ...[
                  IconButton.filled(
                    onPressed: () async {
                      // Crear URL de WhatsApp (simple, sin mensaje predefinido)
                      // Asume que el número incluye código de país y está bien formateado
                      final Uri launchUri = Uri.parse('https://wa.me/${profile.whatsapp!.replaceAll('+', '')}');
                       // TODO: Importar url_launcher y descomentar
                      // if (await canLaunchUrl(launchUri)) {
                      //   await launchUrl(launchUri, mode: LaunchMode.externalApplication); // Abrir en app externa
                      // } else {
                      //    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo abrir WhatsApp para ${profile.whatsapp}')));
                      // }
                    },
                    icon: const Icon(Icons.chat_bubble_outline), // TODO: Usar ícono de WhatsApp si se añade dependencia
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFF2D2D5A), foregroundColor: Colors.white),
                    tooltip: 'WhatsApp',
                  ),
                  const SizedBox(width: 16), // Espacio por si se añaden más iconos
                ],
                 // Podrías añadir Email aquí si es relevante
                 // if (profile.contactEmail.isNotEmpty) ...[ ... ],
              ],
            ),
          ],
        ),
      ),
    );
  }

   /// Widget interno para mostrar el contenido del módulo de bienvenida (texto o video).
  Widget _buildWelcomeContent(BuildContext context, ProviderProfileModel profile) {
    // --- Opción 1: Mostrar TEXTO ---
    if (profile.welcomeModuleType == 'text') {
       if (profile.welcomeMessage.isEmpty) return const SizedBox.shrink(); // No mostrar nada si está vacío
      return Text(
        profile.welcomeMessage,
        style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4), // Mejorar legibilidad
      );
    }

    // --- Opción 2: Mostrar VIDEO ---
    if (profile.welcomeModuleType == 'video' && profile.welcomeVideoUrl != null && profile.welcomeVideoUrl!.isNotEmpty) {
      // *** PLACEHOLDER ***
      // Aquí iría la lógica para inicializar y mostrar el VideoPlayer
      // o el YouTubePlayer, dependiendo de si es 'upload' o 'url'.
      return AspectRatio( // Mantener proporción del video
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black, // Fondo negro para videos
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_fill_outlined, size: 50, color: Colors.white54),
                SizedBox(height: 8),
                Text("Reproductor de Video (Próximamente)", style: TextStyle(color: Colors.white54)),
              ],
            ),
          ),
        ),
      );
    }

    // No mostrar nada si el tipo es video pero no hay URL
    return const SizedBox.shrink();
  }


  // --- MÓDULO Promociones (Placeholder) ---
  Widget _buildPromotionsModule(BuildContext context, ProviderProfileModel profile) {
     return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Promociones',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 120, // Altura ejemplo
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D5A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('Módulo de Promociones (Próximamente)', style: TextStyle(color: Colors.white70)),
              ),
            )
          ],
        ),
      ),
    );
  }


  // --- MÓDULO 4: Portafolio (Implementado) ---
  Widget _buildPortfolioModule(BuildContext context, ProviderProfileModel profile) {
     final firestoreService = context.read<FirestoreService>();

    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Text(
            'Portafolio',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
        ),

        // --- Selector de Categorías del Portafolio ---
        _PortfolioCategorySelector(
          providerId: profile.providerId,
          selectedPortfolioCategoryId: _selectedPortfolioCategoryId,
          brandColor: profile.brandColor,
          onCategorySelected: (categoryId) {
            setState(() {
              _selectedPortfolioCategoryId = categoryId;
            });
          },
        ),

        // --- Cuadrícula de Ítems del Portafolio ---
        StreamBuilder<List<PortfolioItemModel>>(
          stream: firestoreService.getPortfolioItemsStream(
              profile.providerId,
              // Si _selectedPortfolioCategoryId es null, pasamos un string vacío
              // El servicio debería manejar esto (o podríamos ajustar la consulta aquí)
              _selectedPortfolioCategoryId ?? ''),
          builder: (context, snapshot) {
             // Mostrar loading solo si hay una categoría seleccionada (no para "Todos")
            if (snapshot.connectionState == ConnectionState.waiting && _selectedPortfolioCategoryId != null) {
              return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator(color: Colors.white54)));
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error al cargar portafolio: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
              );
            }
            // Mostrar mensaje si no hay ítems en la categoría seleccionada (o en "Todos")
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              // Verificamos si existen categorías en general antes de mostrar el mensaje
              return StreamBuilder<List<PortfolioCategoryModel>>(
                 stream: firestoreService.getPortfolioCategoriesStream(profile.providerId),
                 builder: (context, catSnapshot) {
                   // Solo muestra "No hay ítems" si SÍ existen categorías en el portafolio
                   if (catSnapshot.hasData && catSnapshot.data!.isNotEmpty) {
                     return const Padding(
                       padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 48.0), // Más padding vertical
                       child: Center(child: Text('No hay fotos o videos en esta categoría.', style: TextStyle(color: Colors.white54, fontSize: 16))),
                     );
                   }
                   // Si no hay categorías, este módulo no debería mostrar nada (ni el selector)
                   // La lógica en el builder principal (_buildPortfolioModule) debería manejar esto.
                   // Pero por si acaso, devolvemos vacío aquí.
                   return const SizedBox.shrink();
                 }
              );
            }

            // --- Mostrar la Cuadrícula ---
            final items = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 1.0,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _PortfolioItemCard(item: item);
                },
              ),
            );
          },
        ),
      ]),
    );
  }

  // --- MÓDULO Gift Cards (Placeholder) ---
  Widget _buildGiftCardModule(BuildContext context, ProviderProfileModel profile) {
     return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tarjetas de Regalo',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 120, // Altura ejemplo
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D5A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('Módulo de Gift Cards (Próximamente)', style: TextStyle(color: Colors.white70)),
              ),
            )
          ],
        ),
      ),
    );
  }


  // --- MÓDULO Catálogo de Servicios ---
  Widget _buildServicesModule(BuildContext context, ProviderProfileModel profile) {
    final productService = context.read<ProductService>();

    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Text(
            'Catálogo de Servicios',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
        ),
        // Usa la variable de estado correcta aquí
        _ServiceCategorySelector( // Renombrado
          providerId: profile.providerId,
          selectedCategoryId: _selectedServiceCategoryId, // Variable correcta
          brandColor: profile.brandColor,
          onCategorySelected: (categoryId) {
            setState(() {
              _selectedServiceCategoryId = categoryId; // Variable correcta
            });
          },
        ),
        StreamBuilder<List<ProductModel>>(
          // Usa la variable de estado correcta aquí
          stream: productService.getProducts(profile.providerId,
              categoryId: _selectedServiceCategoryId), // Variable correcta
          builder: (context, snapshot) {
            // ... (resto del builder sin cambios) ...
                 if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingState();
            }
            if (snapshot.hasError) {
              return _ErrorState(error: snapshot.error.toString());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const _EmptyState();
            }
            final services = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return _ServiceCard(
                      service: service,
                      brandColor: profile.brandColor,
                      providerId: profile.providerId);
                },
              ),
            );
          },
        ),
      ]),
    );
  }


  // --- MÓDULO Reseñas ---
  Widget _buildReviewsModule(BuildContext context, ProviderProfileModel profile) {
     return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16), // Ajustar padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row( // Usar Row para el título y el botón "Ver todas"
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               crossAxisAlignment: CrossAxisAlignment.center,
               children: [
                 Text(
                   'Reseñas',
                   style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                         fontWeight: FontWeight.bold,
                         color: Colors.white,
                       ),
                 ),
                 if (profile.reviewCount != null && profile.reviewCount! > 0)
                   TextButton(
                     onPressed: () { /* TODO: Navegar a pantalla de todas las reseñas */ },
                     child: Text('Ver todas (${profile.reviewCount})'),
                     style: TextButton.styleFrom(foregroundColor: profile.brandColor),
                   ),
               ],
             ),
            const SizedBox(height: 16),
            // TODO: Reemplazar con StreamBuilder real y carrusel/lista de reseñas destacadas
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D5A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('Reseñas Destacadas (Próximamente)', style: TextStyle(color: Colors.white70)),
              ),
            )
          ],
        ),
      ),
    );
  }

} // Fin _CatalogLayoutState

// --- WIDGETS AUXILIARES ---

// Widget para fila de información (Icono + Texto)
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  // final VoidCallback? onTap; // Opcional para hacerlo interactivo

  const _InfoRow({required this.icon, required this.text /*, this.onTap */});

  @override
  Widget build(BuildContext context) {
    return InkWell( // Hacer la fila "tocable" si hay onTap
       // onTap: onTap,
       child: Padding( // Añadir padding interno para mejor toque
         padding: const EdgeInsets.symmetric(vertical: 4.0),
         child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
               ),
       ),
    );
  }
}

// Widget para tarjeta de Servicio
class _ServiceCard extends StatelessWidget {
  final ProductModel service;
  final Color brandColor;
  final String providerId;

  const _ServiceCard(
      {required this.service,
      required this.brandColor,
      required this.providerId});

  @override
  Widget build(BuildContext context) {
    // ... (Código sin cambios) ...
        return Card(
      color: const Color(0xFF2D2D5A),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: brandColor.withAlpha(128), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (service.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                service.imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                   return Container( height: 150, color: Colors.white10, child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
                 },
                errorBuilder: (context, error, stack) => const SizedBox(
                    height: 150,
                    child: Center(child: Icon(Icons.error_outline, color: Colors.white38))),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                if (service.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(service.description,
                      style: const TextStyle(color: Colors.white70),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (service.price > 0)
                      Text(
                        // TODO: Considerar formateo de moneda local
                        '\$${service.price.toStringAsFixed(service.price.truncateToDouble() == service.price ? 0 : 2)}', // Mostrar decimales solo si son necesarios
                        style: TextStyle(
                            color: brandColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => BookingScreen(providerId: providerId),
                        ));
                      },
                      icon: const Icon(Icons.calendar_month_outlined, size: 18),
                      label: const Text('Agendar Turno'),
                      style: FilledButton.styleFrom(
                        backgroundColor: brandColor,
                        foregroundColor:
                            ThemeData.estimateBrightnessForColor(brandColor) ==
                                    Brightness.dark
                                ? Colors.white
                                : Colors.black,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- RENOMBRADO ---
// Widget selector para categorías de SERVICIOS
class _ServiceCategorySelector extends StatelessWidget {
  final String providerId;
  final String? selectedCategoryId;
  final Color brandColor;
  final ValueChanged<String?> onCategorySelected;

  const _ServiceCategorySelector({
    required this.providerId,
    required this.selectedCategoryId,
    required this.brandColor,
    required this.onCategorySelected,
  });

   @override
  Widget build(BuildContext context) {
    // Usar CategoryService (para PRODUCTOS)
    final categoryService = context.read<CategoryService>();

    return StreamBuilder<List<CategoryModel>>(
      stream: categoryService.getCategories(providerId), // Llama al método correcto
      builder: (context, snapshot) {
         // ... (resto del código del selector de categorías de servicio sin cambios) ...
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(height: 60); // Ocupar espacio aunque esté vacío
        }
        final categories = snapshot.data!;

        return SizedBox(
          height: 60,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) { /* ... Botón "Ver Todos" ... */
                   final isSelected = selectedCategoryId == null;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: const Text('Ver Todos'),
                    selected: isSelected,
                    onSelected: (selected) => onCategorySelected(null),
                    selectedColor: brandColor,
                    labelStyle: TextStyle(
                        color: isSelected
                            ? (ThemeData.estimateBrightnessForColor(
                                        brandColor) ==
                                    Brightness.dark
                                ? Colors.white
                                : Colors.black)
                            : Colors.white),
                    backgroundColor: const Color(0xFF2D2D5A),
                    shape: StadiumBorder(
                        side: BorderSide(
                            color: isSelected ? brandColor : Colors.white38)),
                  ),
                );
              }
              final category = categories[index - 1];
              final isSelected = selectedCategoryId == category.id;
              return Padding( /* ... Botón de categoría ... */
                   padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(category.name),
                  selected: isSelected,
                  onSelected: (selected) => onCategorySelected(category.id),
                  selectedColor: brandColor,
                  labelStyle: TextStyle(
                      color: isSelected
                          ? (ThemeData.estimateBrightnessForColor(
                                      brandColor) ==
                                  Brightness.dark
                              ? Colors.white
                              : Colors.black)
                          : Colors.white),
                  backgroundColor: const Color(0xFF2D2D5A),
                  shape: StadiumBorder(
                      side: BorderSide(
                          color: isSelected ? brandColor : Colors.white38)),
                ),
              );
            },
          ),
        );
      },
    );
  }
}


// --- NUEVO WIDGET: Selector de Categorías del Portafolio ---
class _PortfolioCategorySelector extends StatelessWidget {
  final String providerId;
  final String? selectedPortfolioCategoryId;
  final Color brandColor;
  final ValueChanged<String?> onCategorySelected;

  const _PortfolioCategorySelector({
    required this.providerId,
    required this.selectedPortfolioCategoryId,
    required this.brandColor,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return StreamBuilder<List<PortfolioCategoryModel>>(
      stream: firestoreService.getPortfolioCategoriesStream(providerId),
      builder: (context, snapshot) {
        // Si no hay categorías, no mostrar nada (ni siquiera el espacio)
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final categories = snapshot.data!;

        // Mostrar el selector solo si hay categorías
        return SizedBox(
          height: 60,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1, // +1 para "Ver Todos"
            itemBuilder: (context, index) {
              if (index == 0) { /* ... Botón "Ver Todos" ... */
                 final isSelected = selectedPortfolioCategoryId == null;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: const Text('Ver Todos'),
                    selected: isSelected,
                    onSelected: (selected) => onCategorySelected(null),
                    selectedColor: brandColor,
                     labelStyle: TextStyle(color: isSelected ? (ThemeData.estimateBrightnessForColor(brandColor) == Brightness.dark ? Colors.white : Colors.black) : Colors.white),
                    backgroundColor: const Color(0xFF2D2D5A),
                    shape: StadiumBorder(side: BorderSide(color: isSelected ? brandColor : Colors.white38)),
                  ),
                );
              }
              final category = categories[index - 1];
              final isSelected = selectedPortfolioCategoryId == category.id;
              return Padding( /* ... Botón de categoría ... */
                   padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(category.name),
                  selected: isSelected,
                  onSelected: (selected) => onCategorySelected(category.id),
                  selectedColor: brandColor,
                   labelStyle: TextStyle(color: isSelected ? (ThemeData.estimateBrightnessForColor(brandColor) == Brightness.dark ? Colors.white : Colors.black) : Colors.white),
                  backgroundColor: const Color(0xFF2D2D5A),
                  shape: StadiumBorder(side: BorderSide(color: isSelected ? brandColor : Colors.white38)),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// --- NUEVO WIDGET: Tarjeta para un Ítem del Portafolio en la Cuadrícula ---
class _PortfolioItemCard extends StatelessWidget {
  final PortfolioItemModel item;

  const _PortfolioItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector( // Hacerlo "tocable"
       onTap: () {
         // TODO: Implementar visualización fullscreen (ej: showDialog con la imagen/video)
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Vista fullscreen próximamente para ${item.type == PortfolioItemType.image ? "imagen" : "video"}'), duration: Duration(seconds: 1)),
         );
       },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFF2D2D5A),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: item.type == PortfolioItemType.image
              ? Image.network(
                  item.url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    // Indicador de carga más sutil
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24));
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.broken_image_outlined, color: Colors.white38);
                  },
                )
              // Placeholder para video con icono de play
              : Stack( // Usar Stack para superponer el icono
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    // Podríamos intentar cargar un thumbnail si la URL lo permite
                    // o simplemente fondo negro
                    Container(color: Colors.black),
                    const Icon(Icons.play_circle_fill_outlined, color: Colors.white54, size: 40),
                    // Aquí iría la lógica del thumbnail o VideoPlayer en el futuro
                  ],
                ),
        ),
      ),
    );
  }
}


// _LoadingState, _EmptyState, _ErrorState (Sin Cambios)
class _LoadingState extends StatelessWidget {
 const _LoadingState();
 @override
 Widget build(BuildContext context) {
   return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator(color: Colors.white54,)));
 }
}
class _EmptyState extends StatelessWidget {
 const _EmptyState();
 @override
 Widget build(BuildContext context) {
   return const Padding( // Usar Padding en lugar de Center para controlar el espacio
     padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 48.0),
     child: Center(
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Icon(Icons.inventory_2_outlined, size: 60, color: Colors.white24), // Icono más relevante
           SizedBox(height: 16),
           Text(
             'Sin Servicios',
             style: TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.bold),
           ),
           SizedBox(height: 8),
           Text(
             'Este proveedor aún no ha añadido servicios a esta categoría.',
             textAlign: TextAlign.center,
             style: TextStyle(fontSize: 14, color: Colors.white54),
           ),
         ],
       ),
     ),
   );
 }
}
class _ErrorState extends StatelessWidget {
 final String error;
 const _ErrorState({required this.error});
 @override
 Widget build(BuildContext context) {
   return Padding( // Usar Padding
     padding: const EdgeInsets.all(16.0),
     child: Center(child: Text('Error al cargar servicios:\n$error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent))),
   );
 }
}