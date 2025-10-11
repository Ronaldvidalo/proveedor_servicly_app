/// lib/features/settings/screens/brand_settings_screen.dart
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';

class BrandSettingsScreen extends StatefulWidget {
  const BrandSettingsScreen({super.key});

  @override
  State<BrandSettingsScreen> createState() => _BrandSettingsScreenState();
}

class _BrandSettingsScreenState extends State<BrandSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _businessNameController;

  bool _isLoading = false;
  
  // Para la selección de imágenes
  XFile? _selectedImageFile;
  String? _existingLogoUrl;

  // Para la selección de color
  Color? _selectedColor;
  final List<Color> _predefinedColors = [
    Colors.blue, Colors.green, Colors.red, Colors.purple, Colors.orange, Colors.teal
  ];

  @override
  void initState() {
    super.initState();
    final userModel = context.read<UserModel>(); // Leemos una vez
    
    _businessNameController = TextEditingController(text: userModel.displayName ?? '');
    _existingLogoUrl = userModel.personalization['logoUrl'] as String?;
    
    final hexColor = userModel.personalization['primaryColor'] as String?;
    _selectedColor = _colorFromHex(hexColor) ?? Theme.of(context).primaryColor;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
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
    final userModel = context.read<UserModel>();
    String? newLogoUrl;

    try {
      // 1. Subir la nueva imagen si el usuario seleccionó una.
      if (_selectedImageFile != null) {
        final ref = FirebaseStorage.instance.ref('logos/${userModel.uid}');
        await ref.putFile(File(_selectedImageFile!.path));
        newLogoUrl = await ref.getDownloadURL();
      }

      // 2. Construir el mapa de personalización actualizado.
      final updatedPersonalization = Map<String, dynamic>.from(userModel.personalization);
      updatedPersonalization['businessName'] = _businessNameController.text.trim();
      if (newLogoUrl != null) {
        updatedPersonalization['logoUrl'] = newLogoUrl;
      }
      if (_selectedColor != null) {
        updatedPersonalization['primaryColor'] = '#${_selectedColor!.value.toRadixString(16).substring(2, 8)}';
      }
      
      // 3. Guardar los datos en Firestore.
      await firestoreService.updateUser(userModel.uid, {'personalization': updatedPersonalization});

      _showSnackbar('¡Marca guardada con éxito!');
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
      appBar: AppBar(title: const Text('Personalizar mi Marca')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                // Sección de Logo
                _buildLogoSelector(),
                const SizedBox(height: 32),

                // Sección de Nombre del Negocio
                Text('Nombre de tu Negocio', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _businessNameController,
                  decoration: const InputDecoration(labelText: 'Ej: Plomería Total'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Este campo es obligatorio' : null,
                ),
                const SizedBox(height: 32),

                // Sección de Color de Marca
                Text('Color de tu Marca', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                _buildColorSelector(),
                const SizedBox(height: 48),

                // Botón de Guardar
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

  Widget _buildLogoSelector() {
    ImageProvider? image;
    if (_selectedImageFile != null) {
      image = FileImage(File(_selectedImageFile!.path));
    } else if (_existingLogoUrl != null) {
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
    return Wrap(
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
    );
  }

  // --- Funciones de Utilidad ---
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