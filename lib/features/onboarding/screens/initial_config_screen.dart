// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 14/10/2025
// Style: Cyber Glow
// This screen was refactored to align with the "Cyber Glow" design philosophy.
// It features custom-styled form fields and a clear, modern layout to
// provide a cohesive final step in the onboarding process.
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';

/// Pantalla final del onboarding para recoger los datos mínimos según el rol.
class InitialConfigScreen extends StatefulWidget {
  final UserModel userModel;
  const InitialConfigScreen({super.key, required this.userModel});

  @override
  State<InitialConfigScreen> createState() => _InitialConfigScreenState();
}

class _InitialConfigScreenState extends State<InitialConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _professionController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userModel.displayName ?? '';
    _professionController.text = widget.userModel.personalization['profession'] as String? ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  /// Guarda los datos finales del perfil y marca el perfil como completo.
  Future<void> _saveAndFinish() async {
    if (!_isLoading && (_formKey.currentState?.validate() ?? false)) {
      setState(() => _isLoading = true);

      final firestoreService = context.read<FirestoreService>();
      final user = context.read<User?>();

      if (user == null) {
        _showSnackbar('Error: Sesión de usuario no válida.', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      final updatedPersonalization = Map<String, dynamic>.from(widget.userModel.personalization);
      
      updatedPersonalization['businessName'] = _nameController.text.trim();
      if (widget.userModel.role == 'provider' || widget.userModel.role == 'both') {
        updatedPersonalization['profession'] = _professionController.text.trim();
      }

      final dataToUpdate = {
        'displayName': _nameController.text.trim(), // Actualizamos el displayName principal
        'personalization': updatedPersonalization,
        'isProfileComplete': true,
      };

      try {
        await firestoreService.updateUser(user.uid, dataToUpdate);
        // El AuthWrapper se encargará de la navegación.
      } catch (e) {
        _showSnackbar('Error al finalizar el perfil: $e', isError: true);
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
        backgroundColor: isError ? Colors.redAccent : Colors.green.shade600,
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
        title: const Text('Configuración Inicial'),
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
                    'Último paso...',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Completa esta información para empezar a usar la aplicación.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70
                    ),
                  ),
                  const SizedBox(height: 40),

                  if (widget.userModel.role == 'provider' || widget.userModel.role == 'both')
                    _buildProviderForm()
                  else
                    _buildClientForm(),
                  
                  const SizedBox(height: 48),

                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _saveAndFinish,
                      style: FilledButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.black,
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24, width: 24,
                              child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black),
                            )
                          : const Text('Guardar y Finalizar'),
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

  // --- WIDGETS DE FORMULARIO REDISEÑADOS ---

  Widget _buildClientForm() {
    return _StyledTextFormField(
      controller: _nameController,
      labelText: 'Tu Nombre y Apellido',
      prefixIcon: Icons.person_outline_rounded,
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().length < 3) {
          return 'Por favor, ingresa un nombre válido.';
        }
        return null;
      },
    );
  }
  
  Widget _buildProviderForm() {
    return Column(
      children: [
        _StyledTextFormField(
          controller: _nameController,
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
          labelText: 'Profesión o Rubro Principal',
          prefixIcon: Icons.work_outline_rounded,
          textCapitalization: TextCapitalization.sentences,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor, ingresa tu profesión o rubro.';
            }
            return null;
          },
        ),
      ],
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
