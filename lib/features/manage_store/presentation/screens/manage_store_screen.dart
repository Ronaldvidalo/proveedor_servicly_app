import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// --- Modelos y Servicios ---
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/models/video_showcase_model.dart';
import 'package:proveedor_servicly_app/core/models/category_model.dart';
import 'package:proveedor_servicly_app/core/services/video_service.dart';
import 'package:proveedor_servicly_app/core/services/category_service.dart';
import 'package:proveedor_servicly_app/core/services/product_service.dart';

// --- Screens & Widgets ---
import 'package:proveedor_servicly_app/widgets/brand_header_card.dart';
import 'package:proveedor_servicly_app/widgets/info_chip.dart';
import 'package:proveedor_servicly_app/widgets/provider_stats_panel.dart';
import 'package:proveedor_servicly_app/widgets/pending_sales_summary.dart';
import 'package:proveedor_servicly_app/widgets/VideoCard.dart';
import 'package:proveedor_servicly_app/features/manage_store/widgets/store_ui_kit.dart'; // NUESTRO KIT
import 'package:proveedor_servicly_app/features/manage_store/widgets/category_product_row.dart'; // NUESTRO WIDGET DE CATEGORIA

// --- Navegación ---
import 'add_edit_video_screen.dart';
import 'video_manager_screen.dart';
import 'manage_categories_screen.dart';
import 'all_products_screen.dart';
import 'video_player_screen.dart';

class ManageStoreScreen extends StatelessWidget {
  final UserModel user;

  const ManageStoreScreen({super.key, required this.user});

  // --- Utilidades ---
  Future<void> _launchURL(String url) async {
    // Lógica simplificada de URL
    final uri = Uri.parse(url.startsWith('http') || url.startsWith('tel') ? url : 'https://$url');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching $url: $e');
    }
  }

  void _showContactSheet(BuildContext context, ProviderProfileModel profile) {
    // ... (Tu lógica de bottom sheet, simplificada para brevedad en este ejemplo,
    // pero idealmente extraída a un widget 'ContactBottomSheet' en otro archivo)
    // Mantengo tu implementación original en mente, pero usando el tema centralizado.
  }

  // --- Constructores de UI ---

  Widget _buildSectionTitle(String title, {bool isFirst = false}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, isFirst ? 16 : 32, 16, 16),
        child: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCyberBg, // Usando constante global
      appBar: AppBar(
        title: const Text('Gestionar Mi Tienda'),
        backgroundColor: kCyberBg,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Identidad
          SliverToBoxAdapter(
            child: BrandHeaderCard(
              user: user,
              onShowContacts: (p) => _showContactSheet(context, p),
              onLaunchUrl: _launchURL,
            ),
          ),

          // 2. Estadísticas
          _buildSectionTitle('Resumen de Actividad'),
          SliverToBoxAdapter(child: ProviderStatsPanel(userId: user.uid)),

          // 3. Ventas Pendientes
          _buildSectionTitle('Ventas Pendientes'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: PendingSalesSummary(providerId: user.uid),
            ),
          ),

          // 4. Videos Promocionales
          _buildSectionTitle('Mis Videos Promocionales'),
          _VideoPromoSection(user: user), // Widget privado extraído abajo para limpieza

          // 5. Gestor de Catálogo (Botones de acción)
          _buildSectionTitle('Mi Catálogo'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: SmallActionCard(
                      title: 'Categorías',
                      icon: Icons.category_outlined,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageCategoriesScreen(user: user))),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SmallActionCard(
                      title: 'Ver Todos',
                      icon: Icons.list_alt_rounded,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AllProductsScreen(user: user))),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 6. Productos por Categoría (Carga dinámica)
          _ProductsByCategoryList(user: user), // Widget privado extraído abajo

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// --- Sub-Componentes Locales (Para no ensuciar el build principal) ---

class _VideoPromoSection extends StatelessWidget {
  final UserModel user;
  const _VideoPromoSection({required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VideoShowcaseModel>>(
      stream: context.read<VideoService>().getVideoShowcasesByProvider(user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SliverToBoxAdapter(child: SizedBox.shrink());
        
        final videos = snapshot.data ?? [];
        
        return SliverToBoxAdapter(
          child: SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: videos.length + 1 + (videos.isNotEmpty ? 1 : 0),
              itemBuilder: (context, index) {
                // A. Añadir Video
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: DashedActionCard(
                      label: 'Añadir\nVideo',
                      icon: Icons.video_call_rounded,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditVideoScreen(user: user))),
                    ),
                  );
                }
                // B. Gestionar Todo (Solo si hay videos)
                if (videos.isNotEmpty && index == videos.length + 1) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: DashedActionCard( // Reutilizamos Dashed pero con estilo "Gestionar"
                      label: 'Gestionar\nVideos',
                      icon: Icons.video_library_rounded,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoManagerScreen(user: user))),
                    ),
                  );
                }
                // C. Video Card
                final video = videos[index - 1];
                return VideoCard(
                  video: video,
                  brandColor: kCyberAccent,
                  onPlayTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(videoShowcase: video))),
                  onEditTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditVideoScreen(user: user, videoToEdit: video))),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ProductsByCategoryList extends StatelessWidget {
  final UserModel user;
  const _ProductsByCategoryList({required this.user});

  @override
  Widget build(BuildContext context) {
    final productService = context.read<ProductService>();
    
    return StreamBuilder<List<CategoryModel>>(
      stream: context.read<CategoryService>().getCategories(user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SliverToBoxAdapter(child: SizedBox.shrink());
        
        final categories = snapshot.data!;
        if (categories.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink()); // O tu EmptyState

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => CategoryProductRow(
              category: categories[index],
              user: user,
              productService: productService,
            ),
            childCount: categories.length,
          ),
        );
      },
    );
  }
}