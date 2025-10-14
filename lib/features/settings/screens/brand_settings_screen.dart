import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/core/services/storage_service.dart';

class BrandSettingsScreen extends StatefulWidget {
  final UserModel user;

  const BrandSettingsScreen({super.key, required this.user});

  @override
  State<BrandSettingsScreen> createState() => _BrandSettingsScreenState();
}

class _BrandSettingsScreenState extends State<BrandSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Los controladores se declaran aquí, pero no se inicializan.
  late TextEditingController _businessNameController;
  late TextEditingController _welcomeMessageController;
  late TextEditingController _addressController;
  late TextEditingController _contactEmailController;
  String? _selectedCountry;
  String _selectedFormat = 'cv';

  bool _isLoading = false;
  XFile? _selectedImageFile;
  String? _existingLogoUrl;
  Color? _selectedColor;
  bool _isInitialized = false; // Bandera para controlar la inicialización

  final List<Color> _predefinedColors = [
    Colors.blue, Colors.green, Colors.red, Colors.purple, Colors.orange, Colors.teal
  ];

  @override
  void initState() {
    super.initState();
    // Inicializamos los controladores con valores vacíos.
    _businessNameController = TextEditingController();
    _welcomeMessageController = TextEditingController();
    _addressController = TextEditingController();
    _contactEmailController = TextEditingController();
  }

  // --- MODIFICACIÓN CLAVE ---
  // Usamos didChangeDependencies para inicializar los valores desde el context.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Usamos una bandera para asegurarnos de que esto solo se ejecute una vez.
    if (!_isInitialized) {
      final personalization = widget.user.personalization;
      
      _businessNameController.text = personalization['businessName'] as String? ?? '';
      _welcomeMessageController.text = personalization['welcomeMessage'] as String? ?? '';
      _addressController.text = personalization['address'] as String? ?? '';
      _contactEmailController.text = personalization['contactEmail'] as String? ?? widget.user.email ?? '';
      _selectedCountry = personalization['country'] as String?;
      _selectedFormat = personalization['publicProfileFormat'] as String? ?? 'cv';
      _existingLogoUrl = personalization['logoUrl'] as String?;
      
      final hexColor = personalization['primaryColor'] as String?;
      _selectedColor = _colorFromHex(hexColor) ?? Theme.of(context).primaryColor;

      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _welcomeMessageController.dispose();
    _addressController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        setState(() {
          _selectedImageFile = image;
        });
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
      updatedPersonalization['country'] = _selectedCountry;
      updatedPersonalization['publicProfileFormat'] = _selectedFormat;
      if (newLogoUrl != null) updatedPersonalization['logoUrl'] = newLogoUrl;
      if (_selectedColor != null) {
        updatedPersonalization['primaryColor'] = '#${_selectedColor!.value.toRadixString(16).substring(2, 8)}';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil Público')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                _buildSectionTitle('Identidad de Marca'),
                const SizedBox(height: 16),
                _buildLogoSelector(),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _businessNameController,
                  decoration: const InputDecoration(labelText: 'Nombre de tu Negocio o Servicio'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Este campo es obligatorio' : null,
                ),
                const SizedBox(height: 24),
                _buildColorSelector(),
                const Divider(height: 48),

                _buildSectionTitle('Formato de Perfil Público'),
                const SizedBox(height: 8),
                Text('Elige cómo verán tus clientes tu página de presentación.', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedFormat,
                  decoration: const InputDecoration(labelText: 'Formato de Perfil'),
                  items: const [
                    DropdownMenuItem(value: 'cv', child: Text('CV Simple')),
                    DropdownMenuItem(value: 'portfolio', child: Text('Catálogo de Trabajos')),
                    DropdownMenuItem(value: 'store', child: Text('Tienda de Servicios')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedFormat = value);
                  },
                ),
                const Divider(height: 48),

                _buildSectionTitle('Contenido del Perfil'),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _welcomeMessageController,
                  decoration: const InputDecoration(labelText: 'Mensaje de Bienvenida o Eslogan'),
                  maxLength: 150,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Dirección o Zona de Cobertura'),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  initialValue: _selectedCountry,
                  decoration: const InputDecoration(labelText: 'País'),
                  onChanged: (value) => _selectedCountry = value,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _contactEmailController,
                  decoration: const InputDecoration(labelText: 'Email de Contacto Público'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 48),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveSettings,
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Guardar Cambios'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold));
  }

  Widget _buildLogoSelector() {
    ImageProvider? image;
    if (_selectedImageFile != null) {
      image = FileImage(File(_selectedImageFile!.path));
    } else if (_existingLogoUrl != null && _existingLogoUrl!.isNotEmpty) {
      image = NetworkImage(_existingLogoUrl!);
    } else {
      image = null; // No hay imagen
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: image,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: image == null ? const Icon(Icons.business, size: 40) : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.upload_file),
            label: const Text('Subir Logo'),
            onPressed: _pickImage,
          ),
        )
      ],
    );
  }
  
  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Color de Marca', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: _predefinedColors.map((color) {
            bool isSelected = _selectedColor?.value == color.value;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected 
                      ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3)
                      : null,
                ),
                child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
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
      backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
    ));
  }

  Color? _colorFromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return null;
    final hexCode = hexColor.replaceAll('#', '');
    if (hexCode.length == 6) {
      return Color(int.parse('FF$hexCode', radix: 16));
    }
    return null;
  }
}

