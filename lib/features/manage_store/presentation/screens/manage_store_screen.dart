import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/product_service.dart';
import 'add_edit_product_screen.dart';
// --- NUEVA IMPORTACIÓN ---
import 'manage_categories_screen.dart';

// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 14/10/2025
// Style: Cyber Glow
// This screen was refactored to use a responsive GridView layout,
// custom product cards, and an enhanced loading/empty state experience,
// aligning with the "Cyber Glow" design philosophy.
// ---------------------------------

/// La pantalla principal para que un proveedor gestione los productos de su tienda.
class ManageStoreScreen extends StatelessWidget {
  final UserModel user;

  const ManageStoreScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final productService = context.read<ProductService>();
    
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Gestionar Mi Tienda'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        // --- MODIFICACIÓN CLAVE ---
        // Se añade un botón de acción para navegar a la gestión de categorías.
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Gestionar Categorías',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ManageCategoriesScreen(user: user),
              ));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: productService.getProducts(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingSkeleton();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar productos: ${snapshot.error}', style: const TextStyle(color: Colors.white70)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const _EmptyState();
          }

          final products = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Espacio para FAB
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 350,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _ProductCard(
                product: product,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => AddEditProductScreen(
                      user: user,
                      productToEdit: product,
                    ),
                  ));
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => AddEditProductScreen(user: user),
          ));
        },
        label: const Text('Añadir Producto'),
        icon: const Icon(Icons.add),
        backgroundColor: accentColor,
        foregroundColor: Colors.black,
      ),
    );
  }
}

// --- WIDGETS PERSONALIZADOS Y REDISEÑADOS ---

/// Tarjeta de producto rediseñada con estilo "Cyber Glow".
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});
  
  Color _getBorderColor() {
    if (product.isExpired) return Colors.redAccent;
    if (product.isExpiringSoon) return Colors.orangeAccent;
    return const Color(0xFF00BFFF).withAlpha(100);
  }

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Color(0xFF2D2D5A);
    final borderColor = _getBorderColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: borderColor.withAlpha(80),
              blurRadius: 12,
              spreadRadius: 1,
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    product.imageUrl.isNotEmpty
                        ? Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) =>
                                progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            errorBuilder: (context, error, stack) =>
                                const Icon(Icons.image_not_supported_outlined, color: Colors.white38, size: 40),
                          )
                        : Container(
                            color: Colors.black.withAlpha(51),
                            child: const Icon(Icons.shopping_bag_outlined, color: Colors.white38, size: 40),
                          ),
                    if (product.isExpired || product.isExpiringSoon)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _StatusTag(
                          isExpired: product.isExpired, 
                          isExpiringSoon: product.isExpiringSoon
                        ),
                      )
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(color: Color(0xFF00BFFF), fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etiqueta visual para el estado de vencimiento del producto.
class _StatusTag extends StatelessWidget {
  final bool isExpired;
  final bool isExpiringSoon;

  const _StatusTag({required this.isExpired, required this.isExpiringSoon});

  @override
  Widget build(BuildContext context) {
    if (!isExpired && !isExpiringSoon) return const SizedBox.shrink();

    final color = isExpired ? Colors.redAccent : Colors.orangeAccent;
    final text = isExpired ? 'VENCIDO' : 'VENCE PRONTO';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(color: color.withAlpha(128), blurRadius: 8)
        ]
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Widget para mostrar cuando la lista de productos está vacía.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store_mall_directory_outlined, size: 80, color: Colors.white24),
            const SizedBox(height: 24),
            Text(
              'Tu tienda está vacía',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toca el botón "+" para añadir tu primer producto y empezar a vender.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}

/// Esqueleto de carga que imita el layout final para una mejor UX.
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 350,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D5A).withAlpha(128),
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }
}

