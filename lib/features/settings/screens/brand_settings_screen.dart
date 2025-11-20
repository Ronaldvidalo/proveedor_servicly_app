// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 19/11/2025
// Style: Cyber Glow
// Feature: Virtual Tour + Geocoding Integration
//
// 1. (FIX) Eliminado parámetro 'shapeBorder' que causaba error en Showcase.
// 2. (FIX) Actualizado 'withOpacity' a 'withValues(alpha: ...)' (Nueva API Flutter).
// 3. (FIX) Reemplazado 'background'/'onBackground' por 'surface'/'onSurface'.
// 4. (NEW) Integración de GeocodingService para convertir dirección a coordenadas GPS.
// ---------------------------------

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
// --- Imports para el Tour ---
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Modelos y Servicios ---
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/core/services/storage_service.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/widgets/info_chip.dart';

// --- IMPORTACIÓN CRÍTICA PARA GEOCODING ---
import 'package:proveedor_servicly_app/core/services/geocoding_service.dart';

// Importamos el ThemeService para leer el tema
import 'package:proveedor_servicly_app/core/services/theme_service.dart';

// --- Navegación ---
import 'package:proveedor_servicly_app/features/auth/widgets/auth_wrapper.dart';
import 'package:proveedor_servicly_app/features/settings/screens/manage_payment_methods_screen.dart';

// ===================================================================
// --- DEFINICIONES DE TEMA PÚBLICO ---
// ===================================================================

class _PublicThemeData {
  final String id;
  final String name;
  final Color background;
  final Color surface;

  const _PublicThemeData({
    required this.id,
    required this.name,
    required this.background,
    required this.surface,
  });
}

final List<_PublicThemeData> _publicProfileThemes = [
  const _PublicThemeData(
    id: 'cyber_glow',
    name: 'Cyber Glow',
    background: Color(0xFF1A1A2E),
    surface: Color(0xFF2D2D5A),
  ),
  const _PublicThemeData(
    id: 'nebula_purple',
    name: 'Nebula Purple',
    background: Color(0xFF2E1A2E),
    surface: Color(0xFF4A2D4A),
  ),
  const _PublicThemeData(
    id: 'crimson_red',
    name: 'Crimson Red',
    background: Color(0xFF2E1A1A),
    surface: Color(0xFF4A2D2D),
  ),
  const _PublicThemeData(
    id: 'matrix_green',
    name: 'Matrix Green',
    background: Color(0xFF1A2E1A),
    surface: Color(0xFF2D4A2D),
  ),
];

Color _getOnColor(Color color) {
  return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
      ? Colors.white
      : Colors.black;
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
// ===================================================================

class BrandSettingsScreen extends StatefulWidget {
  final UserModel user;
  final ProviderProfileModel? brandProfile;

  const BrandSettingsScreen({
    super.key,
    required this.user,
    this.brandProfile,
  });

  @override
  State<BrandSettingsScreen> createState() => BrandSettingsScreenState();
}

class BrandSettingsScreenState extends State<BrandSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Claves Globales para el Tour ---
  final GlobalKey _keyIdentitySection = GlobalKey();
  final GlobalKey _keyColorSection = GlobalKey();
  final GlobalKey _keyThemeSection = GlobalKey();
  final GlobalKey _keyFormatSection = GlobalKey();
  final GlobalKey _keySaveButton = GlobalKey();

  BuildContext? _showCaseContext; 

  late TextEditingController _businessNameController;
  late TextEditingController _sloganController;
  late TextEditingController _addressController;
  late TextEditingController _contactEmailController;
  late TextEditingController _countryController;
  late String _selectedFormat;
  late String _selectedPublicTheme;

  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _websiteController;
  late TextEditingController _instagramController;
  late TextEditingController _facebookController;
  late TextEditingController _tiktokController;

  bool _isLoading = false;
  XFile? _selectedImageFile;
  String? _existingLogoUrl;

  Color _selectedBrandColor = const Color(0xFF00BFFF);

  final List<Color> _predefinedBrandColors = [
    const Color(0xFF00BFFF),
    const Color(0xFF00FF7F),
    const Color(0xFFF000B0),
    const Color(0xFFFFA500),
    Colors.purpleAccent,
    Colors.redAccent,
  ];

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController();
    _sloganController = TextEditingController();
    _addressController = TextEditingController();
    _contactEmailController = TextEditingController();
    _countryController = TextEditingController();
    _phoneController = TextEditingController();
    _whatsappController = TextEditingController();
    _websiteController = TextEditingController();
    _instagramController = TextEditingController();
    _facebookController = TextEditingController();
    _tiktokController = TextEditingController();

    _initializeFields();

    // --- Iniciar chequeo del Tour ---
    _checkIfFirstTime();
  }

  Future<void> _checkIfFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenTour = prefs.getBool('hasSeenBrandSettingsTour_v1') ?? false;

    if (!hasSeenTour) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTour();
        prefs.setBool('hasSeenBrandSettingsTour_v1', true);
      });
    }
  }

  void _startTour() {
    if (_showCaseContext != null) {
      ShowCaseWidget.of(_showCaseContext!).startShowCase([
        _keyIdentitySection,
        _keyColorSection,
        _keyThemeSection,
        _keyFormatSection,
        _keySaveButton,
      ]);
    }
  }

  void _initializeFields() {
    final personalization = widget.user.personalization;

    _businessNameController.text =
        personalization['businessName'] as String? ??
            widget.user.displayName ??
            '';
    _sloganController.text = personalization['slogan'] as String? ??
        personalization['welcomeMessage'] as String? ??
        '';
    _addressController.text = personalization['address'] as String? ?? '';
    _contactEmailController.text = personalization['contactEmail'] as String? ??
        widget.user.email ??
        '';
    _countryController.text = personalization['country'] as String? ?? '';

    _phoneController.text = personalization['phone'] as String? ?? '';
    _whatsappController.text = personalization['whatsapp'] as String? ?? '';
    _websiteController.text = personalization['website'] as String? ?? '';
    _instagramController.text = personalization['instagram'] as String? ?? '';
    _facebookController.text = personalization['facebook'] as String? ?? '';
    _tiktokController.text = personalization['tiktok'] as String? ?? '';

    _selectedFormat = widget.user.publicProfileTemplate ?? 'catalog';
    _existingLogoUrl = personalization['logoUrl'] as String?;

    final hexColor = personalization['primaryColor'] as String?;
    _selectedBrandColor = _colorFromHex(hexColor) ?? const Color(0xFF00BFFF);

    _selectedPublicTheme =
        personalization['publicProfileTheme'] as String? ?? 'cyber_glow';
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _sloganController.dispose();
    _addressController.dispose();
    _contactEmailController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _tiktokController.dispose();
    super.dispose();
  }

  _PublicThemeData _getPublicThemeData(String themeId) {
    return _publicProfileThemes.firstWhere(
      (t) => t.id == themeId,
      orElse: () =>
          _publicProfileThemes.firstWhere((t) => t.id == 'cyber_glow'),
    );
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
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

    // --- NUEVO: Instancia del servicio de Geocoding ---
    final geocodingService = GeocodingService();
    double? newLatitude;
    double? newLongitude;

    final navigator = Navigator.of(context);

    try {
      // 1. Subida de Imagen (si aplica)
      if (_selectedImageFile != null) {
        final String storagePath =
            'brandProfiles/${userModel.uid}/profile_logo.jpg';
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

      // 2. Lógica de GEOCODING (Convertir dirección a coordenadas)
      final addressText = _addressController.text.trim();
      if (addressText.isNotEmpty) {
        try {
          // Tip: Concatenar el país ayuda a la precisión si el usuario no lo escribió en la dirección
          String queryAddress = addressText;
          if (_countryController.text.trim().isNotEmpty) {
             // Evita duplicar si ya lo escribió
             if (!addressText.toLowerCase().contains(_countryController.text.trim().toLowerCase())) {
                queryAddress = "$addressText, ${_countryController.text.trim()}";
             }
          }

          final coords = await geocodingService.getCoordinatesFromAddress(queryAddress);
          if (coords != null) {
            newLatitude = coords['latitude'];
            newLongitude = coords['longitude'];
            debugPrint("GEOCODING ÉXITO: $newLatitude, $newLongitude");
          } else {
             debugPrint("GEOCODING: No se encontraron coordenadas para $queryAddress");
          }
        } catch (e) {
          debugPrint("Error en geocoding: $e");
        }
      }

      final hexColor =
          '#${_selectedBrandColor.value.toRadixString(16).substring(2).toUpperCase()}';

      final Map<String, dynamic> updatedPersonalization =
          Map<String, dynamic>.from(userModel.personalization);

      updatedPersonalization.addAll({
        'businessName': _businessNameController.text.trim(),
        'logoUrl': newLogoUrl ?? _existingLogoUrl ?? '',
        'primaryColor': hexColor,
        'contactEmail': _contactEmailController.text.trim(),
        'address': addressText,
        'country': _countryController.text.trim(),
        'slogan': _sloganController.text.trim(),
        'welcomeMessage': _sloganController.text.trim(),
        'phone': _phoneController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'website': _websiteController.text.trim(),
        'instagram': _instagramController.text.trim(),
        'facebook': _facebookController.text.trim(),
        'tiktok': _tiktokController.text.trim(),
        'publicProfileTheme': _selectedPublicTheme,
        
        // --- GUARDADO DE COORDENADAS ---
        // Si obtuvimos nuevas, las guardamos. Si no, intentamos mantener las viejas si existen.
        // Nota: Si el usuario borra la dirección, quizás quieras borrar las coordenadas (opcional)
        if (newLatitude != null) 'latitude': newLatitude,
        if (newLongitude != null) 'longitude': newLongitude,
      });

      await firestoreService.updateUser(userModel.uid, {
        'personalization': updatedPersonalization,
        'publicProfileTemplate': _selectedFormat,
        'isProfileComplete': true,
        'publicProfileCreated': true,
      });

      try {
        await firestoreService.setBrandProfile(
            userModel.uid, updatedPersonalization);
      } catch (e) {
        debugPrint("No se pudo actualizar brandProfiles (puede ser normal): $e");
      }

      if (!mounted) return;
      _showSnackbar('¡Perfil público guardado con éxito!');

      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        _showSnackbar('Error al guardar la configuración: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData appTheme = Theme.of(context);
    final _PublicThemeData publicTheme =
        _getPublicThemeData(_selectedPublicTheme);
    final ThemeData previewTheme = appTheme.copyWith(
      colorScheme: appTheme.colorScheme.copyWith(
        surface: publicTheme.surface,
        onPrimary: _getOnColor(_selectedBrandColor),
      ),
      scaffoldBackgroundColor: publicTheme.background,
    );

    return ShowCaseWidget(
      builder: (context) {
        _showCaseContext = context;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Editar Perfil Público'),
            backgroundColor: appTheme.scaffoldBackgroundColor,
            foregroundColor: appTheme.colorScheme.onSurface,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline_rounded),
                tooltip: 'Ayuda',
                onPressed: _startTour,
              )
            ],
          ),
          backgroundColor: previewTheme.scaffoldBackgroundColor,
          
          body: Theme(
            data: previewTheme,
            child: Builder(builder: (context) {
              final theme = Theme.of(context);
              final colors = theme.colorScheme;

              final inputDecoration = InputDecoration(
                  filled: true,
                  fillColor: colors.surface, 
                  labelStyle:
                      TextStyle(color: colors.onSurface.withValues(alpha: 0.7)),
                  hintStyle:
                      TextStyle(color: colors.onSurface.withValues(alpha: 0.4)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.primary, width: 2)),
                  errorStyle: TextStyle(color: colors.error.withValues(alpha: 0.9)));

              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 24.0),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: Column(
                        children: [
                          // --- SECCIÓN 1: IDENTIDAD DE MARCA ---
                          _buildSectionCard(
                            theme: theme,
                            title: 'Identidad de Marca (Público)',
                            children: [
                              // TOUR: Paso 1 - Identidad
                              Showcase(
                                key: _keyIdentitySection,
                                title: 'Tu Marca',
                                description: 'Sube tu logo y define el nombre de tu negocio. ¡Es lo primero que verán!',
                                child: _LogoAndNameCard(
                                  imageFile: _selectedImageFile,
                                  existingLogoUrl: _existingLogoUrl,
                                  nameController: _businessNameController,
                                  decoration: inputDecoration,
                                  onTapLogo: _pickImage,
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // TOUR: Paso 2 - Color
                              Showcase(
                                key: _keyColorSection,
                                title: 'Color de Acento',
                                description: 'Elige un color que represente tu marca. Se usará en botones y precios.',
                                child: _ColorSelectorCard(
                                  title: 'Color de Acento (Público)',
                                  predefinedColors: _predefinedBrandColors,
                                  selectedColor: _selectedBrandColor,
                                  onColorSelected: (color) {
                                    setState(() => _selectedBrandColor = color);
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),

                              // TOUR: Paso 3 - Tema
                              Showcase(
                                key: _keyThemeSection,
                                title: 'Atmósfera (Skin)',
                                description: 'Selecciona el estilo de fondo para tu página. Prueba cómo se ve en tiempo real.',
                                child: _PublicThemeSelector(
                                  selectedThemeId: _selectedPublicTheme,
                                  onThemeSelected: (themeId) {
                                    setState(() => _selectedPublicTheme = themeId);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // --- SECCIÓN 2: FORMATO DE PERFIL ---
                          _buildSectionCard(
                              theme: theme,
                              title: 'Formato de Perfil Público',
                              subtitle:
                                  'Elige cómo verán tus clientes tu página de presentación.',
                              children: [
                                // TOUR: Paso 4 - Formato
                                Showcase(
                                  key: _keyFormatSection,
                                  title: 'Diseño de Página',
                                  description: '¿Vendes productos o servicios? Elige "Tienda" o "Catálogo" según necesites.',
                                  child: _TemplateSelector(
                                    selectedFormat: _selectedFormat,
                                    onFormatSelected: (format) {
                                      setState(() => _selectedFormat = format);
                                    },
                                  ),
                                ),
                              ]),
                          const SizedBox(height: 24),

                          // --- SECCIÓN 3: CONTENIDO ---
                          _buildSectionCard(
                              theme: theme,
                              title: 'Contenido del Perfil',
                              children: [
                                TextFormField(
                                  controller: _sloganController,
                                  style: TextStyle(color: colors.onSurface),
                                  decoration: inputDecoration.copyWith(
                                    labelText: 'Slogan o Mensaje de Bienvenida',
                                    prefixIcon: Icon(Icons.campaign_outlined,
                                        color: colors.onSurface.withValues(alpha: 0.7)),
                                  ),
                                  maxLength: 150,
                                ),
                                const SizedBox(height: 16),
                                
                                // --- CAMPO DIRECCIÓN (IMPORTANTE PARA GEO) ---
                                TextFormField(
                                  controller: _addressController,
                                  style: TextStyle(color: colors.onSurface),
                                  decoration: inputDecoration.copyWith(
                                    labelText: 'Dirección o Zona de Cobertura',
                                    helperText: 'Se usará para mostrar "Cerca de mí" en el mapa',
                                    helperStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.6)),
                                    prefixIcon: Icon(Icons.location_on_outlined,
                                        color: colors.onSurface.withValues(alpha: 0.7)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _countryController,
                                  style: TextStyle(color: colors.onSurface),
                                  decoration: inputDecoration.copyWith(
                                    labelText: 'País (Ej: Argentina)',
                                    prefixIcon: Icon(Icons.flag_outlined,
                                        color: colors.onSurface.withValues(alpha: 0.7)),
                                  ),
                                ),
                              ]),
                          const SizedBox(height: 24),

                          // --- SECCIÓN 4: REDES SOCIALES ---
                          _SocialMediaCard(
                            theme: theme,
                            decoration: inputDecoration,
                            phoneController: _phoneController,
                            whatsappController: _whatsappController,
                            websiteController: _websiteController,
                            instagramController: _instagramController,
                            facebookController: _facebookController,
                            tiktokController: _tiktokController,
                          ),
                          const SizedBox(height: 24),

                          // --- SECCIÓN 5: MÉTODOS DE PAGO ---
                          _PaymentMethodsCard(
                            user: widget.user,
                          ),
                          const SizedBox(height: 48),

                          // --- Botón de Guardar ---
                          // TOUR: Paso 5 - Guardar
                          Showcase(
                            key: _keySaveButton,
                            title: 'Publicar',
                            description: 'No olvides guardar para que tus clientes vean los cambios.',
                            child: SizedBox(
                              height: 50,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: appTheme.colorScheme.primary,
                                  foregroundColor: appTheme.colorScheme.onPrimary,
                                ),
                                onPressed: _isLoading ? null : _saveSettings,
                                child: _isLoading
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                            color: appTheme.colorScheme.onPrimary,
                                            strokeWidth: 3))
                                    : const Text('Guardar Cambios'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard(
      {required ThemeData theme,
      required String title,
      String? subtitle,
      required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
          ],
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    final colors = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          style: TextStyle(
              color: isError ? colors.onError : Colors.black, // Contraste
              fontWeight: FontWeight.bold)),
      backgroundColor: isError ? colors.error : const Color(0xFF00FF7F), // successColor
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }
}

// ===================================================================
// --- WIDGETS DE SECCIÓN PERSONALIZADOS ---
// ===================================================================

class _LogoAndNameCard extends StatelessWidget {
  final XFile? imageFile;
  final String? existingLogoUrl;
  final VoidCallback onTapLogo;
  final TextEditingController nameController;
  final InputDecoration decoration;

  const _LogoAndNameCard({
    this.imageFile,
    this.existingLogoUrl,
    required this.onTapLogo,
    required this.nameController,
    required this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    ImageProvider? image;
    if (imageFile != null) {
      image = FileImage(File(imageFile!.path));
    } else if (existingLogoUrl != null && existingLogoUrl!.isNotEmpty) {
      image = NetworkImage(existingLogoUrl!);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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
                  image: image != null
                      ? DecorationImage(image: image, fit: BoxFit.cover)
                      : null,
                  border: Border.all(color: colors.primary, width: 2),
                  color: image == null
                      ? colors.surface.withValues(alpha: 0.4) 
                      : Colors.transparent,
                ),
                child: image == null
                    ? Center(
                        child: Icon(Icons.business_rounded,
                            size: 40,
                            color: colors.onSurface.withValues(alpha: 0.7)))
                    : null,
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: GestureDetector(
                  onTap: onTapLogo,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                          BorderSide(color: colors.surface, width: 2)),
                    ),
                    child: Icon(Icons.edit,
                        size: 18,
                        color: colors.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: nameController,
            style: theme.textTheme.titleMedium
                ?.copyWith(color: colors.onSurface),
            decoration: decoration.copyWith(labelText: 'Nombre de tu Negocio'),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Campo requerido' : null,
          ),
        ),
      ],
    );
  }
}

class _ColorSelectorCard extends StatelessWidget {
  final String title;
  final List<Color> predefinedColors;
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  const _ColorSelectorCard({
    required this.title,
    required this.predefinedColors,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: predefinedColors.map((color) {
            bool isSelected = selectedColor.value == color.value;
            return GestureDetector(
              onTap: () => onColorSelected(color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 3)
                      : Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
                  boxShadow: isSelected
                      ? [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 10)]
                      : [],
                ),
                child: isSelected
                    ? Icon(Icons.check, color: _getOnColor(color), size: 24)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _TemplateSelector extends StatelessWidget {
  final String selectedFormat;
  final ValueChanged<String> onFormatSelected;

  const _TemplateSelector(
      {required this.selectedFormat, required this.onFormatSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TemplateCard(
            title: 'Tienda',
            icon: Icons.store_mall_directory_outlined,
            isSelected: selectedFormat == 'store',
            onTap: () => onFormatSelected('store'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TemplateCard(
            title: 'Catálogo',
            icon: Icons.auto_stories_outlined,
            isSelected: selectedFormat == 'catalog',
            onTap: () => onFormatSelected('catalog'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TemplateCard(
            title: 'CV Simple',
            icon: Icons.person_pin_outlined,
            isSelected: selectedFormat == 'cv',
            onTap: () => onFormatSelected('cv'),
          ),
        ),
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final successColor = const Color(0xFF00FF7F);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? successColor.withValues(alpha: 0.12) : colors.surface, 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? successColor : colors.surface,
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 32,
                color: isSelected
                    ? successColor
                    : colors.onSurface.withValues(alpha: 0.7)),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected ? successColor : colors.onSurface,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodsCard extends StatelessWidget {
  final UserModel user;
  const _PaymentMethodsCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    const summaryText = "1 cuenta configurada (MercadoPago)";

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => ManagePaymentMethodsScreen(user: user)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: colors.primary.withValues(alpha: 0.2),
        highlightColor: colors.primary.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              Icon(Icons.credit_card_outlined, color: colors.primary, size: 28),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Métodos de Pago',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summaryText,
                      style: TextStyle(color: colors.onSurface.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: colors.onSurface.withValues(alpha: 0.3), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialMediaCard extends StatelessWidget {
  final ThemeData theme;
  final InputDecoration decoration;
  final TextEditingController phoneController;
  final TextEditingController whatsappController;
  final TextEditingController websiteController;
  final TextEditingController instagramController;
  final TextEditingController facebookController;
  final TextEditingController tiktokController;

  const _SocialMediaCard({
    required this.theme,
    required this.decoration,
    required this.phoneController,
    required this.whatsappController,
    required this.websiteController,
    required this.instagramController,
    required this.facebookController,
    required this.tiktokController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contacto y Redes Sociales',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
              'Toca un ícono para añadir tu información. Los iconos en color se mostrarán en tu perfil.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
          const SizedBox(height: 24),
          _ClickableIconFormField(
            controller: phoneController,
            icon: Icons.phone_outlined,
            label: 'Teléfono de Contacto',
            hint: 'Ej: +5411...',
            keyboardType: TextInputType.phone,
            decoration: decoration,
          ),
          const SizedBox(height: 12),
          _ClickableIconFormField(
            controller: whatsappController,
            icon: Icons.message_outlined,
            label: 'WhatsApp',
            hint: 'Ej: 54911...',
            keyboardType: TextInputType.phone,
            decoration: decoration,
          ),
          const SizedBox(height: 12),
          _ClickableIconFormField(
            controller: websiteController,
            icon: Icons.language_outlined,
            label: 'Página Web',
            hint: 'https://tu-pagina.com',
            keyboardType: TextInputType.url,
            decoration: decoration,
          ),
          const SizedBox(height: 12),
          _ClickableIconFormField(
            controller: instagramController,
            icon: Icons.camera_alt_outlined, 
            label: 'Instagram',
            hint: 'tuusuario (sin @)',
            keyboardType: TextInputType.text,
            decoration: decoration,
          ),
          const SizedBox(height: 12),
          _ClickableIconFormField(
            controller: facebookController,
            icon: Icons.facebook_outlined,
            label: 'Facebook',
            hint: 'tuusuario o enlace',
            keyboardType: TextInputType.text,
            decoration: decoration,
          ),
          const SizedBox(height: 12),
          _ClickableIconFormField(
            controller: tiktokController,
            icon: Icons.music_note_outlined,
            label: 'TikTok',
            hint: '@tuusuario',
            keyboardType: TextInputType.text,
            decoration: decoration,
          ),
        ],
      ),
    );
  }
}

class _ClickableIconFormField extends StatefulWidget {
  final TextEditingController controller;
  final IconData icon;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final InputDecoration decoration;

  const _ClickableIconFormField({
    required this.controller,
    required this.icon,
    required this.label,
    required this.hint,
    required this.keyboardType,
    required this.decoration,
  });

  @override
  State<_ClickableIconFormField> createState() =>
      _ClickableIconFormFieldState();
}

class _ClickableIconFormFieldState extends State<_ClickableIconFormField> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller.text.isNotEmpty) {
      _isExpanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isFilled = widget.controller.text.isNotEmpty;

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() => _isExpanded = !_isExpanded);
          },
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: isFilled
                    ? colors.primary
                    : colors.onSurface.withValues(alpha: 0.5),
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                widget.label,
                style: TextStyle(
                    color: isFilled
                        ? colors.onSurface
                        : colors.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Icon(
                _isExpanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: TextFormField(
                    controller: widget.controller,
                    style: TextStyle(color: colors.onSurface),
                    decoration: widget.decoration.copyWith(
                      hintText: widget.hint,
                      prefixIcon: null,
                    ),
                    keyboardType: widget.keyboardType,
                    onChanged: (value) {
                      setState(() {
                      });
                    },
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }
}

class _PublicThemeSelector extends StatelessWidget {
  final String selectedThemeId;
  final ValueChanged<String> onThemeSelected;

  const _PublicThemeSelector({
    required this.selectedThemeId,
    required this.onThemeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tema de Fondo (Público)',
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 250,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: _publicProfileThemes.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final themeData = _publicProfileThemes[index];
            final bool isSelected = themeData.id == selectedThemeId;
            return _ThemeChoiceCard(
              theme: themeData,
              isSelected: isSelected,
              onTap: () => onThemeSelected(themeData.id),
            );
          },
        )
      ],
    );
  }
}

class _ThemeChoiceCard extends StatelessWidget {
  final _PublicThemeData theme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeChoiceCard({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color previewPrimaryColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? previewPrimaryColor
                : Colors.white.withValues(alpha: 0.3),
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                height: 20,
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                theme.name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}