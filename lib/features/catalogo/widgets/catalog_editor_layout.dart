// import 'dart:ui'; // ¡Error 4! Eliminado (innecesario)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Modelos y Servicios
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/core/models/portfolio_category_model.dart';
import 'package:proveedor_servicly_app/core/models/portfolio_item_model.dart';
import 'package:proveedor_servicly_app/core/services/permissions_service.dart'; // Para permisos
// Provider y Widgets del Editor
import 'package:proveedor_servicly_app/providers/catalog_editor_provider.dart';

// --- ¡RUTAS CORREGIDAS! ---
// Apuntamos a la carpeta 'modules/screens' donde están realmente los archivos
import 'package:proveedor_servicly_app/features/catalogo/modules/module_config.dart';
import 'package:proveedor_servicly_app/features/catalogo/modules/_category_chip.dart';
import 'package:proveedor_servicly_app/features/catalogo/modules/_portfolio_item_card.dart';

// Otros
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart'; // Para los enums
import 'dart:io'; // Para File


/// Layout "Editor Visual" de un proveedor.
/// Es una copia de CatalogLayout adaptada para la edición en contexto (WYSIWYG).
class CatalogEditorLayout extends StatefulWidget {
  final CatalogEditorProvider provider;
  final String userId;

  const CatalogEditorLayout({
    super.key,
    required this.provider,
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
        widget.provider.loadInitialCategories(widget.userId);
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    // ¡Error 3! Eliminada la variable 'backgroundColor' no usada

    final profile = widget.provider.profile;

    // Determinar visibilidad de módulos
    final showWelcome = profile.showWelcomeModule;
    final showPortfolio = profile.showPortfolioModule;
    final showReviews = profile.showReviewsModule;
    final showPromotions = profile.showPromotionsModule;
    final showGiftCards = profile.showGiftCardModule;

    return CustomScrollView(
      slivers: [
        // Módulo 1.5: CTA Principal (Solo lectura)
        _buildPrimaryCtaModule(context, profile),

        // Módulo 2: Información y Contacto (Editable)
        _buildInfoModule(context, profile, showWelcome),

        // Módulo Promociones (Placeholder)
          if (showPromotions) _buildPromotionsModule(context, profile),

        // Módulo Portafolio (Editable)
        if (showPortfolio) _buildPortfolioModule(context, profile),

        // Módulo Gift Cards (Placeholder)
          if (showGiftCards) _buildGiftCardModule(context, profile),

        // Módulo Catálogo de Servicios (Omitido en el editor)
        // _buildServicesModule(context, profile),

        // Módulo Reseñas (Solo lectura)
        if (showReviews) _buildReviewsModule(context, profile),

        const SliverToBoxAdapter(child: SizedBox(height: 80)), // Espacio para FAB
      ],
    );
  }

  // --- MÓDULO 1.5: CTA Principal (Sin cambios, solo lectura) ---
  Widget _buildPrimaryCtaModule(BuildContext context, ProviderProfileModel profile) {
    final String ratingText = profile.averageRating != null
       ? profile.averageRating!.toStringAsFixed(1)
       : '-.-';
       final String reviewCountText = profile.reviewCount != null && profile.reviewCount! > 0
       ? '(${profile.reviewCount} Reseñas)'
       : '(Sin Reseñas)';

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
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: profile.brandColor,
                  foregroundColor:
                      ThemeData.estimateBrightnessForColor(profile.brandColor) == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () { /* Botón deshabilitado en modo edición */ },
                child: const Text('Agendar Cita Ahora'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MÓDULO 2: Información y Contacto (MODIFICADO PARA EDICIÓN) ---
  Widget _buildInfoModule(BuildContext context, ProviderProfileModel profile, bool showWelcome) {
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
                  _InfoRow(
                    icon: Icons.access_time_outlined,
                    text: profile.openingHours!,
                  ),
                  const SizedBox(height: 12),
                ],
                if (profile.address != null && profile.address!.isNotEmpty) ...[
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: profile.address!,
                  ),
                  const SizedBox(height: 24),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (profile.phone != null && profile.phone!.isNotEmpty) ...[
                      IconButton.filled(
                        onPressed: null, // Deshabilitado
                        icon: const Icon(Icons.phone_outlined),
                        style: IconButton.styleFrom(backgroundColor: const Color(0xFF2D2D5A), foregroundColor: Colors.white),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (profile.whatsapp != null && profile.whatsapp!.isNotEmpty) ...[
                      IconButton.filled(
                        onPressed: null, // Deshabilitado
                        icon: const Icon(Icons.chat_bubble_outline), 
                        style: IconButton.styleFrom(backgroundColor: const Color(0xFF2D2D5A), foregroundColor: Colors.white),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (profile.contactEmail.isNotEmpty) ...[
                      IconButton.filled(
                        onPressed: null, // Deshabilitado
                        icon: const Icon(Icons.email_outlined),
                        style: IconButton.styleFrom(backgroundColor: const Color(0xFF2D2D5A), foregroundColor: Colors.white),
                      ),
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
              onPressed: () => _showEditContactDialog(context, widget.provider),
            ),
          )
        ],
      ),
    );
  }

  /// Widget interno para mostrar el contenido del bienvenida (sin cambios)
  Widget _buildWelcomeContent(BuildContext context, ProviderProfileModel profile) {
    if (profile.welcomeModuleType == 'text') {
       if (profile.welcomeMessage.isEmpty) return const SizedBox.shrink();
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
    return const SizedBox.shrink();
  }


  // --- MÓDULO Portafolio (MODIFICADO PARA EDICIÓN) ---
  Widget _buildPortfolioModule(BuildContext context, ProviderProfileModel profile) {
    final firestoreService = context.read<FirestoreService>();
    final permissions = context.read<PermissionsService>();
    final provider = widget.provider; 
    
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
                tooltip: "Añadir categoría",
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
              ? const SizedBox(height: 60) // Espacio vacío si no hay categorías
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
                            child: CategoryChip( 
                              label: category.name,
                              isSelected: isSelected,
                              onTap: () => provider.selectCategory(category.id),
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
                        // --- CORRECCIÓN use_build_context_synchronously ---
                        final buildContext = context; // Guarda el context
                        final file = await provider.pickPortfolioItem(PortfolioItemType.image);
                        if (file != null && mounted) {
                          _showAddCaptionDialog(buildContext, provider, widget.userId, file, PortfolioItemType.image);
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      icon: const Icon(Icons.video_call_outlined),
                      label: const Text("Añadir Video"),
                      onPressed: provider.isUploadingItem ? null : () async {
                         // --- CORRECCIÓN use_build_context_synchronously ---
                        final buildContext = context; // Guarda el context
                        final file = await provider.pickPortfolioItem(PortfolioItemType.video);
                        if (file != null && mounted) {
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
                    stream: firestoreService.getPortfolioItemsStream(widget.userId, provider.selectedCategoryId!),
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
                           child: Center(child: Text('No hay fotos o videos en esta categoría.', style: TextStyle(color: Colors.white54, fontSize: 16))),
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
                          // --- ¡NOMBRE DE CLASE CORREGIDO! ---
                          // De _PortfolioItemCard a PortfolioItemCard
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

  
  // --- MÓDULOS Placeholder (Sin cambios) ---
  Widget _buildPromotionsModule(BuildContext context, ProviderProfileModel profile) {
    return SliverToBoxAdapter( child: Padding( padding: const EdgeInsets.all(16.0), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Text( 'Promociones', style: Theme.of(context).textTheme.headlineSmall?.copyWith( fontWeight: FontWeight.bold, color: Colors.white, ), ), const SizedBox(height: 16), Container( height: 120, decoration: BoxDecoration( color: const Color(0xFF2D2D5A), borderRadius: BorderRadius.circular(12), ), child: const Center( child: Text('Módulo de Promociones (Próximamente)', style: TextStyle(color: Colors.white70)), ), ) ], ), ), );
  }
  Widget _buildGiftCardModule(BuildContext context, ProviderProfileModel profile) {
    return SliverToBoxAdapter( child: Padding( padding: const EdgeInsets.all(16.0), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Text( 'Tarjetas de Regalo', style: Theme.of(context).textTheme.headlineSmall?.copyWith( fontWeight: FontWeight.bold, color: Colors.white, ), ), const SizedBox(height: 16), Container( height: 120, decoration: BoxDecoration( color: const Color(0xFF2D2D5A), borderRadius: BorderRadius.circular(12), ), child: const Center( child: Text('Módulo de Gift Cards (Próximamente)', style: TextStyle(color: Colors.white70)), ), ) ], ), ), );
  }
  Widget _buildReviewsModule(BuildContext context, ProviderProfileModel profile) {
    return SliverToBoxAdapter( child: Padding( padding: const EdgeInsets.fromLTRB(16, 24, 16, 16), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [ Text( 'Reseñas', style: Theme.of(context).textTheme.headlineSmall?.copyWith( fontWeight: FontWeight.bold, color: Colors.white, ), ), if (profile.reviewCount != null && profile.reviewCount! > 0) TextButton( onPressed: null, /* Deshabilitado en editor */ child: Text('Ver todas (${profile.reviewCount})'), style: TextButton.styleFrom(foregroundColor: profile.brandColor), ), ], ), const SizedBox(height: 16), Container( height: 150, decoration: BoxDecoration( color: const Color(0xFF2D2D5A), borderRadius: BorderRadius.circular(12), ), child: const Center( child: Text('Reseñas Destacadas (Próximamente)', style: TextStyle(color: Colors.white70)), ), ) ], ), ), );
  }

  // --- DIÁLOGOS HELPER ---
  
  void _showEditContactDialog(BuildContext context, CatalogEditorProvider provider) {
    final sloganController = TextEditingController(text: provider.profile.slogan);
    final hoursController = TextEditingController(text: provider.profile.openingHours);
    final emailController = TextEditingController(text: provider.profile.contactEmail);
    final phoneController = TextEditingController(text: provider.profile.phone);
    final whatsappController = TextEditingController(text: provider.profile.whatsapp);
    final welcomeController = TextEditingController(text: provider.profile.welcomeMessage);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Editar Información y Contacto"),
        content: SingleChildScrollView( 
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: welcomeController, decoration: const InputDecoration(labelText: "Mensaje de Bienvenida", border: OutlineInputBorder()), maxLines: 3),
              const SizedBox(height: 12),
              TextFormField(controller: sloganController, decoration: const InputDecoration(labelText: "Slogan", border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextFormField(controller: hoursController, decoration: const InputDecoration(labelText: "Horario", border: OutlineInputBorder()), maxLines: 2),
              const SizedBox(height: 12),
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
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
         return Consumer<CatalogEditorProvider>(
           builder: (context, provider, child) {
             return AlertDialog(
                title: Text(type == PortfolioItemType.image ? "Añadir Foto" : "Añadir Video"),
                // --- CORRECCIÓN LINT --- (sort_child_properties_last)
                // 'actions' va después de 'content'
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
                          // --- CORRECCIÓN use_build_context_synchronously ---
                          final navigator = Navigator.of(ctx); // Guarda navigator
                          final caption = captionController.text.trim();
                          
                          await provider.uploadAndSavePortfolioItem(
                            userId, 
                            file, 
                            caption.isEmpty ? null : caption, 
                            type
                          );
                          
                          if (!mounted) return; // Verifica 'mounted' del State
                          navigator.pop(); // Usa el navigator guardado
                        },
                     child: provider.isUploadingItem 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                        : const Text("Guardar y Subir"),
                  ),
                ],
              );
           },
         );
      }
    );
  }

  void _showAddCategoryDialog(BuildContext context, CatalogEditorProvider provider, String userId) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
                final success = await provider.addPortfolioCategory(userId, nameController.text.trim());
                 if (!mounted) return; 
                if (success) { 
                  navigator.pop(); 
                } else {
                    if (!navigator.mounted) return; // Re-check
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
        context: context,
        builder: (ctx) => AlertDialog(
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
                   await provider.updatePortfolioCategoryName(userId, category.id, nameController.text.trim());
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
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Eliminar Categoría"),
          content: Text("¿Seguro que quieres eliminar la categoría '${category.name}'?\n\n¡Esto también eliminará permanentemente todas las fotos y videos dentro de ella!"),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancelar")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                  final navigator = Navigator.of(ctx); 
                  await provider.deletePortfolioCategory(userId, category.id);
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
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Eliminar Ítem"),
          content: const Text("¿Seguro que quieres eliminar este ítem del portafolio?\nLa acción no se puede deshacer."),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancelar")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                  final navigator = Navigator.of(ctx); 
                  await provider.deletePortfolioItem(userId, item);
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
        ..initialize().then((_) { if (mounted) setState(() {}); }).catchError((error) { debugPrint("Error init welcome video: $error"); })
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