// lib/features/profile/screens/create_profile_screen.dart

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
    // Usamos 'read' para obtener los datos una sola vez al construir la pantalla.
    final userModel = context.read<UserModel?>();
    if (userModel != null) {
      // CORRECCIÓN: Leemos los datos desde el mapa 'personalization'.
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
      // CORRECCIÓN: Obtenemos el modelo actual para no sobreescribir otros datos de personalización.
      final currentUserModel = context.read<UserModel?>();

      if (user == null) {
        _showSnackbar('Error: Sesión de usuario no válida.', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      // CORRECCIÓN: Construimos el mapa de datos a actualizar de forma segura.
      // 1. Hacemos una copia del mapa de personalización existente.
      final updatedPersonalization = Map<String, dynamic>.from(currentUserModel?.personalization ?? {});
      
      // 2. Actualizamos los campos específicos que el usuario modificó en esta pantalla.
      updatedPersonalization['businessName'] = _displayNameController.text.trim();
      updatedPersonalization['profession'] = _professionController.text.trim();

      // 3. Este es el mapa final que enviaremos a Firestore.
      final dataToUpdate = {
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
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

                  // CORRECCIÓN: El campo ahora se llama 'Nombre de tu Negocio o Servicio'
                  TextFormField(
                    controller: _displayNameController,
                    decoration: _buildInputDecoration(
                      context,
                      labelText: 'Nombre de tu Negocio o Servicio',
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

  InputDecoration _buildInputDecoration(BuildContext context, {required String labelText, required IconData prefixIcon}) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: labelText,
      // CORRECCIÓN: 'withOpacity' deprecado, se usa 'withAlpha'.
      prefixIcon: Icon(prefixIcon, color: theme.colorScheme.onSurface.withAlpha(153)), // alpha 153 es ~60% opacidad
      filled: true,
      fillColor: theme.colorScheme.onSurface.withAlpha(13), // alpha 13 es ~5% opacidad
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