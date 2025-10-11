/// lib/features/onboarding/screens/initial_config_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';

/// Pantalla final del onboarding para recoger los datos mínimos según el rol.
class InitialConfigScreen extends StatefulWidget {
  // CORRECCIÓN: Ahora esta pantalla ACEPTA el UserModel directamente en su constructor.
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
    // CORRECCIÓN: Usamos el UserModel que nos pasaron a través del widget,
    // en lugar de buscarlo en Provider. Esto elimina la race condition.
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

      // Usamos el modelo que ya tenemos (widget.userModel) para no perder datos.
      final updatedPersonalization = Map<String, dynamic>.from(widget.userModel.personalization);
      
      updatedPersonalization['businessName'] = _nameController.text.trim();
      if (widget.userModel.role == 'provider' || widget.userModel.role == 'both') {
        updatedPersonalization['profession'] = _professionController.text.trim();
      }

      final dataToUpdate = {
        'personalization': updatedPersonalization,
        'isProfileComplete': true, // ¡La pieza clave que activa el AuthWrapper!
      };

      try {
        await firestoreService.updateUser(user.uid, dataToUpdate);
        // No necesitamos navegar. El AuthWrapper se encargará de forma reactiva.
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
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green.shade600,
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
        title: const Text('Configuración Inicial'),
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
                    'Último paso...',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Completa esta información para empezar.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 40),

                  // CORRECCIÓN: Ahora la decisión de qué formulario mostrar se basa en 'widget.userModel.role'.
                  if (widget.userModel.role == 'provider' || widget.userModel.role == 'both')
                    _buildProviderForm()
                  else
                    _buildClientForm(),
                  
                  const SizedBox(height: 48),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveAndFinish,
                      style: ElevatedButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24, width: 24,
                              child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
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