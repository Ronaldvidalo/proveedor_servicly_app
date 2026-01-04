import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

// --- IMPORTAR LOS WIDGETS REUTILIZABLES ---
import 'package:proveedor_servicly_app/features/settings/widgets/brand_settings_widgets.dart';
import 'package:proveedor_servicly_app/widgets/weekly_schedule_editor.dart';

// Data Prefijos
final Map<String, String> _countryDialCodes = {
  'AR': '+54', 'BO': '+591', 'BR': '+55', 'CL': '+56',
  'CO': '+57', 'EC': '+593', 'PY': '+595', 'PE': '+51',
  'UY': '+598', 'VE': '+58', 'ES': '+34',
};

// Función auxiliar para color
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
  // Recibe la plantilla seleccionada si es creación nueva
  final String? initialTemplate;

  const BrandSettingsScreen({
    super.key, 
    required this.user, 
    this.brandProfile,
    this.initialTemplate,
  });

  @override
  State<BrandSettingsScreen> createState() => BrandSettingsScreenState();
}

class BrandSettingsScreenState extends State<BrandSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Claves Globales para el Tour (Showcase) ---
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

  // Variable NO nullable (por eso daba error antes)
  String _selectedFormat = 'catalog'; 
  String _selectedPublicTheme = 'cyber_glow';

  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _websiteController;
  late TextEditingController _instagramController;
  late TextEditingController _facebookController;
  late TextEditingController _tiktokController;

  Map<int, List<TimeRange>> _weeklySchedule = {};
  bool _worksOnHolidays = false;

  String _currentDialCode = '+54';

  bool _isLoading = false;
  XFile? _selectedImageFile;
  String? _existingLogoUrl;

  final ServiVoiceService _voiceService = ServiVoiceService();
  bool _isSpeaking = false;

  Color _selectedBrandColor = const Color(0xFF00B2B2);

  final List<Color> _predefinedBrandColors = [
    const Color(0xFF00B2B2), const Color(0xFF00FF7F), const Color(0xFFF000B0),
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

    _initializeFields(widget.brandProfile);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _checkIfFirstTime();
    });

    _voiceService.player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isSpeaking = state == PlayerState.playing);
    });
  }

  Future<void> _checkIfFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenTour = prefs.getBool('hasSeenBrandSettingsTour_v5_multi') ?? false;

    if (!hasSeenTour) {
        await _speak("Bienvenido al estudio de diseño. Aquí configuraremos esta tienda específica.");
        if (mounted) {
          _startTour();
          prefs.setBool('hasSeenBrandSettingsTour_v5_multi', true);
        }
    }
  }

  void _startTour() {
    if (_showCaseContext != null) {
      ShowCaseWidget.of(_showCaseContext!).startShowCase([
        _keyIdentitySection,
        _keyColorSection,
        _keyThemeSection,
        _keyFormatSection,
        _keySaveButton
      ]);
    }
  }

  Future<void> _speak(String text) async {
    await _voiceService.speak(text);
  }

  String _getScriptForStep(GlobalKey key) {
    if (key == _keyIdentitySection) return "Aquí define el nombre y logo de ESTA tienda.";
    if (key == _keyColorSection) return "Cada tienda puede tener su propio color.";
    if (key == _keySaveButton) return "Guarda para publicar este perfil.";
    return "";
  }

  void _onShowcaseStepStart(int? index, GlobalKey key) {
    String script = _getScriptForStep(key);
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!, 
        duration: const Duration(milliseconds: 600), 
        curve: Curves.easeInOut, 
        alignment: 0.5
      );
    }
    if (script.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 400), () { 
        if (mounted) _speak(script); 
      });
    }
  }

  void _giveContextualHelp() {
    if (_isSpeaking) { 
      _voiceService.stop(); 
      return; 
    }
    _speak("Estás editando un perfil de negocio. Recuerda que con el plan PRO puedes tener varios.");
  }

  void _initializeFields(ProviderProfileModel? brand) {
    // Usamos 'personalization' como fallback si no hay brand
    final legacyData = widget.user.personalization;

    _businessNameController.text = brand?.businessName ?? widget.user.displayName ?? '';
    _sloganController.text = brand?.slogan ?? '';
    _addressController.text = brand?.address ?? '';
    _contactEmailController.text = brand?.contactEmail ?? widget.user.email ?? '';

    String countryCode = brand?.country ?? 'AR';
    _countryController.text = countryCode;
    _currentDialCode = _countryDialCodes[countryCode] ?? '+54';

    String rawPhone = brand?.phone ?? (legacyData['phone'] as String?) ?? '';
    
    if (rawPhone.startsWith(_currentDialCode)) {
      _phoneController.text = rawPhone.substring(_currentDialCode.length).trim();
    } else {
      _phoneController.text = rawPhone;
    }

    String rawWhatsapp = brand?.whatsapp ?? '';
    if (rawWhatsapp.startsWith(_currentDialCode)) {
      _whatsappController.text = rawWhatsapp.substring(_currentDialCode.length).trim();
    } else {
      _whatsappController.text = rawWhatsapp;
    }

    _websiteController.text = brand?.website ?? '';
    _instagramController.text = brand?.instagram ?? '';
    _facebookController.text = brand?.facebook ?? '';
    _tiktokController.text = brand?.tiktok ?? '';

    // --- CORRECCIÓN DEFINITIVA DE ASIGNACIÓN (OPERADOR ??) ---
    // Usamos '??' para asegurar que nunca se asigne un null a _selectedFormat
    if (brand != null) {
        _selectedFormat = brand.publicProfileTemplate ?? 'catalog';
    } else {
        _selectedFormat = widget.initialTemplate ?? 'catalog';
    }

    _existingLogoUrl = brand?.logoUrl;

    if (brand != null) {
        _selectedBrandColor = brand.brandColor;
    } else {
        final legacyColor = legacyData['primaryColor'] as String?;
        _selectedBrandColor = _colorFromHex(legacyColor) ?? const Color(0xFF00B2B2);
    }
    
    _selectedPublicTheme = brand?.publicProfileTheme ?? 'cyber_glow';
    _weeklySchedule = brand?.weeklySchedule ?? {};
    _worksOnHolidays = brand?.worksOnHolidays ?? false;
  }

  @override
  void dispose() {
    _businessNameController.dispose(); _sloganController.dispose(); _addressController.dispose();
    _contactEmailController.dispose(); _countryController.dispose(); _phoneController.dispose();
    _whatsappController.dispose(); _websiteController.dispose(); _instagramController.dispose();
    _facebookController.dispose(); _tiktokController.dispose(); 
    _voiceService.dispose();
    super.dispose();
  }

  PublicThemeData _getPublicThemeData(String themeId) {
    return publicProfileThemes.firstWhere(
      (t) => t.id == themeId, 
      orElse: () => publicProfileThemes.firstWhere((t) => t.id == 'cyber_glow')
    );
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
    if (!_formKey.currentState!.validate()) {
      _speak("Bancame, hay algunos campos con errores arriba. Revisalos.");
      _showSnackbar("Revisa los campos marcados en rojo.", isError: true);
      return;
    }

    if (_isLoading) return;

    setState(() => _isLoading = true);
    _speak("Guardando perfil...");

    final firestoreService = context.read<FirestoreService>();
    final storageService = context.read<StorageService>();
    final userModel = widget.user;
    final geocodingService = GeocodingService();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    String? newLogoUrl;
    double? newLatitude;
    double? newLongitude;

    try {
      // 1. Determinar ID del documento
      String docId;
      if (widget.brandProfile != null) {
         docId = widget.brandProfile!.id; // Editando existente
      } else {
         // Generamos un ID nuevo en la colección raíz
         docId = FirebaseFirestore.instance.collection('brandProfiles').doc().id; 
      }

      // 2. Subir imagen (Usamos el docId para carpeta única)
      if (_selectedImageFile != null) {
        final String storagePath = 'brandProfiles/${userModel.uid}/$docId/logo.jpg';
        newLogoUrl = await storageService.uploadFileWithProgress(File(_selectedImageFile!.path), storagePath, (progress) {});
      }

      // 3. Geocoding
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
          if (coords != null) { 
            newLatitude = coords['latitude']; 
            newLongitude = coords['longitude']; 
          }
        } catch (e) { debugPrint("Error geocoding: $e"); }
      }

      final hexColor = '#${_selectedBrandColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
      final fullPhone = _phoneController.text.trim().isNotEmpty ? "$_currentDialCode ${_phoneController.text.trim()}" : "";
      final fullWhatsapp = _whatsappController.text.trim().isNotEmpty ? "$_currentDialCode ${_whatsappController.text.trim()}" : "";

      final Map<String, dynamic> serializedSchedule = _weeklySchedule.map((key, value) {
        return MapEntry(key.toString(), value.map((v) => v.toMap()).toList());
      });

      // 4. Construir Data
      final Map<String, dynamic> brandData = {
        'id': docId,
        'providerId': userModel.uid, // Vincula la tienda al usuario
        'isActive': true, 
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
        'weeklySchedule': serializedSchedule,
        'worksOnHolidays': _worksOnHolidays,
        'updatedAt': FieldValue.serverTimestamp(),
        // Si es nuevo, agregamos fecha de creación
        if (widget.brandProfile == null) 'createdAt': FieldValue.serverTimestamp(),
      };

      if (newLatitude != null) brandData['latitude'] = newLatitude;
      if (newLongitude != null) brandData['longitude'] = newLongitude;

      // 5. GUARDAR USANDO EL SERVICIO (A la colección raíz)
      await firestoreService.setBrandProfile(userModel.uid, brandData, docId: docId);

      // 6. Actualizar User (Flags generales)
      await firestoreService.updateUser(userModel.uid, {
        'isProfileComplete': true, 
        'publicProfileCreated': true,
      });

      if (!mounted) return;
      
      messenger.showSnackBar(
        const SnackBar(content: Text('¡Tienda guardada con éxito!'), backgroundColor: Color(0xFF00FF7F))
      );

      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthWrapper()), 
        (route) => false
      );

    } catch (e) {
      debugPrint("Error crítico al guardar: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackbar('Error al guardar cambios.', isError: true);
        _speak("Hubo un problema guardando. Intenta de nuevo.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData appTheme = Theme.of(context);
    final PublicThemeData publicTheme = _getPublicThemeData(_selectedPublicTheme);
    
    final ThemeData previewTheme = appTheme.copyWith(
      colorScheme: appTheme.colorScheme.copyWith(
        surface: publicTheme.surface, 
        onPrimary: getOnColor(_selectedBrandColor)
      ),
      scaffoldBackgroundColor: publicTheme.background,
    );

    return ShowCaseWidget(
      onStart: (index, key) => _onShowcaseStepStart(index, key),
      onComplete: (index, key) { 
        if (index == 4) _speak("¡Todo listo! Tienes una marca increíble."); 
      },
      builder: (context) {
        _showCaseContext = context;
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.brandProfile == null ? 'Nueva Tienda' : 'Editar Tienda'),
            backgroundColor: appTheme.scaffoldBackgroundColor, 
            foregroundColor: appTheme.colorScheme.onSurface, 
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline_rounded),
                tooltip: 'Iniciar Tour Guiado',
                onPressed: () {
                    _speak("Reiniciando el tour guiado.");
                    _startTour();
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0, left: 8.0), 
                child: Center(
                  child: ServiAvatar(
                    isSpeaking: _isSpeaking, 
                    size: 35, 
                    onTap: _giveContextualHelp
                  )
                )
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
                labelStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.7)), 
                hintStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.4)), 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), 
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), 
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.primary, width: 2)), 
                errorStyle: TextStyle(color: colors.error.withValues(alpha: 0.9))
              );

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
                            Showcase(
                              key: _keyIdentitySection, 
                              title: 'Tu Marca', 
                              description: 'Sube tu logo y define el nombre de tu negocio.', 
                              child: IdentityCard(
                                imageFile: _selectedImageFile, 
                                existingLogoUrl: _existingLogoUrl, 
                                nameController: _businessNameController, 
                                decoration: inputDecoration, 
                                onTapLogo: _pickImage
                              )
                            ),
                            const SizedBox(height: 24),
                            Showcase(
                              key: _keyColorSection, 
                              title: 'Color de Acento', 
                              description: 'Elige un color que represente tu marca.', 
                              child: ColorSelector(
                                title: 'Color de Acento (Público)', 
                                predefinedColors: _predefinedBrandColors, 
                                selectedColor: _selectedBrandColor, 
                                onColorSelected: (color) => setState(() => _selectedBrandColor = color)
                              )
                            ),
                            const SizedBox(height: 24),
                            Showcase(
                              key: _keyThemeSection, 
                              title: 'Atmósfera (Skin)', 
                              description: 'Selecciona el estilo de fondo para tu página.', 
                              child: ThemeSelector(
                                selectedThemeId: _selectedPublicTheme, 
                                onThemeSelected: (themeId) => setState(() => _selectedPublicTheme = themeId)
                              )
                            ),
                          ]),
                          
                          const SizedBox(height: 24),
                          
                          BrandSectionCard(title: 'Formato de Perfil Público', subtitle: 'Elige cómo verán tus clientes tu página.', children: [
                            Showcase(
                              key: _keyFormatSection, 
                              title: 'Diseño de Página', 
                              description: '¿Vendes productos o servicios?', 
                              child: TemplateSelector(
                                selectedFormat: _selectedFormat, 
                                onFormatSelected: (format) => setState(() => _selectedFormat = format)
                              )
                            ),
                          ]),
                          
                          const SizedBox(height: 24),

                          if (_selectedFormat == 'catalog')
                            BrandSectionCard(
                              title: 'Gestión de Agenda', 
                              subtitle: 'Define tus horarios para recibir turnos automáticamente.', 
                              children: [
                                WeeklyScheduleEditor(
                                  initialSchedule: _weeklySchedule, 
                                  initialWorksOnHolidays: _worksOnHolidays,
                                  accentColor: _selectedBrandColor,
                                  onChanged: (newSchedule, worksHolidays) {
                                    setState(() {
                                      _weeklySchedule = newSchedule;
                                      _worksOnHolidays = worksHolidays;
                                    });
                                  },
                                ),
                              ]
                            ),

                          if (_selectedFormat == 'catalog') const SizedBox(height: 24),
                          
                          BrandSectionCard(title: 'Contenido del Perfil', children: [
                            TextFormField(
                              controller: _sloganController, 
                              style: TextStyle(color: colors.onSurface), 
                              decoration: inputDecoration.copyWith(
                                labelText: 'Slogan o Mensaje de Bienvenida', 
                                prefixIcon: Icon(Icons.campaign_outlined, color: colors.onSurface.withValues(alpha: 0.7))
                              ), 
                              maxLength: 150
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressController, 
                              style: TextStyle(color: colors.onSurface), 
                              decoration: inputDecoration.copyWith(
                                labelText: 'Dirección o Zona de Cobertura', 
                                helperText: 'Se usará para mostrar "Cerca de mí" en el mapa', 
                                helperStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.6)), 
                                prefixIcon: Icon(Icons.location_on_outlined, color: colors.onSurface.withValues(alpha: 0.7))
                              )
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _countryController, 
                              readOnly: true, 
                              style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5)), 
                              decoration: inputDecoration.copyWith(
                                labelText: 'País', 
                                prefixIcon: Icon(Icons.flag_outlined, color: colors.onSurface.withValues(alpha: 0.5))
                              )
                            ),
                          ]),
                          
                          const SizedBox(height: 24),
                          
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
                          
                          Showcase(
                            key: _keySaveButton, 
                            title: 'Publicar', 
                            description: 'Guarda para que tus clientes vean los cambios.', 
                            child: SizedBox(
                              height: 54, 
                              width: double.infinity, 
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: colors.primary, 
                                  foregroundColor: colors.onPrimary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                ), 
                                onPressed: _isLoading ? null : _saveSettings, 
                                child: _isLoading 
                                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3) 
                                  : const Text('GUARDAR Y PUBLICAR', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1))
                              )
                            )
                          ),
                          const SizedBox(height: 48),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: TextStyle(color: isError ? Colors.white : Colors.black, fontWeight: FontWeight.bold)), 
      backgroundColor: isError ? colors.error : const Color(0xFF00FF7F), 
      behavior: SnackBarBehavior.floating, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
      margin: const EdgeInsets.all(16)
    ));
  }
}