// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 18/11/2025
// Style: Cyber Glow
// 1. (¡NUEVO!) Implementada la previsualización total (Fondo + Acento).
//    El body de la pantalla ahora usa el "Tema Público" y el
//    "Acento Público" seleccionados para una muestra en vivo.
// 2. (FIX) El `AppBar` y el botón `Guardar` se mantienen
//    fijos con el tema "privado" (Cyber Glow Azul).
// 3. (ELIMINADO) Se eliminó el selector de "Tema de la App (Privado)"
//    para simplificar la UX, fijando el tema del proveedor.
// 4. (FIX) Añadida lógica de contraste `_getOnColor` para los
//    iconos sobre el color de acento primario.
// ---------------------------------

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

// --- Modelos y Servicios ---
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/core/services/storage_service.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/widgets/info_chip.dart';

// Importamos el ThemeService para leer el tema (¡pero no cambiarlo!)
import 'package:proveedor_servicly_app/core/services/theme_service.dart';
// ¡NUEVO IMPORT! Para acceder al enum AppPalette
import 'package:proveedor_servicly_app/shared/theme/app_themes.dart';

// --- Navegación ---
import 'package:proveedor_servicly_app/features/auth/widgets/auth_wrapper.dart';
import 'package:proveedor_servicly_app/features/settings/screens/manage_payment_methods_screen.dart';

// ===================================================================
// --- DEFINICIONES DE TEMA PÚBLICO (Movidas aquí para accesibilidad) ---
// ===================================================================

/// Clase de datos simple para nuestros "Skins" de perfil público
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

/// Define los "Skins" permitidos
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

/// Helper para obtener el color de contraste (blanco/negro)
Color _getOnColor(Color color) {
  return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
      ? Colors.white
      : Colors.black;
}

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

  late TextEditingController _businessNameController;
  late TextEditingController _sloganController;
  late TextEditingController _addressController;
  late TextEditingController _contactEmailController;
  late TextEditingController _countryController;
  late String _selectedFormat;
  late String _selectedPublicTheme; // <-- ESTADO PARA TEMA PÚBLICO

  // --- Controladores de Redes Sociales ---
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _websiteController;
  late TextEditingController _instagramController;
  late TextEditingController _facebookController;
  late TextEditingController _tiktokController;

  bool _isLoading = false;
  XFile? _selectedImageFile;
  String? _existingLogoUrl;

  // Color de MARCA (diferente del tema de la APP)
  Color _selectedBrandColor = const Color(0xFF00BFFF);

  // Paleta de colores de marca predefinidos
  final List<Color> _predefinedBrandColors = [
    const Color(0xFF00BFFF), // Cyber Glow Azul
    const Color(0xFF00FF7F), // Cyber Glow Verde
    const Color(0xFFF000B0), // Cyber Glow Rosa
    const Color(0xFFFFA500), // Cyber Glow Naranja
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

  /// Función helper para obtener el tema público seleccionado
  _PublicThemeData _getPublicThemeData(String themeId) {
    return _publicProfileThemes.firstWhere(
      (t) => t.id == themeId,
      // Fallback por si el ID guardado no se encuentra
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

    final navigator = Navigator.of(context);

    try {
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

      final hexColor =
          '#${_selectedBrandColor.value.toRadixString(16).substring(2).toUpperCase()}';

      final Map<String, dynamic> updatedPersonalization =
          Map<String, dynamic>.from(userModel.personalization);

      updatedPersonalization.addAll({
        'businessName': _businessNameController.text.trim(),
        'logoUrl': newLogoUrl ?? _existingLogoUrl ?? '',
        'primaryColor': hexColor,
        'contactEmail': _contactEmailController.text.trim(),
        'address': _addressController.text.trim(),
        'slogan': _sloganController.text.trim(),
        'welcomeMessage': _sloganController.text.trim(),
        'country': _countryController.text.trim(),
        'phone': _phoneController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'website': _websiteController.text.trim(),
        'instagram': _instagramController.text.trim(),
        'facebook': _facebookController.text.trim(),
        'tiktok': _tiktokController.text.trim(),
        'publicProfileTheme': _selectedPublicTheme, // <-- CAMPO GUARDADO
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
    // --- INICIO DE LA LÓGICA DE PREVISUALIZACIÓN ---
    
    // 1. Obtenemos el tema REAL de la app (Tema Privado)
    final ThemeData appTheme = Theme.of(context);
    
    // 2. Obtenemos los datos del "Skin" público seleccionado
    final _PublicThemeData publicTheme =
        _getPublicThemeData(_selectedPublicTheme);

    // 3. Creamos un tema de PREVISUALIZACIÓN sobreescribiendo
    //    el fondo, la superficie Y EL ACENTO.
    final ThemeData previewTheme = appTheme.copyWith(
      colorScheme: appTheme.colorScheme.copyWith(
        surface: publicTheme.surface,
        background: publicTheme.background,
        primary: _selectedBrandColor, // <-- ¡NUEVO! Previsualiza el acento
        onPrimary: _getOnColor(_selectedBrandColor), // Contraste
      ),
      scaffoldBackgroundColor: publicTheme.background,
    );
    // --- FIN DE LA LÓGICA DE PREVISUALIZACIÓN ---

    return Scaffold(
      // El AppBar USA EL TEMA DE LA APP (appTheme)
      appBar: AppBar(
        title: const Text('Editar Perfil Público'),
        // Usamos el color de fondo real de la app, no el de preview
        backgroundColor: appTheme.scaffoldBackgroundColor, 
        foregroundColor: appTheme.colorScheme.onSurface,
        elevation: 0,
      ),
      
      // El Scaffold USA EL COLOR DE FONDO DE PREVISUALIZACIÓN
      backgroundColor: previewTheme.scaffoldBackgroundColor,

      // El Body USA EL TEMA DE PREVISUALIZACIÓN (previewTheme)
      body: Theme(
        data: previewTheme, // <-- ¡LA MAGIA ESTÁ AQUÍ!
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Form(
              key: _formKey,
              // Usamos un Builder para obtener el (context) que
              // contiene el previewTheme
              child: Builder(builder: (context) {
                // Ahora `Theme.of(context)` se refiere al previewTheme
                final theme = Theme.of(context);
                final colors = theme.colorScheme;

                // Definimos la decoración de input USANDO EL TEMA DE PREVISUALIZACIÓN
                final inputDecoration = InputDecoration(
                    filled: true,
                    fillColor: colors.background, // Usa el fondo del tema de preview
                    labelStyle: TextStyle(
                        color: colors.onSurface.withOpacity(0.7)),
                    hintStyle: TextStyle(
                        color: colors.onSurface.withOpacity(0.4)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        // El foco usa el acento del PREVIEW
                        borderSide: BorderSide(
                            color: colors.primary, width: 2)), 
                    errorStyle: TextStyle(
                        color: colors.error.withOpacity(0.9)));

                return ListView(
                  padding: const EdgeInsets.all(24.0),
                  children: [
                    // --- SECCIÓN 1: IDENTIDAD DE MARCA ---
                    _buildSectionCard(
                      theme: theme, // Pasa el tema de preview
                      title: 'Identidad de Marca (Público)',
                      children: [
                        _LogoAndNameCard(
                          imageFile: _selectedImageFile,
                          existingLogoUrl: _existingLogoUrl,
                          nameController: _businessNameController,
                          decoration: inputDecoration,
                          onTapLogo: _pickImage,
                        ),
                        const SizedBox(height: 24),
                        _ColorSelectorCard(
                          title: 'Color de Acento (Público)',
                          predefinedColors: _predefinedBrandColors,
                          selectedColor: _selectedBrandColor,
                          onColorSelected: (color) {
                            setState(() => _selectedBrandColor = color);
                          },
                        ),
                        const SizedBox(height: 24),
                        _PublicThemeSelector(
                          selectedThemeId: _selectedPublicTheme,
                          onThemeSelected: (themeId) {
                            setState(() => _selectedPublicTheme = themeId);
                          },
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
                          _TemplateSelector(
                            selectedFormat: _selectedFormat,
                            onFormatSelected: (format) {
                              setState(() => _selectedFormat = format);
                            },
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
                            style: TextStyle(
                                color: colors.onSurface),
                            decoration: inputDecoration.copyWith(
                              labelText: 'Slogan o Mensaje de Bienvenida',
                              prefixIcon: Icon(Icons.campaign_outlined,
                                  color: colors.onSurface.withOpacity(0.7)),
                            ),
                            maxLength: 150,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _addressController,
                            style: TextStyle(
                                color: colors.onSurface),
                            decoration: inputDecoration.copyWith(
                              labelText: 'Dirección o Zona de Cobertura',
                              prefixIcon: Icon(Icons.location_on_outlined,
                                  color: colors.onSurface.withOpacity(0.7)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _countryController,
                            style: TextStyle(
                                color: colors.onSurface),
                            decoration: inputDecoration.copyWith(
                              labelText: 'País (Ej: AR, US, ES)',
                              prefixIcon: Icon(Icons.flag_outlined,
                                  color: colors.onSurface.withOpacity(0.7)),
                            ),
                            maxLength: 2,
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
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        // El botón usará el color de acento de la APP (appTheme)
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
                    const SizedBox(height: 24),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  /// Contenedor reutilizable para cada sección.
  /// (Usa el color 'surface' del tema que se le pasa)
  Widget _buildSectionCard(
      {required ThemeData theme,
      required String title,
      String? subtitle,
      required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, // <-- USA EL TEMA (DE PREVIEW)
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
                    color: theme.colorScheme.onSurface.withOpacity(0.7))),
          ],
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    // El snackbar usa el tema de la APP, no el de preview
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
}

// ===================================================================
// --- WIDGETS DE SECCIÓN PERSONALIZADOS ---
// ===================================================================

/// Combina el selector de logo y el nombre del negocio.
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
    // Usará el tema de preview que viene del 'Builder'
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
                  // El borde AHORA usa el color de acento del PREVIEW
                  border: Border.all(color: colors.primary, width: 2), 
                  color: image == null
                      ? colors.surface.withAlpha(100)
                      : Colors.transparent,
                ),
                child: image == null
                    ? Center(
                        child: Icon(Icons.business_rounded,
                            size: 40,
                            color: colors.onSurface.withOpacity(0.7)))
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
                      // El botón AHORA usa el color de acento del PREVIEW
                      color: colors.primary, 
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                          BorderSide(color: colors.surface, width: 2)),
                    ),
                    // Icono con contraste automático
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

/// Muestra la paleta de colores de la app para la MARCA
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
    final theme = Theme.of(context); // Usará el tema de preview
    
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 3)
                      : Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                  boxShadow: isSelected
                      ? [BoxShadow(color: color.withAlpha(178), blurRadius: 10)]
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

/// (Tu Idea 3) Muestra los formatos de perfil como tarjetas visuales
class _TemplateSelector extends StatelessWidget {
  final String selectedFormat;
  final ValueChanged<String> onFormatSelected;

  const _TemplateSelector(
      {required this.selectedFormat, required this.onFormatSelected});

  @override
  Widget build(BuildContext context) {
    // Forzamos la fila con Expanded para que siempre usen el espacio
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

/// (MEJORA: Tipografía reducida a labelLarge)
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
    final theme = Theme.of(context); // Usará el tema de preview
    final colors = theme.colorScheme;
    final successColor = const Color(0xFF00FF7F); // Color de éxito es constante

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? successColor.withAlpha(30) : colors.background,
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
                    : colors.onSurface.withOpacity(0.7)),
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

/// (Widget Corregido) Muestra un resumen de los métodos de pago
class _PaymentMethodsCard extends StatelessWidget {
  final UserModel user;
  const _PaymentMethodsCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Usará el tema de preview
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
        splashColor: colors.primary.withOpacity(0.2), // Splash de acento de PREVIEW
        highlightColor: colors.primary.withOpacity(0.1), // Highlight de acento de PREVIEW
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              Icon(Icons.credit_card_outlined, color: colors.primary, size: 28), // Icono de acento de PREVIEW
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
                      style: TextStyle(color: colors.onSurface.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: colors.onSurface.withOpacity(0.3), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de Redes Sociales con campos expandibles
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
    // Este widget recibe el tema (de preview) explícitamente
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
                  ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
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
            icon: Icons.message_outlined, // Reemplazar con ícono de WhatsApp
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
            icon: IconsKE.instagram, // Helper class
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

/// El widget de formulario expandible
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
    final colors = Theme.of(context).colorScheme; // Usará el tema de preview
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
                // El icono usa el acento del PREVIEW
                color: isFilled
                    ? colors.primary 
                    : colors.onSurface.withOpacity(0.5),
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                widget.label,
                style: TextStyle(
                    color: isFilled
                        ? colors.onSurface
                        : colors.onSurface.withOpacity(0.5),
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Icon(
                _isExpanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                color: colors.onSurface.withOpacity(0.5),
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
                      prefixIcon: null, // No necesitamos el ícono aquí
                    ),
                    keyboardType: widget.keyboardType,
                    onChanged: (value) {
                      setState(() {
                        // Reconstruye para actualizar el color del icono
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

/// El widget selector principal para los temas públicos
class _PublicThemeSelector extends StatelessWidget {
  final String selectedThemeId;
  final ValueChanged<String> onThemeSelected;

  const _PublicThemeSelector({
    required this.selectedThemeId,
    required this.onThemeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Usará el tema de preview
    
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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5, // Tarjetas más anchas que altas
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

/// La tarjeta visual individual para cada "Skin"
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
    // El borde SÍ usa el acento del PREVIEW
    final Color previewPrimaryColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: theme.background, // Muestra el color de fondo
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? previewPrimaryColor // Borde de acento de PREVIEW
                : Colors.white.withOpacity(0.3), // Borde tenue
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Muestra el color de la tarjeta/superficie
              Container(
                width: double.infinity,
                height: 20,
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              // Muestra el nombre
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