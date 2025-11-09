import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/core/services/storage_service.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/features/auth/widgets/auth_wrapper.dart';

class BrandSettingsScreen extends StatefulWidget {
  final UserModel user;
  final String? initialTemplateId;
  final ProviderProfileModel? brandProfile;

  const BrandSettingsScreen({
    super.key,
    required this.user,
    this.initialTemplateId,
    this.brandProfile,
  });

  @override
  State<BrandSettingsScreen> createState() => _BrandSettingsScreenState();
}

class _BrandSettingsScreenState extends State<BrandSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _businessNameController;
  late TextEditingController _welcomeMessageController;
  late TextEditingController _addressController;
  late TextEditingController _contactEmailController;
  late TextEditingController _countryController;
  late String _selectedFormat;
  
  // --- ¡NUEVOS CONTROLADORES! ---
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _websiteController;
  late TextEditingController _instagramController;
  late TextEditingController _facebookController;
  late TextEditingController _tiktokController;
  // --- FIN NUEVOS CONTROLADORES ---

  bool _isLoading = false;
  XFile? _selectedImageFile;
  String? _existingLogoUrl;
  Color? _selectedColor;
  bool _isInitialized = false;

  final List<Color> _predefinedColors = [
    const Color(0xFF00BFFF), // Cyber Glow Accent
    Colors.greenAccent,
    Colors.redAccent,
    Colors.purpleAccent,
    Colors.orangeAccent,
    Colors.tealAccent,
  ];

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController();
    _welcomeMessageController = TextEditingController();
    _addressController = TextEditingController();
    _contactEmailController = TextEditingController();
    _countryController = TextEditingController();
    
    // --- ¡NUEVOS CONTROLADORES! ---
    _phoneController = TextEditingController();
    _whatsappController = TextEditingController();
    _websiteController = TextEditingController();
    _instagramController = TextEditingController();
    _facebookController = TextEditingController();
    _tiktokController = TextEditingController();
    // --- FIN NUEVOS CONTROLADORES ---
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final brand = widget.brandProfile;
      final personalization = widget.user.personalization;

      // Rellena los campos del formulario
      _businessNameController.text = brand?.businessName ??
          personalization['businessName'] as String? ??
          widget.user.displayName ?? '';

      _welcomeMessageController.text = brand?.welcomeMessage ??
          personalization['welcomeMessage'] as String? ??
          '¡Bienvenido a mi perfil!';

      _addressController.text =
          brand?.address ?? personalization['address'] as String? ?? '';

      _contactEmailController.text = brand?.contactEmail ??
          personalization['contactEmail'] as String? ??
          widget.user.email ?? '';

      _countryController.text =
          personalization['country'] as String? ?? '';

      // --- ¡NUEVOS CAMPOS LEÍDOS! ---
      _phoneController.text = brand?.phone ?? '';
      _whatsappController.text = brand?.whatsapp ?? '';
      _websiteController.text = brand?.website ?? '';
      _instagramController.text = brand?.instagram ?? '';
      _facebookController.text = brand?.facebook ?? '';
      _tiktokController.text = brand?.tiktok ?? '';
      // --- FIN NUEVOS CAMPOS ---

      _selectedFormat = brand?.profileType ??
          widget.initialTemplateId ??
          widget.user.publicProfileTemplate ??
          'catalog';

      _existingLogoUrl = brand?.logoUrl;
      _selectedColor = brand?.brandColor ?? const Color(0xFF00BFFF);

      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _welcomeMessageController.dispose();
    _addressController.dispose();
    _contactEmailController.dispose();
    _countryController.dispose();
    
    // --- ¡NUEVOS CONTROLADORES! ---
    _phoneController.dispose();
    _whatsappController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _tiktokController.dispose();
    // --- FIN NUEVOS CONTROLADORES ---
    
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) setState(() => _selectedImageFile = image);
    } catch (e) {
      _showSnackbar('Error al seleccionar la imagen: $e', isError: true);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    setState(() => _isLoading = true);

    final firestoreService = context.read<FirestoreService>();
    final storageService = context.read<StorageService>();
    final userModel = widget.user;
    String? newLogoUrl;

    final navigator = Navigator.of(context);

    try {
      // 1. Subir la imagen
      if (_selectedImageFile != null) {
        final String storagePath = 'brandProfiles/${userModel.uid}/profile_logo.jpg';
        if (_existingLogoUrl != null && _existingLogoUrl!.isNotEmpty) {
          try {
            await storageService.deleteFileByUrl(_existingLogoUrl!);
          } catch (e) {
            debugPrint("No se pudo borrar logo anterior: $e");
          }
        }
        newLogoUrl = await storageService.uploadFileWithProgress(
          File(_selectedImageFile!.path),
          storagePath,
          (progress) {},
        );
      }

      // 2. Preparar el color
      final hexColor = _selectedColor ?? const Color(0xFF00BFFF);
      final hexString = '#${hexColor.value.toRadixString(16).substring(2).toUpperCase()}';

      // 3. Obtener el 'brand' existente
      final brand = widget.brandProfile;

      // 4. Crear los mapas de módulos, respetando los valores 'show' existentes
      final Map<String, dynamic> welcomeModule = {
        'show': brand?.showWelcomeModule ?? true,
        'type': brand?.welcomeModuleType ?? 'text',
        'text_content': _welcomeMessageController.text.trim(),
        'video_url': brand?.welcomeVideoUrl,
        'video_source_type': brand?.welcomeVideoSourceType,
      };
      
      final Map<String, dynamic> portfolioModule = {'show': brand?.showPortfolioModule ?? true};
      final Map<String, dynamic> reviewsModule = {'show': brand?.showReviewsModule ?? true};
      final Map<String, dynamic> bookingModule = {'show': brand?.showBookingModule ?? true};
      final Map<String, dynamic> promotionsModule = {'show': brand?.showPromotionsModule ?? false};
      final Map<String, dynamic> giftCardModule = {'show': brand?.showGiftCardModule ?? false};
      final Map<String, dynamic> quotesModule = {'show': brand?.showQuotesModule ?? false};

      // 5. Crear el mapa de datos principal (alineado con tu modelo original)
      final Map<String, dynamic> brandData = {
        // --- CAMPOS PLANOS ---
        'businessName': _businessNameController.text.trim(),
        'logoUrl': newLogoUrl ?? _existingLogoUrl ?? '',
        'publicProfileTemplate': _selectedFormat,
        'contactEmail': _contactEmailController.text.trim(),
        'address': _addressController.text.trim(),
        'primaryColor': hexString,
        'slogan': _welcomeMessageController.text.trim(),
        'welcomeMessage': _welcomeMessageController.text.trim(),

        // --- ¡NUEVOS CAMPOS GUARDADOS! ---
        'phone': _phoneController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'website': _websiteController.text.trim(),
        'instagram': _instagramController.text.trim(),
        'facebook': _facebookController.text.trim(),
        'tiktok': _tiktokController.text.trim(),
        // --- FIN NUEVOS CAMPOS ---

        // --- CAMPOS ANIDADOS (personalization) ---
        // Tu 'ProviderProfileModel.fromFirestore' lee de 'personalization',
        // así que guardamos los datos allí también para consistencia.
        'personalization': {
          'businessName': _businessNameController.text.trim(),
          'logoUrl': newLogoUrl ?? _existingLogoUrl ?? '',
          'primaryColor': hexString,
          'contactEmail': _contactEmailController.text.trim(),
          'address': _addressController.text.trim(),
          'slogan': _welcomeMessageController.text.trim(),
          'country': _countryController.text.trim(),
          
          // --- ¡NUEVOS CAMPOS GUARDADOS (anidados)! ---
          'phone': _phoneController.text.trim(),
          'whatsapp': _whatsappController.text.trim(),
          'website': _websiteController.text.trim(),
          'instagram': _instagramController.text.trim(),
          'facebook': _facebookController.text.trim(),
          'tiktok': _tiktokController.text.trim(),
          
          // Guardamos los mapas de módulos dentro de personalization
          'welcomeModule': welcomeModule,
          'portfolioModule': portfolioModule,
          'reviewsModule': reviewsModule,
          'bookingModule': bookingModule,
          'promotionsModule': promotionsModule,
          'giftCardModule': giftCardModule,
          'quotesModule': quotesModule,

          // Mantenemos los otros campos
          'averageRating': brand?.averageRating ?? 0,
          'reviewCount': brand?.reviewCount ?? 0,
          'openingHours': brand?.openingHours,
        },
        
        // Campos de nivel superior
        'activeModules': brand?.activeModules ?? ['clients', 'agenda'],
      };

      // 6. Guardar en 'brandProfiles'
      await firestoreService.setBrandProfile(userModel.uid, brandData);

      // 7. Actualizar 'users'
      await firestoreService.updateUser(userModel.uid, {
        'isProfileComplete': true,
        'publicProfileCreated': true,
        'publicProfileTemplate': _selectedFormat,
        'personalization.country': _countryController.text.trim(),
        'personalization.businessName': _businessNameController.text.trim(),
      });

      if (!mounted) return;
      _showSnackbar('¡Perfil público guardado con éxito!');

      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
        (route) => false,
      );

    } catch (e) {
      if (mounted) _showSnackbar('Error al guardar la configuración: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);

    final inputDecoration = InputDecoration(
        filled: true,
        fillColor: surfaceColor,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accentColor, width: 2)), 
        errorStyle: TextStyle(color: Colors.redAccent.shade100));

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Editar Perfil Público'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                _buildSectionCard(
                  title: 'Identidad de Marca',
                  children: [
                    _buildLogoSelector(),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _businessNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: inputDecoration.copyWith(labelText: 'Nombre de tu Negocio o Servicio'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Este campo es obligatorio' : null,
                    ),
                    const SizedBox(height: 24),
                    _buildColorSelector(),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionCard(
                    title: 'Formato de Perfil Público',
                    subtitle: 'Elige cómo verán tus clientes tu página de presentación.',
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selectedFormat,
                        decoration: inputDecoration.copyWith(labelText: 'Formato de Perfil'),
                        dropdownColor: surfaceColor,
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(value: 'catalog', child: Text('Catálogo de Servicios')),
                          DropdownMenuItem(value: 'store', child: Text('Tienda de Servicios')),
                          DropdownMenuItem(value: 'cv', child: Text('CV Simple')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _selectedFormat = value);
                        },
                        validator: (value) => value == null ? 'Selecciona un formato' : null,
                      ),
                    ]),
                const SizedBox(height: 24),
                _buildSectionCard(
                    title: 'Contenido del Perfil',
                    children: [
                      TextFormField(
                        controller: _welcomeMessageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: inputDecoration.copyWith(labelText: 'Mensaje de Bienvenida o Eslogan'),
                        maxLength: 150,
                        maxLines: 3,
                        minLines: 1,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        style: const TextStyle(color: Colors.white),
                        decoration: inputDecoration.copyWith(labelText: 'Dirección o Zona de Cobertura'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _countryController,
                        style: const TextStyle(color: Colors.white),
                        decoration: inputDecoration.copyWith(labelText: 'País'),
                      ),
                    ]),
                
                // --- ¡NUEVA SECCIÓN DE CONTACTO Y REDES! ---
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: 'Contacto y Redes Sociales',
                  children: [
                    TextFormField(
                      controller: _contactEmailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: inputDecoration.copyWith(
                        labelText: 'Email de Contacto Público',
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.isNotEmpty && (!value.contains('@') || !value.contains('.'))) {
                          return 'Por favor, introduce un email válido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      style: const TextStyle(color: Colors.white),
                      decoration: inputDecoration.copyWith(
                        labelText: 'Teléfono de Contacto (Opcional)',
                        prefixIcon: const Icon(Icons.phone_outlined, color: Colors.white70),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _whatsappController,
                      style: const TextStyle(color: Colors.white),
                      decoration: inputDecoration.copyWith(
                        labelText: 'WhatsApp (Opcional)',
                        prefixIcon: const Icon(Icons.message_outlined, color: Colors.white70),
                        hintText: 'Ej: 54911...'
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _websiteController,
                      style: const TextStyle(color: Colors.white),
                      decoration: inputDecoration.copyWith(
                        labelText: 'Página Web (Opcional)',
                        prefixIcon: const Icon(Icons.language_outlined, color: Colors.white70),
                        hintText: 'https://...'
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _instagramController,
                      style: const TextStyle(color: Colors.white),
                      decoration: inputDecoration.copyWith(
                        labelText: 'Instagram (Opcional)',
                        prefixIcon: const Icon(Icons.photo_camera_outlined, color: Colors.white70),
                        hintText: 'ej: tuusuario (sin @)'
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _facebookController,
                      style: const TextStyle(color: Colors.white),
                      decoration: inputDecoration.copyWith(
                        labelText: 'Facebook (Opcional)',
                        prefixIcon: const Icon(Icons.facebook_outlined, color: Colors.white70),
                        hintText: 'ej: tuusuario'
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tiktokController,
                      style: const TextStyle(color: Colors.white),
                      decoration: inputDecoration.copyWith(
                        labelText: 'TikTok (Opcional)',
                        prefixIcon: const Icon(Icons.music_note_outlined, color: Colors.white70),
                        hintText: 'ej: @tuusuario'
                      ),
                    ),
                  ]
                ),
                // --- FIN DE NUEVA SECCIÓN ---

                const SizedBox(height: 48),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _saveSettings,
                    style: FilledButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.black),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                        : const Text('Guardar Cambios', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, String? subtitle, required List<Widget> children}) {
    const surfaceColor = Color(0xFF2D2D5A);
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: Colors.white70)),
          ],
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLogoSelector() {
    ImageProvider? image;
    if (_selectedImageFile != null) {
      image = FileImage(File(_selectedImageFile!.path));
    } else if (_existingLogoUrl != null && _existingLogoUrl!.isNotEmpty) {
      image = NetworkImage(_existingLogoUrl!);
    }

    return Row(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: image != null ? DecorationImage(image: image, fit: BoxFit.cover) : null,
                  border: Border.all(color: const Color(0xFF00BFFF), width: 2),
                  color: image == null ? Colors.white.withAlpha(20) : Colors.transparent,
                ),
                child: image == null ? const Center(child: Icon(Icons.business_rounded, size: 40, color: Colors.white70)) : null,
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF00BFFF),
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(BorderSide(color: Color(0xFF1A1A2E), width: 2)),
                    ),
                    child: const Icon(Icons.edit, size: 18, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        const Expanded(
          child: Text(
            'Sube el logo de tu negocio para una apariencia profesional.',
            style: TextStyle(color: Colors.white70),
          ),
        )
      ],
    );
  }

  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Color de Marca', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: _predefinedColors.map((color) {
            bool isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                  boxShadow: isSelected ? [BoxShadow(color: color.withAlpha(178), blurRadius: 10)] : [],
                ),
                child: isSelected ? const Icon(Icons.check, color: Colors.black, size: 24) : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Color? _colorFromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return null;
    final hexCode = hexColor.replaceAll('#', '');
    if (hexCode.length == 6) {
      final validHexCode = 'FF$hexCode';
       try {
         return Color(int.parse(validHexCode, radix: 16));
       } catch (e) {
         return null;
       }
    }
    return null;
  }
} // --- ¡FIN DE LA CLASE _BrandSettingsScreenState! ---