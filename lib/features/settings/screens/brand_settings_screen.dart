import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart'; 

// --- Imports para el Tour ---
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Modelos y Servicios ---
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/core/services/storage_service.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/services/geocoding_service.dart';

// --- Navegación ---
import 'package:proveedor_servicly_app/features/auth/widgets/auth_wrapper.dart';

// --- IMPORTS DE LA IA ---
import 'package:proveedor_servicly_app/ai/services/voice_service.dart';
import 'package:proveedor_servicly_app/ai/widgets/servi_avatar.dart';

// --- IMPORTAR LOS WIDGETS REUTILIZABLES (NUEVO ARCHIVO) ---
import 'package:proveedor_servicly_app/features/settings/widgets/brand_settings_widgets.dart';

// Data Prefijos
final Map<String, String> _countryDialCodes = {
  'AR': '+54', 'BO': '+591', 'BR': '+55', 'CL': '+56',
  'CO': '+57', 'EC': '+593', 'PY': '+595', 'PE': '+51',
  'UY': '+598', 'VE': '+58', 'ES': '+34',
};

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

class BrandSettingsScreen extends StatefulWidget {
  final UserModel user;
  final ProviderProfileModel? brandProfile;

  const BrandSettingsScreen({super.key, required this.user, this.brandProfile});

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

  String _currentDialCode = '+54'; 

  bool _isLoading = false;
  XFile? _selectedImageFile;
  String? _existingLogoUrl;

  final ServiVoiceService _voiceService = ServiVoiceService();
  bool _isSpeaking = false;

  Color _selectedBrandColor = const Color(0xFF00BFFF);

  final List<Color> _predefinedBrandColors = [
    const Color(0xFF00BFFF), const Color(0xFF00FF7F), const Color(0xFFF000B0),
    const Color(0xFFFFA500), Colors.purpleAccent, Colors.redAccent,
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

    _voiceService.player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isSpeaking = state == PlayerState.playing);
    });

    _checkIfFirstTime();
  }

  Future<void> _checkIfFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenTour = prefs.getBool('hasSeenBrandSettingsTour_v3') ?? false;

    if (!hasSeenTour) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _speak("Bienvenido al estudio de diseño. Aquí definiremos cómo te ve el mundo. Ya cargué tus datos básicos.");
        if (mounted) {
          _startTour();
          prefs.setBool('hasSeenBrandSettingsTour_v3', true);
        }
      });
    }
  }

  void _startTour() {
    if (_showCaseContext != null) {
      ShowCaseWidget.of(_showCaseContext!).startShowCase([_keyIdentitySection, _keyColorSection, _keyThemeSection, _keyFormatSection, _keySaveButton]);
    }
  }

  Future<void> _speak(String text) async {
    await _voiceService.speak(text);
  }

  String _getScriptForStep(GlobalKey key) {
    if (key == _keyIdentitySection) return "Confirmemos tu identidad. Ya puse el nombre de tu negocio, pero puedes cambiarlo.";
    if (key == _keyColorSection) return "El color transmite emociones. Elige uno que represente la energía de tu marca.";
    if (key == _keyThemeSection) return "La atmósfera es clave. Prueba los temas oscuros o neón.";
    if (key == _keyFormatSection) return "Aquí está el formato que elegiste antes. Puedes cambiarlo si gustas.";
    if (key == _keySaveButton) return "Cuando te guste lo que ves, guarda los cambios para publicar tu sitio web.";
    return "";
  }

  void _onShowcaseStepStart(int? index, GlobalKey key) {
    String script = _getScriptForStep(key);
    if (key.currentContext != null) {
      Scrollable.ensureVisible(key.currentContext!, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut, alignment: 0.5);
    }
    if (script.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 400), () { if (mounted) _speak(script); });
    }
  }

  void _giveContextualHelp() {
    if (_isSpeaking) { _voiceService.stop(); return; }
    _speak("Estás en el editor de marca. Aquí puedes cambiar colores, logos y redes sociales cuando quieras. No olvides guardar al final.");
  }

  void _initializeFields() {
    final brand = widget.brandProfile;
    final userLegacy = widget.user.personalization; 

    _businessNameController.text = brand?.businessName ?? userLegacy['businessName'] ?? widget.user.displayName ?? '';
    _sloganController.text = brand?.slogan ?? userLegacy['slogan'] ?? '';
    _addressController.text = brand?.address ?? userLegacy['address'] ?? '';
    _contactEmailController.text = brand?.contactEmail ?? widget.user.email ?? '';
    
    String countryCode = brand?.country ?? userLegacy['country'] ?? 'AR';
    _countryController.text = countryCode;
    _currentDialCode = _countryDialCodes[countryCode] ?? '+54'; 

    String rawPhone = brand?.phone ?? userLegacy['phone'] ?? '';
    if (rawPhone.startsWith(_currentDialCode)) {
      _phoneController.text = rawPhone.substring(_currentDialCode.length).trim();
    } else {
      _phoneController.text = rawPhone;
    }

    String rawWhatsapp = brand?.whatsapp ?? userLegacy['whatsapp'] ?? '';
    if (rawWhatsapp.startsWith(_currentDialCode)) {
      _whatsappController.text = rawWhatsapp.substring(_currentDialCode.length).trim();
    } else {
      _whatsappController.text = rawWhatsapp;
    }

    _websiteController.text = brand?.website ?? userLegacy['website'] ?? '';
    _instagramController.text = brand?.instagram ?? userLegacy['instagram'] ?? '';
    _facebookController.text = brand?.facebook ?? userLegacy['facebook'] ?? '';
    _tiktokController.text = brand?.tiktok ?? userLegacy['tiktok'] ?? '';

    _selectedFormat = brand?.publicProfileTemplate ?? widget.user.publicProfileTemplate ?? 'catalog';
    _existingLogoUrl = brand?.logoUrl ?? userLegacy['logoUrl'];

    final hexColor = brand?.primaryColor ?? userLegacy['primaryColor'];
    _selectedBrandColor = _colorFromHex(hexColor) ?? const Color(0xFF00BFFF);
    _selectedPublicTheme = brand?.publicProfileTheme ?? userLegacy['publicProfileTheme'] ?? 'cyber_glow';
  }

  @override
  void dispose() {
    _businessNameController.dispose(); _sloganController.dispose(); _addressController.dispose();
    _contactEmailController.dispose(); _countryController.dispose(); _phoneController.dispose();
    _whatsappController.dispose(); _websiteController.dispose(); _instagramController.dispose();
    _facebookController.dispose(); _tiktokController.dispose(); _voiceService.dispose(); 
    super.dispose();
  }

  PublicThemeData _getPublicThemeData(String themeId) {
    return publicProfileThemes.firstWhere((t) => t.id == themeId, orElse: () => publicProfileThemes.firstWhere((t) => t.id == 'cyber_glow'));
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
    _speak("Guardando tu marca. Esto se verá genial.");

    final firestoreService = context.read<FirestoreService>();
    final storageService = context.read<StorageService>();
    final userModel = widget.user;
    String? newLogoUrl;
    final geocodingService = GeocodingService();
    double? newLatitude;
    double? newLongitude;
    final navigator = Navigator.of(context);

    try {
      if (_selectedImageFile != null) {
        final String storagePath = 'brandProfiles/${userModel.uid}/profile_logo.jpg';
        if (_existingLogoUrl != null && _existingLogoUrl!.isNotEmpty) {
          try { await storageService.deleteFileByUrl(_existingLogoUrl!); } catch (e) { debugPrint("No se pudo borrar logo: $e"); }
        }
        newLogoUrl = await storageService.uploadFileWithProgress(File(_selectedImageFile!.path), storagePath, (progress) {});
      }

      final addressText = _addressController.text.trim();
      if (addressText.isNotEmpty) {
        try {
          String queryAddress = addressText;
          if (_countryController.text.trim().isNotEmpty) {
             if (!addressText.toLowerCase().contains(_countryController.text.trim().toLowerCase())) {
               queryAddress = "$addressText, ${_countryController.text.trim()}";
             }
          }
          final coords = await geocodingService.getCoordinatesFromAddress(queryAddress);
          if (coords != null) { newLatitude = coords['latitude']; newLongitude = coords['longitude']; }
        } catch (e) { debugPrint("Error geocoding: $e"); }
      }

      final hexColor = '#${_selectedBrandColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
      final fullPhone = _phoneController.text.trim().isNotEmpty ? "$_currentDialCode ${_phoneController.text.trim()}" : "";
      final fullWhatsapp = _whatsappController.text.trim().isNotEmpty ? "$_currentDialCode ${_whatsappController.text.trim()}" : "";

      final Map<String, dynamic> brandData = {
        'providerId': userModel.uid,
        'businessName': _businessNameController.text.trim(),
        'slogan': _sloganController.text.trim(),
        'welcomeMessage': _sloganController.text.trim(),
        'contactEmail': _contactEmailController.text.trim(),
        'country': _countryController.text.trim(),
        'address': addressText,
        'logoUrl': newLogoUrl ?? _existingLogoUrl ?? '',
        'primaryColor': hexColor,
        'publicProfileTemplate': _selectedFormat,
        'publicProfileTheme': _selectedPublicTheme,
        'phone': fullPhone,
        'whatsapp': fullWhatsapp,
        'website': _websiteController.text.trim(),
        'instagram': _instagramController.text.trim(),
        'facebook': _facebookController.text.trim(),
        'tiktok': _tiktokController.text.trim(),
      };

      if (newLatitude != null) brandData['latitude'] = newLatitude;
      if (newLongitude != null) brandData['longitude'] = newLongitude;

      await firestoreService.setBrandProfile(userModel.uid, brandData);
      await firestoreService.updateUser(userModel.uid, {'publicProfileTemplate': _selectedFormat, 'isProfileComplete': true, 'publicProfileCreated': true});

      if (!mounted) return;
      _showSnackbar('¡Perfil público guardado con éxito!');
      navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const AuthWrapper()), (route) => false);
    } catch (e) {
      if (mounted) _showSnackbar('Error al guardar: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData appTheme = Theme.of(context);
    final PublicThemeData publicTheme = _getPublicThemeData(_selectedPublicTheme);
    final ThemeData previewTheme = appTheme.copyWith(
      colorScheme: appTheme.colorScheme.copyWith(surface: publicTheme.surface, onPrimary: getOnColor(_selectedBrandColor)),
      scaffoldBackgroundColor: publicTheme.background,
    );

    return ShowCaseWidget(
      onStart: (index, key) => _onShowcaseStepStart(index, key),
      onComplete: (index, key) { if (index == 4) _speak("¡Todo listo! Tienes una marca increíble."); },
      builder: (context) {
        _showCaseContext = context;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Editar Perfil Público'),
            backgroundColor: appTheme.scaffoldBackgroundColor, foregroundColor: appTheme.colorScheme.onSurface, elevation: 0,
            actions: [Padding(padding: const EdgeInsets.only(right: 16.0), child: Center(child: ServiAvatar(isSpeaking: _isSpeaking, size: 35, onTap: _giveContextualHelp)))],
          ),
          backgroundColor: previewTheme.scaffoldBackgroundColor,
          body: Theme(
            data: previewTheme,
            child: Builder(builder: (context) {
              final theme = Theme.of(context);
              final colors = theme.colorScheme;
              final inputDecoration = InputDecoration(filled: true, fillColor: colors.surface, labelStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.7)), hintStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.4)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.primary, width: 2)), errorStyle: TextStyle(color: colors.error.withValues(alpha: 0.9)));

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
                          BrandSectionCard(title: 'Identidad de Marca (Público)', children: [
                            Showcase(key: _keyIdentitySection, title: 'Tu Marca', description: 'Sube tu logo y define el nombre de tu negocio.', child: IdentityCard(imageFile: _selectedImageFile, existingLogoUrl: _existingLogoUrl, nameController: _businessNameController, decoration: inputDecoration, onTapLogo: _pickImage)),
                            const SizedBox(height: 24),
                            Showcase(key: _keyColorSection, title: 'Color de Acento', description: 'Elige un color que represente tu marca.', child: ColorSelector(title: 'Color de Acento (Público)', predefinedColors: _predefinedBrandColors, selectedColor: _selectedBrandColor, onColorSelected: (color) => setState(() => _selectedBrandColor = color))),
                            const SizedBox(height: 24),
                            Showcase(key: _keyThemeSection, title: 'Atmósfera (Skin)', description: 'Selecciona el estilo de fondo para tu página.', child: ThemeSelector(selectedThemeId: _selectedPublicTheme, onThemeSelected: (themeId) => setState(() => _selectedPublicTheme = themeId))),
                          ]),
                          const SizedBox(height: 24),
                          BrandSectionCard(title: 'Formato de Perfil Público', subtitle: 'Elige cómo verán tus clientes tu página.', children: [
                            Showcase(key: _keyFormatSection, title: 'Diseño de Página', description: '¿Vendes productos o servicios?', child: TemplateSelector(selectedFormat: _selectedFormat, onFormatSelected: (format) => setState(() => _selectedFormat = format))),
                          ]),
                          const SizedBox(height: 24),
                          BrandSectionCard(title: 'Contenido del Perfil', children: [
                            TextFormField(controller: _sloganController, style: TextStyle(color: colors.onSurface), decoration: inputDecoration.copyWith(labelText: 'Slogan o Mensaje de Bienvenida', prefixIcon: Icon(Icons.campaign_outlined, color: colors.onSurface.withValues(alpha: 0.7))), maxLength: 150),
                            const SizedBox(height: 16),
                            TextFormField(controller: _addressController, style: TextStyle(color: colors.onSurface), decoration: inputDecoration.copyWith(labelText: 'Dirección o Zona de Cobertura', helperText: 'Se usará para mostrar "Cerca de mí" en el mapa', helperStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.6)), prefixIcon: Icon(Icons.location_on_outlined, color: colors.onSurface.withValues(alpha: 0.7)))),
                            const SizedBox(height: 16),
                            TextFormField(controller: _countryController, readOnly: true, style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5)), decoration: inputDecoration.copyWith(labelText: 'País (Seleccionado al inicio)', prefixIcon: Icon(Icons.flag_outlined, color: colors.onSurface.withValues(alpha: 0.5)))),
                          ]),
                          const SizedBox(height: 24),
                          
                          // ✅ CORREGIDO: Eliminado el parámetro 'theme'
                          ContactInfoSection(
                            decoration: inputDecoration, 
                            phoneController: _phoneController, 
                            whatsappController: _whatsappController, 
                            websiteController: _websiteController, 
                            instagramController: _instagramController, 
                            facebookController: _facebookController, 
                            tiktokController: _tiktokController, 
                            dialCode: _currentDialCode
                          ),
                          
                          const SizedBox(height: 24),
                          PaymentMethodsCard(user: widget.user),
                          const SizedBox(height: 48),
                          Showcase(key: _keySaveButton, title: 'Publicar', description: 'Guarda para que tus clientes vean los cambios.', child: SizedBox(height: 50, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: appTheme.colorScheme.primary, foregroundColor: appTheme.colorScheme.onPrimary), onPressed: _isLoading ? null : _saveSettings, child: _isLoading ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: appTheme.colorScheme.onPrimary, strokeWidth: 3)) : const Text('Guardar Cambios')))),
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

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    final colors = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message, style: TextStyle(color: isError ? colors.onError : Colors.black, fontWeight: FontWeight.bold)), backgroundColor: isError ? colors.error : const Color(0xFF00FF7F), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16)));
  }
}