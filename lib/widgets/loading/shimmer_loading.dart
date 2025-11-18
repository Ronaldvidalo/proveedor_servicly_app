// lib/common/widgets/loading/shimmer_loading.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui; // Necesario para PathMetric y listEquals

// --- Estilos Globales utilizados en el Shimmer ---
// Colores base del tema 'Cyber Glow' oscuro
const Color _surfaceColor = Color(0xFF2D2D5A); 
const Color _highlightColor = Color(0xFF3A3A6E); 

/// Un transformador de gradiente que simula el movimiento de la luz
/// en el efecto shimmer.
class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});
  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // Calcula la traslación horizontal
    final translationX = bounds.width * slidePercent * 2.0 - bounds.width;
    return Matrix4.translationValues(translationX, 0.0, 0.0);
  }
}

/// Objeto genérico que se pinta con el gradiente shimmer.
class ShimmerObject extends StatelessWidget {
  final double? width;
  final double? height;
  final bool isCircle;
  final LinearGradient gradient;

  const ShimmerObject({
    super.key,
    required this.gradient,
    this.width,
    this.height,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: isCircle ? null : BorderRadius.circular(16),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      ),
    );
  }
}

/// Esqueleto de carga completo del Dashboard con efecto Shimmer.
class LoadingSkeleton extends StatefulWidget {
  final String? userName;
  final String? businessName;
  
  // Renombramos de _LoadingSkeleton a LoadingSkeleton
  const LoadingSkeleton({super.key, this.userName, this.businessName}); 

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  // Genera el gradiente que se mueve
  LinearGradient get _shimmerGradient {
    return LinearGradient(
      colors: const [_surfaceColor, _highlightColor, _surfaceColor],
      stops: const [0.1, 0.3, 0.4],
      begin: const Alignment(-1.0, -0.3),
      end: const Alignment(1.0, 0.3),
      tileMode: TileMode.clamp,
      transform:
          _SlidingGradientTransform(slidePercent: _shimmerController.value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final gradient = _shimmerGradient;
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Skeleton para Avatar
                    ShimmerObject(width: 44, height: 44, gradient: gradient, isCircle: true),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerObject(
                              width: 150, height: 16, gradient: gradient),
                          const SizedBox(height: 8),
                          ShimmerObject(
                              width: 220, height: 28, gradient: gradient),
                        ],
                      ),
                    ),
                    // Skeleton para botones de acción
                    ShimmerObject(width: 44, height: 44, gradient: gradient, isCircle: true),
                    const SizedBox(width: 8),
                    ShimmerObject(width: 44, height: 44, gradient: gradient, isCircle: true),
                  ],
                ),
              ),
            ),
            // Placeholder para Métricas
            SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              sliver: SliverToBoxAdapter(
                  child: ShimmerObject(height: 120, gradient: gradient)),
            ),
            // Placeholder para Botón Perfil Público
            SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              sliver: SliverToBoxAdapter(
                  child: ShimmerObject(height: 50, gradient: gradient)),
            ),
            // Placeholder para Módulos (Grid)
            SliverPadding(
              padding: const EdgeInsets.all(24.0),
              sliver: SliverGrid.count(
                crossAxisCount: 
                    (MediaQuery.of(context).size.width / 180).floor().clamp(2, 5),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children:
                    List.generate(6, (index) => ShimmerObject(gradient: gradient)),
              ),
            ),
          ],
        );
      },
    );
  }
}