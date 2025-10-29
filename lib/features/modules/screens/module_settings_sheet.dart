import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/providers/catalog_editor_provider.dart';
// ¡AÑADIDO! Importamos el servicio de permisos
import 'package:proveedor_servicly_app/core/services/permissions_service.dart';

/// Un Modal BottomSheet que permite al proveedor
/// activar o desactivar la visibilidad de los módulos de su catálogo.
class ModuleSettingsSheet extends StatelessWidget {
  const ModuleSettingsSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Leemos el servicio de permisos del contexto.
    // Esto asume que PermissionsService está proveído en tu MultiProvider
    // tal como me mostraste (como un ProxyProvider).
    final permissions = context.read<PermissionsService>();

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del BottomSheet
          Text(
            "Configurar Módulos",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            "Selecciona qué módulos quieres mostrar en tu perfil público.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Divider(height: 32),

          // --- Lista de Módulos ---
          // Usamos 'Consumer' para que cada switch se reconstruya
          // cuando su valor cambie en el 'CatalogEditorProvider'.

          // Módulo de Bienvenida
          Consumer<CatalogEditorProvider>(
            builder: (context, provider, child) {
              return SwitchListTile(
                title: const Text("Módulo de Bienvenida"),
                // ¡CORREGIDO! Usamos el campo 'showWelcomeModule'
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
                title: const Text("Módulo de Portafolio"),
                // ¡CORREGIDO! Usamos 'showPortfolioModule'
                value: provider.profile.showPortfolioModule,
                // Lógica de Permisos: Se basa en 'canUsePortfolioModule'
                onChanged: permissions.canUsePortfolioModule ? (newValue) {
                  provider.setModuleVisibility(
                    moduleKey: 'showPortfolioModule',
                    isVisible: newValue,
                  );
                } : null, // Deshabilitado si no tiene permiso
              );
            },
          ),
          
          // Módulo de Promociones
          Consumer<CatalogEditorProvider>(
            builder: (context, provider, child) {
              return SwitchListTile(
                title: Row(
                  children: [
                    const Text("Módulo de Promociones"),
                    if (!permissions.canUsePromotionsModule)
                      _buildUpgradeChip(),
                  ],
                ),
                // ¡CORREGIDO! Usamos 'showPromotionsModule'
                value: provider.profile.showPromotionsModule,
                // Lógica de Permisos:
                onChanged: permissions.canUsePromotionsModule ? (newValue) {
                  provider.setModuleVisibility(
                    moduleKey: 'showPromotionsModule',
                    isVisible: newValue,
                  );
                } : null, // Deshabilitado
              );
            },
          ),
          
          // Módulo de Gift Cards
          Consumer<CatalogEditorProvider>(
            builder: (context, provider, child) {
              return SwitchListTile(
                title: Row(
                  children: [
                    const Text("Módulo de Gift Cards"),
                    if (!permissions.canUseGiftCardModule)
                      _buildUpgradeChip(),
                  ],
                ),
                // ¡CORREGIDO! Usamos 'showGiftCardModule'
                value: provider.profile.showGiftCardModule,
                // Lógica de Permisos:
                onChanged: permissions.canUseGiftCardModule ? (newValue) {
                  provider.setModuleVisibility(
                    moduleKey: 'showGiftCardModule',
                    isVisible: newValue,
                  );
                } : null, // Deshabilitado
              );
            },
          ),
          
          // Módulo de Reseñas
          Consumer<CatalogEditorProvider>(
            builder: (context, provider, child) {
              return SwitchListTile(
                title: const Text("Módulo de Reseñas"),
                // ¡CORREGIDO! Usamos 'showReviewsModule'
                value: provider.profile.showReviewsModule,
                // Lógica de Permisos:
                onChanged: permissions.canUseReviewsModule ? (newValue) {
                  provider.setModuleVisibility(
                    moduleKey: 'showReviewsModule',
                    isVisible: newValue,
                  );
                } : null, // Deshabilitado
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