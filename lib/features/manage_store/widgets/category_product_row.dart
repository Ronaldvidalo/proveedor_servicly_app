import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/category_model.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/product_service.dart';
import 'package:proveedor_servicly_app/widgets/ProductCardRefactor.dart';
import 'package:proveedor_servicly_app/features/manage_store/widgets/store_ui_kit.dart'; // Importa el kit creado arriba
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              category.name,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            height: 220,
            child: StreamBuilder<List<ProductModel>>(
              stream: productService.getProducts(user.uid, categoryId: category.id, limit: 5),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: kCyberAccent));
                }
                final products = snapshot.data ?? [];

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: products.length + 2, // +1 Añadir, +1 Ver Más
                  itemBuilder: (context, index) {
                    // 1. Botón Añadir
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
                    // 2. Botón Ver Más (al final)
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
                          brandColor: kCyberAccent,
                          onDetailTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => AddEditProductScreen(user: user, productToEdit: product),
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