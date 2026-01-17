import 'package:flutter/material.dart';

class SmartFeaturedSection<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final bool isLoading;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final VoidCallback? onSeeAllTap;
  final double height;
  final EdgeInsetsGeometry padding;

  const SmartFeaturedSection({
    super.key,
    required this.title,
    required this.items,
    required this.itemBuilder,
    this.isLoading = false,
    this.onSeeAllTap,
    this.height = 220.0, // Altura por defecto del carrusel
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    // 1. ESTADO DE CARGA: Skeleton o Loader discreto
    if (isLoading) {
      return Container(
        height: height,
        margin: padding,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    // 2. ESTADO VACÍO (LA MAGIA ✨)
    // Si la lista está vacía, el widget ocupa 0 espacio.
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    // 3. ESTADO CON DATOS
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabecera de la Sección
        Padding(
          padding: EdgeInsets.symmetric(horizontal: (padding as EdgeInsets).left),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onSeeAllTap != null)
                TextButton(
                  onPressed: onSeeAllTap,
                  child: const Text('Ver todo', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),

        // Carrusel Horizontal
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: padding,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return itemBuilder(context, items[index]);
            },
          ),
        ),
      ],
    );
  }
}