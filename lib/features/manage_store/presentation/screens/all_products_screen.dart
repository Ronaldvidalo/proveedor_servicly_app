import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- Modelos ---
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/models/category_model.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';

// --- Servicios ---
import 'package:proveedor_servicly_app/core/services/product_service.dart';

// --- Widgets y Pantallas ---
import 'package:proveedor_servicly_app/features/manage_store/presentation/screens/add_edit_product_screen.dart';
// Asegúrate de importar tu tarjeta de producto refactorizada
import 'package:proveedor_servicly_app/widgets/ProductCardRefactor.dart'; 

class AllProductsScreen extends StatelessWidget {
  final UserModel user;
  final CategoryModel? categoryFilter;

  const AllProductsScreen({
    super.key, 
    required this.user,
    this.categoryFilter
  });

  @override
  Widget build(BuildContext context) {
    // Paleta Cyber Glow
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);

    // Si hay filtro de categoría, usamos su nombre, si no "Todos los Productos"
    final title = categoryFilter != null 
        ? categoryFilter!.name 
        : 'Inventario Completo';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // TODO: Implementar búsqueda en el futuro
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text("Búsqueda próximamente..."))
               );
            },
          ),
        ],
      ),
      
      // --- CUERPO: STREAM BUILDER CONECTADO ---
      body: StreamBuilder<List<ProductModel>>(
        // Llamamos al servicio con la nueva lógica de RAÍZ
        stream: context.read<ProductService>().getProducts(
          user.uid, 
          categoryId: categoryFilter?.id // Si es null, trae todos
        ),
        builder: (context, snapshot) {
          // 1. Estado de Carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: accentColor));
          }

          // 2. Estado de Error
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar productos:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final products = snapshot.data ?? [];

          // 3. Estado Vacío
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.white.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    categoryFilter != null 
                        ? 'No hay productos en esta categoría.' 
                        : 'Aún no tienes productos.',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => _navigateToAddProduct(context),
                    icon: const Icon(Icons.add),
                    label: const Text("Crear el primero"),
                    style: OutlinedButton.styleFrom(foregroundColor: accentColor),
                  )
                ],
              ),
            );
          }

          // 4. Estado con Datos (Grilla)
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 columnas
              childAspectRatio: 0.75, // Ajusta según el alto de tu ProductCardRefactor
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCardRefactor(
                product: product,
                brandColor: accentColor,
                // Al tocar, vamos a editar
                onDetailTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AddEditProductScreen(user: user, productToEdit: product),
                  ));
                },
              );
            },
          );
        },
      ),

      // --- FAB: AÑADIR PRODUCTO ---
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddProduct(context),
        backgroundColor: accentColor,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToAddProduct(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      // Si estamos filtrando por categoría, la pasamos pre-seleccionada
      builder: (_) => AddEditProductScreen(
        user: user, 
        preselectedCategory: categoryFilter
      ),
    ));
  }
}