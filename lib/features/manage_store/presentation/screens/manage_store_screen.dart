// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 26/10/2025
// Style: Cyber Glow
// This screen was fully refactored based on the user's innovative UX proposal
// to solve overload and overflow issues.
// 1. Replaced the large brand section with a compact header card (_BrandHeaderCard)
//    that uses an expandable accordion for contact info.
// 2. Converted "Pending Sales" and "Video Promos" into horizontal carousels.
// 3. Replaced the static 4-column product grid with a responsive
//    SliverGridDelegateWithMaxCrossAxisExtent, fixing all layout overflows.
// 4. Removed the FloatingActionButton and added an _AddProductCard directly
//    into the grid for a more intuitive "add" experience.
// 5. Category management is now a compact button row.
// 6. Fixed all import and logic errors.
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui'; // Para PathMetric
import 'package:flutter/foundation.dart' show listEquals; // Para listEquals

// --- Modelos y Servicios ---
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/product_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:proveedor_servicly_app/core/models/order_model.dart';
import 'package:proveedor_servicly_app/core/services/order_service.dart';
import 'order_detail_screen.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/features/settings/screens/brand_settings_screen.dart';
import 'add_edit_product_screen.dart';
import 'manage_categories_screen.dart';
import 'all_products_screen.dart';
import 'add_edit_video_screen.dart';
import 'package:proveedor_servicly_app/core/models/video_showcase_model.dart';
import 'package:proveedor_servicly_app/core/services/video_service.dart';
import 'video_manager_screen.dart';
// --- NUEVO IMPORT ---
import 'package:proveedor_servicly_app/core/services/category_service.dart';
import 'package:proveedor_servicly_app/core/models/category_model.dart';
import 'package:proveedor_servicly_app/widgets/ProductCardRefactor.dart';
import 'package:proveedor_servicly_app/widgets/VideoCard.dart';
import 'package:proveedor_servicly_app/features/manage_store/presentation/screens/video_player_screen.dart';
// --- IMPORTACIÓN DEL WIDGET REUTILIZABLE ---
import 'package:proveedor_servicly_app/widgets/brand_header_card.dart';
import 'package:proveedor_servicly_app/widgets/info_chip.dart';
import 'package:proveedor_servicly_app/widgets/stats_summary_card.dart';
import 'package:proveedor_servicly_app/widgets/pending_orders_carousel.dart';
import 'package:proveedor_servicly_app/widgets/provider_stats_panel.dart';


class ManageStoreScreen extends StatelessWidget {
  final UserModel user;

  const ManageStoreScreen({super.key, required this.user});

  /// Para lanzar URLs
  Future<void> _launchURL(String url) async {
    String launchableUrl = url;
    if (!url.startsWith('http://') &&
        !url.startsWith('https://') &&
        !url.startsWith('tel:') &&
        !url.startsWith('mailto:') &&
        !url.startsWith('https://wa.me/')) {
      launchableUrl = 'https://$url';
    }
    final Uri uri = Uri.parse(launchableUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error al lanzar $url: $e');
    }
  }

  // --- Método para mostrar el panel de contactos ---
  void _showContactSheet(BuildContext context, ProviderProfileModel brandProfile) {
    const surfaceColor = Color(0xFF2D2D5A);
    // const accentColor = Color(0xFF00BFFF); // No se usa aquí

    final List<Widget> contactChips = [
      if (brandProfile.phone != null && brandProfile.phone!.isNotEmpty)
        InfoChip(icon: Icons.phone_outlined, label: brandProfile.phone!, onTap: () => _launchURL('tel:${brandProfile.phone!}')),
      if (brandProfile.whatsapp != null && brandProfile.whatsapp!.isNotEmpty)
        InfoChip(icon: Icons.message_outlined, label: brandProfile.whatsapp!, onTap: () => _launchURL('https://wa.me/${brandProfile.whatsapp!}')),
      if (brandProfile.contactEmail.isNotEmpty)
        InfoChip(icon: Icons.email_outlined, label: brandProfile.contactEmail, onTap: () => _launchURL('mailto:${brandProfile.contactEmail}')),
      if (brandProfile.website != null && brandProfile.website!.isNotEmpty)
        InfoChip(icon: Icons.language_outlined, label: 'Web', onTap: () => _launchURL(brandProfile.website!)),
      if (brandProfile.instagram != null && brandProfile.instagram!.isNotEmpty)
        InfoChip(icon: IconsKE.instagram, label: 'Instagram', onTap: () => _launchURL('https://instagram.com/${brandProfile.instagram!}')),
      if (brandProfile.facebook != null && brandProfile.facebook!.isNotEmpty)
        InfoChip(icon: Icons.facebook_outlined, label: 'Facebook', onTap: () => _launchURL('https://facebook.com/${brandProfile.facebook!}')),
      if (brandProfile.tiktok != null && brandProfile.tiktok!.isNotEmpty)
        InfoChip(icon: Icons.music_note_outlined, label: 'TikTok', onTap: () => _launchURL('https://tiktok.com/${brandProfile.tiktok!}')),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      barrierColor: Colors.black.withAlpha(128),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Información de Contacto',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.of(ctx).pop(),
                  )
                ],
              ),
              const SizedBox(height: 16),
              if (contactChips.isEmpty)
                const Text(
                  'No has añadido información de contacto pública. Edita tu perfil de marca para añadirla.',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                )
              else
                Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: contactChips,
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1A1A2E);
    // CORRECCIÓN: 'accentColor' no se usaba aquí, eliminado.

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Gestionar Mi Tienda'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // --- SECCIÓN 1: Identidad de Marca (USANDO WIDGET REUTILIZABLE) ---
          SliverToBoxAdapter(
            child: BrandHeaderCard(
              user: user,
              onShowContacts: (brandProfile) {
                _showContactSheet(context, brandProfile);
              },
              onLaunchUrl: _launchURL,
            ),
          ),

          // --- ¡NUEVA SECCIÓN 2: Estadísticas! ---
        // --- ¡SECCIÓN 2: Estadísticas (AHORA CON DATOS REALES)! ---
          _buildSectionTitle('Resumen de Actividad', false),
          SliverToBoxAdapter(
          child: ProviderStatsPanel(userId: user.uid),
        ),

          // --- SECCIÓN 3: Ventas/Órdenes Pendientes (Carrusel) ---
          _buildSectionTitle('Ventas Pendientes', false),
          SliverToBoxAdapter(
            child: PendingOrdersCarousel(user: user),
          ),

          // --- SECCIÓN 4: Gestor de Promoción (Videos) ---
          _buildSectionTitle('Mis Videos Promocionales', false),
          _buildVideoPromoSection(context, user),

          // --- SECCIÓN 5: Gestor de Catálogo (Compacto) ---
          _buildSectionTitle('Mi Catálogo', false),
          _buildContentManagementSection(context, user),

          // --- SECCIÓN 6: Productos (Grilla Responsiva) ---
          _buildProductsByCategoriesSection(context, user),


          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // --- WIDGET PARA SECCIÓN 2 (Ventas) ---
  Widget _buildPendingOrdersSection(BuildContext context, UserModel user) {
    final orderService = context.read<OrderService>();
    const accentColor = Color(0xFF00BFFF);

    return StreamBuilder<List<OrderModel>>(
      stream: orderService.getPendingOrders(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: CircularProgressIndicator(color: accentColor),
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
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final pendingOrders = snapshot.data!;

        return SliverToBoxAdapter(
          child: SizedBox(
            height: 100, 
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: pendingOrders.length,
              itemBuilder: (context, index) {
                final order = pendingOrders[index];
                return _OrderCard(order: order);
              },
            ),
          ),
        );
      },
    );
  }
  
  // --- WIDGET PARA SECCIÓN 3 (Contenido) ---
  Widget _buildContentManagementSection(BuildContext context, UserModel user) {
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Expanded(
              child: _SmallActionCard(
                title: 'Categorías',
                icon: Icons.category_outlined,
                accentColor: accentColor,
                surfaceColor: surfaceColor,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ManageCategoriesScreen(user: user),
                  ));
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _SmallActionCard(
                title: 'Ver Todos',
                icon: Icons.list_alt_rounded,
                accentColor: accentColor,
                surfaceColor: surfaceColor,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    // CORRECCIÓN: 'AllProductsScreen' no acepta 'categoryFilter'
                    builder: (_) => AllProductsScreen(user: user),
                  ));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET PARA SECCIÓN 4 (Videos) ---
  Widget _buildVideoPromoSection(BuildContext context, UserModel user) {
    final videoService = context.read<VideoService>();
    const accentColor = Color(0xFF00BFFF);

    return StreamBuilder<List<VideoShowcaseModel>>(
      stream: videoService.getVideoShowcasesByProvider(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: CircularProgressIndicator(color: accentColor),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
              child: Center(
                  child: Text('Error al cargar videos: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent))));
        }

        final videos = snapshot.data ?? [];
        
        // --- ¡LÓGICA DE UX CORREGIDA! ---
        // Siempre mostramos el carrusel para que el botón "+" esté visible.
        return SliverToBoxAdapter(
          child: SizedBox(
            height: 150, 
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              // +1 para el botón de Añadir (siempre)
              // +1 para "Gestionar" (solo si hay videos)
              itemCount: videos.length + 1 + (videos.isNotEmpty ? 1 : 0), 
              itemBuilder: (context, index) {
                
                // 1. Botón de Añadir (Siempre primero)
                if (index == 0) {
                   return _AddVideoCard(onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AddEditVideoScreen(user: user),
                    ));
                  });
                }

                // 2. Botón de Gestionar (Al final, solo si hay videos)
                if (videos.isNotEmpty && index == videos.length + 1) {
                  return _ManageAllVideosCard(onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => VideoManagerScreen(user: user),
                    ));
                  });
                }

                // 3. Tarjetas de Video (Ajustamos el índice)
                final video = videos[index - 1]; 
                return VideoCard( // <-- Usando tu widget reutilizable
                  video: video,
                  brandColor: accentColor, 
                  onPlayTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => VideoPlayerScreen(videoShowcase: video),
                    ));
                  },
                  onEditTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AddEditVideoScreen(
                        user: user,
                        videoToEdit: video,
                      ),
                    ));
                  }, 
                );
              },
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET PARA SECCIÓN 5 (Productos por Categoría) ---
  Widget _buildProductsByCategoriesSection(BuildContext context, UserModel user) {
    final categoryService = context.read<CategoryService>();
    final productService = context.read<ProductService>(); // Obtenido aquí

    return StreamBuilder<List<CategoryModel>>(
      stream: categoryService.getCategories(user.uid), 
      builder: (context, categorySnapshot) {
        if (categorySnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingSkeleton(); 
        }
        if (categorySnapshot.hasError) {
          return SliverToBoxAdapter(
              child: Center(
                  child: Text('Error: ${categorySnapshot.error}',
                      style: const TextStyle(color: Colors.redAccent))));
        }
        
        final categories = categorySnapshot.data ?? [];

        if (categories.isEmpty) {
          return const SliverToBoxAdapter(child: _EmptyState());
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final category = categories[index];
              return _ProductCarousel(
                category: category,
                user: user,
                productService: productService, // Pasa el servicio
              );
            },
            childCount: categories.length,
          ),
        );
      },
    );
  }

  // --- WIDGET AUXILIAR PARA TÍTULOS DE SECCIÓN ---
  
  Widget _buildSectionTitle(String title, bool isFirst) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, isFirst ? 16 : 32, 16, 16),
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

// ===================================================================
// --- WIDGETS AUXILIARES ---
// ===================================================================

/// (NUEVO) Fila de Productos para una Categoría Específica
class _ProductCarousel extends StatelessWidget {
  final CategoryModel category;
  final UserModel user;
  final ProductService productService;

  const _ProductCarousel({
    required this.category,
    required this.user,
    required this.productService,
  });

  @override
  Widget build(BuildContext context) {
    // const accentColor = Color(0xFF00BFFF); // No se usa aquí

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Título de la Categoría
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              category.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // 2. Fila Horizontal de Productos
          SizedBox(
            height: 220, // Altura fija para el carrusel
            child: StreamBuilder<List<ProductModel>>(
              // CORRECCIÓN: Llamada al método correcto
              stream: productService.getProducts(user.uid, categoryId: category.id, limit: 5),
              builder: (context, productSnapshot) {
                if (productSnapshot.connectionState == ConnectionState.waiting) {
                  // Un esqueleto de carga horizontal
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: 3,
                    itemBuilder: (context, index) => Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D5A).withAlpha(128),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  );
                }
                
                final products = productSnapshot.data ?? [];

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: products.length + 2, // +1 Añadir, +1 Ver Más
                  itemBuilder: (context, index) {
                    // 1. Botón Añadir (Tu Idea)
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: _AddProductCard(onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            // CORRECCIÓN: Pasamos el 'category' a 'AddEditProductScreen'
                            builder: (_) => AddEditProductScreen(user: user, preselectedCategory: category),
                          ));
                        }),
                      );
                    }
                    // 2. Botón Ver Más (Tu Idea)
                    if (index == products.length + 1) {
                      return _SeeAllCard(onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          // CORRECCIÓN: Pasamos el 'category' a 'AllProductsScreen'
                          builder: (_) => AllProductsScreen(user: user, categoryFilter: category),
                        ));
                      });
                    }
                    // 3. Tarjeta de Producto
                    final product = products[index - 1];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: SizedBox(
                        width: 160, // Ancho fijo para las tarjetas en el carrusel
                        child: ProductCardRefactor( // <-- Usando tu widget reutilizable
                          product: product,
                          brandColor: const Color(0xFF00BFFF), 
                          onDetailTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => AddEditProductScreen(
                                user: user,
                                productToEdit: product,
                              ),
                            ));
                          },
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

// --- (NUEVO) Tarjeta de Acción Compacta ---
class _SmallActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final Color surfaceColor;
  final VoidCallback onTap;

  const _SmallActionCard({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.surfaceColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: accentColor.withAlpha(77),
      highlightColor: accentColor.withAlpha(38),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withAlpha((255 * 0.3).round()))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accentColor, size: 20),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                title,
                style:
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- (NUEVO) Tarjeta para Añadir Producto (Estilo Dotted) ---
class _AddProductCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddProductCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00BFFF);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: accentColor.withAlpha(77),
        highlightColor: accentColor.withAlpha(38),
        child: DottedBorder(
          color: accentColor.withAlpha(153),
          strokeWidth: 2,
          radius: const Radius.circular(16),
          borderType: BorderType.rRect,
          dashPattern: const [8, 6],
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 40, color: accentColor),
                SizedBox(height: 12),
                Text('Añadir Producto',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- (NUEVO) Tarjeta "Ver Más" ---
class _SeeAllCard extends StatelessWidget {
  final VoidCallback onTap;
  const _SeeAllCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160, // Mismo ancho que las tarjetas de producto
        margin: const EdgeInsets.only(right: 12.0),
        decoration: BoxDecoration(
          color: surfaceColor.withAlpha(150),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withAlpha(100),
            width: 1,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_forward_rounded, size: 40, color: accentColor),
              SizedBox(height: 12),
              Text('Ver Más',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- DottedBorder y sus dependencias ---
enum BorderType { rect, rRect }

class DottedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final Radius radius;
  final BorderType borderType;
  final List<double> dashPattern;

  const DottedBorder({
    super.key,
    required this.child,
    this.color = Colors.black,
    this.strokeWidth = 1,
    this.radius = const Radius.circular(0),
    this.borderType = BorderType.rect,
    this.dashPattern = const <double>[3, 1],
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedPainter(
        color: color,
        strokeWidth: strokeWidth,
        radius: radius,
        borderType: borderType,
        dashPattern: dashPattern,
      ),
      child: child,
    );
  }
}

class _DottedPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final Radius radius;
  final BorderType borderType;
  final List<double> dashPattern;

  _DottedPainter({
    this.color = Colors.black,
    this.strokeWidth = 1,
    this.radius = const Radius.circular(0),
    this.borderType = BorderType.rect,
    this.dashPattern = const <double>[3, 1],
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    Path path;
    if (borderType == BorderType.rRect) {
      final validRadius = Radius.elliptical(radius.x.abs(), radius.y.abs());
      path = Path()
        ..addRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height), validRadius));
    } else {
      path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    Path dashPath = Path();
    double distance = 0.0;
    if (dashPattern.isNotEmpty && dashPattern[0] > 0) {
      final double dashLength = dashPattern[0];
      final double gapLength = dashPattern.length > 1 ? dashPattern[1] : 0;
      final double totalDashPatternLength = dashLength + gapLength;

      if (totalDashPatternLength > 0) {
        for (PathMetric pathMetric in path.computeMetrics()) {
          while (distance < pathMetric.length) {
            final double end = (distance + dashLength).clamp(0.0, pathMetric.length);
            dashPath.addPath(
              pathMetric.extractPath(distance, end),
              Offset.zero,
            );
            distance += totalDashPatternLength;
          }
        }
      } else {
        dashPath = path;
      }
    } else {
      dashPath = path;
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(_DottedPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.radius != radius ||
      oldDelegate.borderType != borderType ||
      !listEquals(oldDelegate.dashPattern, dashPattern);
}

// --- Resto de widgets auxiliares (StatusTag, EmptyState, etc.) ---

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
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_mall_directory_outlined,
                size: 80, color: Colors.white24),
            SizedBox(height: 24),
            Text('Añade categorías',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              'Crea categorías en "Gestor de Contenido" para empezar a añadir productos.',
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
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate(
          [
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D5A).withAlpha(128),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 12.0),
      decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withAlpha(100))),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => OrderDetailScreen(order: order),
            ));
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        color: accentColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Venta Pendiente',
                      style: TextStyle(
                          color: accentColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  order.items.isNotEmpty
                      ? order.items.first['name']
                      : 'Orden Desconocida',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Cliente: ${order.clientName} - \$${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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

class _ManageAllVideosCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ManageAllVideosCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12.0),
        decoration: BoxDecoration(
          color: surfaceColor.withAlpha(100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accentColor.withAlpha(150),
            width: 2,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_rounded,
                color: accentColor, size: 40),
            SizedBox(height: 8),
            Text(
              'Gestionar\nVideos',
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