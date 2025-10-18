import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/category_model.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/services/category_service.dart';
import 'package:proveedor_servicly_app/core/services/product_service.dart';
// --- NUEVA IMPORTACIÓN ---
import 'package:proveedor_servicly_app/features/booking/screens/booking_screen.dart';

/// Un widget de layout que muestra el perfil de un proveedor con un estilo de "Catálogo de Servicios".
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
    final productService = context.read<ProductService>();
    final brandColor = widget.profile.brandColor;
    const backgroundColor = Color(0xFF1A1A2E);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, widget.profile, brandColor),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Text(
                    'Nuestros Servicios',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                _CategorySelector(
                  providerId: widget.providerId,
                  selectedCategoryId: _selectedCategoryId,
                  brandColor: brandColor,
                  onCategorySelected: (categoryId) {
                    setState(() {
                      _selectedCategoryId = categoryId;
                    });
                  },
                ),
              ],
            ),
          ),
          StreamBuilder<List<ProductModel>>(
            stream: productService.getProducts(widget.providerId, categoryId: _selectedCategoryId),
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
              return SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final service = services[index];
                      return _ServiceCard(service: service, brandColor: brandColor, providerId: widget.providerId);
                    },
                    childCount: services.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ProviderProfileModel profile, Color brandColor) {
    return SliverAppBar(
      expandedHeight: 280.0,
      pinned: true,
      backgroundColor: const Color(0xFF1A1A2E),
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          profile.businessName,
          style: TextStyle(
            color: ThemeData.estimateBrightnessForColor(brandColor) == Brightness.dark ? Colors.white : Colors.black,
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
}

/// Una tarjeta que representa un servicio en el catálogo.
class _ServiceCard extends StatelessWidget {
  final ProductModel service;
  final Color brandColor;
  final String providerId;

  const _ServiceCard({required this.service, required this.brandColor, required this.providerId});

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
                errorBuilder: (context, error, stack) => const SizedBox(height: 150, child: Icon(Icons.error, color: Colors.white38)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                if (service.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(service.description, style: const TextStyle(color: Colors.white70), maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if(service.price > 0)
                      Text(
                        '\$${service.price.toStringAsFixed(2)}',
                        style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () {
                        // --- MODIFICACIÓN CLAVE ---
                        // Navega a la pantalla de reserva de turnos.
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => BookingScreen(providerId: providerId),
                        ));
                      },
                      icon: const Icon(Icons.calendar_month_outlined, size: 18),
                      label: const Text('Agendar Turno'),
                      style: FilledButton.styleFrom(
                        backgroundColor: brandColor,
                        foregroundColor: ThemeData.estimateBrightnessForColor(brandColor) == Brightness.dark ? Colors.white : Colors.black,
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

// --- WIDGETS AUXILIARES ---

class _CategorySelector extends StatelessWidget {
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
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        final categories = snapshot.data!;
        return SliverToBoxAdapter(
          child: SizedBox(
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
                      labelStyle: TextStyle(color: isSelected ? (ThemeData.estimateBrightnessForColor(brandColor) == Brightness.dark ? Colors.white : Colors.black) : Colors.white),
                      backgroundColor: const Color(0xFF2D2D5A),
                      shape: StadiumBorder(side: BorderSide(color: isSelected ? brandColor : Colors.white38)),
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
                    labelStyle: TextStyle(color: isSelected ? (ThemeData.estimateBrightnessForColor(brandColor) == Brightness.dark ? Colors.white : Colors.black) : Colors.white),
                    backgroundColor: const Color(0xFF2D2D5A),
                    shape: StadiumBorder(side: BorderSide(color: isSelected ? brandColor : Colors.white38)),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}


class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(child: Center(child: Padding(
      padding: EdgeInsets.all(32.0),
      child: CircularProgressIndicator(),
    )));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(
      child: Center(
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
                style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
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
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Center(child: Text('Error al cargar servicios:\n$error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent))),
    );
  }
}

