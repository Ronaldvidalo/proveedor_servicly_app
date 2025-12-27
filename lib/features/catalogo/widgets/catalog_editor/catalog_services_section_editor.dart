import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
          // HEADER DE SECCIÓN
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
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF6200EE)),
                ),
              ],
            ),
          ),

          // LISTADO DE SERVICIOS (Corregido para evitar pantalla roja)
          StreamBuilder<List<ProductModel>>(
            stream: productService.getProducts(providerId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ));
              }

              final products = snapshot.data ?? [];

              if (products.isEmpty) {
                return _buildEmptyState(context);
              }

              // ✅ SOLUCIÓN AL ERROR: Usamos ListView en lugar de SliverList
              return ListView.builder(
                shrinkWrap: true, // Permite que el ListView viva dentro de una Column
                physics: const NeverScrollableScrollPhysics(), // El scroll lo maneja el CustomScrollView principal
                itemCount: products.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _buildServiceItem(context, product);
                },
              );
            },
          ),
          const SizedBox(height: 100), // Espacio para el botón flotante
        ],
      ),
    );
  }

  Widget _buildServiceItem(BuildContext context, ProductModel product) {
    // Lógica técnica: Si el costo es mayor al precio, alertamos al ingeniero
    final bool isLowProfit = (product.cost ?? 0) >= product.price;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isLowProfit ? Colors.redAccent.withOpacity(0.3) : Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            product.imageUrl,
            width: 50, height: 50, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.white10, child: const Icon(Icons.image_not_supported)),
          ),
        ),
        title: Text(product.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Venta: \$${product.price}", style: const TextStyle(color: Color(0xFF00B2B2), fontSize: 12)),
            // Información técnica para el editor
            Text("Costo: \$${product.cost ?? 0.0} | Stock: ${product.quantity}", 
              style: TextStyle(color: isLowProfit ? Colors.redAccent : Colors.white38, fontSize: 10)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white54),
          onPressed: () => _navigateToEditor(context, product: product),
        ),
      ),
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
            child: const Text("Crear mi primer servicio"),
          ),
        ],
      ),
    );
  }

  void _navigateToEditor(BuildContext context, {ProductModel? product}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProductScreen(
          productToEdit: product,
        ),
      ),
    );
  }
}