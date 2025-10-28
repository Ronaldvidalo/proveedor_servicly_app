import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'catalog_preview_screen.dart'; // Import for preview

import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/core/services/permissions_service.dart';
import 'package:proveedor_servicly_app/core/services/storage_service.dart';

class ManageCatalogScreen extends StatefulWidget {
  final UserModel user;
  const ManageCatalogScreen({super.key, required this.user});

  @override
  State<ManageCatalogScreen> createState() => _ManageCatalogScreenState();
}

class _ManageCatalogScreenState extends State<ManageCatalogScreen>
    with SingleTickerProviderStateMixin {
  late final FirestoreService _firestoreService;
  late final StorageService _storageService;

  late Map<String, dynamic> _personalizationData;
  bool _isLoading = false;

  // Module States
  late bool _showWelcomeModule;
  late String _welcomeModuleType;
  late TextEditingController _welcomeTextController;
  late TextEditingController _welcomeVideoUrlController;
  late TabController _videoTabController;
  String _videoSourceType = 'url';
  String? _uploadedVideoUrl;
  bool _isUploading = false;
  double? _uploadProgress;
  late TextEditingController _sloganController;
  late TextEditingController _openingHoursController;
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late bool _showPortfolioModule;
  late bool _showReviewsModule;
  // --- NUEVO ESTADO ---
  late bool _showPromotionsModule;
  late bool _showGiftCardModule;


  @override
  void initState() {
    super.initState();
    _firestoreService = context.read<FirestoreService>();
    _storageService = context.read<StorageService>();
    _personalizationData = Map<String, dynamic>.from(widget.user.personalization);

    // Init Welcome
    final welcomeModule = _personalizationData['welcomeModule'] as Map<String, dynamic>? ?? {};
    _showWelcomeModule = welcomeModule['show'] as bool? ?? true;
    _welcomeModuleType = welcomeModule['type'] as String? ?? 'text';
    _welcomeTextController = TextEditingController(text: welcomeModule['text_content'] as String? ?? '');
    _videoSourceType = welcomeModule['video_source_type'] as String? ?? 'url';
    _welcomeVideoUrlController = TextEditingController(text: welcomeModule['video_url'] as String? ?? '');
    _uploadedVideoUrl = (_videoSourceType == 'upload') ? welcomeModule['video_url'] : null;
    _videoTabController = TabController(length: 2, vsync: this);
    _videoTabController.index = (_videoSourceType == 'upload') ? 1 : 0;

    // Init Info/Contact
    _sloganController = TextEditingController(text: _personalizationData['slogan'] as String? ?? '');
    _openingHoursController = TextEditingController(text: _personalizationData['openingHours'] as String? ?? '');
    _phoneController = TextEditingController(text: _personalizationData['phone'] as String? ?? '');
    _whatsappController = TextEditingController(text: _personalizationData['whatsapp'] as String? ?? '');

    // Init Portfolio
    final portfolioModule = _personalizationData['portfolioModule'] as Map<String, dynamic>? ?? {};
    _showPortfolioModule = portfolioModule['show'] as bool? ?? true;

    // Init Reviews
    final reviewsModule = _personalizationData['reviewsModule'] as Map<String, dynamic>? ?? {};
    _showReviewsModule = reviewsModule['show'] as bool? ?? true;

    // --- INIT NUEVOS MÓDULOS ---
    final promotionsModule = _personalizationData['promotionsModule'] as Map<String, dynamic>? ?? {};
    _showPromotionsModule = promotionsModule['show'] as bool? ?? true;

    final giftCardModule = _personalizationData['giftCardModule'] as Map<String, dynamic>? ?? {};
    _showGiftCardModule = giftCardModule['show'] as bool? ?? true;
  }

  @override
  void dispose() {
    // Dispose all controllers
    _welcomeTextController.dispose();
    _welcomeVideoUrlController.dispose();
    _videoTabController.dispose();
    _sloganController.dispose();
    _openingHoursController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  // _pickAndUploadVideo remains the same

    Future<void> _pickAndUploadVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? videoFile = await picker.pickVideo(source: ImageSource.gallery);

    if (videoFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = null;
    });

    try {
      final File file = File(videoFile.path);
      final String filePath =
          'provider_assets/${widget.user.uid}/welcome_video/${DateTime.now().millisecondsSinceEpoch}_${videoFile.name}';

      final String downloadUrl =
          await _storageService.uploadFileWithProgress(
        file,
        filePath,
        (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      if (!mounted) return;

      setState(() {
        _uploadedVideoUrl = downloadUrl;
        _welcomeVideoUrlController.text = downloadUrl;
        _videoSourceType = 'upload';
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Video subido con éxito.'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al subir el video: $e'),
            backgroundColor: Colors.red),
      );
    }
  }


  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      // 1. Welcome module
      _personalizationData['welcomeModule'] = {
        'show': _showWelcomeModule,
        'type': _welcomeModuleType,
        'text_content': _welcomeTextController.text,
        'video_source_type': _videoSourceType,
        'video_url': _welcomeVideoUrlController.text,
      };

      // 2. Info & Contact
      _personalizationData['slogan'] = _sloganController.text;
      _personalizationData['openingHours'] = _openingHoursController.text;
      _personalizationData['phone'] = _phoneController.text;
      _personalizationData['whatsapp'] = _whatsappController.text;

      // 3. Portfolio Visibility
      _personalizationData['portfolioModule'] = {'show': _showPortfolioModule};

      // 4. Reviews Visibility
      _personalizationData['reviewsModule'] = {'show': _showReviewsModule};

      // --- 5. NUEVOS MÓDULOS VISIBILITY ---
      _personalizationData['promotionsModule'] = {'show': _showPromotionsModule};
      _personalizationData['giftCardModule'] = {'show': _showGiftCardModule};


      // 6. Save entire personalization map
      await _firestoreService.updateUser(
        widget.user.uid,
        {'personalization': _personalizationData},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Perfil de catálogo actualizado!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // _buildPreviewModel remains mostly the same, just add new fields
  ProviderProfileModel _buildPreviewModel() {
      Color colorFromHex(String? hexColor) { /* ... */
      if (hexColor == null) return Colors.deepPurple;
      final hexCode = hexColor.replaceAll('#', '');
      if (hexCode.length == 6) {
        try {
          return Color(int.parse('FF$hexCode', radix: 16));
        } catch (e) { return Colors.deepPurple; }
      }
      return Colors.deepPurple;
    }

    final personalization = widget.user.personalization;
    final welcomeModule = personalization['welcomeModule'] as Map<String, dynamic>? ?? {};
    final portfolioModule = personalization['portfolioModule'] as Map<String, dynamic>? ?? {};
    final reviewsModule = personalization['reviewsModule'] as Map<String, dynamic>? ?? {};
    // --- NUEVO ---
    final promotionsModule = personalization['promotionsModule'] as Map<String, dynamic>? ?? {};
    final giftCardModule = personalization['giftCardModule'] as Map<String, dynamic>? ?? {};


    final baseProfile = ProviderProfileModel(
      providerId: widget.user.uid,
      businessName: personalization['businessName'] as String? ?? 'Mi Negocio',
      logoUrl: personalization['logoUrl'] as String? ?? '',
      brandColor: colorFromHex(personalization['primaryColor'] as String?),
      activeModules: widget.user.activeModules,
      profileType: widget.user.publicProfileTemplate ?? 'catalog',
      contactEmail: personalization['contactEmail'] as String? ?? '',
      address: personalization['address'] as String?,
      slogan: personalization['slogan'] as String?,
      averageRating: (personalization['averageRating'] as num?)?.toDouble(),
      reviewCount: personalization['reviewCount'] as int?,
      openingHours: personalization['openingHours'] as String?,
      phone: personalization['phone'] as String?,
      whatsapp: personalization['whatsapp'] as String?,
      welcomeMessage: welcomeModule['text_content'] as String? ?? personalization['welcomeMessage'] as String? ?? 'Bienvenido...',
      showWelcomeModule: welcomeModule['show'] as bool? ?? true,
      welcomeModuleType: welcomeModule['type'] as String? ?? 'text',
      welcomeVideoUrl: welcomeModule['video_url'] as String?,
      welcomeVideoSourceType: welcomeModule['video_source_type'] as String?,
      showPortfolioModule: portfolioModule['show'] as bool? ?? true,
      showReviewsModule: reviewsModule['show'] as bool? ?? true,
      // --- NUEVO ---
      showPromotionsModule: promotionsModule['show'] as bool? ?? true,
      showGiftCardModule: giftCardModule['show'] as bool? ?? true,
    );

    // Apply local state
    final previewProfile = baseProfile.copyWith(
      // Info & Contacto
      slogan: _sloganController.text,
      openingHours: _openingHoursController.text,
      phone: _phoneController.text,
      whatsapp: _whatsappController.text,
      // Bienvenida
      showWelcomeModule: _showWelcomeModule,
      welcomeModuleType: _welcomeModuleType,
      welcomeMessage: _welcomeModuleType == 'text' ? _welcomeTextController.text : baseProfile.welcomeMessage,
      welcomeVideoUrl: _welcomeVideoUrlController.text,
      welcomeVideoSourceType: _videoSourceType,
      // Visibilidad Módulos
      showPortfolioModule: _showPortfolioModule,
      showReviewsModule: _showReviewsModule,
      // --- NUEVO ---
      showPromotionsModule: _showPromotionsModule,
      showGiftCardModule: _showGiftCardModule,
    );

    return previewProfile;
  }

  // --- onPreview function remains the same (uses _buildPreviewModel) ---
    void _onPreview() {
       final previewProfile = _buildPreviewModel();
       Navigator.of(context).push(
         MaterialPageRoute(
           builder: (_) => CatalogPreviewScreen(
             previewProfile: previewProfile,
           ),
         ),
       );
     }


  @override
  Widget build(BuildContext context) {
    final permissions = context.watch<PermissionsService>();
    final bool canUseVideo = permissions.canUseWelcomeVideo;
    final bool canUsePortfolio = permissions.canUsePortfolioModule;
    final bool canUseReviews = permissions.canUseReviewsModule;
    // --- NUEVOS PERMISOS ---
    final bool canUsePromotions = permissions.canUsePromotionsModule;
    final bool canUseGiftCards = permissions.canUseGiftCardModule;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Catálogo'),
        actions: [
          // --- BOTÓN DE VISTA PREVIA ---
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilledButton.icon(
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Previa'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: _isLoading || _isUploading ? null : _onPreview,
            ),
          ),
          // --- Botón Guardar ---
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilledButton(
              onPressed: _isLoading || _isUploading ? null : _saveChanges,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Guardar'),
            ),
          ),
        ],
      ),
      // --- BODY: ListView con las tarjetas de edición ---
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildWelcomeModuleCard(context, canUseVideo),
          const SizedBox(height: 16),
          _buildInfoContactModuleCard(context),
          const SizedBox(height: 16),
          _buildPortfolioModuleCard(context, canUsePortfolio),
          const SizedBox(height: 16),
          // --- NUEVAS TARJETAS ---
          _buildPromotionsModuleCard(context, canUsePromotions),
          const SizedBox(height: 16),
          _buildGiftCardModuleCard(context, canUseGiftCards),
          const SizedBox(height: 16),
          _buildReviewsModuleCard(context, canUseReviews),
        ],
      ),
    );
  }

  // --- Widgets for Edit Cards ---
  // _buildWelcomeModuleCard, _buildVideoUploadTab, _buildInfoContactModuleCard
  // remain exactly the same as before.

    Widget _buildWelcomeModuleCard(BuildContext context, bool canUseVideo) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Módulo de Bienvenida',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text(
                  'Mostrar una bio o video al inicio de tu perfil.'),
              value: _showWelcomeModule,
              onChanged: (value) {
                // Trigger rebuild to update preview
                setState(() => _showWelcomeModule = value);
              },
            ),
            if (_showWelcomeModule) ...[
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                      value: 'text',
                      label: Text('Texto'),
                      icon: Icon(Icons.description_outlined)),
                  ButtonSegment(
                      value: 'video',
                      label: Text('Video'),
                      icon: Icon(Icons.videocam_outlined)),
                ],
                selected: {_welcomeModuleType},
                onSelectionChanged: (Set<String> newSelection) {
                   // Trigger rebuild to update preview
                  setState(() => _welcomeModuleType = newSelection.first);
                },
              ),
              const SizedBox(height: 24),
              if (_welcomeModuleType == 'text')
                TextFormField(
                  controller: _welcomeTextController,
                  decoration: const InputDecoration(
                    labelText: 'Mensaje de bienvenida',
                    border: OutlineInputBorder(),
                    helperText:
                        'Escribe una breve bienvenida o "bio" para tus clientes.',
                  ),
                  maxLines: 5,
                  maxLength: 500,
                   // Trigger rebuild on text change
                  onChanged: (text) => setState(() {}),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (canUseVideo) ...[
                      TabBar(
                        controller: _videoTabController,
                        onTap: (index) {
                           // Trigger rebuild to update preview
                          setState(() {
                            _videoSourceType = (index == 0) ? 'url' : 'upload';
                          });
                        },
                        tabs: const [
                          Tab(text: 'Enlace (URL)'),
                          Tab(text: 'Subir Archivo'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      [
                        TextFormField(
                          controller: _welcomeVideoUrlController,
                          enabled: _videoSourceType == 'url',
                          decoration: const InputDecoration(
                            labelText: 'URL del Video (YouTube, Vimeo)',
                            border: OutlineInputBorder(),
                            helperText:
                                'Pega el enlace a tu video promocional.',
                          ),
                           // Trigger rebuild on text change
                           onChanged: (text) => setState(() {}),
                        ),
                        _buildVideoUploadTab(),
                      ][_videoTabController.index],
                    ] else ...[
                      TextFormField(
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'URL del Video (YouTube, Vimeo)',
                          border: const OutlineInputBorder(),
                          helperText:
                              'Esta función requiere un plan Optimiza o superior.',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: FilledButton.icon(
                          icon: const Icon(Icons.star_outline),
                          label: const Text('Actualizar Plan'),
                          onPressed: () {
                            // TODO: Navegar a la pantalla de planes
                          },
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVideoUploadTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.upload_file_outlined),
          label: const Text('Seleccionar Video de la Galería'),
          onPressed: _isUploading ? null : _pickAndUploadVideo,
        ),
        if (_isUploading) ...[
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.grey.shade300,
            valueColor:
                AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            _uploadProgress == null
                ? 'Preparando subida...'
                : 'Subiendo... ${(100 * _uploadProgress!).toStringAsFixed(0)}%',
            textAlign: TextAlign.center,
          ),
        ],
        // Show preview only if a video was uploaded in THIS session
        if (!_isUploading &&
            _uploadedVideoUrl != null &&
            _videoSourceType == 'upload' &&
            _welcomeVideoUrlController.text == _uploadedVideoUrl ) ...[
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text('Video Cargado'),
            subtitle: Text(
              _uploadedVideoUrl!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
         // Show existing video URL if source is upload but not changed this session
         if (!_isUploading &&
            _videoSourceType == 'upload' &&
             _welcomeVideoUrlController.text.isNotEmpty &&
             _welcomeVideoUrlController.text != _uploadedVideoUrl
             ) ...[
                 const SizedBox(height: 16),
                 ListTile(
                   leading: Icon(Icons.link, color: Colors.grey),
                   title: Text('Video Guardado Anteriormente'),
                   subtitle: Text(
                     _welcomeVideoUrlController.text,
                     maxLines: 1,
                     overflow: TextOverflow.ellipsis,
                     style: const TextStyle(color: Colors.grey),
                   ),
                 )
             ]
      ],
    );
  }

  Widget _buildInfoContactModuleCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Información y Contacto', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _sloganController,
              decoration: const InputDecoration(
                labelText: 'Eslogan o Especialidad',
                border: OutlineInputBorder(),
                helperText: 'Una frase corta que describa tu negocio (opcional).',
                 prefixIcon: Icon(Icons.campaign_outlined)
              ),
              maxLength: 100,
               onChanged: (text) => setState(() {}), // Update preview
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _openingHoursController,
              decoration: const InputDecoration(
                labelText: 'Horario de Atención',
                border: OutlineInputBorder(),
                helperText: 'Ej: Lunes a Viernes: 9am - 6pm',
                prefixIcon: Icon(Icons.access_time_outlined),
              ),
              maxLines: 2,
               onChanged: (text) => setState(() {}), // Update preview
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Teléfono Principal',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
               onChanged: (text) => setState(() {}), // Update preview
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _whatsappController,
              decoration: const InputDecoration(
                labelText: 'WhatsApp (Número con código de país)',
                border: OutlineInputBorder(),
                helperText: 'Ej: +54911xxxxxxxx',
                 prefixIcon: Icon(Icons.chat_bubble_outline),
              ),
               keyboardType: TextInputType.phone,
                onChanged: (text) => setState(() {}), // Update preview
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioModuleCard(BuildContext context, bool canUsePortfolio) {
     return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Módulo de Portafolio', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Mostrar una galería con tus trabajos.'),
              value: _showPortfolioModule,
              onChanged: !canUsePortfolio ? null : (value) {
                setState(() => _showPortfolioModule = value);
              },
            ),
             if (canUsePortfolio && _showPortfolioModule)
               Padding(
                 padding: const EdgeInsets.only(bottom: 8.0, left: 16.0, right: 16.0),
                 child: OutlinedButton.icon(
                   icon: const Icon(Icons.photo_library_outlined),
                   label: const Text('Gestionar Galería'),
                   onPressed: () {
                     // TODO: Navegar a una pantalla dedicada para subir/ordenar fotos del portafolio
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Pantalla de gestión de portafolio (Próximamente).'))
                     );
                   },
                   // Style button to make it more visible if needed
                   style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40) // Make it wider
                   ),
                 ),
               ),
            if (!canUsePortfolio)
              Padding(
                 padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: Text(
                  'El módulo de portafolio requiere un plan Optimiza o superior.',
                  style: TextStyle(color: Theme.of(context).disabledColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- NUEVA TARJETA DE PROMOCIONES ---
  Widget _buildPromotionsModuleCard(BuildContext context, bool canUsePromotions) {
     return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Módulo de Promociones', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Destacar ofertas y descuentos especiales.'),
              value: _showPromotionsModule,
              onChanged: !canUsePromotions ? null : (value) {
                setState(() => _showPromotionsModule = value);
              },
            ),
             if (canUsePromotions && _showPromotionsModule)
               Padding(
                 padding: const EdgeInsets.only(bottom: 8.0, left: 16.0, right: 16.0),
                 child: OutlinedButton.icon(
                   icon: const Icon(Icons.local_offer_outlined),
                   label: const Text('Gestionar Promociones'),
                   onPressed: () {
                     // TODO: Navigate to promotions management screen
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Pantalla de gestión de promociones (Próximamente).'))
                     );
                   },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40)
                   ),
                 ),
               ),
            if (!canUsePromotions)
              Padding(
                 padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: Text(
                  'El módulo de promociones requiere un plan Optimiza o superior.',
                   style: TextStyle(color: Theme.of(context).disabledColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- NUEVA TARJETA DE GIFT CARDS ---
 Widget _buildGiftCardModuleCard(BuildContext context, bool canUseGiftCards) {
     return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Módulo de Gift Cards', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Ofrecer tarjetas de regalo a tus clientes.'),
              value: _showGiftCardModule,
              onChanged: !canUseGiftCards ? null : (value) {
                setState(() => _showGiftCardModule = value);
              },
            ),
             if (canUseGiftCards && _showGiftCardModule)
               Padding(
                 padding: const EdgeInsets.only(bottom: 8.0, left: 16.0, right: 16.0),
                 child: OutlinedButton.icon(
                   icon: const Icon(Icons.card_giftcard_outlined),
                   label: const Text('Gestionar Gift Cards'),
                   onPressed: () {
                     // TODO: Navigate to gift card management screen
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Pantalla de gestión de gift cards (Próximamente).'))
                     );
                   },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40)
                   ),
                 ),
               ),
            if (!canUseGiftCards)
              Padding(
                 padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: Text(
                  'El módulo de gift cards requiere un plan Expande o superior.',
                   style: TextStyle(color: Theme.of(context).disabledColor),
                ),
              ),
          ],
        ),
      ),
    );
  }


  Widget _buildReviewsModuleCard(BuildContext context, bool canUseReviews) {
      return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Módulo de Reseñas', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Mostrar valoraciones de tus clientes.'),
              value: _showReviewsModule,
               onChanged: !canUseReviews ? null : (value) {
                 // Update preview
                setState(() => _showReviewsModule = value);
              },
            ),
             if (!canUseReviews) // Just in case
              Padding(
                 padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: Text(
                  'El módulo de reseñas no está disponible en tu plan actual.',
                   style: TextStyle(color: Theme.of(context).disabledColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
} // End of State class