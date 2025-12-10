// --- UX/UI Enhancement Comment ---
// Widget: ProductSelectionModal
// Ubicación: lib/features/budget/presentation/widgets/product_selection_modal.dart
// Responsabilidad: Listar productos del inventario para agregarlos a una cotización.
// Funcionalidad: Búsqueda local + Conversión a QuoteItem.

import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';
// Importamos el repositorio de inventario (Asegúrate de tener acceso a él)
import 'package:proveedor_servicly_app/features/inventory/data/inventory_repository.dart';
import 'package:proveedor_servicly_app/features/budget/models/quote_item_model.dart';

class ProductSelectionModal extends StatefulWidget {
  final InventoryRepository inventoryRepository;

  const ProductSelectionModal({
    super.key,
    required this.inventoryRepository,
  });

  @override
  State<ProductSelectionModal> createState() => _ProductSelectionModalState();
}

class _ProductSelectionModalState extends State<ProductSelectionModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85, // 85% de la pantalla
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // --- HEADER DEL MODAL ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const CloseButton(),
                Expanded(
                  child: Text(
                    "Seleccionar Producto",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Espacio para equilibrar el botón de cierre
              ],
            ),
          ),

          // --- BARRA DE BÚSQUEDA ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Buscar por nombre o SKU...",
                prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),

          const Divider(),

          // --- LISTA DE PRODUCTOS ---
          Expanded(
            child: StreamBuilder<List<ProductModel>>(
              stream: widget.inventoryRepository.getProductsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error cargando inventario",
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  );
                }

                final products = snapshot.data ?? [];

                // Filtro local por búsqueda
                final filteredProducts = products.where((product) {
                  final name = product.name.toLowerCase();
                  final sku = product.sku.toLowerCase();
                  return name.contains(_searchQuery) || sku.contains(_searchQuery);
                }).toList();

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: theme.disabledColor),
                        const SizedBox(height: 12),
                        Text(
                          "No se encontraron productos",
                          style: TextStyle(color: theme.disabledColor),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _buildProductItem(context, product);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(BuildContext context, ProductModel product) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      onTap: () {
        // --- AQUÍ OCURRE LA MAGIA DE LA UNIFICACIÓN ---
        // Convertimos ProductModel -> QuoteItem automáticamente
        final quoteItem = QuoteItem.fromProduct(product);
        
        // Cerramos el modal y devolvemos el ítem convertido
        Navigator.pop(context, quoteItem);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      tileColor: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDark 
            ? BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)) 
            : BorderSide.none,
      ),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          image: product.imageUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(product.imageUrl),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: product.imageUrl.isEmpty
            ? Icon(Icons.image_not_supported, color: theme.colorScheme.primary.withValues(alpha: 0.5))
            : null,
      ),
      title: Text(
        product.name,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product.sku.isNotEmpty)
            Text(
              "SKU: ${product.sku}",
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          Text(
            "\$${product.price.toStringAsFixed(2)}", // Muestra el precio actual
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      trailing: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
    );
  }
}