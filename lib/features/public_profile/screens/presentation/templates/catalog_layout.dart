import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/category_model.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/services/category_service.dart';
import 'package:proveedor_servicly_app/core/services/product_service.dart';
import 'package:proveedor_servicly_app/features/booking/screens/booking_screen.dart';

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
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1A1A2E);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // --- MÓDULO 1: Cabecera y Credibilidad ---
          _buildSliverAppBar(context, widget.profile),

          // --- MÓDULO 1.5: CTA Principal (Botón "Agendar Cita") ---
          _buildPrimaryCtaModule(context, widget.profile),

          // --- MÓDULO 2: Información y Contacto ---
          _buildInfoModule(context, widget.profile),

          // --- MÓDULO 4: Portafolio/Galería ---
          _buildPortfolioModule(context, widget.profile),

          // --- MÓDULO 3: Catálogo de Servicios (Tu lógica anterior) ---
          _buildServicesModule(context, widget.profile),

          // --- MÓDULO 5: Reseñas y Calificaciones ---
          _buildReviewsModule(context, widget.profile),
        ],
      ),
    );
  }

  // --- MÓDULO 1: Cabecera (El que ya teníamos) ---
  Widget _buildSliverAppBar(BuildContext context, ProviderProfileModel profile) {
    final brandColor = profile.brandColor;
    return SliverAppBar(
      expandedHeight: 280.0,
      pinned: true,
      backgroundColor: const Color(0xFF1A1A2E),
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          profile.businessName,
          style: TextStyle(
            color: ThemeData.estimateBrightnessForColor(brandColor) == Brightness.dark
                ? Colors.white
                : Colors.black,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
          ),
        ),
        centerTitle: true,
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (profile.logoUrl.isNotEmpty)
              Image.network(
                profile.logoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: brandColor),
              ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withAlpha(102), Colors.black.withAlpha(204)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MÓDULO 1.5: CTA Principal (Nuevo) ---
  Widget _buildPrimaryCtaModule(BuildContext context, ProviderProfileModel profile) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ranking (Placeholder de datos)
            Row(
              children: [
                Icon(Icons.star, color: Colors.yellow[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  "4.8 (158 Reseñas)", // TODO: Leer desde profile.ranking
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
                      ThemeData.estimateBrightnessForColor(profile.brandColor) ==
                              Brightness.dark
                          ? Colors.white
                          : Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle:
                      const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
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

  // --- MÓDULO 2: Información y Contacto (Mejorado) ---
  Widget _buildInfoModule(BuildContext context, ProviderProfileModel profile) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
            
            // Bio (Lo que hicimos en ManageCatalogScreen)
            if (profile.showWelcomeModule && profile.welcomeModuleType == 'text' && profile.welcomeMessage.isNotEmpty)
              Text(
                profile.welcomeMessage,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            
            // TODO: Añadir el widget de VideoPlayer aquí
            if (profile.showWelcomeModule && profile.welcomeModuleType == 'video')
              Container( /* Placeholder para el video */ ),

            const SizedBox(height: 24),

            // --- Datos de Contacto (como el mockup) ---
            _InfoRow(
              icon: Icons.access_time_outlined,
              text: profile.openingHours ?? 'Horario no definido', // TODO: Añadir a ProfileModel
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.location_on_outlined,
              text: profile.address ?? 'Dirección no definida',
            ),
            const SizedBox(height: 24),
            
            // Botones de Contacto
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // TODO: Añadir profile.phone
                IconButton.filled(
                  onPressed: () { /* TODO: launchUrl('tel:${profile.phone}') */ },
                  icon: const Icon(Icons.phone_outlined),
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF2D2D5A)),
                ),
                const SizedBox(width: 16),
                IconButton.filled(
                  onPressed: () { /* TODO: launchUrl('https://wa.me/${profile.whatsapp}') */ },
                  icon: const Icon(Icons.chat_bubble_outline), // Usar un Icono de WhatsApp si lo tienes
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF2D2D5A)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- MÓDULO 4: Portafolio (Nuevo Placeholder) ---
  Widget _buildPortfolioModule(BuildContext context, ProviderProfileModel profile) {
    // TODO: Leer del 'PermissionsService' si este módulo está habilitado
    // if (!permissions.canUsePortfolioModule) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Portafolio',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 16),
            // TODO: Reemplazar con un StreamBuilder a la sub-colección 'portfolio'
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D5A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('Galería de Imágenes (Próximamente)', style: TextStyle(color: Colors.white70)),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- MÓDULO 3: Catálogo de Servicios (Tu lógica anterior, ahora modularizada) ---
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
        _CategorySelector(
          providerId: profile.providerId,
          selectedCategoryId: _selectedCategoryId,
          brandColor: profile.brandColor,
          onCategorySelected: (categoryId) {
            setState(() {
              _selectedCategoryId = categoryId;
            });
          },
        ),
        StreamBuilder<List<ProductModel>>(
          stream: productService.getProducts(profile.providerId,
              categoryId: _selectedCategoryId),
          builder: (context, snapshot) {
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

  // --- MÓDULO 5: Reseñas (Nuevo Placeholder) ---
  Widget _buildReviewsModule(BuildContext context, ProviderProfileModel profile) {
    // TODO: Leer del 'PermissionsService' si este módulo está habilitado
    // if (!permissions.canUseReviewsModule) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reseñas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 16),
            // TODO: Reemplazar con un StreamBuilder a la sub-colección 'reviews'
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D5A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('Módulo de Reseñas (Próximamente)', style: TextStyle(color: Colors.white70)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// --- WIDGETS AUXILIARES (Sin cambios) ---

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}

class _ServiceCard extends StatelessWidget {
  // ... (Tu código de _ServiceCard no cambia)
  final ProductModel service;
  final Color brandColor;
  final String providerId;

  const _ServiceCard(
      {required this.service,
      required this.brandColor,
      required this.providerId});

  @override
  Widget build(BuildContext context) {
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
                errorBuilder: (context, error, stack) => const SizedBox(
                    height: 150,
                    child: Icon(Icons.error, color: Colors.white38)),
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
                        '\$${service.price.toStringAsFixed(2)}',
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

class _CategorySelector extends StatelessWidget {
  // ... (Tu código de _CategorySelector no cambia)
  final String providerId;
  final String? selectedCategoryId;
  final Color brandColor;
  final ValueChanged<String?> onCategorySelected;

  const _CategorySelector({
    required this.providerId,
    required this.selectedCategoryId,
    required this.brandColor,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final categoryService = context.read<CategoryService>();

    return StreamBuilder<List<CategoryModel>>(
      stream: categoryService.getCategories(providerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final categories = snapshot.data!;

        return SizedBox(
          height: 60,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
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
              return Padding(
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

class _LoadingState extends StatelessWidget {
  // ... (Tu código de _LoadingState no cambia)
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return const Center(
        child: Padding(
      padding: EdgeInsets.all(32.0),
      child: CircularProgressIndicator(),
    ));
  }
}

class _EmptyState extends StatelessWidget {
  // ... (Tu código de _EmptyState no cambia)
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 80, color: Colors.white24),
            SizedBox(height: 24),
            Text(
              'Sin Servicios',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Este proveedor aún no ha añadido servicios a esta categoría.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  // ... (Tu código de _ErrorState no cambia)
  final String error;
  const _ErrorState({required this.error});
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text('Error al cargar servicios:\n$error',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.redAccent)),
    ));
  }
}