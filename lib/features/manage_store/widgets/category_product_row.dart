import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/category_model.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/product_service.dart';
import 'package:proveedor_servicly_app/widgets/product_card_refactor.dart';
import 'package:proveedor_servicly_app/features/manage_store/widgets/store_ui_kit.dart';
import 'package:proveedor_servicly_app/features/manage_store/presentation/screens/add_edit_product_screen.dart';
import 'package:proveedor_servicly_app/features/manage_store/presentation/screens/all_products_screen.dart';

class CategoryProductRow extends StatelessWidget {
  final CategoryModel category;
  final UserModel user;
  final ProductService productService;

  const CategoryProductRow({
    super.key,
    required this.category,
    required this.user,
    required this.productService,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la Categoría
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                // Opción: Botón pequeño de "Ver todos" aquí también
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AllProductsScreen(user: user, categoryFilter: category),
                  )),
                  child: const Text("Ver todos", style: TextStyle(color: kCyberAccent, fontSize: 12)),
                )
              ],
            ),
          ),
          
          // Carrusel Horizontal
          SizedBox(
            height: 220,
            child: StreamBuilder<List<ProductModel>>(
              // Aquí se llama al servicio que YA apuntamos a la colección raíz
              stream: productService.getProductsByCategory(user.uid, category.id, limit: 5), 
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                   return const Center(child: Text("Error al cargar", style: TextStyle(color: Colors.red)));
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: kCyberAccent));
                }
                
                final products = snapshot.data ?? [];

                // Si no hay productos, mostramos solo el botón de añadir
                // Ajuste visual para que no se vea vacío
                if (products.isEmpty) {
                   return Padding(
                     padding: const EdgeInsets.only(left: 16.0),
                     child: DashedActionCard(
                        label: 'Añadir a\n${category.name}',
                        width: 160,
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => AddEditProductScreen(user: user, preselectedCategory: category),
                        )),
                      ),
                   );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: products.length + 2, // +1 Añadir al inicio, +1 Ver Más al final
                  itemBuilder: (context, index) {
                    // 1. Botón Añadir (Siempre el primero)
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: DashedActionCard(
                          label: 'Añadir\nProducto',
                          width: 160,
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => AddEditProductScreen(user: user, preselectedCategory: category),
                          )),
                        ),
                      );
                    }
                    
                    // 2. Botón Ver Más (Siempre el último)
                    if (index == products.length + 1) {
                      return SeeAllCard(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => AllProductsScreen(user: user, categoryFilter: category),
                        )),
                      );
                    }
                    
                    // 3. Producto Real
                    final product = products[index - 1];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: SizedBox(
                        width: 160,
                        child: ProductCardRefactor(
                          product: product,
                          brandColor: const Color(0xFF00BFFF),
                          isEditable: true, // <--- IMPORTANTE: MODO GESTOR ACTIVADO
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => AddEditProductScreen(user: user, product: product),
                          )),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}