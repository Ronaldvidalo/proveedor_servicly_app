import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/services/product_service.dart';

/// Un widget de layout que muestra el perfil de un proveedor con un estilo de "tienda".
///
/// Obtiene y muestra una lista de productos del proveedor en tiempo real.
class TiendaLayout extends StatelessWidget {
  final String providerId;
  final ProviderProfileModel profile;

  const TiendaLayout({
    super.key,
    required this.providerId,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final productService = context.read<ProductService>();
    final brandColor = profile.brandColor;
    final businessName = profile.businessName;
    final logoUrl = profile.logoUrl;

    // Determina el color del texto del AppBar para un buen contraste.
    final appBarTextColor = ThemeData.estimateBrightnessForColor(brandColor) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: brandColor,
            foregroundColor: appBarTextColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                businessName,
                style: TextStyle(
                  color: appBarTextColor,
                  shadows: const [Shadow(color: Colors.black38, blurRadius: 4)],
                ),
              ),
              centerTitle: true,
              background: logoUrl.isNotEmpty
                  ? Image.network(
                      logoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          // --- CORRECCIÓN ---
                          // Se reemplaza .withOpacity() por .withAlpha()
                          Container(color: brandColor.withAlpha((255 * 0.5).round())),
                    )
                  : Container(color: brandColor.withAlpha((255 * 0.5).round())),
            ),
          ),
          
          // Encabezado de la sección de productos
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Text(
                'Nuestros Productos y Servicios',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
          // StreamBuilder para mostrar los productos en tiempo real.
          StreamBuilder<List<ProductModel>>(
            // --- CORRECCIÓN ---
            // Se usa el nombre de método correcto 'getProducts'.
            stream: productService.getProducts(providerId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text('Error al cargar productos: ${snapshot.error}')),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Este proveedor aún no ha añadido productos a su tienda.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                );
              }

              final products = snapshot.data!;

              // Usamos un SliverGrid para mostrar los productos.
              return SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Muestra 2 productos por fila
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75, // Ajusta la proporción de las tarjetas
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = products[index];
                      return _ProductCard(product: product);
                    },
                    childCount: products.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Un widget de tarjeta para mostrar un único producto en la cuadrícula.
class _ProductCard extends StatelessWidget {
  final ProductModel product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withAlpha((255 * 0.1).round()),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              color: Colors.grey.shade200,
              // TODO: Reemplazar este placeholder por la Image.network(product.imageUrl)
              // cuando se implemente la subida de imágenes.
              child: const Center(
                child: Icon(Icons.shopping_bag_outlined, size: 50, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

