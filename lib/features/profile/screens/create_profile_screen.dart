// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 14/10/2025
// Style: Cyber Glow
// This screen was refactored to align with the "Cyber Glow" design philosophy.
// It features custom-styled form elements for a professional and cohesive
// profile creation/editing experience.
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';

/// Una pantalla de formulario para que los usuarios completen o editen su perfil.
class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _professionController = TextEditingController();

  var _isLoading = false;

  @override
  void initState() {
    super.initState();
    final userModel = context.read<UserModel?>();
    if (userModel != null) {
      _displayNameController.text = userModel.displayName ?? '';
      _professionController.text = userModel.personalization['profession'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  /// Valida el formulario y guarda los datos del perfil en Firestore.
  Future<void> _saveProfile() async {
    if (!_isLoading && (_formKey.currentState?.validate() ?? false)) {
      setState(() => _isLoading = true);

      final firestoreService = context.read<FirestoreService>();
      final user = context.read<User?>();
      final currentUserModel = context.read<UserModel?>();

      if (user == null) {
        _showSnackbar('Error: Sesión de usuario no válida.', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      final updatedPersonalization = Map<String, dynamic>.from(currentUserModel?.personalization ?? {});
      
      updatedPersonalization['businessName'] = _displayNameController.text.trim();
      updatedPersonalization['profession'] = _professionController.text.trim();

      final dataToUpdate = {
        'displayName': _displayNameController.text.trim(),
        'personalization': updatedPersonalization,
        'isProfileComplete': true,
      };

      try {
        await firestoreService.updateUser(user.uid, dataToUpdate);
        _showSnackbar('Perfil guardado con éxito.');

        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        _showSnackbar('Error al guardar el perfil: $e', isError: true);
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.redAccent
            : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Completar Perfil'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Cuéntanos sobre tu negocio',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Esta información aparecerá en tus presupuestos y contratos.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 40),

                  _StyledTextFormField(
                    controller: _displayNameController,
                    labelText: 'Nombre de tu Negocio o Servicio',
                    prefixIcon: Icons.business_center_outlined,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().length < 3) {
                        return 'Por favor, ingresa un nombre válido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  _StyledTextFormField(
                    controller: _professionController,
                    labelText: 'Profesión o Rubro',
                    prefixIcon: Icons.work_outline_rounded,
                    textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, ingresa tu profesión o rubro.';
                        }
                        return null;
                      },
                  ),
                  const SizedBox(height: 48),

                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: FilledButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.black,
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.black,
                              ),
                            )
                          : const Text('Guardar Perfil'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Un widget reutilizable para los campos de texto con el estilo "Cyber Glow".
class _StyledTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final FormFieldValidator<String>? validator;
  final TextCapitalization textCapitalization;

  const _StyledTextFormField({
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);

    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon, color: accentColor),
        filled: true,
        fillColor: surfaceColor,
        labelStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentColor, width: 2),
        ),
         errorStyle: TextStyle(color: Colors.redAccent.shade100),
      ),
      textCapitalization: textCapitalization,
      validator: validator,
    );
  }
}
