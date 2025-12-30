import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Modelos y Servicios
import 'package:proveedor_servicly_app/core/models/category_model.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/services/category_service.dart';
import 'package:proveedor_servicly_app/core/services/product_service.dart';
import 'package:proveedor_servicly_app/features/catalogo/modules/_category_chip.dart';

class CatalogServicesSection extends StatefulWidget {
  final String providerId;
  final Color brandColor;
  final List<ProductModel> selectedServices; 
  final Function(ProductModel) onServiceTap; 

  const CatalogServicesSection({
    super.key,
    required this.providerId,
    required this.brandColor,
    required this.selectedServices,
    required this.onServiceTap,
  });

  @override
  State<CatalogServicesSection> createState() => _CatalogServicesSectionState();
}

class _CatalogServicesSectionState extends State<CatalogServicesSection> {
  String? _selectedServiceCategoryId;
  Stream<List<ProductModel>>? _productsStream;

  @override
  void initState() {
    super.initState();
    // ✅ INICIALIZACIÓN ÚNICA: Evita que el stream se resetee al seleccionar productos
    _initProductsStream();
  }

  void _initProductsStream() {
    final productService = context.read<ProductService>();
    _productsStream = productService.getProducts(
      widget.providerId, 
      categoryId: _selectedServiceCategoryId
    );
  }

  void _updateCategory(String? newCategoryId) {
    if (_selectedServiceCategoryId == newCategoryId) return;
    setState(() {
      _selectedServiceCategoryId = newCategoryId;
      _initProductsStream(); // ✅ Solo recreamos el stream si cambia la categoría
    });
  }

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 16, 8),
          child: Text(
            'Servicios y Precios',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        
        _buildServiceCategorySelector(),

        StreamBuilder<List<ProductModel>>(
          stream: _productsStream, // ✅ Usamos la variable persistente
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF00B2B2))),
              );
            }

            final services = snapshot.data ?? [];
            if (services.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text("No hay servicios", style: TextStyle(color: Colors.white24))),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return _ServiceItemRow(
                    service: service, 
                    brandColor: widget.brandColor,
                    isSelected: widget.selectedServices.any((s) => s.id == service.id),
                    onTap: () => widget.onServiceTap(service),
                  );
                },
              ),
            );
          },
        ),
      ]),
    );
  }

  Widget _buildServiceCategorySelector() {
    final categoryService = context.read<CategoryService>();
    return StreamBuilder<List<CategoryModel>>(
      stream: categoryService.getCategories(widget.providerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        final categories = snapshot.data!;

        return SizedBox(
          height: 55,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final cat = isAll ? null : categories[index - 1];
              final isSelected = isAll 
                  ? _selectedServiceCategoryId == null 
                  : _selectedServiceCategoryId == cat?.id;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: CategoryChip(
                  label: isAll ? 'Todos' : cat!.name,
                  isSelected: isSelected,
                  onTap: () => _updateCategory(isAll ? null : cat?.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ServiceItemRow extends StatelessWidget {
  final ProductModel service;
  final Color brandColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceItemRow({
    required this.service, 
    required this.brandColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 🔍 DETERMINAR MEDIO PRINCIPAL
    final String? mainImg = service.imageUrl.isNotEmpty ? service.imageUrl : null;
    final Map<String, dynamic>? firstGallery = service.mediaGallery.isNotEmpty ? service.mediaGallery.first : null;
    final String? thumbUrl = mainImg ?? firstGallery?['url'];
    final bool isVideo = firstGallery?['type'] == 'video' || (thumbUrl?.contains('.mp4') ?? false);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D5A).withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? brandColor : Colors.white.withOpacity(0.05),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 🖼️ MINIATURA CON DETECCIÓN DE VIDEO Y MAXIMIZADOR
            GestureDetector(
              onTap: () => _showFullscreen(context), // Maximiza al tocar el medio
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Hero(
                    tag: 'product_${service.id}',
                    child: Container(
                      width: 85, height: 85,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.black26,
                        image: thumbUrl != null 
                          ? DecorationImage(image: NetworkImage(thumbUrl), fit: BoxFit.cover) 
                          : null,
                      ),
                      child: thumbUrl == null ? const Icon(Icons.image_not_supported, color: Colors.white10) : null,
                    ),
                  ),
                  if (isVideo)
                    const Icon(Icons.play_circle_fill, color: Colors.white, size: 32),
                ],
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  if (service.description.isNotEmpty)
                    Text(service.description, style: const TextStyle(color: Colors.white60, fontSize: 12), maxLines: 2),
                  const SizedBox(height: 8),
                  Text("\$${NumberFormat("#,##0").format(service.price)}", 
                    style: TextStyle(color: brandColor, fontWeight: FontWeight.w900, fontSize: 17)),
                ],
              ),
            ),

            Icon(isSelected ? Icons.check_circle : Icons.add_circle_outline, color: isSelected ? brandColor : Colors.white24, size: 28),
          ],
        ),
      ),
    );
  }

  void _showFullscreen(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => FullscreenMediaViewer(service: service)
    ));
  }
}

// 🎬 VISUALIZADOR DE MEDIOS PRO (SOPORTA ZOOM Y VIDEO)
class FullscreenMediaViewer extends StatelessWidget {
  final ProductModel service;
  const FullscreenMediaViewer({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    // Combinar URL principal y galería para navegación
    final List<Map<String, dynamic>> mediaList = [
      if (service.imageUrl.isNotEmpty) {'url': service.imageUrl, 'type': 'image'},
      ...service.mediaGallery
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(service.name, style: const TextStyle(fontSize: 14)),
      ),
      body: PageView.builder(
        itemCount: mediaList.length,
        itemBuilder: (context, index) {
          final item = mediaList[index];
          final bool isVideo = item['type'] == 'video' || item['url'].toString().contains('.mp4');

          return Center(
            child: InteractiveViewer( // ✅ GESTOS DE ZOOM
              minScale: 0.5,
              maxScale: 4.0,
              child: Hero(
                tag: index == 0 ? 'product_${service.id}' : 'media_$index',
                child: isVideo 
                  ? _VideoPlaceholder(url: item['url']) 
                  : Image.network(item['url'], fit: BoxFit.contain),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  final String url;
  const _VideoPlaceholder({required this.url});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.play_circle_outline, color: Colors.white, size: 100),
        const SizedBox(height: 20),
        const Text("Video disponible", style: TextStyle(color: Colors.white54)),
        TextButton(
          onPressed: () {}, // Aquí conectarías tu reproductor de video favorito
          child: const Text("Tocar para reproducir", style: TextStyle(color: Color(0xFF00B2B2))),
        )
      ],
    );
  }
}