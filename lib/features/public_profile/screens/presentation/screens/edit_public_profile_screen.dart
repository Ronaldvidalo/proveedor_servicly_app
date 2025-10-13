import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';

/// Una pantalla para que el proveedor complete los detalles de su perfil público
/// basado en la plantilla seleccionada.
class EditPublicProfileScreen extends StatefulWidget {
  final String templateId;
  // --- MODIFICACIÓN: Aceptamos el UserModel directamente ---
  final UserModel user;

  const EditPublicProfileScreen({
    super.key, 
    required this.templateId,
    required this.user,
  });

  @override
  State<EditPublicProfileScreen> createState() => _EditPublicProfileScreenState();
}

class _EditPublicProfileScreenState extends State<EditPublicProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controladores para los campos del formulario
  late final TextEditingController _businessNameController;
  late final TextEditingController _welcomeMessageController;
  late final TextEditingController _contactEmailController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    // Usamos el UserModel que recibimos por el constructor.
    final personalization = widget.user.personalization;

    _businessNameController = TextEditingController(text: personalization['businessName'] as String? ?? '');
    _welcomeMessageController = TextEditingController(text: personalization['welcomeMessage'] as String? ?? '');
    _contactEmailController = TextEditingController(text: personalization['contactEmail'] as String? ?? widget.user.email ?? '');
    _addressController = TextEditingController(text: personalization['address'] as String? ?? '');
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _welcomeMessageController.dispose();
    _contactEmailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Procesa y guarda los datos del perfil en Firestore.
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final firestoreService = context.read<FirestoreService>();
    // --- MODIFICACIÓN: Ya no necesitamos leer el usuario del contexto ---
    final user = widget.user;

    final updatedPersonalization = {
      'businessName': _businessNameController.text.trim(),
      'welcomeMessage': _welcomeMessageController.text.trim(),
      'contactEmail': _contactEmailController.text.trim(),
      'address': _addressController.text.trim(),
    };
    
    final finalPersonalization = {...user.personalization, ...updatedPersonalization};

    try {
      await firestoreService.updateUser(user.uid, {'personalization': finalPersonalization});
      await firestoreService.setPublicProfileTemplate(
        userId: user.uid,
        templateId: widget.templateId,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡Perfil público creado con la plantilla "${widget.templateId}"!')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ocurrió un error al guardar el perfil.')),
        );
      }
    } finally {
       if (mounted) {
         setState(() => _isLoading = false);
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configurar Perfil "${widget.templateId}"'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            _buildGenericForm(),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FilledButton.icon(
                    icon: const Icon(Icons.save_alt_rounded),
                    label: const Text('Guardar y Publicar'),
                    onPressed: _saveProfile,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenericForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Completa la información que verán tus clientes.',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _businessNameController,
          decoration: const InputDecoration(
            labelText: 'Nombre de tu Negocio o Profesional',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business_center_outlined),
          ),
          validator: (value) => (value == null || value.isEmpty) ? 'Este campo es requerido' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _welcomeMessageController,
          decoration: const InputDecoration(
            labelText: 'Mensaje de Bienvenida',
            hintText: 'Ej: ¡Hola! Bienvenido a mi espacio de servicios.',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.message_outlined),
          ),
          maxLines: 3,
           validator: (value) => (value == null || value.isEmpty) ? 'Este campo es requerido' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _contactEmailController,
          decoration: const InputDecoration(
            labelText: 'Email de Contacto Público',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email_outlined),
          ),
           keyboardType: TextInputType.emailAddress,
           validator: (value) {
            if (value == null || value.isEmpty) return 'Este campo es requerido';
            if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) return 'Ingresa un email válido';
            return null;
           },
        ),
         const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Dirección (Opcional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
      ],
    );
  }
}

