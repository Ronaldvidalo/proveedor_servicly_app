import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- Modelos ---
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';

// --- Servicios ---
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';

// --- Widgets del Editor (Los que creamos hoy) ---
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog_editor/catalog_hero_header_editor.dart';
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog_editor/catalog_portfolio_section_editor.dart';
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog_editor/catalog_services_section_editor.dart';
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog_editor/catalog_trust_signals_editor.dart';

// --- Widgets de Visualización (Reutilizados) ---
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog/catalog_promotions_section.dart';
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog/catalog_trust_signals.dart';
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog/catalog_gift_card_section.dart';
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog/catalog_reviews_section.dart';


class CatalogEditorScreen extends StatefulWidget {
  final String providerId;

  const CatalogEditorScreen({
    super.key, 
    required this.providerId
  });

  @override
  State<CatalogEditorScreen> createState() => _CatalogEditorScreenState();
}

class _CatalogEditorScreenState extends State<CatalogEditorScreen> {
  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    // Obtenemos el usuario actual para pasarlo a los editores que requieren navegar a BrandSettings
    final currentUser = context.read<UserModel?>();

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Error de sesión")));
    }

    return StreamBuilder<ProviderProfileModel?>(
      stream: firestoreService.getCatalogStream(widget.providerId), // Stream para cambios en tiempo real
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF1A1A2E),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF00B2B2))),
          );
        }

        final profile = snapshot.data;

        if (profile == null) {
          return const Scaffold(
            body: Center(child: Text("No se encontró la configuración del catálogo")),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF1A1A2E),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Header con edición de identidad (Redirige a Brand Settings)
              CatalogHeroHeaderEditor(
                profile: profile,
                user: currentUser,
              ),

              // 2. Módulo de Promociones (Vista previa)
              const CatalogPromotionsSection(),

              // 3. Señales de confianza (Vista previa)
              CatalogTrustSignalsEditor(profile: profile),

              // 4. Portafolio con botones de Gestión (Subir fotos / Categorías)
              CatalogPortfolioSectionEditor(
                providerId: widget.providerId,
                brandColor: profile.brandColor,
              ),

              // 5. Servicios con conexión a Inventario y Costos
              CatalogServicesSectionEditor(
                providerId: widget.providerId,
                brandColor: profile.brandColor,
              ),

              // 6. Gift Cards (Configuración rápida)
              const CatalogGiftCardSection(),

              // 7. Reseñas (Interruptor de visibilidad)
              _buildModuleToggle(
                context,
                title: "Opiniones de Clientes",
                subtitle: "Mostrar testimonios reales en tu perfil",
                isEnabled: profile.showReviewsModule,
                onChanged: (val) => _updateModuleVisibility('showReviewsModule', val),
              ),
              
              if (profile.showReviewsModule)
                CatalogReviewsSection(profile: profile),

              // Espacio final
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          
          // Botón de finalización / Guardado global
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF00B2B2),
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text("VISTA FINALIZADA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  // --- LÓGICA DE CONFIGURACIÓN DEL EDITOR ---

  Future<void> _updateModuleVisibility(String field, bool value) async {
    await context.read<FirestoreService>().updateCatalogField(
      widget.providerId, 
      {field: value}
    );
  }

  Widget _buildModuleToggle(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isEnabled,
    required Function(bool) onChanged,
  }) {
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            Switch(
              value: isEnabled,
              activeColor: const Color(0xFF00B2B2),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}