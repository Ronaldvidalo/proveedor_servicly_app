import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Modelos y Servicios
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/services/product_service.dart';
import 'package:proveedor_servicly_app/features/manage_store/presentation/screens/add_edit_product_screen.dart';

class CatalogServicesSectionEditor extends StatelessWidget {
  final String providerId;
  final Color brandColor;

  const CatalogServicesSectionEditor({
    super.key,
    required this.providerId,
    required this.brandColor,
  });

  @override
  Widget build(BuildContext context) {
    final productService = context.read<ProductService>();

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER DE SECCIÓN ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Servicios e Inventario", 
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Gestión profesional de catálogo", 
                      style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
                IconButton.filled(
                  onPressed: () => _navigateToEditor(context),
                  icon: const Icon(Icons.add, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF00B2B2)),
                ),
              ],
            ),
          ),

          // --- LISTADO DE SERVICIOS DINÁMICO ---
          StreamBuilder<List<ProductModel>>(
            stream: productService.getProducts(providerId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: Color(0xFF00B2B2)),
                ));
              }

              final products = snapshot.data ?? [];
              if (products.isEmpty) return _buildEmptyState(context);

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  return _buildServiceItem(context, products[index]);
                },
              );
            },
          ),
          const SizedBox(height: 100), 
        ],
      ),
    );
  }

  Widget _buildServiceItem(BuildContext context, ProductModel product) {
    // Lógica técnica de rentabilidad
    final bool isLowProfit = (product.cost) >= product.price;

    // 🔍 DETERMINAR MINIATURA Y TIPO DE MEDIO
    final String? mainImg = product.imageUrl.isNotEmpty ? product.imageUrl : null;
    final Map<String, dynamic>? firstGallery = product.mediaGallery.isNotEmpty ? product.mediaGallery.first : null;
    final String? thumbUrl = mainImg ?? firstGallery?['url'];
    final bool isVideo = firstGallery?['type'] == 'video' || (thumbUrl?.contains('.mp4') ?? false);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isLowProfit ? Colors.redAccent.withValues(alpha: 0.3) : Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 🖼️ MINIATURA INTERACTIVA (MAXIMIZABLE)
            GestureDetector(
              onTap: () => _openFullscreenMedia(context, product),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Hero(
                    tag: 'editor_media_${product.id}',
                    child: Container(
                      width: 75, height: 75,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.black26,
                        image: thumbUrl != null 
                          ? DecorationImage(image: NetworkImage(thumbUrl), fit: BoxFit.cover) 
                          : null,
                      ),
                      child: thumbUrl == null ? const Icon(Icons.image_not_supported, color: Colors.white10) : null,
                    ),
                  ),
                  if (isVideo)
                    const Icon(Icons.play_circle_fill, color: Colors.white, size: 30),
                  
                  // Badge de "Ampliar"
                  Positioned(
                    bottom: 4, right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                      child: const Icon(Icons.fullscreen, color: Colors.white70, size: 12),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(width: 16),

            // 📋 INFO TÉCNICA Y PRECIOS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text("Venta: \$${NumberFormat("#,##0").format(product.price)}", 
                        style: const TextStyle(color: Color(0xFF00B2B2), fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text("Costo: \$${product.cost.toStringAsFixed(0)} | Stock: ${product.quantity ?? 0}", 
                    style: TextStyle(color: isLowProfit ? Colors.redAccent : Colors.white38, fontSize: 11)),
                ],
              ),
            ),

            // ⚙️ ACCIONES
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: Colors.white54, size: 28),
              onPressed: () => _navigateToEditor(context, product: product),
            ),
          ],
        ),
      ),
    );
  }

  // --- LÓGICA DE NAVEGACIÓN Y VISUALIZACIÓN ---

  void _openFullscreenMedia(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => _SimpleFullscreenViewer(product: product),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined, color: Colors.white10, size: 64),
          const SizedBox(height: 16),
          const Text("No hay servicios cargados", style: TextStyle(color: Colors.white38)),
          TextButton(
            onPressed: () => _navigateToEditor(context),
            child: const Text("Crear mi primer servicio", style: TextStyle(color: Color(0xFF00B2B2))),
          ),
        ],
      ),
    );
  }

  void _navigateToEditor(BuildContext context, {ProductModel? product}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProductScreen(product: product),
      ),
    );
  }
}

// 🎬 VISUALIZADOR RÁPIDO PARA EL EDITOR (Zoom e Info)
class _SimpleFullscreenViewer extends StatelessWidget {
  final ProductModel product;
  const _SimpleFullscreenViewer({required this.product});

  @override
  Widget build(BuildContext context) {
    final List<String> allMedia = [
      if (product.imageUrl.isNotEmpty) product.imageUrl,
      ...product.mediaGallery.map((m) => m['url'].toString())
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(product.name, style: const TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        itemCount: allMedia.length,
        itemBuilder: (context, index) {
          final url = allMedia[index];
          final bool isVideo = url.contains('.mp4');

          return Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Hero(
                tag: index == 0 ? 'editor_media_${product.id}' : 'gallery_editor_$index',
                child: isVideo 
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_circle_outline, color: Colors.white, size: 80),
                        SizedBox(height: 16),
                        Text("Vista previa de Video", style: TextStyle(color: Colors.white54)),
                      ],
                    )
                  : Image.network(url, fit: BoxFit.contain),
              ),
            ),
          );
        },
      ),
    );
  }
}