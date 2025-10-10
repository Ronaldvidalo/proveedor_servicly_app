/// lib/features/onboarding/screens/initial_config_screen.dart
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';

/// Pantalla final del onboarding para recoger los datos mínimos según el rol.
class InitialConfigScreen extends StatefulWidget {
  const InitialConfigScreen({super.key});

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
    // Precargamos el nombre si viene de Google Sign-In.
    final userModel = context.read<UserModel?>();
    if (userModel != null) {
      _nameController.text = userModel.displayName ?? '';
    }
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
      final userModel = context.read<UserModel?>();

      if (user == null || userModel == null) {
        _showSnackbar('Error: Sesión de usuario no válida.', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      // Hacemos una copia del mapa de personalización para no perder datos.
      final updatedPersonalization = Map<String, dynamic>.from(userModel.personalization);
      
      // Actualizamos los campos según el rol.
      updatedPersonalization['businessName'] = _nameController.text.trim();
      if (userModel.role == 'provider' || userModel.role == 'both') {
        updatedPersonalization['profession'] = _professionController.text.trim();
      }

      final dataToUpdate = {
        'personalization': updatedPersonalization,
        'isProfileComplete': true, // ¡La pieza clave que activa el AuthWrapper!
      };

      try {
        await firestoreService.updateUser(user.uid, dataToUpdate);
        // No necesitamos navegar. El AuthWrapper lo hará por nosotros
        // al detectar el cambio en 'isProfileComplete'.
      } catch (e) {
        _showSnackbar('Error al finalizar el perfil: $e', isError: true);
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
      // El 'isLoading' no se revierte a 'false' en caso de éxito
      // porque la pantalla desaparecerá automáticamente.
    }
  }
  
  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos el UserModel para obtener el rol del usuario.
    final userModel = context.watch<UserModel?>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración Inicial'),
      ),
      body: userModel == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Último paso...',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Completa esta información para empezar.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 40),

                        // --- Campos del Formulario (condicionales al rol) ---
                        if (userModel.role == 'provider' || userModel.role == 'both')
                          _buildProviderForm()
                        else
                          _buildClientForm(),
                        
                        const SizedBox(height: 48),

                        // --- Botón de Guardar ---
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveAndFinish,
                            style: ElevatedButton.styleFrom(
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                                  )
                                : const Text('Guardar y Finalizar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  /// Construye los campos del formulario para el rol de Cliente.
  Widget _buildClientForm() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Tu Nombre y Apellido',
        prefixIcon: Icon(Icons.person_outline),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().length < 3) {
          return 'Por favor, ingresa un nombre válido.';
        }
        return null;
      },
    );
  }

  /// Construye los campos del formulario para el rol de Proveedor.
  Widget _buildProviderForm() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre de tu Negocio o Servicio',
            prefixIcon: Icon(Icons.business_center_outlined),
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
          decoration: const InputDecoration(
            labelText: 'Profesión o Rubro Principal',
            prefixIcon: Icon(Icons.work_outline),
          ),
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