import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- Modelos ---
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';

// --- Servicios ---
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';

// --- Widgets del Editor ---
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog_editor/catalog_hero_header_editor.dart';
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog_editor/catalog_portfolio_section_editor.dart';
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog_editor/catalog_services_section_editor.dart';
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog_editor/catalog_trust_signals_editor.dart';
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog_editor/catalog_gift_card_section_editor.dart';
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog_editor/catalog_promotions_section_editor.dart';

// --- Widgets de Visualización ---
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog/catalog_reviews_section.dart';

class CatalogEditorScreen extends StatefulWidget {
  final String providerId;
  const CatalogEditorScreen({super.key, required this.providerId});

  @override
  State<CatalogEditorScreen> createState() => _CatalogEditorScreenState();
}

class _CatalogEditorScreenState extends State<CatalogEditorScreen> {
  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    final currentUser = context.read<UserModel?>();

    if (currentUser == null) return const Scaffold(body: Center(child: Text("Error de sesión")));

    return StreamBuilder<ProviderProfileModel?>(
      stream: firestoreService.getCatalogStream(widget.providerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: Color(0xFF1A1A2E), body: Center(child: CircularProgressIndicator(color: Color(0xFF00B2B2))));
        }

        final profile = snapshot.data;
        if (profile == null) return const Scaffold(body: Center(child: Text("No se encontró la configuración del catálogo")));

        return Scaffold(
          backgroundColor: const Color(0xFF0D0D1A),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Header Editor
              CatalogHeroHeaderEditor(profile: profile, user: currentUser),

              // 2. Sección de Promociones (Usando el nuevo widget editor)
              CatalogPromotionsSectionEditor(providerId: widget.providerId),

              // 3. Señales de confianza
              CatalogTrustSignalsEditor(profile: profile),

              // 4. Portafolio
              CatalogPortfolioSectionEditor(providerId: widget.providerId, brandColor: profile.brandColor),

              // 5. Servicios
              CatalogServicesSectionEditor(providerId: widget.providerId, brandColor: profile.brandColor),

              // 6. Sección de Gift Cards (Usando el nuevo widget editor)
              CatalogGiftCardSectionEditor(providerId: widget.providerId),

              // 7. Reseñas con Toggle
              _buildModuleToggle(
                context,
                title: "Opiniones de Clientes",
                subtitle: "Mostrar testimonios reales en tu perfil",
                isEnabled: profile.showReviewsModule,
                onChanged: (val) => _updateModuleVisibility('showReviewsModule', val),
              ),
              
              if (profile.showReviewsModule) CatalogReviewsSection(profile: profile),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF00B2B2),
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
            label: const Text("VISTA FINALIZADA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Future<void> _updateModuleVisibility(String field, bool value) async {
    await context.read<FirestoreService>().updateCatalogField(widget.providerId, {field: value});
  }

  Widget _buildModuleToggle(BuildContext context, {required String title, required String subtitle, required bool isEnabled, required Function(bool) onChanged}) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isEnabled ? const Color(0xFF00B2B2).withValues(alpha: 0.3) : Colors.white10),
        ),
        child: Row(
          children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11))])),
            Switch(value: isEnabled, activeColor: const Color(0xFF00B2B2), onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}