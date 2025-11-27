// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 20/10/2025
// Style: Cyber Glow (Adaptive Light/Dark)
// QA FIX 26/11/2025:
// 1. Eliminados colores hardcoded. Ahora usa ThemeService para modo claro/oscuro.
// 2. Validaciones y lógica de negocio FCM preservadas.
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../shared/data/professions.dart';

import '../../home/screens/home_screen.dart'; 
import '../../dashboard/screens/dashboard_screen.dart'; 

class OnboardingScreen extends StatefulWidget {
  final UserModel userModel;
  const OnboardingScreen({super.key, required this.userModel});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  String? _selectedRole;
  String? _selectedCountry;
  String? _selectedProfession;
  bool _isLoading = false;

  final List<Map<String, String>> _countries = [
    {'code': 'AR', 'name': 'Argentina'}, {'code': 'BO', 'name': 'Bolivia'},
    {'code': 'BR', 'name': 'Brasil'}, {'code': 'CL', 'name': 'Chile'},
    {'code': 'CO', 'name': 'Colombia'}, {'code': 'EC', 'name': 'Ecuador'},
    {'code': 'PY', 'name': 'Paraguay'}, {'code': 'PE', 'name': 'Perú'},
    {'code': 'UY', 'name': 'Uruguay'}, {'code': 'VE', 'name': 'Venezuela'},
    {'code': 'ES', 'name': 'España'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userModel.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveAndFinish() async {
    if (!_isLoading && (_formKey.currentState?.validate() ?? false)) {
      if (_selectedRole == null) {
        _showSnackbar('Debes seleccionar si eres Cliente o Proveedor.', isError: true);
        return;
      }
      if (_selectedCountry == null) {
        _showSnackbar('Debes seleccionar tu país.', isError: true);
        return;
      }
      if (_selectedRole == 'provider' && _selectedProfession == null) {
         _showSnackbar('Como proveedor, debes seleccionar tu rubro principal.', isError: true);
        return;
      }

      if (kDebugMode) print("[Onboarding] Solicitando permiso de notificaciones...");
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false, 
      );
      
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
      updatedPersonalization['country'] = _selectedCountry;
      if (_selectedRole == 'provider') {
        updatedPersonalization['mainCategory'] = _selectedProfession;
      }

      final dataToUpdate = {
        'displayName': _nameController.text.trim(),
        'personalization': updatedPersonalization,
        'role': _selectedRole,
        'isProfileComplete': true,
      };

      try {
        await firestoreService.updateUser(user.uid, dataToUpdate);

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          final fcmToken = await messaging.getToken();
          if (fcmToken != null) {
            await firestoreService.saveDeviceToken(uid: user.uid, token: fcmToken);
          }
        }
        
        if (!mounted) return; 

        Widget destinationScreen;
        if (_selectedRole == 'provider') {
          destinationScreen = const DashboardScreen();
        } else {
          destinationScreen = const HomeScreen();
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => destinationScreen),
          (route) => false, 
        );

      } catch (e) {
        if (mounted) {
           _showSnackbar('Error al finalizar el perfil: $e', isError: true);
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
    // QA FIX: Usar colores del tema
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Decoración base para inputs (extraída del tema)
    final inputDecorationTheme = theme.inputDecorationTheme;
    final inputDecoration = InputDecoration(
        filled: true,
        fillColor: inputDecorationTheme.fillColor,
        labelStyle: inputDecorationTheme.labelStyle,
        prefixIconColor: inputDecorationTheme.prefixIconColor,
        border: inputDecorationTheme.border,
        focusedBorder: inputDecorationTheme.focusedBorder,
        enabledBorder: inputDecorationTheme.enabledBorder,
    );
    
    return Scaffold(
      // QA FIX: Fondo dinámico
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Configuración Inicial'),
        elevation: 0,
        // AppBar transparente pero adaptable
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        automaticallyImplyLeading: false,
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
                  Text(
                    '¡Casi listo!',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold, 
                      color: colorScheme.onSurface // Texto dinámico
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Completa estos datos para personalizar tu experiencia.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7)
                    ),
                  ),
                  const SizedBox(height: 40),

                  _buildSectionTitle('1. Elige tu rol en Servicly', theme),
                  const SizedBox(height: 16),
                  _buildRoleSelector(theme),

                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: _selectedRole != null ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 32),
                        _buildSectionTitle('2. Completa tu perfil', theme),
                        const SizedBox(height: 24),
                        _buildCountrySelector(inputDecoration, theme),
                        const SizedBox(height: 24),
                        _buildNameField(inputDecoration, theme),
                        if (_selectedRole == 'provider') ...[
                           const SizedBox(height: 24),
                          _buildProfessionSelector(inputDecoration, theme),
                        ],
                        const SizedBox(height: 48),
                        _buildSaveButton(theme),
                      ],
                    ) : const SizedBox.shrink(),
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
  
  Text _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title, 
      style: theme.textTheme.titleLarge?.copyWith(
        color: theme.colorScheme.onSurface, 
        fontWeight: FontWeight.bold
      )
    );
  }

  Row _buildRoleSelector(ThemeData theme) {
    final accentColor = theme.primaryColor;
    return Row(
      children: [
        Expanded(child: _RoleSelectionCard(
          title: 'Soy Cliente',
          icon: Icons.shopping_bag_outlined,
          isSelected: _selectedRole == 'client',
          onTap: () => setState(() => _selectedRole = 'client'),
          theme: theme,
        )),
        const SizedBox(width: 16),
        Expanded(child: _RoleSelectionCard(
          title: 'Soy Proveedor',
          icon: Icons.store_mall_directory_outlined,
          isSelected: _selectedRole == 'provider',
          onTap: () => setState(() => _selectedRole = 'provider'),
          theme: theme,
        )),
      ],
    );
  }

  DropdownButtonFormField<String> _buildCountrySelector(InputDecoration baseDecoration, ThemeData theme) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCountry,
      decoration: baseDecoration.copyWith(
        labelText: 'País', 
        prefixIcon: Icon(Icons.public, color: theme.inputDecorationTheme.prefixIconColor)
      ),
      // QA FIX: Dropdown con fondo de tarjeta del tema
      dropdownColor: theme.cardTheme.color,
      style: TextStyle(color: theme.colorScheme.onSurface), // Texto de items dinámico
      items: _countries.map((country) {
        return DropdownMenuItem(value: country['code'], child: Text(country['name']!));
      }).toList(),
      onChanged: (value) => setState(() => _selectedCountry = value),
      validator: (value) => value == null ? 'Debes seleccionar un país' : null,
    );
  }

  TextFormField _buildNameField(InputDecoration baseDecoration, ThemeData theme) {
    final isProvider = _selectedRole == 'provider';
    return TextFormField(
      controller: _nameController,
      // QA FIX: Texto de input dinámico
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: baseDecoration.copyWith(
        labelText: isProvider ? 'Nombre de tu Negocio o Marca' : 'Tu Nombre y Apellido',
        prefixIcon: Icon(
          isProvider ? Icons.business_center_outlined : Icons.person_outline_rounded,
          color: theme.inputDecorationTheme.prefixIconColor
        ),
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

  DropdownButtonFormField<String> _buildProfessionSelector(InputDecoration baseDecoration, ThemeData theme) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedProfession,
      decoration: baseDecoration.copyWith(
        labelText: 'Rubro Principal', 
        prefixIcon: Icon(Icons.work_outline_rounded, color: theme.inputDecorationTheme.prefixIconColor)
      ),
      dropdownColor: theme.cardTheme.color,
      style: TextStyle(color: theme.colorScheme.onSurface),
      items: kProfessions.map((profession) {
        return DropdownMenuItem(
          value: profession['label'] as String,
          child: Row(
            children: [
              Icon(profession['icon'] as IconData?, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
              const SizedBox(width: 12),
              Text(profession['label'] as String),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedProfession = value),
      validator: (value) => value == null ? 'Debes seleccionar tu rubro' : null,
    );
  }

  SizedBox _buildSaveButton(ThemeData theme) {
    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: _isLoading ? null : _saveAndFinish,
        // El estilo viene del tema, pero podemos forzar overrides si queremos
        child: _isLoading
            ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: theme.colorScheme.onPrimary))
            : const Text('Guardar y Finalizar'),
      ),
    );
  }
}

class _RoleSelectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  const _RoleSelectionCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // QA FIX: Usar colores del tema para la tarjeta
    final cardColor = theme.cardTheme.color;
    final accentColor = theme.primaryColor;
    final textColor = theme.colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.15) : cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon, 
              size: 32, 
              color: isSelected ? accentColor : textColor.withValues(alpha: 0.7)
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? theme.colorScheme.onSurface : textColor.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}