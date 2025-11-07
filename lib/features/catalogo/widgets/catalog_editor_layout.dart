import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io'; // Para File
import 'package:image_picker/image_picker.dart'; // Para XFile

// Modelos y Servicios
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/core/models/portfolio_category_model.dart';
import 'package:proveedor_servicly_app/core/models/portfolio_item_model.dart';
import 'package:proveedor_servicly_app/core/services/permissions_service.dart';
import 'package:proveedor_servicly_app/providers/catalog_editor_provider.dart';

// Widgets Auxiliares
import 'package:proveedor_servicly_app/features/catalogo/modules/_portfolio_item_card.dart';
import 'package:proveedor_servicly_app/features/catalogo/modules/module_settings_sheet.dart';

import 'package:video_player/video_player.dart';


/// Layout "Editor Visual" de un proveedor.
/// Es una copia de CatalogLayout adaptada para la edición en contexto (WYSIWYG).
class CatalogEditorLayout extends StatefulWidget {
  final String userId;

  const CatalogEditorLayout({
    super.key,
    required this.userId,
  });

  @override
  State<CatalogEditorLayout> createState() => _CatalogEditorLayoutState();
}

class _CatalogEditorLayoutState extends State<CatalogEditorLayout> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CatalogEditorProvider>().loadInitialCategories(widget.userId);
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    // --- ¡CAMBIO CLAVE! ---
    // Usamos context.watch para que el layout se reconstruya
    // cuando el provider notifique cambios (ej. activar/desactivar módulos).
    final provider = context.watch<CatalogEditorProvider>();
    final profile = provider.profile;
    
    // Determinar visibilidad de módulos
    final showWelcome = profile.showWelcomeModule;
    final showPortfolio = profile.showPortfolioModule;
    final showReviews = profile.showReviewsModule;
    final showPromotions = profile.showPromotionsModule;
    final showGiftCards = profile.showGiftCardModule;
    final showBooking = profile.showBookingModule;
    final showQuotes = profile.showQuotesModule;

    // --- ¡AHORA ESTO ES UN SCAFFOLD! ---
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Fondo oscuro
      
      // El CustomScrollView va en el body
      body: CustomScrollView(
        slivers: [
          // MÓDULO 1: Cabecera (SliverAppBar)
          _buildSliverHeader(context, provider, profile),

          // MÓDULO 1.5: CTA Principal
          if (showBooking)
            _buildPrimaryCtaModule(context, profile),

          // MÓDULO 2: Información y Contacto
          _buildInfoModule(context, provider, profile, showWelcome),

          // MÓDULO Promociones
          _buildPromotionsModule(context, provider, profile, showPromotions),

          // MÓDULO Portafolio
          if (showPortfolio) _buildPortfolioModule(context, provider, profile),

          // MÓDULO Gift Cards
          _buildGiftCardModule(context, provider, profile, showGiftCards),

          // MÓDULO Presupuestos
          _buildQuotesModule(context, provider, profile, showQuotes),

          // MÓDULO Reseñas
          if (showReviews)
            _buildReviewsModule(context, profile),

          const SliverToBoxAdapter(child: SizedBox(height: 80)), // Espacio para FAB
        ],
      ),

      // El FAB ahora vive en este Scaffold
      floatingActionButton: FloatingActionButton(
        tooltip: "Configurar módulos",
        onPressed: () {
          // --- ¡CORRECCIÓN! ---
          // Llamamos a _showModuleSettings, que está definido aquí abajo.
          _showModuleSettings(context);
        },
        child: const Icon(Icons.layers_outlined),
      ),
    );
  }

  // --- MÓDULO 1: Cabecera (AHORA ES UNA SLIVERAPPBAR) ---
  Widget _buildSliverHeader(BuildContext context, CatalogEditorProvider provider, ProviderProfileModel profile) {
    final brandColor = profile.brandColor;
    final isUploadingLogo = provider.isUploadingLogo;
    final isDirty = provider.isDirty; 
    final isSaving = provider.isSaving; 

    return SliverAppBar(
      expandedHeight: 280.0,
      pinned: true,
      backgroundColor: const Color(0xFF1A1A2E), 
      foregroundColor: Colors.white, // Flecha de "atrás"
      
      // Botón de Guardar
      actions: [
        if (isSaving)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
          )
        else
          TextButton(
            onPressed: isDirty
                ? () async {
                    // Usamos context.read porque estamos en un callback
                    final provider = context.read<CatalogEditorProvider>();
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final success = await provider.saveChangesToFirestore(providerId: widget.userId);
                    
                    if (!mounted) return;
                    if (success) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Cambios guardados con éxito!'), backgroundColor: Colors.green),
                      );
                    } else {
                       scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Error al guardar los cambios.'), backgroundColor: Colors.red),
                      );
                    }
                  }
                : null,
            child: Text(
              "Guardar",
              style: TextStyle(
                color: isDirty ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
      ],

      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 72, bottom: 16, end: 150), 
        title: Text(
          profile.businessName, // Título dinámico
          style: TextStyle(
            color: ThemeData.estimateBrightnessForColor(brandColor) == Brightness.dark
                ? Colors.white
                : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16, 
            shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        centerTitle: false, 
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen de fondo (logo/banner)
            if (profile.logoUrl.isNotEmpty)
              Image.network(
                profile.logoUrl,
                fit: BoxFit.cover,
                key: ValueKey(profile.logoUrl), 
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(color: brandColor.withAlpha((255 * 0.5).round()));
                },
                errorBuilder: (_, __, ___) => Container(color: brandColor),
              )
            else
              Container(color: brandColor),

            // Filtro de desenfoque y gradiente oscuro
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha((255 * 0.3).round()),
                      Colors.black.withAlpha((255 * 0.7).round()),
                    ],
                    stops: const [0.0, 0.8],
                  ),
                ),
              ),
            ),
            
            // Botón de Edición de Portada
            Positioned(
              top: 40, // Ajustado para no chocar con la flecha de 'atrás'
              right: 16,
              child: isUploadingLogo
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                  )
                : IconButton(
                    icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 28),
                    tooltip: "Cambiar foto de portada/logo",
                    onPressed: () {
                      context.read<CatalogEditorProvider>().updateLogoImage(widget.userId);
                    },
                  ),
            ),

            // Eslogan opcional
            if (profile.slogan != null && profile.slogan!.isNotEmpty)
              Positioned(
                bottom: 60, 
                left: 16,
                right: 16,
                child: Text(
                  profile.slogan!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withAlpha((255 * 0.9).round()),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    shadows: const [Shadow(color: Colors.black87, blurRadius: 6)],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- MÓDULO 1.5: CTA Principal (Sin cambios) ---
  Widget _buildPrimaryCtaModule(BuildContext context, ProviderProfileModel profile) {
    final String ratingText = profile.averageRating != null ? profile.averageRating!.toStringAsFixed(1) : '-.-';
    final String reviewCountText = profile.reviewCount != null && profile.reviewCount! > 0 ? '(${profile.reviewCount} Reseñas)' : '(Sin Reseñas)';

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.yellow[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  "$ratingText $reviewCountText",
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: profile.brandColor,
                  foregroundColor: ThemeData.estimateBrightnessForColor(profile.brandColor) == Brightness.dark ? Colors.white : Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: null, // Botón deshabilitado en modo edición
                child: const Text('Agendar Cita Ahora'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MÓDULO 2: Información y Contacto (MODIFICADO PARA EDICIÓN) ---
  Widget _buildInfoModule(BuildContext context, CatalogEditorProvider provider, ProviderProfileModel profile, bool showWelcome) {
    return SliverToBoxAdapter(
      child: Stack( 
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Información',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 16),
                
                if (showWelcome) ...[
                  _buildWelcomeContent(context, profile), 
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 24),
                ],

                if (profile.openingHours != null && profile.openingHours!.isNotEmpty) ...[
                  _InfoRow(icon: Icons.access_time_outlined, text: profile.openingHours!),
                  const SizedBox(height: 12),
                ],
                if (profile.address != null && profile.address!.isNotEmpty) ...[
                  _InfoRow(icon: Icons.location_on_outlined, text: profile.address!),
                  const SizedBox(height: 24),
                ],

                // Botones de Contacto (Vista deshabilitada)
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (profile.phone != null && profile.phone!.isNotEmpty) ...[
                      IconButton.filled(onPressed: null, icon: const Icon(Icons.phone_outlined), style: IconButton.styleFrom(backgroundColor: const Color(0xFF2D2D5A), foregroundColor: Colors.white)),
                      const SizedBox(width: 16),
                    ],
                    if (profile.whatsapp != null && profile.whatsapp!.isNotEmpty) ...[
                      IconButton.filled(onPressed: null, icon: const Icon(Icons.chat_bubble_outline), style: IconButton.styleFrom(backgroundColor: const Color(0xFF2D2D5A), foregroundColor: Colors.white)),
                      const SizedBox(width: 16),
                    ],
                    if (profile.contactEmail.isNotEmpty) ...[
                      IconButton.filled(onPressed: null, icon: const Icon(Icons.email_outlined), style: IconButton.styleFrom(backgroundColor: const Color(0xFF2D2D5A), foregroundColor: Colors.white)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: Icon(Icons.edit, color: Colors.blue.shade400, size: 24),
              tooltip: "Editar Información y Contacto",
              onPressed: () => _showEditContactDialog(context, provider), // Pasamos el provider
            ),
          )
        ],
      ),
    );
  }

  /// Widget interno para mostrar el contenido del bienvenida (sin cambios)
  Widget _buildWelcomeContent(BuildContext context, ProviderProfileModel profile) {
    if (profile.welcomeModuleType == 'text') {
       if (profile.welcomeMessage.isEmpty) return const SizedBox(height: 10); 
      return Text(
        profile.welcomeMessage,
        style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
      );
    }
    if (profile.welcomeModuleType == 'video' && profile.welcomeVideoUrl != null && profile.welcomeVideoUrl!.isNotEmpty) {
      bool isUploadedVideo = profile.welcomeVideoSourceType == 'upload';
      if (isUploadedVideo) {
        return _WelcomeVideoPlayer(videoUrl: profile.welcomeVideoUrl!);
      } else {
        return AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('Video externo (YouTube, etc.)\n${profile.welcomeVideoUrl}', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54))),
          ),
        );
      }
    }
    return const SizedBox(height: 10);
  }


  // --- MÓDULO Portafolio (MODIFICADO PARA EDICIÓN) ---
  Widget _buildPortfolioModule(BuildContext context, CatalogEditorProvider provider, ProviderProfileModel profile) {
    final firestoreService = context.read<FirestoreService>();
    final permissions = context.read<PermissionsService>();
    
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0), 
          child: Row( 
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Portafolio',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                tooltip: "Añadir NUEVA categoría",
                onPressed: permissions.canAddPortfolioCategory(provider.localCategories.length)
                  ? () => _showAddCategoryDialog(context, provider, widget.userId)
                  : null, 
              ),
            ],
          ),
        ),

        // --- Selector de Categorías (MODIFICADO) ---
        provider.isLoadingCategories
          ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2)))
          : provider.localCategories.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                  child: Center(child: Text("Aún no tienes categorías. ¡Añade una!", style: TextStyle(color: Colors.white54))),
                )
              : SizedBox(
                  height: 60,
                  child: ReorderableListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: provider.localCategories.length,
                    itemBuilder: (context, index) {
                      final category = provider.localCategories[index];
                      final isSelected = provider.selectedCategoryId == category.id;
                      return Stack(
                        key: ValueKey(category.id),
                        clipBehavior: Clip.none, 
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0, top: 4, left: 4),
                            child: RawChip(
                              label: Text(category.name),
                              labelStyle: TextStyle(color: isSelected ? (ThemeData.estimateBrightnessForColor(profile.brandColor) == Brightness.dark ? Colors.white : Colors.black) : Colors.white),
                              selected: isSelected,
                              onSelected: (_) => provider.selectCategory(category.id),
                              selectedColor: profile.brandColor,
                              backgroundColor: const Color(0xFF2D2D5A),
                              shape: StadiumBorder(side: BorderSide(color: isSelected ? profile.brandColor : Colors.white38)),
                              pressElevation: 6.0,
                            ),
                          ),
                          Positioned(
                            top: -10,
                            right: 0,
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () => _showEditCategoryDialog(context, provider, widget.userId, category),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                    child: Icon(Icons.edit, size: 14, color: Colors.blue.shade700),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => _showDeleteCategoryDialog(context, provider, widget.userId, category),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                    child: Icon(Icons.delete_forever, size: 14, color: Colors.red.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                    onReorder: (oldIndex, newIndex) {
                      provider.reorderPortfolioCategories(widget.userId, oldIndex, newIndex);
                    },
                  ),
                ),

        // --- Cuadrícula de Ítems (MODIFICADO) ---
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (provider.selectedCategoryId != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text("Añadir Foto"),
                      onPressed: provider.isUploadingItem ? null : () async {
                        final buildContext = context; 
                        final file = await provider.pickPortfolioItem(PortfolioItemType.image);
                        if (file != null && buildContext.mounted) {
                          _showAddCaptionDialog(buildContext, provider, widget.userId, file, PortfolioItemType.image);
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      icon: const Icon(Icons.video_call_outlined),
                      label: const Text("Añadir Video"),
                      onPressed: provider.isUploadingItem ? null : () async {
                        final buildContext = context; 
                        final file = await provider.pickPortfolioItem(PortfolioItemType.video);
                        if (file != null && buildContext.mounted) {
                          _showAddCaptionDialog(buildContext, provider, widget.userId, file, PortfolioItemType.video);
                        }
                      },
                    ),
                  ],
                ),
              if (provider.selectedCategoryId != null)
                const SizedBox(height: 16),
              
              provider.selectedCategoryId == null
                ? const Center(child: Text("Selecciona o crea una categoría.", style: TextStyle(color: Colors.white54)))
                : StreamBuilder<List<PortfolioItemModel>>(
                    stream: firestoreService.getCatalogPortfolioItemsStream(widget.userId, provider.selectedCategoryId!), 
                    builder: (context, itemSnapshot) {
                      if (itemSnapshot.connectionState == ConnectionState.waiting && !provider.isUploadingItem) {
                        return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator(color: Colors.white54)));
                      }
                      if (itemSnapshot.hasError) {
                        return Text('Error: ${itemSnapshot.error}', style: const TextStyle(color: Colors.redAccent));
                      }
                      
                      final items = itemSnapshot.data ?? [];
                      final screenWidth = MediaQuery.of(context).size.width;
                      final crossAxisCount = (screenWidth / 150).floor().clamp(2, 4);

                      if (items.isEmpty && !provider.isUploadingItem) {
                         return const Padding(
                           padding: EdgeInsets.symmetric(vertical: 48.0),
                           child: Center(child: Text('Añade fotos o videos a esta categoría.', style: TextStyle(color: Colors.white54, fontSize: 16))),
                         );
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: items.length + (provider.isUploadingItem ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (provider.isUploadingItem && index == items.length) {
                            return _buildUploadingPlaceholder(provider.uploadProgress);
                          }
                          final item = items[index];
                          return PortfolioItemCard( 
                            item: item, 
                            isEditable: true, 
                            onDelete: () => _showDeleteItemDialog(context, provider, widget.userId, item)
                          );
                        },
                      );
                    },
                  ),
            ],
          ),
        ),
      ]),
    );
  }

  
  // --- MÓDULOS Placeholder (ACTUALIZADOS) ---

  Widget _buildActivationPlaceholder({
    required String title,
    required String description,
    required bool hasPermission,
    required String moduleKey,
  }) {
    final provider = context.read<CatalogEditorProvider>();
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D5A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.shade700, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (hasPermission)
            ElevatedButton(
              onPressed: () {
                provider.setModuleVisibility(moduleKey: moduleKey, isVisible: true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Activar"),
            )
          else
            ElevatedButton(
              onPressed: () { /* TODO: Navegar a la pantalla de "Mejorar Plan" */ },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700),
              child: const Text("Mejorar Plan"),
            ),
        ],
      ),
    );
  }

  Widget _buildPromotionsModule(BuildContext context, CatalogEditorProvider provider, ProviderProfileModel profile, bool showPromotions) {
    final permissions = context.read<PermissionsService>();
    
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Promociones',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 16),
            
            if (showPromotions)
              Container(
                height: 120, 
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D5A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade700) 
                ),
                child: Stack( 
                  children: [
                    const Center(
                      child: Text('Módulo de Promociones ACTIVO (Próximamente)', style: TextStyle(color: Colors.white70)),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue.shade400, size: 24),
                        tooltip: "Gestionar Promociones",
                        onPressed: () { /* TODO: Abrir diálogo/pantalla de gestión de promos */ },
                      ),
                    )
                  ],
                ),
              )
            else
              _buildActivationPlaceholder(
                title: "Módulo de Promociones",
                description: "Atrae más clientes ofreciendo descuentos y ofertas especiales.",
                hasPermission: permissions.canUsePromotionsModule,
                moduleKey: 'showPromotionsModule',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftCardModule(BuildContext context, CatalogEditorProvider provider, ProviderProfileModel profile, bool showGiftCards) {
    final permissions = context.read<PermissionsService>();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tarjetas de Regalo',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 16),

            if (showGiftCards)
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D5A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade700)
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Text('Módulo de Gift Cards ACTIVO (Próximamente)', style: TextStyle(color: Colors.white70)),
                    ),
                     Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue.shade400, size: 24),
                        tooltip: "Gestionar Gift Cards",
                        onPressed: () { /* TODO: Abrir diálogo/pantalla de gestión de gift cards */ },
                      ),
                    )
                  ],
                ),
              )
            else
              _buildActivationPlaceholder(
                title: "Tarjetas de Regalo",
                description: "Permite que tus clientes regalen tus servicios a otros.",
                hasPermission: permissions.canUseGiftCardModule,
                moduleKey: 'showGiftCardModule',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotesModule(BuildContext context, CatalogEditorProvider provider, ProviderProfileModel profile, bool showQuotes) {
    final permissions = context.read<PermissionsService>();
    final hasPermission = permissions.canUseGiftCardModule; // Reusamos permiso de GiftCard

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Presupuestos',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 16),

            if (showQuotes)
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D5A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade700)
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Text('Módulo de Presupuestos ACTIVO (Próximamente)', style: TextStyle(color: Colors.white70)),
                    ),
                     Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue.shade400, size: 24),
                        tooltip: "Gestionar Presupuestos",
                        onPressed: () { /* TODO: Abrir diálogo/pantalla de gestión de presupuestos */ },
                      ),
                    )
                  ],
                ),
              )
            else
              _buildActivationPlaceholder(
                title: "Gestor de Presupuestos",
                description: "Crea y envía presupuestos formales a tus clientes.",
                hasPermission: hasPermission,
                moduleKey: 'showQuotesModule',
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReviewsModule(BuildContext context, ProviderProfileModel profile) {
    return SliverToBoxAdapter( child: Padding( padding: const EdgeInsets.fromLTRB(16, 24, 16, 16), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [ Text( 'Reseñas', style: Theme.of(context).textTheme.headlineSmall?.copyWith( fontWeight: FontWeight.bold, color: Colors.white, ), ), if (profile.reviewCount != null && profile.reviewCount! > 0) TextButton( onPressed: null, style: TextButton.styleFrom(foregroundColor: profile.brandColor), /* Deshabilitado en editor */ child: Text('Ver todas (${profile.reviewCount})'), ), ], ), const SizedBox(height: 16), Container( height: 150, decoration: BoxDecoration( color: const Color(0xFF2D2D5A), borderRadius: BorderRadius.circular(12), ), child: const Center( child: Text('Reseñas Destacadas (Próximamente)', style: TextStyle(color: Colors.white70)), ), ) ], ), ), );
  }

  // --- DIÁLOGOS HELPER ---
  
  void _showEditContactDialog(BuildContext context, CatalogEditorProvider provider) {
    // Usamos el 'provider' que recibimos como argumento
    final profile = provider.profile;
    final businessNameController = TextEditingController(text: profile.businessName);
    final sloganController = TextEditingController(text: profile.slogan);
    final hoursController = TextEditingController(text: profile.openingHours);
    final emailController = TextEditingController(text: profile.contactEmail);
    final phoneController = TextEditingController(text: profile.phone);
    final whatsappController = TextEditingController(text: profile.whatsapp);
    final welcomeController = TextEditingController(text: profile.welcomeMessage);
    // final addressController = TextEditingController(text: profile.address);

    showDialog(
      context: context, // Usamos el context del build
      builder: (ctx) => AlertDialog( // ctx es el context del diálogo
        title: const Text("Editar Información y Contacto"),
        content: SingleChildScrollView( 
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: businessNameController, decoration: const InputDecoration(labelText: "Nombre del Negocio", border: OutlineInputBorder()), textCapitalization: TextCapitalization.words),
              const SizedBox(height: 12),
              TextFormField(controller: welcomeController, decoration: const InputDecoration(labelText: "Mensaje de Bienvenida", border: OutlineInputBorder()), maxLines: 3, textCapitalization: TextCapitalization.sentences),
              const SizedBox(height: 12),
              TextFormField(controller: sloganController, decoration: const InputDecoration(labelText: "Slogan", border: OutlineInputBorder()), textCapitalization: TextCapitalization.sentences),
              const SizedBox(height: 12),
              TextFormField(controller: hoursController, decoration: const InputDecoration(labelText: "Horario", border: OutlineInputBorder()), maxLines: 2),
              const SizedBox(height: 12),
              // TextFormField(controller: addressController, decoration: const InputDecoration(labelText: "Dirección", border: OutlineInputBorder())),
              // const SizedBox(height: 12),
              TextFormField(controller: emailController, decoration: const InputDecoration(labelText: "Email de Contacto", border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              TextFormField(controller: phoneController, decoration: const InputDecoration(labelText: "Teléfono", border: OutlineInputBorder()), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TextFormField(controller: whatsappController, decoration: const InputDecoration(labelText: "WhatsApp", hintText: "Ej: 54911...", border: OutlineInputBorder()), keyboardType: TextInputType.phone),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text("Aplicar Cambios"),
            onPressed: () {
              // ¡CORRECCIÓN! Usamos el 'provider' (pasado como argumento)
              // O podemos usar context.read aquí, que también funciona.
              // final provider = context.read<CatalogEditorProvider>(); // Alternativa
              provider.updateBusinessName(businessNameController.text.trim());
              provider.updateWelcomeText(welcomeController.text.trim());
              provider.updateSlogan(sloganController.text.trim().isEmpty ? null : sloganController.text.trim());
              provider.updateOpeningHours(hoursController.text.trim().isEmpty ? null : hoursController.text.trim());
              provider.updateContactEmail(emailController.text.trim());
              provider.updatePhone(phoneController.text.trim().isEmpty ? null : phoneController.text.trim());
              provider.updateWhatsapp(whatsappController.text.trim().isEmpty ? null : whatsappController.text.trim());
              
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showAddCaptionDialog(BuildContext context, CatalogEditorProvider provider, String userId, XFile file, PortfolioItemType type) {
    final captionController = TextEditingController();
    
    showDialog(
      context: context, // Usamos el context del build
      barrierDismissible: false,
      builder: (ctx) { // ctx es el context del diálogo
         // --- ¡CORRECCIÓN! ---
         // Envolvemos el AlertDialog en un ChangeNotifierProvider.value
         // para pasar el provider al árbol del diálogo
         return ChangeNotifierProvider.value(
           value: provider, 
           child: Consumer<CatalogEditorProvider>( // Ahora el Consumer usará el provider
             builder: (consumerContext, provider, child) { 
               return AlertDialog(
                  title: Text(type == PortfolioItemType.image ? "Añadir Foto" : "Añadir Video"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 150,
                        width: 150,
                        child: type == PortfolioItemType.image
                            ? Image.file(File(file.path), fit: BoxFit.cover)
                            : Container(color: Colors.black, child: const Center(child: Icon(Icons.videocam, color: Colors.white, size: 50))),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: captionController,
                        decoration: const InputDecoration(
                          labelText: "Título (Opcional)",
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: provider.isUploadingItem ? null : () => Navigator.of(ctx).pop(), 
                      child: const Text("Cancelar")
                    ),
                    ElevatedButton(
                      onPressed: provider.isUploadingItem 
                        ? null 
                        : () async {
                            final navigator = Navigator.of(ctx); 
                            final caption = captionController.text.trim();
                            
                            // Usamos el provider del Consumer
                            await provider.uploadAndSavePortfolioItem(
                              userId, 
                              file, 
                              caption.isEmpty ? null : caption, 
                              type
                            );
                            
                            if (!mounted) return;
                            navigator.pop(); 
                          },
                       child: provider.isUploadingItem 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                          : const Text("Guardar y Subir"),
                    ),
                  ],
                );
             },
           ),
         );
      }
    );
  }

  // --- El resto de diálogos helper ---
  // (Usamos context.read en los callbacks onPressed)

  void _showAddCategoryDialog(BuildContext context, CatalogEditorProvider provider, String userId) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context, // Context bueno
      builder: (ctx) => AlertDialog( // ctx
        title: const Text("Nueva Categoría"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "Nombre de la categoría"),
            autofocus: true,
            validator: (value) => (value == null || value.trim().isEmpty) ? 'El nombre es requerido' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                 final scaffoldMessenger = ScaffoldMessenger.of(ctx); 
                 final navigator = Navigator.of(ctx); 
                 // Leemos el provider del context original (el bueno)
                 final success = await context.read<CatalogEditorProvider>().addPortfolioCategory(userId, nameController.text.trim());
                 if (!mounted) return; 
                if (success) { 
                  navigator.pop(); 
                } else {
                    if (!navigator.mounted) return; 
                    scaffoldMessenger.showSnackBar( 
                       const SnackBar(content: Text('Error al añadir categoría o límite alcanzado.'), backgroundColor: Colors.orange)
                    );
                }
              }
            },
            child: const Text("Añadir"),
          ),
        ],
      ),
    );
  }
  
  void _showEditCategoryDialog(BuildContext context, CatalogEditorProvider provider, String userId, PortfolioCategoryModel category) {
     final nameController = TextEditingController(text: category.name);
     final formKey = GlobalKey<FormState>();

      showDialog(
        context: context, // Context bueno
        builder: (ctx) => AlertDialog( // ctx
          title: const Text("Editar Categoría"),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nuevo nombre"),
              autofocus: true,
              validator: (value) => (value == null || value.trim().isEmpty) ? 'El nombre es requerido' : null,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () async {
                 if (formKey.currentState?.validate() ?? false) {
                   final navigator = Navigator.of(ctx); 
                   await context.read<CatalogEditorProvider>().updatePortfolioCategoryName(userId, category.id, nameController.text.trim());
                    if (!mounted) return; 
                    navigator.pop(); 
                 }
              },
              child: const Text("Guardar"),
            ),
          ],
        ),
      );
  }
  
   void _showDeleteCategoryDialog(BuildContext context, CatalogEditorProvider provider, String userId, PortfolioCategoryModel category) {
      showDialog(
        context: context, // Context bueno
        builder: (ctx) => AlertDialog( // ctx
          title: const Text("Eliminar Categoría"),
          content: Text("¿Seguro que quieres eliminar la categoría '${category.name}'?\n\n¡Esto también eliminará permanentemente todas las fotos y videos dentro de ella!"),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancelar")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                  final navigator = Navigator.of(ctx); 
                  await context.read<CatalogEditorProvider>().deletePortfolioCategory(userId, category.id);
                   if (!mounted) return; 
                   navigator.pop(); 
              },
              child: const Text("Eliminar Todo"),
            ),
          ],
        ),
      );
  }
  
  void _showDeleteItemDialog(BuildContext context, CatalogEditorProvider provider, String userId, PortfolioItemModel item) {
      showDialog(
        context: context, // Context bueno
        builder: (ctx) => AlertDialog( // ctx
          title: const Text("Eliminar Ítem"),
          content: const Text("¿Seguro que quieres eliminar este ítem del portafolio?\nLa acción no se puede deshacer."),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancelar")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                  final navigator = Navigator.of(ctx); 
                  await context.read<CatalogEditorProvider>().deletePortfolioItem(userId, item);
                   if (!mounted) return; 
                   navigator.pop();
              },
              child: const Text("Eliminar"),
            ),
          ],
        ),
      );
  }

  /// Placeholder visual mientras se sube un ítem.
  Widget _buildUploadingPlaceholder(double progress) {
    return Card(
      color: Colors.grey.shade300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             CircularProgressIndicator(value: progress > 0 ? progress : null, strokeWidth: 2),
             const SizedBox(height: 8),
             Text("Subiendo...", style: TextStyle(fontSize: 10, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }
  
  // --- ¡MÉTODO AÑADIDO! ---
  // Este método ahora vive aquí, ya que el FAB está en el Scaffold de este layout
  void _showModuleSettings(BuildContext context) {
    showModalBottomSheet(
      context: context, // Usa el context del build
      isScrollControlled: true,
      backgroundColor: Colors.grey[850], 
      shape: const RoundedRectangleBorder(
         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        // Usamos ChangeNotifierProvider.value para pasar el provider
        // que YA ESTÁ en el context de este widget.
        return ChangeNotifierProvider.value(
          value: context.read<CatalogEditorProvider>(),
          child: const ModuleSettingsSheet(),
        );
      },
    );
  }

} // Fin _CatalogEditorLayoutState

// --- WIDGETS AUXILIARES DE CATALOG_LAYOUT (COPIADOS) ---

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
   return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Icon(icon, color: Colors.white70, size: 20),
         const SizedBox(width: 16),
         Expanded(
           child: Text(
             text,
             style: const TextStyle(color: Colors.white, fontSize: 16),
           ),
         ),
       ],
       ),
   );
  }
}

class _WelcomeVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const _WelcomeVideoPlayer({required this.videoUrl});

  @override
  State<_WelcomeVideoPlayer> createState() => _WelcomeVideoPlayerState();
}

class _WelcomeVideoPlayerState extends State<_WelcomeVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _showControls = false;

  @override
  void initState() {
    super.initState();
    final videoUri = Uri.tryParse(widget.videoUrl);
    if (videoUri != null) {
      _controller = VideoPlayerController.networkUrl(videoUri)
        ..initialize().then((_) { if (mounted) setState(() {}); }).catchError((e) { debugPrint("Error init welcome video: $e"); })
        ..setLooping(true);
      _controller.addListener(() { if (mounted && _isPlaying != _controller.value.isPlaying) { setState(() { _isPlaying = _controller.value.isPlaying; }); }});
    } else {
       _controller = VideoPlayerController.networkUrl(Uri.parse('invalid-url'));
       debugPrint("Invalid welcome video URL: ${widget.videoUrl}");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() { setState(() { if (_controller.value.isPlaying) { _controller.pause(); } else { _controller.play(); } }); }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container( decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)), child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54))),
      );
    }
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: MouseRegion(
          onHover: (_) => setState(() => _showControls = true),
          onExit: (_) => setState(() => _showControls = false),
          child: GestureDetector(
            onTap: () => setState(() => _showControls = !_showControls),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                VideoPlayer(_controller),
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    decoration: BoxDecoration( color: Colors.black.withAlpha((255 * 0.4).round()), borderRadius: BorderRadius.circular(8)),
                    child: Center(
                      child: IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: Colors.white,
                          size: 60.0,
                        ),
                        onPressed: _togglePlayPause,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }
}