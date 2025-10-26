import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Para kDebugMode
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../shared/data/professions.dart';

// --- NUEVAS IMPORTACIONES PARA NAVEGACIÓN MANUAL ---
import '../../home/screens/home_screen.dart'; // Para clientes
import '../../dashboard/screens/dashboard_screen.dart'; // Para proveedores

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
      // ... (Validaciones de rol, país, etc. se mantienen) ...
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

      // --- LÓGICA FCM (PASO 1): SOLICITAR PERMISOS ---
      if (kDebugMode) print("[Onboarding] Solicitando permiso de notificaciones...");
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false, 
      );
      if (kDebugMode) print("[Onboarding] Estado del permiso: ${settings.authorizationStatus}");
      // -------------------------------------------------
      
      setState(() => _isLoading = true);

      final firestoreService = context.read<FirestoreService>();
      final user = context.read<User?>();

      if (user == null) {
        _showSnackbar('Error: Sesión de usuario no válida.', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      // ... (Creación de updatedPersonalization y dataToUpdate se mantiene igual) ...
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
        // --- LÓGICA FCM (PASO 2): GUARDAR PERFIL Y TOKEN ---
        
        // 1. Guardar el perfil del usuario
        await firestoreService.updateUser(user.uid, dataToUpdate);
        if (kDebugMode) print("[Onboarding] Perfil guardado exitosamente.");

        // 2. Si el usuario dio permiso, obtener y guardar el token FCM
        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          if (kDebugMode) print("[Onboarding] Intentando obtener y guardar token FCM...");
          final fcmToken = await messaging.getToken();
          if (fcmToken != null) {
            await firestoreService.saveDeviceToken(uid: user.uid, token: fcmToken);
          } else {
             if (kDebugMode) print("[Onboarding] No se pudo obtener el token FCM esta vez.");
          }
        } else {
           if (kDebugMode) print("[Onboarding] Permiso de notificación no concedido. Saltando guardado de token.");
        }
        
        // --- SOLUCIÓN: NAVEGACIÓN MANUAL ---
        // Ya que el guardado fue exitoso, navegamos manualmente
        // a la pantalla correcta y limpiamos el stack.
        
        if (!mounted) return; // Comprobación de seguridad final

        // Determinamos la pantalla de destino según el rol guardado
        Widget destinationScreen;
        if (_selectedRole == 'provider') {
          destinationScreen = const DashboardScreen();
        } else {
          destinationScreen = const HomeScreen();
        }

        // Usamos pushAndRemoveUntil para limpiar la pila de navegación.
        // Esto previene que el usuario pueda presionar "atrás" y volver aquí.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => destinationScreen),
          (route) => false, // Esta condición elimina todas las rutas anteriores
        );
        // --- FIN DE LA SOLUCIÓN ---

      } catch (e) {
        // Si hay un error, SÍ nos quedamos en esta pantalla
        if (mounted) {
           _showSnackbar('Error al finalizar el perfil: $e', isError: true);
           setState(() => _isLoading = false); // Detenemos el spinner
        }
      }
      // Se elimina el bloque 'finally'. La navegación (éxito)
      // o el 'catch' (error) manejan el estado _isLoading.
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

  // ... (El resto de tu método `build` y widgets auxiliares 
  // _buildSectionTitle, _buildRoleSelector, etc. se quedan EXACTAMENTE IGUAL) ...
  // (El código ha sido omitido de esta respuesta por brevedad,
  // pero está completo en el Canvas)
  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);

    final inputDecoration = InputDecoration(
        filled: true,
        fillColor: surfaceColor,
        labelStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accentColor, width: 2)),
      );
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Configuración Inicial'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
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
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Completa estos datos para personalizar tu experiencia.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 40),

                  _buildSectionTitle('1. Elige tu rol en Servicly'),
                  const SizedBox(height: 16),
                  _buildRoleSelector(accentColor),

                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: _selectedRole != null ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 32),
                        _buildSectionTitle('2. Completa tu perfil'),
                        const SizedBox(height: 24),
                        _buildCountrySelector(inputDecoration),
                        const SizedBox(height: 24),
                        _buildNameField(inputDecoration),
                        if (_selectedRole == 'provider') ...[
                           const SizedBox(height: 24),
                          _buildProfessionSelector(inputDecoration),
                        ],
                        const SizedBox(height: 48),
                        _buildSaveButton(accentColor),
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
  
  Text _buildSectionTitle(String title) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold));
  }

  Row _buildRoleSelector(Color accentColor) {
    return Row(
      children: [
        Expanded(child: _RoleSelectionCard(
          title: 'Soy Cliente',
          icon: Icons.shopping_bag_outlined,
          isSelected: _selectedRole == 'client',
          onTap: () => setState(() => _selectedRole = 'client'),
          accentColor: accentColor,
        )),
        const SizedBox(width: 16),
        Expanded(child: _RoleSelectionCard(
          title: 'Soy Proveedor',
          icon: Icons.store_mall_directory_outlined,
          isSelected: _selectedRole == 'provider',
          onTap: () => setState(() => _selectedRole = 'provider'),
          accentColor: accentColor,
        )),
      ],
    );
  }

  DropdownButtonFormField<String> _buildCountrySelector(InputDecoration baseDecoration) {
    return DropdownButtonFormField<String>(
      value: _selectedCountry,
      decoration: baseDecoration.copyWith(labelText: 'País', prefixIcon: const Icon(Icons.public)),
      dropdownColor: const Color(0xFF2D2D5A),
      style: const TextStyle(color: Colors.white),
      items: _countries.map((country) {
        return DropdownMenuItem(value: country['code'], child: Text(country['name']!));
      }).toList(),
      onChanged: (value) => setState(() => _selectedCountry = value),
      validator: (value) => value == null ? 'Debes seleccionar un país' : null,
    );
  }

  TextFormField _buildNameField(InputDecoration baseDecoration) {
    final isProvider = _selectedRole == 'provider';
    return TextFormField(
      controller: _nameController,
      style: const TextStyle(color: Colors.white),
      decoration: baseDecoration.copyWith(
        labelText: isProvider ? 'Nombre de tu Negocio o Marca' : 'Tu Nombre y Apellido',
        prefixIcon: Icon(isProvider ? Icons.business_center_outlined : Icons.person_outline_rounded),
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

  DropdownButtonFormField<String> _buildProfessionSelector(InputDecoration baseDecoration) {
    return DropdownButtonFormField<String>(
      value: _selectedProfession,
      decoration: baseDecoration.copyWith(labelText: 'Rubro Principal', prefixIcon: const Icon(Icons.work_outline_rounded)),
      dropdownColor: const Color(0xFF2D2D5A),
      style: const TextStyle(color: Colors.white),
      items: kProfessions.map((profession) {
        return DropdownMenuItem(
          value: profession['label'] as String,
          child: Row(
            children: [
              Icon(profession['icon'] as IconData?, size: 20, color: Colors.white70),
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

  SizedBox _buildSaveButton(Color accentColor) {
    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: _isLoading ? null : _saveAndFinish,
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        child: _isLoading
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black))
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
  final Color accentColor;

  const _RoleSelectionCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Color(0xFF2D2D5A);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withAlpha(50) : surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? accentColor : Colors.white70),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

