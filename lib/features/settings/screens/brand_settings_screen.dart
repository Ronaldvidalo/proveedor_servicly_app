import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/core/services/storage_service.dart';
// ¡NUEVO! Importamos el modelo de perfil para usar los valores por defecto
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart'; 
// --- CORRECCIÓN: Importación correcta de AuthWrapper ---
import 'package:proveedor_servicly_app/features/auth/widgets/auth_wrapper.dart';

class BrandSettingsScreen extends StatefulWidget {
  final UserModel user;
  final String? initialTemplateId;

  const BrandSettingsScreen({
    super.key,
    required this.user,
    this.initialTemplateId,
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
    _countryController = TextEditingController(); // Inicializar controller
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      // Los datos de 'personalization' en el 'userModel' pueden estar vacíos
      // si es la primera vez que el usuario entra aquí.
      final personalization = widget.user.personalization;

      _businessNameController.text = personalization['businessName'] as String? ?? widget.user.displayName ?? '';
      _welcomeMessageController.text = personalization['welcomeMessage'] as String? ?? '¡Bienvenido a mi perfil!';
      _addressController.text = personalization['address'] as String? ?? '';
      _contactEmailController.text = personalization['contactEmail'] as String? ?? widget.user.email ?? '';
      _countryController.text = personalization['country'] as String? ?? ''; // Asignar al controller

      _selectedFormat = widget.initialTemplateId ?? widget.user.publicProfileTemplate ?? 'catalog'; // Default a 'catalog'
      _existingLogoUrl = personalization['logoUrl'] as String?;

      final hexColor = personalization['primaryColor'] as String?;
      _selectedColor = _colorFromHex(hexColor) ?? const Color(0xFF00BFFF);

      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _welcomeMessageController.dispose();
    _addressController.dispose();
    _contactEmailController.dispose();
    _countryController.dispose(); // Disponer del controller
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

  // --- ¡FUNCIÓN DE GUARDADO MODIFICADA! ---
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    setState(() => _isLoading = true);

    final firestoreService = context.read<FirestoreService>();
    final storageService = context.read<StorageService>();
    final userModel = widget.user;
    String? newLogoUrl;

    // Guardamos el context para usarlo después del await
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // 1. Subir la imagen (si hay una nueva)
      if (_selectedImageFile != null) {
        // Usamos la nueva ruta de 'catalogs'
        final String storagePath = 'catalogs/${userModel.uid}/profile_logo.jpg';
        
        // Borramos la imagen anterior si existía
        if (_existingLogoUrl != null && _existingLogoUrl!.isNotEmpty) {
           try { await storageService.deleteFileByUrl(_existingLogoUrl!); }
           catch(e) { debugPrint("No se pudo borrar logo anterior: $e"); }
        }

        newLogoUrl = await storageService.uploadFileWithProgress(
          File(_selectedImageFile!.path),
          storagePath,
          (progress) { /* Callback de progreso (opcional) */ },
        );
      }

      // 2. Preparar el mapa de datos para 'catalogs/{userId}'
      final hexColor = _selectedColor ?? const Color(0xFF00BFFF);
      final hexString = '#${hexColor.red.toRadixString(16).padLeft(2, '0')}'
                         '${hexColor.green.toRadixString(16).padLeft(2, '0')}'
                         '${hexColor.blue.toRadixString(16).padLeft(2, '0')}';

      // Creamos el objeto de perfil con TODOS los datos (nuevos y por defecto)
      // Usamos ProviderProfileModel para asegurar que todos los campos booleanos
      // (showWelcomeModule, etc.) se inicialicen correctamente.
      final newCatalogProfile = ProviderProfileModel(
        providerId: userModel.uid,
        businessName: _businessNameController.text.trim(),
        logoUrl: newLogoUrl ?? _existingLogoUrl ?? '',
        brandColor: _selectedColor ?? const Color(0xFF00BFFF),
        activeModules: userModel.activeModules ?? [], // Hereda de user
        profileType: _selectedFormat, // ¡USA EL FORMATO SELECCIONADO!
        contactEmail: _contactEmailController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        slogan: null, // El editor principal manejará esto
        averageRating: 0, 
        reviewCount: 0, 
        openingHours: null, // El editor principal manejará esto
        phone: null, // El editor principal manejará esto
        whatsapp: null, // El editor principal manejará esto
        welcomeMessage: _welcomeMessageController.text.trim(),
        // Valores por defecto para los booleanos
        showWelcomeModule: true,
        welcomeModuleType: 'text',
        showPortfolioModule: true,
        showReviewsModule: true,
        showPromotionsModule: false,
        showGiftCardModule: false,
        showBookingModule: true,
        showQuotesModule: false,
      );
      
      // Convertimos el modelo a un mapa para guardarlo
      final catalogData = newCatalogProfile.toMap();
      
      // Añadimos campos extra que no están en el modelo pero sí en el formulario
      catalogData['country'] = _countryController.text.trim();
      catalogData['primaryColor'] = hexString.toUpperCase();
      // ¡IMPORTANTE! Aseguramos que el template se guarde en el mapa
      catalogData['publicProfileTemplate'] = _selectedFormat;


      // 3. Guardar los datos del perfil PÚBLICO en la colección 'catalogs'
      await firestoreService.setCatalogData(userModel.uid, catalogData);

      // 4. Actualizar el documento 'users' solo con datos de estado
      await firestoreService.updateUser(userModel.uid, {
        'isProfileComplete': true, 
        'publicProfileCreated': true, 
        'publicProfileTemplate': _selectedFormat, // Guardamos la plantilla aquí también por si acaso
      });
      // --- FIN DEL CAMBIO DE LÓGICA ---
      
      if (!mounted) return;
      _showSnackbar('¡Perfil público guardado con éxito!');
      
      // Navegamos de vuelta al AuthWrapper
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
        (route) => false,
      );

    } catch (e) {
      if(mounted) _showSnackbar('Error al guardar la configuración: $e', isError: true);
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
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accentColor, width: 2)),
      errorStyle: TextStyle(color: Colors.redAccent.shade100)
    );

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
                      value: _selectedFormat, 
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
                  ]
                ),
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactEmailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: inputDecoration.copyWith(labelText: 'Email de Contacto Público'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.isNotEmpty && (!value.contains('@') || !value.contains('.'))) {
                          return 'Por favor, introduce un email válido.';
                        }
                        return null;
                      },
                    ),
                  ]
                ),
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

  /// UI Polish: Un contenedor reutilizable para cada sección del formulario.
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
            clipBehavior: Clip.none, // Permitir que el botón sobresalga
            children: [
              Container(
                width: 80, height: 80, // Asegurar tamaño
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: image != null ? DecorationImage(image: image, fit: BoxFit.cover) : null,
                  border: Border.all(color: const Color(0xFF00BFFF), width: 2),
                   color: image == null ? Colors.white.withAlpha(20) : Colors.transparent, // Fondo si no hay imagen
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
                       border: Border.fromBorderSide(BorderSide(color: Color(0xFF1A1A2E), width: 2)), // Borde para separar
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
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: isSelected
                      ? [BoxShadow(color: color.withAlpha(178), blurRadius: 10)]
                      : [],
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
    if (hexCode.length >= 6) {
      final validHexCode = hexCode.length == 6 ? 'FF$hexCode' : (hexCode.length == 8 ? hexCode : null);
       if (validHexCode != null) {
         try {
           return Color(int.parse(validHexCode, radix: 16));
         } catch (e) {
           return null;
         }
       }
    }
    return null;
  }
}