/// lib/features/profile/screens/create_profile_screen.dart
library;

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

  // --- MEJORA DE UX: AUTOCOMPLETADO DE DATOS ---
  // Se autocompletan los campos con la información existente del usuario.
  @override
  void initState() {
    super.initState();
    // Usamos 'read' para obtener los datos una sola vez al construir la pantalla.
    final userModel = context.read<UserModel?>();
    if (userModel != null) {
      _displayNameController.text = userModel.displayName ?? '';
      _professionController.text = userModel.profession ?? '';
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

      if (user == null) {
        _showSnackbar('Error: Sesión de usuario no válida.', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      final profileData = {
        'displayName': _displayNameController.text.trim(),
        'profession': _professionController.text.trim(),
        'isProfileComplete': true,
      };

      try {
        await firestoreService.updateUser(user.uid, profileData);
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

  // --- MEJORA DE UI: SNACKBAR ESTILIZADO ---
  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completar Perfil'),
        // UI Polish: Un AppBar más limpio sin elevación por defecto
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Center( // <-- DISEÑO RESPONSIVO: Centra el contenido
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox( // <-- DISEÑO RESPONSIVO: Limita el ancho
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Cuéntanos un poco sobre ti',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Esta información aparecerá en tus presupuestos y contratos.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- Campo de Nombre y Apellido ---
                  TextFormField(
                    controller: _displayNameController,
                    decoration: _buildInputDecoration(
                      context,
                      labelText: 'Nombre y Apellido',
                      prefixIcon: Icons.person_outline,
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().length < 3) {
                        return 'Por favor, ingresa un nombre válido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // --- Campo de Profesión ---
                  TextFormField(
                    controller: _professionController,
                    decoration: _buildInputDecoration(
                      context,
                      labelText: 'Profesión o Rubro',
                      prefixIcon: Icons.work_outline,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                     validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, ingresa tu profesión o rubro.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 48),

                  // --- Botón de Guardar ---
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
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

  // --- MEJORA DE UI: DECORACIÓN DE INPUT REUTILIZABLE ---
  InputDecoration _buildInputDecoration(BuildContext context, {required String labelText, required IconData prefixIcon}) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(prefixIcon, color: theme.colorScheme.onSurface.withOpacity(0.6)),
      // Usamos los colores del tema de la app en lugar de valores hardcodeados
      filled: true,
      fillColor: theme.colorScheme.onSurface.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.primaryColor, width: 2),
      ),
    );
  }
}