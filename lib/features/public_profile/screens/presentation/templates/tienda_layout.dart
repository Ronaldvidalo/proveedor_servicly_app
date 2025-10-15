// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 14/10/2025
// Style: Cyber Glow (Hybrid)
// This layout was refactored to blend the app's "Cyber Glow" aesthetic with the
// provider's brand identity. It uses the provider's brand color as the primary
// accent throughout a dark, modern interface, creating a unique and professional
// public-facing storefront.
// ---------------------------------

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/category_model.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/services/category_service.dart';
import 'package:proveedor_servicly_app/core/services/product_service.dart';
import 'package:proveedor_servicly_app/core/viewmodels/cart_provider.dart';
import 'package:proveedor_servicly_app/features/cart/screens/cart_screen.dart';


/// Un widget de layout que muestra el perfil de un proveedor con un estilo de "tienda".
/// Ahora con capacidad de filtrar productos por categoría.
class TiendaLayout extends StatefulWidget {
  final String providerId;
  final ProviderProfileModel profile;

  const TiendaLayout({
    super.key,
    required this.providerId,
    required this.profile,
  });

  @override
  State<TiendaLayout> createState() => _TiendaLayoutState();
}

class _TiendaLayoutState extends State<TiendaLayout> {
  // Estado para mantener la categoría seleccionada. `null` significa "todos".
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Text(
                'Nuestros Productos y Servicios',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white
                ),
              ),
            ),
          ),
          
          // --- NUEVO WIDGET: Barra de selección de categorías ---
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
          
          StreamBuilder<List<ProductModel>>(
            // El stream ahora se filtra por la categoría seleccionada.
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

              final products = snapshot.data!;

              return SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = products[index];
                      return _ProductCard(product: product, brandColor: brandColor);
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

  Widget _buildSliverAppBar(BuildContext context, ProviderProfileModel profile, Color brandColor) {
    final appBarTextColor = ThemeData.estimateBrightnessForColor(brandColor) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return SliverAppBar(
      expandedHeight: 280.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF1A1A2E),
      foregroundColor: Colors.white,
      actions: [
        _CartBadge(brandColor: brandColor), // Ícono del carrito
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          profile.businessName,
          style: TextStyle(
            color: appBarTextColor,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 1))],
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
                    colors: [
                      Colors.black.withAlpha(102), // 0.4 opacity
                      Colors.black.withAlpha(204), // 0.8 opacity
                    ],
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

/// --- WIDGETS ---

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
          // Si no hay categorías, no mostramos nada.
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final categories = snapshot.data!;

        return SliverToBoxAdapter(
          child: SizedBox(
            height: 60,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length + 1, // +1 para el chip "Todos"
              itemBuilder: (context, index) {
                // El primer chip siempre es "Todos"
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

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final Color brandColor;

  const _ProductCard({required this.product, required this.brandColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D5A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brandColor.withAlpha(128), width: 1), // 0.5 opacity
        boxShadow: [
          BoxShadow(color: brandColor.withAlpha(51), blurRadius: 10, spreadRadius: 1) // 0.2 opacity
        ]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () => _showProductDetailDialog(context, product, brandColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    product.imageUrl.isNotEmpty
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) => 
                            progress == null ? child : Center(child: CircularProgressIndicator(strokeWidth: 2, color: brandColor)),
                          errorBuilder: (context, error, stackTrace) => 
                            const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.white38, size: 40)),
                        )
                      : Container(
                          color: Colors.black.withAlpha(51), // 0.2 opacity
                          child: const Center(child: Icon(Icons.shopping_bag_outlined, size: 50, color: Colors.white38)),
                        ),
                    if (product.promoText != null && product.promoText!.isNotEmpty)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.promoText!,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8.0,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        if (product.isOnSale) ...[
                          Text(
                            '\$${product.promoPrice!.toStringAsFixed(2)}',
                            style: TextStyle( color: brandColor, fontWeight: FontWeight.bold, fontSize: 18 ),
                          ),
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: const TextStyle( color: Colors.white54, decoration: TextDecoration.lineThrough, fontSize: 14 ),
                          ),
                        ] else ...[
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: TextStyle( color: brandColor, fontWeight: FontWeight.bold, fontSize: 18 ),
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

void _showProductDetailDialog(BuildContext context, ProductModel product, Color brandColor) {
  int quantity = 1;

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      final cart = dialogContext.read<CartProvider>();
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2D2D5A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            contentPadding: const EdgeInsets.all(0),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: product.imageUrl.isNotEmpty
                        ? Image.network(product.imageUrl, fit: BoxFit.cover)
                        : const Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.white38),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if(product.description.isNotEmpty) ...[
                          Text(product.description, style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 24),
                        ],
                        
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('Precio:', style: TextStyle(fontSize: 18, color: brandColor, fontWeight: FontWeight.bold)),
                              if (product.isOnSale) ...[
                                Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.white54, decoration: TextDecoration.lineThrough, fontSize: 16),
                                ),
                                Text(
                                  '\$${product.promoPrice!.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 22, color: brandColor, fontWeight: FontWeight.bold),
                                ),
                              ] else ...[
                                Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 22, color: brandColor, fontWeight: FontWeight.bold),
                                ),
                              ]
                            ],
                          ),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Cantidad:', style: TextStyle(fontSize: 16, color: Colors.white)),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A2E),
                                borderRadius: BorderRadius.circular(30)
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, color: Colors.white70),
                                    onPressed: () {
                                      if (quantity > 1) setState(() => quantity--);
                                    },
                                  ),
                                  Text('$quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                  IconButton(
                                    icon: Icon(Icons.add, color: brandColor),
                                    onPressed: () => setState(() => quantity++),
                                  ),
                                ],
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
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('Cerrar', style: TextStyle(color: brandColor)),
              ),
              FilledButton.icon(
                onPressed: () {
                  cart.addItem(product, quantity);
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Se añadieron $quantity "${product.name}" al carrito.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: brandColor,
                  foregroundColor: ThemeData.estimateBrightnessForColor(brandColor) == Brightness.dark
                      ? Colors.white : Colors.black,
                ),
                icon: const Icon(Icons.add_shopping_cart_outlined),
                label: const Text('Añadir al Carrito'),
              ),
            ],
          );
        },
      );
    },
  );
}

class _CartBadge extends StatelessWidget {
  const _CartBadge({required this.brandColor});
  final Color brandColor;

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, size: 28),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const CartScreen(),
                ));
              },
            ),
            if (cart.totalItems > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: brandColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1A1A2E), width: 2),
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    '${cart.totalItems}',
                    style: TextStyle(
                      color: ThemeData.estimateBrightnessForColor(brandColor) == Brightness.dark
                          ? Colors.white : Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// --- WIDGETS DE ESTADO ---
class _LoadingState extends StatelessWidget {
  const _LoadingState({super.key});
  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D5A).withAlpha(128), // 0.5 opacity
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          childCount: 4,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});
  @override
  Widget build(BuildContext context) {
    return const SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.storefront_outlined, size: 80, color: Colors.white24),
              SizedBox(height: 24),
              Text(
                'Tienda en Construcción',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Este proveedor aún no ha añadido productos a su tienda.',
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
  const _ErrorState({super.key, required this.error});
  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      child: Center(child: Text('Error al cargar productos:\n$error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent))),
    );
  }
}

