/// lib/features/profile/screens/create_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  void dispose() {
    _displayNameController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  /// Valida el formulario y guarda los datos del perfil en Firestore.
  Future<void> _saveProfile() async {
    // Si no está cargando y el formulario es válido...
    if (!_isLoading && (_formKey.currentState?.validate() ?? false)) {
      setState(() => _isLoading = true);

      // Obtenemos los servicios y el UID del usuario actual.
      final firestoreService = context.read<FirestoreService>();
      final user = context.read<User?>();

      // Verificación de seguridad: el usuario debe estar logueado.
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No se encontró el usuario.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Creamos el mapa de datos a actualizar.
      final profileData = {
        'displayName': _displayNameController.text.trim(),
        'profession': _professionController.text.trim(),
        'isProfileComplete': true, // ¡La pieza clave!
      };

      try {
        // Llamamos al servicio para actualizar los datos.
        await firestoreService.updateUser(user.uid, profileData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil guardado con éxito.')),
        );

        // Si todo sale bien, cerramos la pantalla de perfil.
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el perfil: $e')),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completar Perfil'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Cuéntanos un poco sobre ti',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Esta información aparecerá en tus presupuestos y contratos.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),

                // --- Campo de Nombre y Apellido ---
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(labelText: 'Nombre y Apellido'),
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
                  decoration: const InputDecoration(labelText: 'Profesión o Rubro'),
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
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar Perfil'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}