import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/portfolio_category_model.dart';
import 'package:proveedor_servicly_app/core/models/portfolio_item_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';

// Importamos tus widgets personalizados
import 'package:proveedor_servicly_app/features/catalogo/modules/_category_chip.dart';
import 'package:proveedor_servicly_app/features/catalogo/modules/_portfolio_item_card.dart';

class CatalogPortfolioSection extends StatefulWidget {
  final String providerId;
  final Color brandColor;

  const CatalogPortfolioSection({
    super.key,
    required this.providerId,
    required this.brandColor,
  });

  @override
  State<CatalogPortfolioSection> createState() => _CatalogPortfolioSectionState();
}

class _CatalogPortfolioSectionState extends State<CatalogPortfolioSection> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return SliverList(
      delegate: SliverChildListDelegate([
        // --- TÍTULO DE SECCIÓN ---
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 16, 8),
          child: Text(
            'Portafolio',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // --- SELECTOR DE CATEGORÍAS (Usando CategoryChip) ---
        _buildCategorySelector(firestoreService),

        // --- CUADRÍCULA DE TRABAJOS ---
        StreamBuilder<List<PortfolioItemModel>>(
          stream: firestoreService.getPortfolioItemsStream(
              widget.providerId, _selectedCategoryId ?? ''),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && _selectedCategoryId != null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24),
                ),
              );
            }
            
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox(
                height: 150,
                child: Center(
                  child: Text("No hay fotos en esta categoría", 
                    style: TextStyle(color: Colors.white24, fontSize: 14)),
                ),
              );
            }

            final items = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                // Diseño de 3 columnas para un look de galería profesional
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.0,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) => PortfolioItemCard(
                  item: items[index], 
                  isEditable: false, // En el perfil público no se edita
                ),
              ),
            );
          },
        ),
      ]),
    );
  }

  Widget _buildCategorySelector(FirestoreService firestore) {
    return StreamBuilder<List<PortfolioCategoryModel>>(
      stream: firestore.getPortfolioCategoriesStream(widget.providerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        final categories = snapshot.data!;

        return SizedBox(
          height: 55,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final cat = isAll ? null : categories[index - 1];
              final isSelected = isAll ? _selectedCategoryId == null : _selectedCategoryId == cat?.id;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                // Usamos tu widget CategoryChip reutilizable
                child: CategoryChip(
                  label: isAll ? 'Todos' : cat!.name,
                  isSelected: isSelected,
                  onTap: () => setState(() => _selectedCategoryId = isAll ? null : cat?.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}