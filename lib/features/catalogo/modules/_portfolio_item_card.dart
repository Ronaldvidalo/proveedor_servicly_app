import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proveedor_servicly_app/core/models/portfolio_item_model.dart';
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog/portfolio_item_detail_view.dart';

class PortfolioItemCard extends StatelessWidget {
  final PortfolioItemModel item;
  final bool isEditable;
  final VoidCallback? onDelete;
  final String providerId; 
  // ✅ NUEVOS PARÁMETROS: Para alimentar la lógica del botón de contacto
  final String profileType;
  final String businessName;

  const PortfolioItemCard({
    super.key,
    required this.item,
    required this.isEditable,
    required this.providerId,
    required this.profileType,    // Requerido ahora
    required this.businessName,   // Requerido ahora
    this.onDelete,
  }) : assert(!isEditable || onDelete != null, 'onDelete callback is required when isEditable is true');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget content;

    if (item.type == PortfolioItemType.image) {
      content = Image.network(
        item.url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_outlined, color: colorScheme.error, size: 32),
              const SizedBox(height: 4),
              Text(
                "Error", 
                style: TextStyle(color: colorScheme.error, fontSize: 10)
              )
            ],
          ),
        ),
      );
    } else { 
      content = Container(
        color: theme.brightness == Brightness.dark 
            ? Colors.black26 
            : Colors.grey.shade200,
        child: Center(
          child: Icon(
            Icons.play_circle_outline_rounded, 
            color: colorScheme.primary, 
            size: 50
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Hero(
        tag: 'portfolio_item_${item.id}',
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
               BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Stack(
              fit: StackFit.expand,
              children: [
                content,
                if (isEditable)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.6),
                      type: MaterialType.circle,
                      child: InkWell(
                        onTap: onDelete,
                        customBorder: const CircleBorder(),
                        splashColor: Colors.red.withValues(alpha: 0.4),
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    if (isEditable) return;

    final String currentViewerId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => PortfolioItemDetailView(
          item: item,
          providerId: providerId,
          currentViewerId: currentViewerId,
          // ✅ PASAMOS LOS NUEVOS DATOS REQUERIDOS
          profileType: profileType,
          businessName: businessName,
        ),
      ),
    );
  }
}