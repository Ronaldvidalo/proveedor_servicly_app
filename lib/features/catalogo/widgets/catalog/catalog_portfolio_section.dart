import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/portfolio_category_model.dart';
import 'package:proveedor_servicly_app/core/models/portfolio_item_model.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart'; // ✅ Nuevo Import
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

    // ✅ PASO TÉCNICO 1: Escuchamos el perfil del proveedor para obtener rubro y nombre comercial
    return StreamBuilder<ProviderProfileModel?>(
      stream: firestoreService.getCatalogStream(widget.providerId),
      builder: (context, profileSnapshot) {
        if (profileSnapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white10),
            )),
          );
        }

        final profile = profileSnapshot.data;
        // Valores por defecto si el perfil no carga para evitar errores de compilación
        final profileType = profile?.profileType ?? 'profesional';
        final businessName = profile?.businessName ?? 'Servicly App';

        return SliverList(
          delegate: SliverChildListDelegate([
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 16, 8),
              child: Text(
                'Evidencia de Trabajos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // 1. Selector de Carpetas
            _buildCategorySelector(firestoreService),

            // 2. Grilla de Imágenes y Videos
            if (_selectedCategoryId != null)
              StreamBuilder<List<PortfolioItemModel>>(
                stream: firestoreService.getCatalogPortfolioItemsStream(
                    widget.providerId, _selectedCategoryId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24),
                      ),
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return _buildErrorMessage("Error de conexión con el portafolio");
                  }

                  final items = snapshot.data ?? [];
                  
                  if (items.isEmpty) {
                    return _buildErrorMessage("No hay fotos en esta categoría");
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        // ✅ PASO TÉCNICO 2: Inyectamos los datos del perfil requeridos por la tarjeta
                        return PortfolioItemCard(
                          item: items[index], 
                          isEditable: false,
                          providerId: widget.providerId,
                          profileType: profileType, // <--- Enviamos el rubro
                          businessName: businessName, // <--- Enviamos el nombre
                        );
                      },
                    ),
                  );
                },
              )
            else
              const SizedBox(height: 100),
          ]),
        );
      },
    );
  }

  Widget _buildCategorySelector(FirestoreService firestore) {
    return StreamBuilder<List<PortfolioCategoryModel>>(
      stream: firestore.getCatalogPortfolioCategoriesStream(widget.providerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        
        final categories = snapshot.data!;

        if (_selectedCategoryId == null || !categories.any((c) => c.id == _selectedCategoryId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedCategoryId = categories.first.id);
          });
        }

        return SizedBox(
          height: 55,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = _selectedCategoryId == cat.id;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: CategoryChip(
                  label: cat.name,
                  isSelected: isSelected,
                  onTap: () => setState(() => _selectedCategoryId = cat.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorMessage(String msg) {
    return SizedBox(
      height: 150,
      child: Center( 
        child: Text(
          msg, 
          style: const TextStyle(color: Colors.white24, fontSize: 13),
        ),
      ),
    );
  }
}