import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io'; 
import 'package:image_picker/image_picker.dart'; 

// Modelos y Servicios
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/core/models/portfolio_category_model.dart';
import 'package:proveedor_servicly_app/core/models/portfolio_item_model.dart';
import 'package:proveedor_servicly_app/core/services/permissions_service.dart';
import 'package:proveedor_servicly_app/providers/catalog_editor_provider.dart';

// Widgets Auxiliares
// QA FIX: Ruta corregida o asumida correcta
import 'package:proveedor_servicly_app/features/catalogo/modules/_portfolio_item_card.dart'; 

import 'package:proveedor_servicly_app/features/catalogo/modules/module_settings_sheet.dart';

import 'package:video_player/video_player.dart';


/// Layout "Editor Visual" de un proveedor.
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
    final provider = context.watch<CatalogEditorProvider>();
    final profile = provider.profile;
    
    // QA FIX: Obtener tema
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final showWelcome = profile.showWelcomeModule;
    final showPortfolio = profile.showPortfolioModule;
    final showReviews = profile.showReviewsModule;
    final showPromotions = profile.showPromotionsModule;
    final showGiftCards = profile.showGiftCardModule;
    final showBooking = profile.showBookingModule;
    final showQuotes = profile.showQuotesModule;

    return Scaffold(
      // QA FIX: Fondo dinámico
      backgroundColor: theme.scaffoldBackgroundColor,
      
      body: CustomScrollView(
        slivers: [
          // MÓDULO 1: Cabecera
          _buildSliverHeader(context, provider, profile, theme),

          // MÓDULO 1.5: CTA Principal
          if (showBooking)
            _buildPrimaryCtaModule(context, profile, theme),

          // MÓDULO 2: Información y Contacto
          _buildInfoModule(context, provider, profile, showWelcome, theme),

          // MÓDULO Promociones
          _buildPromotionsModule(context, provider, profile, showPromotions, theme),

          // MÓDULO Portafolio
          if (showPortfolio) _buildPortfolioModule(context, provider, profile, theme),

          // MÓDULO Gift Cards
          _buildGiftCardModule(context, provider, profile, showGiftCards, theme),

          // MÓDULO Presupuestos
          _buildQuotesModule(context, provider, profile, showQuotes, theme),

          // MÓDULO Reseñas
          if (showReviews)
            _buildReviewsModule(context, profile, theme),

          const SliverToBoxAdapter(child: SizedBox(height: 80)), 
        ],
      ),

      floatingActionButton: FloatingActionButton(
        tooltip: "Configurar módulos",
        backgroundColor: colorScheme.primary,
        onPressed: () {
          _showModuleSettings(context);
        },
        child: Icon(Icons.layers_outlined, color: colorScheme.onPrimary),
      ),
    );
  }

  // --- MÓDULO 1: Cabecera ---
  Widget _buildSliverHeader(BuildContext context, CatalogEditorProvider provider, ProviderProfileModel profile, ThemeData theme) {
    final brandColor = profile.brandColor;
    final isUploadingLogo = provider.isUploadingLogo;
    final isDirty = provider.isDirty; 
    final isSaving = provider.isSaving; 
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      expandedHeight: 280.0,
      pinned: true,
      // QA FIX: Fondo AppBar dinámico
      backgroundColor: theme.scaffoldBackgroundColor, 
      foregroundColor: colorScheme.onSurface, 
      
      actions: [
        if (isSaving)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: colorScheme.primary, strokeWidth: 3)),
          )
        else
          TextButton(
            onPressed: isDirty
                ? () async {
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
                // QA FIX: Color dinámico
                color: isDirty ? colorScheme.primary : theme.disabledColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
      ],

      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 72, bottom: 16, end: 150), 
        title: Text(
          profile.businessName, 
          style: const TextStyle(
            // QA FIX: El texto sobre la imagen SIEMPRE debe ser blanco/claro para contrastar con el overlay oscuro
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16, 
            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
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
                  return Container(color: brandColor.withValues(alpha: 0.5));
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
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.0, 0.8],
                  ),
                ),
              ),
            ),
            
            Positioned(
              top: 40, 
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

            if (profile.slogan != null && profile.slogan!.isNotEmpty)
              Positioned(
                bottom: 60, 
                left: 16,
                right: 16,
                child: Text(
                  profile.slogan!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
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

  // --- MÓDULO 1.5: CTA Principal ---
  Widget _buildPrimaryCtaModule(BuildContext context, ProviderProfileModel profile, ThemeData theme) {
    final String ratingText = profile.averageRating != null ? profile.averageRating!.toStringAsFixed(1) : '-.-';
    final String reviewCountText = profile.reviewCount != null && profile.reviewCount! > 0 ? '(${profile.reviewCount} Reseñas)' : '(Sin Reseñas)';
    final colorScheme = theme.colorScheme;

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
                  // QA FIX: Texto dinámico
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: profile.brandColor, // Mantiene color de marca del usuario
                  foregroundColor: ThemeData.estimateBrightnessForColor(profile.brandColor) == Brightness.dark ? Colors.white : Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: null, 
                child: const Text('Agendar Cita Ahora'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MÓDULO 2: Información y Contacto ---
  Widget _buildInfoModule(BuildContext context, CatalogEditorProvider provider, ProviderProfileModel profile, bool showWelcome, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    
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
                  style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 16),
                
                if (showWelcome) ...[
                  _buildWelcomeContent(context, profile, theme), 
                  const SizedBox(height: 24),
                  Divider(color: theme.dividerColor),
                  const SizedBox(height: 24),
                ],

                if (profile.openingHours != null && profile.openingHours!.isNotEmpty) ...[
                  _InfoRow(icon: Icons.access_time_outlined, text: profile.openingHours!, theme: theme),
                  const SizedBox(height: 12),
                ],
                if (profile.address != null && profile.address!.isNotEmpty) ...[
                  _InfoRow(icon: Icons.location_on_outlined, text: profile.address!, theme: theme),
                  const SizedBox(height: 24),
                ],

                // Botones de Contacto
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (profile.phone != null && profile.phone!.isNotEmpty) ...[
                      _ContactButton(icon: Icons.phone_outlined, theme: theme),
                      const SizedBox(width: 16),
                    ],
                    if (profile.whatsapp != null && profile.whatsapp!.isNotEmpty) ...[
                      _ContactButton(icon: Icons.chat_bubble_outline, theme: theme),
                      const SizedBox(width: 16),
                    ],
                    if (profile.contactEmail.isNotEmpty) ...[
                      _ContactButton(icon: Icons.email_outlined, theme: theme),
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
              icon: Icon(Icons.edit, color: colorScheme.primary, size: 24),
              tooltip: "Editar Información y Contacto",
              onPressed: () => _showEditContactDialog(context, provider, theme),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildWelcomeContent(BuildContext context, ProviderProfileModel profile, ThemeData theme) {
    if (profile.welcomeModuleType == 'text') {
       if (profile.welcomeMessage.isEmpty) return const SizedBox(height: 10); 
      return Text(
        profile.welcomeMessage,
        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.8), fontSize: 16, height: 1.4),
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
            child: Center(child: Text('Video externo (YouTube, etc.)\n${profile.welcomeVideoUrl}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54))),
          ),
        );
      }
    }
    return const SizedBox(height: 10);
  }


  // --- MÓDULO Portafolio ---
  Widget _buildPortfolioModule(BuildContext context, CatalogEditorProvider provider, ProviderProfileModel profile, ThemeData theme) {
    final firestoreService = context.read<FirestoreService>();
    final permissions = context.read<PermissionsService>();
    final colorScheme = theme.colorScheme;
    
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0), 
          child: Row( 
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Portafolio',
                style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                tooltip: "Añadir NUEVA categoría",
                onPressed: permissions.canAddPortfolioCategory(provider.localCategories.length)
                  ? () => _showAddCategoryDialog(context, provider, widget.userId, theme)
                  : null, 
              ),
            ],
          ),
        ),

        // --- Selector de Categorías ---
        provider.isLoadingCategories
          ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary)))
          : provider.localCategories.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                  child: Center(child: Text("Aún no tienes categorías. ¡Añade una!", style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)))),
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
                              labelStyle: TextStyle(
                                color: isSelected 
                                  ? (ThemeData.estimateBrightnessForColor(profile.brandColor) == Brightness.dark ? Colors.white : Colors.black) 
                                  : colorScheme.onSurface),
                              selected: isSelected,
                              onSelected: (_) => provider.selectCategory(category.id),
                              selectedColor: profile.brandColor,
                              // QA FIX: Color de chip inactivo dinámico
                              backgroundColor: theme.cardTheme.color,
                              shape: StadiumBorder(side: BorderSide(color: isSelected ? profile.brandColor : theme.dividerColor)),
                              pressElevation: 6.0,
                            ),
                          ),
                          Positioned(
                            top: -10,
                            right: 0,
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () => _showEditCategoryDialog(context, provider, widget.userId, category, theme),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, shape: BoxShape.circle, border: Border.all(color: theme.dividerColor)),
                                    child: Icon(Icons.edit, size: 14, color: Colors.blue.shade700),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => _showDeleteCategoryDialog(context, provider, widget.userId, category, theme),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, shape: BoxShape.circle, border: Border.all(color: theme.dividerColor)),
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

        // --- Cuadrícula de Ítems ---
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
                      style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
                      onPressed: provider.isUploadingItem ? null : () async {
                        final buildContext = context; 
                        final file = await provider.pickPortfolioItem(PortfolioItemType.image);
                        if (file != null && buildContext.mounted) {
                          _showAddCaptionDialog(buildContext, provider, widget.userId, file, PortfolioItemType.image, theme);
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      icon: const Icon(Icons.video_call_outlined),
                      label: const Text("Añadir Video"),
                      style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
                      onPressed: provider.isUploadingItem ? null : () async {
                        final buildContext = context; 
                        final file = await provider.pickPortfolioItem(PortfolioItemType.video);
                        if (file != null && buildContext.mounted) {
                          _showAddCaptionDialog(buildContext, provider, widget.userId, file, PortfolioItemType.video, theme);
                        }
                      },
                    ),
                  ],
                ),
              if (provider.selectedCategoryId != null)
                const SizedBox(height: 16),
              
              provider.selectedCategoryId == null
                ? Center(child: Text("Selecciona o crea una categoría.", style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5))))
                : StreamBuilder<List<PortfolioItemModel>>(
                    stream: firestoreService.getCatalogPortfolioItemsStream(widget.userId, provider.selectedCategoryId!), 
                    builder: (context, itemSnapshot) {
                      if (itemSnapshot.connectionState == ConnectionState.waiting && !provider.isUploadingItem) {
                        return Center(child: Padding(padding: const EdgeInsets.all(32.0), child: CircularProgressIndicator(color: colorScheme.primary)));
                      }
                      if (itemSnapshot.hasError) {
                        return Text('Error: ${itemSnapshot.error}', style: const TextStyle(color: Colors.redAccent));
                      }
                      
                      final items = itemSnapshot.data ?? [];
                      final screenWidth = MediaQuery.of(context).size.width;
                      final crossAxisCount = (screenWidth / 150).floor().clamp(2, 4);

                      if (items.isEmpty && !provider.isUploadingItem) {
                         return Padding(
                           padding: const EdgeInsets.symmetric(vertical: 48.0),
                           child: Center(child: Text('Añade fotos o videos a esta categoría.', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 16))),
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
                            return _buildUploadingPlaceholder(provider.uploadProgress, theme);
                          }
                          final item = items[index];
                          return PortfolioItemCard( 
                            item: item, 
                            isEditable: true, 
                            onDelete: () => _showDeleteItemDialog(context, provider, widget.userId, item, theme)
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

  // --- MÓDULOS Placeholder ---

  Widget _buildActivationPlaceholder({
    required String title,
    required String description,
    required bool hasPermission,
    required String moduleKey,
    required ThemeData theme,
  }) {
    final provider = context.read<CatalogEditorProvider>();
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        // QA FIX: Color de tarjeta dinámico
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.8))),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text("Activar"),
            )
          else
            ElevatedButton(
              onPressed: () { },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white),
              child: const Text("Mejorar Plan"),
            ),
        ],
      ),
    );
  }

  Widget _buildPromotionsModule(BuildContext context, CatalogEditorProvider provider, ProviderProfileModel profile, bool showPromotions, ThemeData theme) {
    final permissions = context.read<PermissionsService>();
    final colorScheme = theme.colorScheme;
    
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Promociones',
              style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 16),
            
            if (showPromotions)
              Container(
                height: 120, 
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade700) 
                ),
                child: Stack( 
                  children: [
                    Center(
                      child: Text('Módulo de Promociones ACTIVO (Próximamente)', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7))),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: Icon(Icons.edit, color: colorScheme.primary, size: 24),
                        tooltip: "Gestionar Promociones",
                        onPressed: () { },
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
                theme: theme,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftCardModule(BuildContext context, CatalogEditorProvider provider, ProviderProfileModel profile, bool showGiftCards, ThemeData theme) {
    final permissions = context.read<PermissionsService>();
    final colorScheme = theme.colorScheme;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tarjetas de Regalo',
              style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 16),

            if (showGiftCards)
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade700)
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text('Módulo de Gift Cards ACTIVO (Próximamente)', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7))),
                    ),
                      Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: Icon(Icons.edit, color: colorScheme.primary, size: 24),
                        tooltip: "Gestionar Gift Cards",
                        onPressed: () { },
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
                theme: theme,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotesModule(BuildContext context, CatalogEditorProvider provider, ProviderProfileModel profile, bool showQuotes, ThemeData theme) {
    final permissions = context.read<PermissionsService>();
    final hasPermission = permissions.canUseGiftCardModule; 
    final colorScheme = theme.colorScheme;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Presupuestos',
              style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 16),

            if (showQuotes)
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade700)
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text('Módulo de Presupuestos ACTIVO (Próximamente)', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7))),
                    ),
                      Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: Icon(Icons.edit, color: colorScheme.primary, size: 24),
                        tooltip: "Gestionar Presupuestos",
                        onPressed: () { },
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
                theme: theme,
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReviewsModule(BuildContext context, ProviderProfileModel profile, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return SliverToBoxAdapter( child: Padding( padding: const EdgeInsets.fromLTRB(16, 24, 16, 16), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [ Text( 'Reseñas', style: Theme.of(context).textTheme.headlineSmall?.copyWith( fontWeight: FontWeight.bold, color: colorScheme.onSurface, ), ), if (profile.reviewCount != null && profile.reviewCount! > 0) TextButton( onPressed: null, style: TextButton.styleFrom(foregroundColor: profile.brandColor), child: Text('Ver todas (${profile.reviewCount})'), ), ], ), const SizedBox(height: 16), Container( height: 150, decoration: BoxDecoration( color: theme.cardTheme.color, borderRadius: BorderRadius.circular(12), ), child: Center( child: Text('Reseñas Destacadas (Próximamente)', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7))), ), ) ], ), ), );
  }

  // --- DIÁLOGOS HELPER ---
  
  void _showEditContactDialog(BuildContext context, CatalogEditorProvider provider, ThemeData theme) {
    final profile = provider.profile;
    final businessNameController = TextEditingController(text: profile.businessName);
    final sloganController = TextEditingController(text: profile.slogan);
    final hoursController = TextEditingController(text: profile.openingHours);
    final emailController = TextEditingController(text: profile.contactEmail);
    final phoneController = TextEditingController(text: profile.phone);
    final whatsappController = TextEditingController(text: profile.whatsapp);
    final welcomeController = TextEditingController(text: profile.welcomeMessage);

    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        // QA FIX: Fondo de diálogo dinámico
        backgroundColor: theme.cardTheme.color,
        title: Text("Editar Información y Contacto", style: TextStyle(color: theme.colorScheme.onSurface)),
        content: SingleChildScrollView( 
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Los TextFormField usan el inputDecorationTheme del tema global, así que ya son dinámicos
              TextFormField(controller: businessNameController, decoration: const InputDecoration(labelText: "Nombre del Negocio"), textCapitalization: TextCapitalization.words),
              const SizedBox(height: 12),
              TextFormField(controller: welcomeController, decoration: const InputDecoration(labelText: "Mensaje de Bienvenida"), maxLines: 3, textCapitalization: TextCapitalization.sentences),
              const SizedBox(height: 12),
              TextFormField(controller: sloganController, decoration: const InputDecoration(labelText: "Slogan"), textCapitalization: TextCapitalization.sentences),
              const SizedBox(height: 12),
              TextFormField(controller: hoursController, decoration: const InputDecoration(labelText: "Horario"), maxLines: 2),
              const SizedBox(height: 12),
              TextFormField(controller: emailController, decoration: const InputDecoration(labelText: "Email de Contacto"), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              TextFormField(controller: phoneController, decoration: const InputDecoration(labelText: "Teléfono"), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TextFormField(controller: whatsappController, decoration: const InputDecoration(labelText: "WhatsApp", hintText: "Ej: 54911..."), keyboardType: TextInputType.phone),
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

  void _showAddCaptionDialog(BuildContext context, CatalogEditorProvider provider, String userId, XFile file, PortfolioItemType type, ThemeData theme) {
    final captionController = TextEditingController();
    
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (ctx) {
         return ChangeNotifierProvider.value(
           value: provider, 
           child: Consumer<CatalogEditorProvider>(
             builder: (consumerContext, provider, child) { 
               return AlertDialog(
                  backgroundColor: theme.cardTheme.color,
                  title: Text(type == PortfolioItemType.image ? "Añadir Foto" : "Añadir Video", style: TextStyle(color: theme.colorScheme.onSurface)),
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

  void _showAddCategoryDialog(BuildContext context, CatalogEditorProvider provider, String userId, ThemeData theme) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardTheme.color,
        title: Text("Nueva Categoría", style: TextStyle(color: theme.colorScheme.onSurface)),
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
  
  void _showEditCategoryDialog(BuildContext context, CatalogEditorProvider provider, String userId, PortfolioCategoryModel category, ThemeData theme) {
     final nameController = TextEditingController(text: category.name);
     final formKey = GlobalKey<FormState>();

     showDialog(
       context: context,
       builder: (ctx) => AlertDialog(
         backgroundColor: theme.cardTheme.color,
         title: Text("Editar Categoría", style: TextStyle(color: theme.colorScheme.onSurface)),
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
  
   void _showDeleteCategoryDialog(BuildContext context, CatalogEditorProvider provider, String userId, PortfolioCategoryModel category, ThemeData theme) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: theme.cardTheme.color,
          title: Text("Eliminar Categoría", style: TextStyle(color: theme.colorScheme.onSurface)),
          content: Text("¿Seguro que quieres eliminar la categoría '${category.name}'?\n\n¡Esto también eliminará permanentemente todas las fotos y videos dentro de ella!", style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
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
  
  void _showDeleteItemDialog(BuildContext context, CatalogEditorProvider provider, String userId, PortfolioItemModel item, ThemeData theme) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: theme.cardTheme.color,
          title: Text("Eliminar Ítem", style: TextStyle(color: theme.colorScheme.onSurface)),
          content: Text("¿Seguro que quieres eliminar este ítem del portafolio?\nLa acción no se puede deshacer.", style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
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

  Widget _buildUploadingPlaceholder(double progress, ThemeData theme) {
    return Card(
      color: theme.cardTheme.color,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             CircularProgressIndicator(value: progress > 0 ? progress : null, strokeWidth: 2, color: theme.colorScheme.primary),
             const SizedBox(height: 8),
             Text("Subiendo...", style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }
  
  void _showModuleSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: context.read<CatalogEditorProvider>(),
          child: const ModuleSettingsSheet(),
        );
      },
    );
  }

} 

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final ThemeData theme;
  
  const _InfoRow({required this.icon, required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
   return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Icon(icon, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), size: 20),
         const SizedBox(width: 16),
         Expanded(
           child: Text(
             text,
             style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
           ),
         ),
       ],
       ),
   );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final ThemeData theme;
  const _ContactButton({required this.icon, required this.theme});

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: null, 
      icon: Icon(icon), 
      style: IconButton.styleFrom(
        backgroundColor: theme.cardTheme.color, 
        foregroundColor: theme.colorScheme.onSurface
      )
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
                    decoration: BoxDecoration( color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(8)),
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