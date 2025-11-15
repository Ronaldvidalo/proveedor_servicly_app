import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/services/follow_service.dart';
import 'package:proveedor_servicly_app/core/services/product_service.dart';
import 'package:proveedor_servicly_app/core/services/video_service.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';

/// Un panel de estadísticas reutilizable que muestra 4 métricas clave
/// para el proveedor, obtenidas de múltiples servicios.
/// AHORA EN UNA GRILLA 2x2.
class ProviderStatsPanel extends StatelessWidget {
  final String userId;

  const ProviderStatsPanel({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final followService = context.watch<FollowService>();
    final productService = context.watch<ProductService>();
    final videoService = context.watch<VideoService>();
    final firestoreService = context.watch<FirestoreService>();

    const accentColor = Color(0xFF00BFFF);

    // Combinamos todos los streams en uno solo para manejarlos juntos
    // (Esto es un enfoque más avanzado, pero mantendremos los StreamBuilders anidados por ahora
    // ya que funcionan y son más fáciles de leer).

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      // No necesitamos color de fondo aquí, las tarjetas lo tendrán
      child: StreamBuilder<int>(
        stream: followService.getFollowersCount(userId),
        builder: (context, followersSnap) {
          final followers = followersSnap.data ?? 0;

          return StreamBuilder<List<dynamic>>(
            stream: productService.getProducts(userId),
            builder: (context, productsSnap) {
              final productCount = productsSnap.data?.length ?? 0;

              return StreamBuilder<List<dynamic>>(
                stream: videoService.getVideoShowcasesByProvider(userId),
                builder: (context, videosSnap) {
                  final videoCount = videosSnap.data?.length ?? 0;

                  return StreamBuilder<dynamic>(
                    stream: firestoreService.getBrandProfile(userId),
                    builder: (context, profileSnap) {
                      final rating = profileSnap.data?.averageRating ?? 0.0;
                      
                      // Si CUALQUIER stream está cargando, mostramos un loader
                      if (followersSnap.connectionState == ConnectionState.waiting ||
                          productsSnap.connectionState == ConnectionState.waiting ||
                          videosSnap.connectionState == ConnectionState.waiting ||
                          profileSnap.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 180, // Altura para 2 filas
                          child: Center(child: CircularProgressIndicator(color: accentColor)),
                        );
                      }

                      // --- ¡DISEÑO DE GRILLA 2x2! ---
                      return GridView.count(
                        crossAxisCount: 2, // 2 columnas
                        shrinkWrap: true, // Para que quepa en el SliverList
                        physics: const NeverScrollableScrollPhysics(), // No queremos scroll aquí
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.0, // Más anchos que altos (ajusta esto a tu gusto)
                        children: [
                          _StatTile(
                            value: followers.toString(),
                            label: 'Seguidores',
                            icon: Icons.person_add_alt_1_outlined,
                            color: Colors.greenAccent.shade100,
                          ),
                          _StatTile(
                            value: productCount.toString(),
                            label: 'Productos',
                            icon: Icons.shopping_bag_outlined,
                            color: Colors.lightBlueAccent.shade100,
                          ),
                          _StatTile(
                            value: videoCount.toString(),
                            label: 'Publicaciones',
                            icon: Icons.video_library_outlined,
                            color: Colors.purpleAccent.shade100,
                          ),
                          _StatTile(
                            value: rating.toStringAsFixed(1),
                            label: 'Ranking',
                            icon: Icons.star_border_outlined,
                            color: Colors.orangeAccent.shade100,
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Widget interno rediseñado como una "tarjeta"
class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Color(0xFF2D2D5A);
    
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)) // Borde sutil
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. Icono
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          // 2. Textos
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24, // Grande y claro
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13, // Más pequeño
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}