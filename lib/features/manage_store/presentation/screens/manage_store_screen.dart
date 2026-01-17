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
import 'package:proveedor_servicly_app/widgets/provider_stats_panel.dart';
import 'package:proveedor_servicly_app/widgets/pending_sales_summary.dart';
import 'package:proveedor_servicly_app/widgets/video_card.dart';
import 'package:proveedor_servicly_app/features/manage_store/widgets/store_ui_kit.dart';
import 'package:proveedor_servicly_app/features/manage_store/widgets/category_product_row.dart';

// --- Navegación ---
import 'add_edit_video_screen.dart';
import 'video_manager_screen.dart';
import 'manage_categories_screen.dart';
import 'all_products_screen.dart';
import 'video_player_screen.dart';

// Constantes
const double kWebBreakpoint = 900.0;
const double kMaxWebWidth = 1400.0;

class ManageStoreScreen extends StatelessWidget {
  final UserModel user;

  const ManageStoreScreen({super.key, required this.user});

  // --- Utilidades ---
  Future<void> _launchURL(String url) async {
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
    // Tu lógica de bottom sheet
  }

  @override
  Widget build(BuildContext context) {
    // Usamos LayoutBuilder para decidir si pintamos Móvil o Web
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > kWebBreakpoint) {
          return _buildWebDashboard(context);
        } else {
          return _buildMobileLayout(context);
        }
      },
    );
  }

  // ===========================================================================
  // 🖥️ LAYOUT WEB (NUEVO DISEÑO DASHBOARD)
  // ===========================================================================
  Widget _buildWebDashboard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Fondo Dashboard oscuro profesional
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kMaxWebWidth),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- COLUMNA IZQUIERDA (Principal - 65%) ---
              Expanded(
                flex: 7,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Header de Marca (Más compacto en web)
                            BrandHeaderCard(
                              user: user,
                              onShowContacts: (p) => _showContactSheet(context, p),
                              onLaunchUrl: _launchURL,
                            ),
                            const SizedBox(height: 32),

                            // 2. Título Dashboard
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Panel de Control", style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                                FilledButton.icon(
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AllProductsScreen(user: user))),
                                  icon: const Icon(Icons.inventory_2_outlined),
                                  label: const Text("Gestor de Inventario"),
                                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00BFFF)), // Tu color de marca
                                )
                              ],
                            ),
                            const SizedBox(height: 24),

                            // 3. Estadísticas (Ocupan ancho completo de esta columna)
                            ProviderStatsPanel(userId: user.uid),
                            
                            const SizedBox(height: 32),
                            _buildSectionTitle('Productos por Categoría'),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    // 4. Lista de Productos (Slivers)
                    _ProductsByCategoryList(user: user),
                    const SliverToBoxAdapter(child: SizedBox(height: 50)),
                  ],
                ),
              ),

              // --- SEPARADOR VERTICAL ---
              Container(width: 1, color: Colors.white.withOpacity(0.1)),

              // --- COLUMNA DERECHA (Lateral / Herramientas - 35%) ---
              Expanded(
                flex: 4,
                child: Container(
                  color: const Color(0xFF1E293B), // Fondo ligeramente más claro para sidebar
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildSectionTitle('Acciones Rápidas', fontSize: 18),
                      const SizedBox(height: 16),
                      // Grid de acciones
                      GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _WebActionCard(
                            title: "Crear\nCategoría", 
                            icon: Icons.create_new_folder_outlined, 
                            color: Colors.purpleAccent,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageCategoriesScreen(user: user)))
                          ),
                          _WebActionCard(
                            title: "Subir\nVideo", 
                            icon: Icons.video_call_outlined, 
                            color: Colors.redAccent,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditVideoScreen(user: user)))
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                      _buildSectionTitle('Estado de Pedidos', fontSize: 18),
                      const SizedBox(height: 16),
                      PendingSalesSummary(providerId: user.uid),

                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle('Mis Historias', fontSize: 18),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoManagerScreen(user: user))),
                            tooltip: "Gestionar Videos",
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Videos en grid vertical para el sidebar
                      _WebVideoSidebarList(user: user),
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

  // ===========================================================================
  // 📱 LAYOUT MÓVIL (TU CÓDIGO ORIGINAL INTACTO)
  // ===========================================================================
  Widget _buildMobileLayout(BuildContext context) {
    const kCyberBg = Color(0xFF0F172A); // Tu color de fondo original (asumido)

    return Scaffold(
      backgroundColor: kCyberBg,
      appBar: AppBar(
        title: const Text('Gestionar Mi Tienda'),
        backgroundColor: kCyberBg,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: BrandHeaderCard(
              user: user,
              onShowContacts: (p) => _showContactSheet(context, p),
              onLaunchUrl: _launchURL,
            ),
          ),
          _buildMobileSectionTitle('Resumen de Actividad'),
          SliverToBoxAdapter(child: ProviderStatsPanel(userId: user.uid)),
          _buildMobileSectionTitle('Ventas Pendientes'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: PendingSalesSummary(providerId: user.uid),
            ),
          ),
          _buildMobileSectionTitle('Mis Videos Promocionales'),
          _VideoPromoSection(user: user),
          _buildMobileSectionTitle('Mi Catálogo'),
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
          _ProductsByCategoryList(user: user),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // --- Helpers UI ---

  Widget _buildSectionTitle(String title, {double fontSize = 20}) {
    return Text(
      title,
      style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildMobileSectionTitle(String title, {bool isFirst = false}) {
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
}

// ===========================================================================
// WIDGETS AUXILIARES (Refactorizados)
// ===========================================================================

// Tarjeta de Acción rápida para Web
class _WebActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _WebActionCard({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// Lista de videos vertical para el sidebar web
class _WebVideoSidebarList extends StatelessWidget {
  final UserModel user;
  const _WebVideoSidebarList({required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VideoShowcaseModel>>(
      stream: context.read<VideoService>().getVideoShowcasesByProvider(user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) return const SizedBox.shrink();
        final videos = snapshot.data!;
        if (videos.isEmpty) return const Text("No hay videos aún.", style: TextStyle(color: Colors.grey));

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, 
            childAspectRatio: 0.7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8
          ),
          itemCount: videos.length > 4 ? 4 : videos.length, // Mostrar máx 4 en sidebar
          itemBuilder: (context, index) {
            final video = videos[index];
            return VideoCard(
              video: video,
              brandColor: const Color(0xFF00BFFF),
              onPlayTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(videoShowcase: video))),
              onEditTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditVideoScreen(user: user, videoToEdit: video))),
            );
          },
        );
      },
    );
  }
}

// Versión original horizontal para Móvil
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
                if (videos.isNotEmpty && index == videos.length + 1) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: DashedActionCard(
                      label: 'Gestionar\nVideos',
                      icon: Icons.video_library_rounded,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoManagerScreen(user: user))),
                    ),
                  );
                }
                final video = videos[index - 1];
                return VideoCard(
                  video: video,
                  brandColor: const Color(0xFF00BFFF),
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
        if (categories.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

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