import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/providers/catalog_editor_provider.dart';
import 'package:proveedor_servicly_app/core/services/permissions_service.dart';

class ModuleSettingsSheet extends StatelessWidget {
  const ModuleSettingsSheet({super.key}); // Añadido super.key

  @override
  Widget build(BuildContext context) {
    final permissions = context.read<PermissionsService>();

    return Container(
      // Damos un color de fondo oscuro que coincida con el editor
      color: Colors.grey[850], // O el color que prefieras
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del BottomSheet
          Text(
            "Configurar Módulos",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white), // Texto blanco
          ),
          Text(
            "Selecciona qué módulos quieres mostrar en tu perfil público.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70), // Texto más claro
          ),
          const Divider(height: 32, color: Colors.white24), // Divisor más claro

          // Módulo de Bienvenida
          Consumer<CatalogEditorProvider>(
            builder: (context, provider, child) {
              return SwitchListTile(
                title: const Text("Módulo de Bienvenida", style: TextStyle(color: Colors.white)),
                value: provider.profile.showWelcomeModule,
                onChanged: (newValue) {
                  provider.setModuleVisibility(
                    moduleKey: 'showWelcomeModule',
                    isVisible: newValue,
                  );
                },
              );
            },
          ),
          
          // Módulo de Portafolio
          Consumer<CatalogEditorProvider>(
            builder: (context, provider, child) {
              return SwitchListTile(
                title: const Text("Módulo de Portafolio", style: TextStyle(color: Colors.white)),
                value: provider.profile.showPortfolioModule,
                onChanged: permissions.canUsePortfolioModule ? (newValue) {
                  provider.setModuleVisibility(
                    moduleKey: 'showPortfolioModule',
                    isVisible: newValue,
                  );
                } : null, 
              );
            },
          ),
          
          // Módulo de Promociones
          Consumer<CatalogEditorProvider>(
            builder: (context, provider, child) {
              return SwitchListTile(
                title: Row(
                  children: [
                    const Text("Módulo de Promociones", style: TextStyle(color: Colors.white)),
                    if (!permissions.canUsePromotionsModule)
                      _buildUpgradeChip(),
                  ],
                ),
                value: provider.profile.showPromotionsModule,
                onChanged: permissions.canUsePromotionsModule ? (newValue) {
                  provider.setModuleVisibility(
                    moduleKey: 'showPromotionsModule',
                    isVisible: newValue,
                  );
                } : null, 
              );
            },
          ),
          
          // Módulo de Gift Cards
          Consumer<CatalogEditorProvider>(
            builder: (context, provider, child) {
              return SwitchListTile(
                title: Row(
                  children: [
                    const Text("Módulo de Gift Cards", style: TextStyle(color: Colors.white)),
                    if (!permissions.canUseGiftCardModule)
                      _buildUpgradeChip(),
                  ],
                ),
                value: provider.profile.showGiftCardModule,
                onChanged: permissions.canUseGiftCardModule ? (newValue) {
                  provider.setModuleVisibility(
                    moduleKey: 'showGiftCardModule',
                    isVisible: newValue,
                  );
                } : null, 
              );
            },
          ),
          
          // Módulo de Reseñas
          Consumer<CatalogEditorProvider>(
            builder: (context, provider, child) {
              return SwitchListTile(
                title: const Text("Módulo de Reseñas", style: TextStyle(color: Colors.white)),
                value: provider.profile.showReviewsModule,
                onChanged: permissions.canUseReviewsModule ? (newValue) {
                  provider.setModuleVisibility(
                    moduleKey: 'showReviewsModule',
                    isVisible: newValue,
                  );
                } : null, 
              );
            },
          ),

          const SizedBox(height: 16),
          // Botón para cerrar
          Center(
            child: TextButton(
              child: const Text("Cerrar"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
           // Padding para la barra de navegación del sistema (gestos)
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  /// Un pequeño chip visual para indicar que se requiere un plan pago.
  Widget _buildUpgradeChip() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.shade700,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        "PLAN PAGO",
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}