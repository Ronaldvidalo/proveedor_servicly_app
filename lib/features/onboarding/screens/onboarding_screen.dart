// Archivo: lib/features/onboarding/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:audioplayers/audioplayers.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 

// --- Imports de Modelos y Servicios ---
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../shared/data/professions.dart';

// --- Imports de Navegación ---
import '../../home/screens/home_screen.dart'; 
import '../../public_profile/screens/presentation/screens/select_profile_template_screen.dart';

// --- IMPORTS DE LA IA (SERVI) ---
import 'package:proveedor_servicly_app/ai/services/voice_service.dart';
import 'package:proveedor_servicly_app/ai/widgets/servi_avatar.dart';

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

  // --- VARIABLES DE IA (SERVI) ---
  final ServiVoiceService _voiceService = ServiVoiceService();
  bool _isSpeaking = false;

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

    // 1. Escuchar estado de voz
    _voiceService.player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isSpeaking = state == PlayerState.playing);
      }
    });

    // 2. Bienvenida
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        String name = widget.userModel.displayName?.split(' ')[0] ?? "colega";
        if (name.isEmpty) name = "colega";
        _speak("¡Casi listo $name! Completa estos datos finales para personalizar tu experiencia inteligente.");
      }
    });
  }

  Future<void> _speak(String text) async {
    await _voiceService.speak(text);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _voiceService.dispose(); 
    super.dispose();
  }

  Future<void> _saveAndFinish() async {
    if (!_isLoading && (_formKey.currentState?.validate() ?? false)) {
      
      // --- VALIDACIONES ---
      if (_selectedRole == null) {
        _speak("Oye, olvidaste seleccionar tu rol. ¿Eres cliente o proveedor?");
        _showSnackbar('Debes seleccionar si eres Cliente o Proveedor.', isError: true);
        return;
      }
      if (_selectedCountry == null) {
        _speak("Necesito saber tu país para mostrarte precios en tu moneda.");
        _showSnackbar('Debes seleccionar tu país.', isError: true);
        return;
      }
      if (_selectedRole == 'provider' && _selectedProfession == null) {
         _speak("Si vas a ofrecer servicios, necesito saber tu profesión principal.");
         _showSnackbar('Como proveedor, debes seleccionar tu rubro principal.', isError: true);
        return;
      }

      setState(() => _isLoading = true);
      _speak("¡Perfecto! Configurando tu perfil. Iniciando motores.");

      final firestoreService = context.read<FirestoreService>();
      final user = context.read<User?>(); // Usuario de Auth

      if (user == null) {
        _showSnackbar('Error: Sesión de usuario no válida.', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // Referencias
      final userRef = firestore.collection('users').doc(user.uid);
      final brandRef = firestore.collection('brandProfiles').doc(user.uid);

      // --- 1. DATOS MAESTROS PARA 'USERS' (Cuenta y Seguridad) ---
      // Aquí NO va información pública de la tienda.
      batch.set(userRef, {
        'uid': user.uid,
        'email': user.email,
        'displayName': _nameController.text.trim(), // Nombre real de la persona
        'role': _selectedRole,
        'planType': 'free', // Plan por defecto
        'isProfileComplete': true,
        
        // Configuración por defecto
        'activeModules': _selectedRole == 'provider' 
            ? ['agenda', 'clients', 'orders-module'] // Módulos básicos + Pedidos
            : [],

        // Seguridad
        'isVerified': false, 
        'phoneVerified': false,
        'emailVerified': user.emailVerified, 
        'verificationStatus': 'unverified',
        'createdAt': FieldValue.serverTimestamp(),
        
        // Limpieza: Eliminamos campos legacy si existen (opcional)
        'personalization': FieldValue.delete(),
        'logoUrl': FieldValue.delete(),
        'businessName': FieldValue.delete(),
      }, SetOptions(merge: true));


      // --- 2. DATOS PARA 'BRANDPROFILES' (Solo si es PROVEEDOR) ---
      if (_selectedRole == 'provider') {
        batch.set(brandRef, {
          'providerId': user.uid,
          
          // Identidad Pública
          'businessName': _nameController.text.trim(), // Por defecto usa el nombre personal, luego pueden cambiarlo a marca
          'mainCategory': _selectedProfession,
          'country': _selectedCountry,
          
          // Estilo Visual (Valores por defecto Cyber Glow)
          'primaryColor': '#00BFFF', 
          'publicProfileTemplate': 'store',
          'publicProfileTheme': 'cyber_glow',
          'logoUrl': '',
          'slogan': '',
          
          // Datos de Contacto Públicos (Inicializados vacíos o con email de registro)
          'contactEmail': user.email, 
          'whatsapp': '',
          'instagram': '',
          'facebook': '',
          'address': '',
          'website': '',
          'welcomeMessage': '¡Bienvenidos a mi perfil profesional!',
          
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      try {
        // --- EJECUTAR ESCRITURA EN BATCH ---
        await batch.commit();

        // --- 3. CONFIGURAR FCM (OPCIONAL) ---
        try {
          if (kDebugMode) print("[Onboarding] Solicitando permiso notificaciones...");
          final messaging = FirebaseMessaging.instance;
          final settings = await messaging.requestPermission(provisional: true);
          
          if (settings.authorizationStatus == AuthorizationStatus.authorized) {
            final fcmToken = await messaging.getToken();
            if (fcmToken != null) {
              await firestoreService.saveDeviceToken(uid: user.uid, token: fcmToken);
            }
          }
        } catch (e) {
          debugPrint("Aviso: No se pudo configurar FCM en onboarding (no crítico): $e");
        }
        
        if (!mounted) return; 

        // --- 4. REDIRECCIÓN ---
        Widget destinationScreen;
        if (_selectedRole == 'provider') {
          // Si es proveedor -> Selección de Plantilla
          destinationScreen = SelectProfileTemplateScreen(user: widget.userModel);
        } else {
          // Si es cliente -> Home
          destinationScreen = const HomeScreen();
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => destinationScreen),
          (route) => false, 
        );

      } catch (e) {
        if (mounted) {
           _speak("Ups, hubo un error al guardar. Inténtalo de nuevo.");
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final inputDecorationTheme = theme.inputDecorationTheme;
    
    // Decoración base para inputs
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Configuración Inicial'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: ServiAvatar(
                isSpeaking: _isSpeaking, 
                size: 35,
                onTap: () => _speak("Completa los campos para que pueda personalizar la app para ti."),
              ),
            ),
          )
        ],
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
                      color: colorScheme.onSurface 
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Completa estos datos para personalizar tu experiencia.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7) // CORREGIDO
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
    return Row(
      children: [
        Expanded(child: _RoleSelectionCard(
          title: 'Soy Cliente',
          icon: Icons.shopping_bag_outlined,
          isSelected: _selectedRole == 'client',
          onTap: () {
             if (_selectedRole != 'client') _speak("Modo Cliente seleccionado.");
             setState(() => _selectedRole = 'client');
          },
          theme: theme,
        )),
        const SizedBox(width: 16),
        Expanded(child: _RoleSelectionCard(
          title: 'Soy Proveedor',
          icon: Icons.store_mall_directory_outlined,
          isSelected: _selectedRole == 'provider',
          onTap: () {
             if (_selectedRole != 'provider') _speak("Modo Proveedor seleccionado.");
             setState(() => _selectedRole = 'provider');
          },
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
      dropdownColor: theme.cardTheme.color,
      style: TextStyle(color: theme.colorScheme.onSurface), 
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
              Icon(profession['icon'] as IconData?, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)), // CORREGIDO
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
    final cardColor = theme.cardTheme.color;
    final accentColor = theme.primaryColor;
    final textColor = theme.colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.15) : cardColor, // CORREGIDO
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
              color: isSelected ? accentColor : textColor.withValues(alpha: 0.7) // CORREGIDO
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? theme.colorScheme.onSurface : textColor.withValues(alpha: 0.7), // CORREGIDO
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}