import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/product_service.dart';
// --- ¡NUEVAS IMPORTACIONES! ---
import 'package:proveedor_servicly_app/core/models/order_model.dart';
import 'package:proveedor_servicly_app/core/services/order_service.dart';
import 'order_detail_screen.dart'; 
// --- FIN DE NUEVAS IMPORTACIONES ---
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/features/settings/screens/brand_settings_screen.dart';
import 'add_edit_product_screen.dart';
import 'manage_categories_screen.dart';
import 'all_products_screen.dart';
import 'add_edit_video_screen.dart';

// --- ¡IMPORTACIONES CORREGIDAS! ---
import 'package:proveedor_servicly_app/core/models/video_showcase_model.dart';
import 'package:proveedor_servicly_app/core/services/video_service.dart';
import 'video_manager_screen.dart';
// --- FIN DE CORRECCIÓN ---


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
          _buildBrandIdentitySection(context, user),

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
          _buildVideoPromoSection(context, user),

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
  Widget _buildBrandIdentitySection(BuildContext context, UserModel user) {
    final firestoreService = context.read<FirestoreService>();
    const surfaceColor = Color(0xFF2D2D5A);
    const accentColor = Color(0xFF00BFFF);

    // --- ¡CORRECCIÓN! ---
    // Definimos el color aquí para que el método pueda "verlo".
    const backgroundColor = Color(0xFF1A1A2E);
    // --- FIN DE CORRECCIÓN ---

    // Usamos un StreamBuilder para obtener los datos de 'brandProfiles'
    return StreamBuilder<ProviderProfileModel?>(
      stream: firestoreService.getBrandProfile(user.uid),
      builder: (context, snapshot) {
        // --- Estado de Carga ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(
            child: Container(
              height: 120, // Altura del widget final
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                  child: CircularProgressIndicator(color: accentColor)),
            ),
          );
        }

        // --- Estado de Error o Sin Datos ---
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          // Muestra un widget "roto" o "vacío"
          return SliverToBoxAdapter(
            child: Container(
              // ... (código de error sin cambios)
              height: 120,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent),
              ),
              child: const Center(
                child: Text(
                  'No se pudo cargar tu perfil de marca. Intenta editarlo para crearlo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          );
        }

        // --- Estado de Éxito ---
        final brandProfile = snapshot.data!;

        return SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withAlpha(100)),
            ),
            child: Row(
              children: [
                // 1. Logo
                CircleAvatar(
                  radius: 30,
                  backgroundColor: backgroundColor, // <-- AHORA FUNCIONA
                  backgroundImage: brandProfile.logoUrl.isNotEmpty
                      ? NetworkImage(brandProfile.logoUrl)
                      : null,
                  child: brandProfile.logoUrl.isEmpty
                      ? const Icon(Icons.business_rounded,
                          size: 30, color: accentColor)
                      : null,
                ),
                const SizedBox(width: 16),

                // 2. Textos (Nombre y Eslogan)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        brandProfile.businessName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        // Esta línea (con ??) es correcta, ignora la advertencia
                        brandProfile.welcomeMessage ?? 'Añade un eslogan',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // 3. Botón de Editar
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: accentColor),
                  tooltip: 'Editar Perfil de Marca',
                  onPressed: () {
                    // Navega a la pantalla que ya construimos
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => BrandSettingsScreen(
                        user: user,

                        // --- ¡MODIFICACIÓN! ---
                        // Ya no pasamos initialTemplateId,
                        // pasamos el perfil completo.
                        brandProfile: brandProfile,
                        // initialTemplateId: brandProfile.profileType, <-- ELIMINADO
                        // --- FIN DE MODIFICACIÓN ---
                      ),
                    ));
                  },
                ),
              ],
            ),
          ),
        );
      },
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
          // Si no hay productos, NO mostramos el botón "Ver todo"
          return const SliverToBoxAdapter(child: _EmptyState());
        }

        final products = snapshot.data!;

        // --- ¡MODIFICACIÓN! ---
        // Usamos un SliverMainAxisGroup para agrupar
        // la grilla Y el botón en un solo bloque.
        return SliverMainAxisGroup(
          slivers: [
            // 1. El Grid de 2x4 (tu código original)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
            ),

            // 2. ¡NUEVO BOTÓN! (Reemplaza el TODO)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0), // Espacio
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.list_alt_rounded, size: 20),
                  label: const Text('Ver/Gestionar todos los productos'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00BFFF), // accentColor
                      backgroundColor:
                          const Color(0xFF2D2D5A).withAlpha(150), // surfaceColor
                      side: const BorderSide(
                          color: Color(0xFF2D2D5A)), // surfaceColor
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      // Navegamos a la nueva pantalla
                      builder: (_) => AllProductsScreen(user: user),
                    ));
                  },
                ),
              ),
            ),
            // --- FIN DE LA MODIFICACIÓN ---
          ],
        );
      },
    );
  }

  // --- WIDGET PARA SECCIÓN 4 (PLACEHOLDER) ---
 Widget _buildVideoPromoSection(BuildContext context, UserModel user) {
    final videoService = context.read<VideoService>();
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);

    return StreamBuilder<List<VideoShowcaseModel>>(
      stream: videoService.getVideoShowcasesByProvider(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: accentColor),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            // ... (código de error sin cambios)
          );
        }

        // --- ¡MODIFICADO! ---
        // Ya no comprobamos si está vacío aquí,
        // lo hacemos en el builder de la lista.
        final videos = snapshot.data ?? [];
        // --- FIN MODIFICACIÓN ---

        return SliverMainAxisGroup(
          slivers: [
            // 1. Carrusel Horizontal de Videos + Botón de Añadir
            SliverToBoxAdapter(
              child: SizedBox(
                height: 150, // Altura del carrusel
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  
                  // --- ¡MODIFICACIÓN! ---
                  // +1 para el botón de "Añadir"
                  itemCount: videos.length + 1, 
                  // --- FIN MODIFICACIÓN ---
                  
                  itemBuilder: (context, index) {
                    
                    // --- ¡NUEVA LÓGICA! ---
                    if (index == videos.length) {
                      // Si es el último item, muestra la tarjeta de "Añadir"
                      return _AddVideoCard(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => AddEditVideoScreen(user: user),
                          ));
                        },
                      );
                    }
                  
                    // --- FIN NUEVA LÓGICA ---

                    // Si no, muestra la tarjeta de video normal
                    final video = videos[index];
                    return _VideoCard(video: video);
                  },
                ),
              ),
            ),
            
            // 2. Botón "Gestionar Todo" (Solo aparece si tienes videos)
            if (videos.isNotEmpty) // <-- ¡MODIFICADO!
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.video_library_rounded, size: 20),
                    label: const Text('Ver/Gestionar todos los videos'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: accentColor,
                        backgroundColor: surfaceColor.withAlpha(150),
                        side: const BorderSide(color: surfaceColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle:
                            const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => VideoManagerScreen(user: user),
                      ));
                    },
                  ),
                ),
              ),
          ],
        );
      },
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
} // --- FIN DE LA CLASE ManageStoreScreen ---


// --- WIDGETS AUXILIARES (AHORA FUERA DE LA CLASE) ---

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

// --- ¡NUEVO WIDGET AUXILIAR PARA LA TARJETA DE VIDEO! ---
// --- ¡MOVIDO A SU LUGAR CORRECTO! ---
class _VideoCard extends StatelessWidget {
  final VideoShowcaseModel video;
  const _VideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Color(0xFF2D2D5A);
    const accentColor = Color(0xFF00BFFF);

    return GestureDetector(
      onTap: () {
        // TODO: Navegar al editor de video (AddEditVideoScreen)
        // Navigator.of(context).push(MaterialPageRoute(
        //   builder: (_) => AddEditVideoScreen(user: user, videoToEdit: video),
        // ));
      },
      child: Container(
        width: 120, // Ancho de la tarjeta
        margin: const EdgeInsets.only(right: 12.0),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          image: video.thumbnailUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(video.thumbnailUrl),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Overlay oscuro
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withAlpha(178)], // <-- CORREGIDO
                ),
              ),
            ),
            // Icono de Play
            const Center(
              child: Icon(Icons.play_circle_outline_rounded,
                  color: Colors.white70, size: 40),
            ),
            // Título del video
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                video.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Indicador de "Promocionado" (¡Lógica de negocio!)
            if (video.isPromoted)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PROMO',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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

Widget _buildVideoPromoSection(BuildContext context, UserModel user) {
    final videoService = context.read<VideoService>();
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);

    return StreamBuilder<List<VideoShowcaseModel>>(
      stream: videoService.getVideoShowcasesByProvider(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: accentColor),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            // ... (código de error sin cambios)
          );
        }

        // --- ¡MODIFICADO! ---
        // Ya no comprobamos si está vacío aquí,
        // lo hacemos en el builder de la lista.
        final videos = snapshot.data ?? [];
        // --- FIN MODIFICACIÓN ---

        return SliverMainAxisGroup(
          slivers: [
            // 1. Carrusel Horizontal de Videos + Botón de Añadir
            SliverToBoxAdapter(
              child: SizedBox(
                height: 150, // Altura del carrusel
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  
                  // --- ¡MODIFICACIÓN! ---
                  // +1 para el botón de "Añadir"
                  itemCount: videos.length + 1, 
                  // --- FIN MODIFICACIÓN ---
                  
                  itemBuilder: (context, index) {
                    
                    // --- ¡NUEVA LÓGICA! ---
                    if (index == videos.length) {
                      // Si es el último item, muestra la tarjeta de "Añadir"
                      return _AddVideoCard(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => AddEditVideoScreen(user: user),
                          ));
                        },
                      );
                    }
                    // --- FIN NUEVA LÓGICA ---

                    // Si no, muestra la tarjeta de video normal
                    final video = videos[index];
                    return _VideoCard(video: video);
                  },
                ),
              ),
            ),
            
            // 2. Botón "Gestionar Todo" (Solo aparece si tienes videos)
            if (videos.isNotEmpty) // <-- ¡MODIFICADO!
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.video_library_rounded, size: 20),
                    label: const Text('Ver/Gestionar todos los videos'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: accentColor,
                        backgroundColor: surfaceColor.withAlpha(150),
                        side: const BorderSide(color: surfaceColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle:
                            const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => VideoManagerScreen(user: user),
                      ));
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

// --- ¡NUEVO WIDGET AUXILIAR PARA AÑADIR VIDEOS! ---
class _AddVideoCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddVideoCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120, // Mismo ancho que _VideoCard
        margin: const EdgeInsets.only(right: 12.0),
        decoration: BoxDecoration(
          color: surfaceColor.withAlpha(100), // Más sutil
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accentColor.withAlpha(150), // Borde Cyber Glow
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded,
                color: accentColor, size: 40),
            const SizedBox(height: 8),
            const Text(
              'Añadir\nVideo',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}