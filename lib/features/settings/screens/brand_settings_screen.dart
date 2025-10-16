import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/core/services/storage_service.dart';

// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 14/10/2025
// Style: Cyber Glow
// This screen was refactored to align with the "Cyber Glow" design philosophy.
// It features custom-styled form elements, interactive logo/color pickers,
// and a card-based layout for better visual organization and user experience.
// ---------------------------------

class BrandSettingsScreen extends StatefulWidget {
  final UserModel user;

  const BrandSettingsScreen({super.key, required this.user});

  @override
  State<BrandSettingsScreen> createState() => _BrandSettingsScreenState();
}

class _BrandSettingsScreenState extends State<BrandSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _businessNameController;
  late TextEditingController _welcomeMessageController;
  late TextEditingController _addressController;
  late TextEditingController _contactEmailController;
  late TextEditingController _countryController; // CORRECCIÓN: Usar un controller
  String _selectedFormat = 'cv';

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
    _countryController = TextEditingController(); // CORRECCIÓN: Inicializar controller
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final personalization = widget.user.personalization;
      
      _businessNameController.text = personalization['businessName'] as String? ?? '';
      _welcomeMessageController.text = personalization['welcomeMessage'] as String? ?? '';
      _addressController.text = personalization['address'] as String? ?? '';
      _contactEmailController.text = personalization['contactEmail'] as String? ?? widget.user.email ?? '';
      _countryController.text = personalization['country'] as String? ?? ''; // CORRECCIÓN: Asignar al controller
      _selectedFormat = personalization['publicProfileFormat'] as String? ?? 'cv';
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
    _countryController.dispose(); // CORRECCIÓN: Disponer del controller
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        setState(() => _selectedImageFile = image);
      }
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

    try {
      if (_selectedImageFile != null) {
        newLogoUrl = await storageService.uploadProductImage(
          imageFile: _selectedImageFile!,
          userId: userModel.uid,
        );
      }

      final updatedPersonalization = Map<String, dynamic>.from(userModel.personalization);
      updatedPersonalization['businessName'] = _businessNameController.text.trim();
      updatedPersonalization['welcomeMessage'] = _welcomeMessageController.text.trim();
      updatedPersonalization['address'] = _addressController.text.trim();
      updatedPersonalization['contactEmail'] = _contactEmailController.text.trim();
      updatedPersonalization['country'] = _countryController.text.trim(); // CORRECCIÓN: Leer desde el controller
      updatedPersonalization['publicProfileFormat'] = _selectedFormat;
      if (newLogoUrl != null) updatedPersonalization['logoUrl'] = newLogoUrl;
      if (_selectedColor != null) {
        // CORRECCIÓN: Se usa el valor del color de forma segura sin la propiedad obsoleta.
        updatedPersonalization['primaryColor'] = '#${_selectedColor!.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
      }
      
      await firestoreService.updateUser(userModel.uid, {'personalization': updatedPersonalization});

      _showSnackbar('¡Perfil público guardado con éxito!');
      if(mounted) Navigator.of(context).pop();

    } catch (e) {
      _showSnackbar('Error al guardar la configuración: $e', isError: true);
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
                      initialValue: _selectedFormat,
                      decoration: inputDecoration.copyWith(labelText: 'Formato de Perfil'),
                      dropdownColor: surfaceColor,
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'cv', child: Text('CV Simple')),
                        DropdownMenuItem(value: 'portfolio', child: Text('Catálogo de Trabajos')),
                        DropdownMenuItem(value: 'store', child: Text('Tienda de Servicios')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedFormat = value);
                      },
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
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      style: const TextStyle(color: Colors.white),
                      decoration: inputDecoration.copyWith(labelText: 'Dirección o Zona de Cobertura'),
                    ),
                    const SizedBox(height: 16),
                    // CORRECCIÓN: Se usa el controller en lugar de initialValue y onChanged.
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
                        if (value != null && value.isNotEmpty && !value.contains('@')) {
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
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: image != null ? DecorationImage(image: image, fit: BoxFit.cover) : null,
                  border: Border.all(color: const Color(0xFF00BFFF), width: 2),
                ),
                child: image == null ? const Center(child: Icon(Icons.business_rounded, size: 40, color: Colors.white70)) : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF00BFFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, size: 16, color: Colors.black),
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
            // CORRECCIÓN: Se comparan los objetos Color directamente.
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
                      // CORRECCIÓN: Se usa '.withAlpha()' en lugar de '.withOpacity()'.
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
    ));
  }

  Color? _colorFromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return null;
    final hexCode = hexColor.replaceAll('#', '');
    if (hexCode.length >= 6) {
      return Color(int.parse('FF${hexCode.substring(0, 6)}', radix: 16));
    }
    return null;
  }
}
