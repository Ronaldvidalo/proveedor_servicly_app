import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/product_service.dart';
// --- ¡NUEVAS IMPORTACIONES! ---
import 'package:proveedor_servicly_app/core/models/order_model.dart';
import 'package:proveedor_servicly_app/core/services/order_service.dart';
import 'order_detail_screen.dart'; // <-- Crearemos esta pantalla
// --- FIN DE NUEVAS IMPORTACIONES ---
import 'add_edit_product_screen.dart';
import 'manage_categories_screen.dart';

// ... (Comentario UX/UI sin cambios) ...

class ManageStoreScreen extends StatelessWidget {
  final UserModel user;

  const ManageStoreScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Gestionar Mi Tienda'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: const [],
      ),
      // --- ¡ESTRUCTURA DEL BODY MODIFICADA! ---
      // Ya no es un StreamBuilder, es un CustomScrollView
      // que contendrá MÚLTIPLES StreamBuilders.
      body: CustomScrollView(
        slivers: [
          // --- SECCIÓN 1: Identidad de Marca (Placeholder) ---
          _buildBrandIdentityPlaceholder(context, user),

          // --- SECCIÓN 2: Ventas/Órdenes Pendientes (¡NUEVO!) ---
          _buildSectionTitle('Ventas Pendientes de Verificación'),
          _buildPendingOrdersSection(context, user),

          // --- SECCIÓN 3: Gestor de Contenido (Tu código anterior) ---
          _buildSectionTitle('Gestor de Contenido'),
          // Mantenemos tu tarjeta de Categorías
          SliverToBoxAdapter(child: _CategoryManagerCard(user: user)),
          _buildProductsSection(context, user),

          // --- SECCIÓN 4: Gestor de Promoción (Videos - Placeholder) ---
          _buildSectionTitle('Mis Videos Promocionales'),
          _buildVideoPromoPlaceholder(context, user),

          // Añadimos un espacio al final para que el FAB no tape el contenido
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Por ahora, solo añade productos.
          // En el futuro, lo convertiremos en un "Speed Dial"
          // para añadir Productos, Videos, Categorías, etc.
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

  // --- WIDGET PARA SECCIÓN 1 (PLACEHOLDER) ---
  Widget _buildBrandIdentityPlaceholder(BuildContext context, UserModel user) {
    // TODO: Construir la UI de Identidad de Marca
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D5A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Sección 1: Identidad de Marca (Logo, Nombre, etc.)',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ),
    );
  }

  // --- WIDGET PARA SECCIÓN 2 (¡NUEVO!) ---
  Widget _buildPendingOrdersSection(BuildContext context, UserModel user) {
    final orderService = context.read<OrderService>();

    return StreamBuilder<List<OrderModel>>(
      stream: orderService.getPendingOrders(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Muestra un loader pequeño
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Color(0xFF00BFFF)),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Text('Error al cargar órdenes: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent)),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // Muestra un mensaje amigable
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                child: Text('🎉 ¡No tienes ventas pendientes por verificar!',
                    style: TextStyle(color: Colors.white70)),
              ),
            ),
          );
        }

        final pendingOrders = snapshot.data!;

        // Si hay datos, muestra una lista
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final order = pendingOrders[index];
              return _OrderCard(order: order); // <-- ¡Nuevo widget de tarjeta!
            },
            childCount: pendingOrders.length,
          ),
        );
      },
    );
  }

  // --- WIDGET PARA SECCIÓN 3 (Tu código movido) ---
  Widget _buildProductsSection(BuildContext context, UserModel user) {
    final productService = context.read<ProductService>();

    // Usamos el plan del 2x4 que definiste (limit: 8)
    return StreamBuilder<List<ProductModel>>(
      stream: productService.getProducts(user.uid, limit: 8), // <-- Límite
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingSkeleton(); // Tu skeleton original
        }
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
              child: Center(
                  child: Text('Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent))));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(child: _EmptyState()); // Tu empty state
        }

        final products = snapshot.data!;
        
        // El Grid de 2x4
        return SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, // <-- Tal como pediste
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
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
              childCount: products.length,
            ),
          ),
        );
        // TODO: Añadir el botón "Ver/Gestionar todo" aquí
      },
    );
  }

  // --- WIDGET PARA SECCIÓN 4 (PLACEHOLDER) ---
  Widget _buildVideoPromoPlaceholder(BuildContext context, UserModel user) {
    // TODO: Construir la UI de Videos Promocionales
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D5A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Sección 4: Gestor de Videos Promocionales',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ),
    );
  }

  // --- WIDGET AUXILIAR PARA TÍTULOS DE SECCIÓN ---
  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// --- WIDGETS DE PRODUCTO (Tu código sin cambios) ---
class _CategoryManagerCard extends StatelessWidget {
  // ... (Tu código de _CategoryManagerCard va aquí, sin cambios)
  final UserModel user;
  const _CategoryManagerCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        color: const Color(0xFF2D2D5A),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF00BFFF), width: 1)),
        child: ListTile(
          leading: const Icon(Icons.category_outlined,
              color: Color(0xFF00BFFF), size: 32),
          title: const Text('Gestionar Categorías',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: const Text('Crea y organiza las carpetas de tus productos.',
              style: TextStyle(color: Colors.white70)),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ManageCategoriesScreen(user: user),
            ));
          },
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  // ... (Tu código de _ProductCard va aquí, sin cambios)
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
                                progress == null
                                    ? child
                                    : const Center(
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2)),
                            errorBuilder: (context, error, stack) =>
                                const Icon(Icons.image_not_supported_outlined,
                                    color: Colors.white38, size: 40),
                          )
                        : Container(
                            color: Colors.black.withAlpha(51),
                            child: const Icon(Icons.shopping_bag_outlined,
                                color: Colors.white38, size: 40),
                          ),
                    if (product.isExpired || product.isExpiringSoon)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _StatusTag(
                            isExpired: product.isExpired,
                            isExpiringSoon: product.isExpiringSoon),
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
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: Color(0xFF00BFFF),
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
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

class _StatusTag extends StatelessWidget {
  // ... (Tu código de _StatusTag va aquí, sin cambios)
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
          boxShadow: [BoxShadow(color: color.withAlpha(128), blurRadius: 8)]),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  // ... (Tu código de _EmptyState va aquí, sin cambios)
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store_mall_directory_outlined,
                size: 80, color: Colors.white24),
            const SizedBox(height: 24),
            Text(
              'Tu tienda está vacía',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.white),
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

class _LoadingSkeleton extends StatelessWidget {
  // ... (Tu código de _LoadingSkeleton va aquí, sin cambios)
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    // --- MODIFICADO: Lo convertí en Sliver para que funcione ---
    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverGrid.builder(
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
      ),
    );
  }
}

// --- ¡NUEVO WIDGET PARA LA TARJETA DE ORDEN! ---
class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withAlpha(100))),
        child: ListTile(
          leading: const Icon(Icons.receipt_long_outlined, color: accentColor),
          title: Text(
            // Muestra el primer item como título
            order.items.isNotEmpty
                ? order.items.first['name']
                : 'Orden Desconocida',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Cliente: ${order.clientName} - Total: \$${order.total.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38),
          onTap: () {
            // Navega a la pantalla de detalles para verificar
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => OrderDetailScreen(order: order),
            ));
          },
        ),
      ),
    );
  }
}