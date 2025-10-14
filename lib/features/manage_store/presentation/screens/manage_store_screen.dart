import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/product_service.dart';
import 'add_edit_product_screen.dart';

/// La pantalla principal para que un proveedor gestione los productos de su tienda.
class ManageStoreScreen extends StatelessWidget {
  final UserModel user;

  const ManageStoreScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final productService = context.read<ProductService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Mi Tienda'),
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: productService.getProducts(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar productos: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Aún no has añadido productos.\n¡Toca el botón "+" para empezar!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            );
          }

          final products = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80), // Espacio para el botón flotante
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final isExpired = product.isExpired;
              final isExpiringSoon = product.isExpiringSoon;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                shadowColor: Colors.black.withAlpha((255 * 0.1).round()),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isExpired
                        ? Colors.red.shade700
                        : isExpiringSoon
                            ? Colors.orange.shade700
                            : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: ListTile(
                  // --- MODIFICACIÓN ---
                  // Se añade un widget 'leading' para mostrar la imagen.
                  leading: SizedBox(
                    width: 56,
                    height: 56,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: product.imageUrl.isNotEmpty
                          ? Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              // Muestra un indicador de carga mientras la imagen se descarga.
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                              },
                              // Muestra un ícono de error si la imagen no se puede cargar.
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
                          ),
                    ),
                  ),
                  title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text(
                    'Precio: \$${product.price.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  trailing: Icon(
                    Icons.circle,
                    size: 12,
                    color: isExpired
                        ? Colors.red.shade700
                        : isExpiringSoon
                            ? Colors.orange.shade700
                            : Colors.green.shade600,
                  ),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AddEditProductScreen(
                        user: user,
                        productToEdit: product,
                      ),
                    ));
                  },
                ),
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
      ),
    );
  }
}

