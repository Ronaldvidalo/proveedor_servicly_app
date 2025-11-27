import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/providers/catalog_editor_provider.dart';
import 'package:proveedor_servicly_app/core/services/permissions_service.dart';

/// Un Modal BottomSheet que permite al proveedor
/// activar o desactivar la visibilidad de los módulos de su catálogo.
class ModuleSettingsSheet extends StatelessWidget {
  const ModuleSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final permissions = context.read<PermissionsService>();

    // QA FIX: Obtener tema del contexto
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      // QA FIX: Fondo dinámico (Coincide con el color de las tarjetas/modales)
      color: theme.cardTheme.color,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del BottomSheet
          Text(
            "Configurar Módulos",
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface, // Texto dinámico
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Selecciona qué módulos quieres mostrar en tu perfil público.",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 32, color: theme.dividerColor),

          // Módulo de Bienvenida
          Consumer<CatalogEditorProvider>(
            builder: (context, provider, child) {
              return SwitchListTile(
                title: Text("Módulo de Bienvenida", style: TextStyle(color: colorScheme.onSurface)),
                value: provider.profile.showWelcomeModule,
                activeColor: colorScheme.primary,
                onChanged: (newValue) {
                  provider.setModuleVisibility(
                    moduleKey: 'showWelcomeModule',
                    isVisible: newValue,
                  );
                },
              );
            },
          ),

          // Módulo de Agendar Cita
          Consumer<CatalogEditorProvider>(
            builder: (context, provider, child) {
              return SwitchListTile(
                title: Text("Módulo de Agendar Cita", style: TextStyle(color: colorScheme.onSurface)),
                value: provider.profile.showBookingModule,
                activeColor: colorScheme.primary,
                onChanged: (newValue) {
                  provider.setModuleVisibility(
                    moduleKey: 'showBookingModule',
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
                title: Text("Módulo de Portafolio", style: TextStyle(color: colorScheme.onSurface)),
                value: provider.profile.showPortfolioModule,
                activeColor: colorScheme.primary,
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
                    Text("Módulo de Promociones", style: TextStyle(color: colorScheme.onSurface)),
                    if (!permissions.canUsePromotionsModule)
                      _buildUpgradeChip(),
                  ],
                ),
                value: provider.profile.showPromotionsModule,
                activeColor: colorScheme.primary,
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
                    Text("Módulo de Gift Cards", style: TextStyle(color: colorScheme.onSurface)),
                    if (!permissions.canUseGiftCardModule)
                      _buildUpgradeChip(),
                  ],
                ),
                value: provider.profile.showGiftCardModule,
                activeColor: colorScheme.primary,
                onChanged: permissions.canUseGiftCardModule ? (newValue) {
                  provider.setModuleVisibility(
                    moduleKey: 'showGiftCardModule',
                    isVisible: newValue,
                  );
                } : null,
              );
            },
          ),

          // Módulo de Presupuestos
          Consumer<CatalogEditorProvider>(
            builder: (context, provider, child) {
              final canUse = permissions.canUseGiftCardModule; // Reutilizamos permiso por ahora
              return SwitchListTile(
                title: Row(
                  children: [
                    Text("Módulo de Presupuestos", style: TextStyle(color: colorScheme.onSurface)),
                    if (!canUse) _buildUpgradeChip(),
                  ],
                ),
                value: provider.profile.showQuotesModule,
                activeColor: colorScheme.primary,
                onChanged: canUse ? (newValue) {
                  provider.setModuleVisibility(
                    moduleKey: 'showQuotesModule',
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
                title: Text("Módulo de Reseñas", style: TextStyle(color: colorScheme.onSurface)),
                value: provider.profile.showReviewsModule,
                activeColor: colorScheme.primary,
                onChanged: (newValue) {
                  provider.setModuleVisibility(
                    moduleKey: 'showReviewsModule',
                    isVisible: newValue,
                  );
                },
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
          color: Colors.white, // Mantenemos blanco sobre ámbar oscuro para contraste
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}