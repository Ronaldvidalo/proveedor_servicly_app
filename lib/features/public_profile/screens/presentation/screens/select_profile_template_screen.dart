// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart'; // Audio control

// --- Models and Services ---
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart'; 
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';

// --- Navigation ---
import 'package:proveedor_servicly_app/features/settings/screens/brand_settings_screen.dart';

// --- IA Servi ---
import 'package:proveedor_servicly_app/ai/services/voice_service.dart';
import 'package:proveedor_servicly_app/ai/widgets/servi_avatar.dart';

/// A screen where users choose a template for their public profile.
class SelectProfileTemplateScreen extends StatefulWidget {
  /// The current user model.
  final UserModel user;
  
  /// Determines if we are creating a fresh new profile (multi-tenant)
  final bool isNewProfile;

  const SelectProfileTemplateScreen({
    super.key, 
    required this.user,
    this.isNewProfile = false, // Default: False (Legacy/Edit mode)
  });

  @override
  State<SelectProfileTemplateScreen> createState() => _SelectProfileTemplateScreenState();
}

class _SelectProfileTemplateScreenState extends State<SelectProfileTemplateScreen> {
  // --- AI AND STATE VARIABLES ---
  final ServiVoiceService _voiceService = ServiVoiceService();
  bool _isSpeaking = false;
  String? _selectedTemplateId; 
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // 1. Listener to animate avatar when speaking
    _voiceService.player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isSpeaking = state == PlayerState.playing);
      }
    });

    // 2. INITIAL EXPLANATION BY AI
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _speak(widget.isNewProfile 
            ? "Vamos a crear una nueva sucursal. ¿Qué formato tendrá esta tienda?" 
            : "Último paso. ¿Qué formato prefieres? Elige 'Tienda' o 'Catálogo'.");
      }
    });
  }

  Future<void> _speak(String text) async {
    await _voiceService.speak(text);
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }

  /// Saves the selection and navigates to brand settings
  Future<void> _confirmAndNavigate() async {
    if (_selectedTemplateId == null) {
      _speak("Por favor, selecciona una opción para continuar.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona una plantilla primero."))
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final firestore = context.read<FirestoreService>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      try {
        // --- LOGICA DE CREACIÓN NUEVA (MULTI-TENANT) ---
        if (widget.isNewProfile) {
           await _speak("¡Perfecto! Creando nueva tienda...");
           await Future.delayed(const Duration(milliseconds: 500));

           if (!mounted) return;

           // Navegamos directamente a BrandSettings pasando NULL en brandProfile
           // y pasando el template seleccionado.
           Navigator.of(context).pushReplacement(
             MaterialPageRoute(
               builder: (_) => BrandSettingsScreen(
                 user: widget.user,
                 brandProfile: null, // <--- ESTO ES LA CLAVE PARA "NUEVO"
                 initialTemplate: _selectedTemplateId, // Pasamos la elección
               ),
             ),
           );
           return;
        }

        // --- LÓGICA ORIGINAL (LEGACY / PRIMER PERFIL) ---
        
        // 1. We update the User in Firestore (Solo para el perfil principal)
        await firestore.updateUser(uid, {
          'publicProfileTemplate': _selectedTemplateId,
          'publicProfileCreated': true, 
        });

        // 2. Fetch data from DB (Legacy)
        ProviderProfileModel? currentProfile = await firestore.getProviderPublicProfile(uid);
        
        // Fix: Ensure object exists with ID
        currentProfile ??= ProviderProfileModel(
            id: uid, 
            providerId: uid,
            businessName: widget.user.displayName ?? 'Mi Negocio', 
            logoUrl: '',
            brandColor: Colors.blue,
            activeModules: const [],
            profileType: _selectedTemplateId!,
            contactEmail: widget.user.email ?? '',
            welcomeMessage: '¡Bienvenidos!',
            publicProfileTemplate: _selectedTemplateId,
          );
        
        if (currentProfile.publicProfileTemplate != _selectedTemplateId) {
           currentProfile = currentProfile.copyWith(publicProfileTemplate: _selectedTemplateId);
        }

        if (!mounted) return;

        // Final Feedback
        await _speak("¡Excelente elección! Ahora personalicemos tu marca.");
        await Future.delayed(const Duration(milliseconds: 1000));

        if (!mounted) return;

        // 3. Navigate
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => BrandSettingsScreen(
              user: widget.user,
              brandProfile: currentProfile!, 
            ),
          ),
        );

      } catch (e) {
        debugPrint("Error saving template or navigating: $e");
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
           setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Elige una Plantilla'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: !widget.isNewProfile, // Si es nuevo, permitimos volver atrás
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: ServiAvatar(
                isSpeaking: _isSpeaking,
                size: 40,
                onTap: () => _speak("La Tienda tiene carrito y pagos. El Catálogo es para que te contacten."),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  'Selecciona cómo quieres presentar tus servicios a tus clientes.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7)
                  ),
                ),
                const SizedBox(height: 24),
                
                // CV
                _TemplateOptionCard(
                  icon: Icons.person_outline,
                  title: 'Perfil Profesional (CV)',
                  description: 'Ideal para freelancers y consultores. Muestra tu experiencia.',
                  templateId: 'cv',
                  isSelected: _selectedTemplateId == 'cv',
                  onTap: (id) {
                    _speak("Perfil Profesional. Perfecto para mostrar quién eres y tu experiencia.");
                    setState(() => _selectedTemplateId = id);
                  },
                ),

                // STORE
                _TemplateOptionCard(
                  icon: Icons.store_outlined,
                  title: 'Tienda de Servicios',
                  description: 'Ventas directas con carrito. Ideal para productos o paquetes fijos.',
                  templateId: 'store',
                  isSelected: _selectedTemplateId == 'store',
                  onTap: (id) {
                    _speak("Tienda de Servicios. Incluye carrito de compras y precios fijos.");
                    setState(() => _selectedTemplateId = id);
                  },
                ),

                // CATALOG
                _TemplateOptionCard(
                  icon: Icons.collections_bookmark_outlined,
                  title: 'Catálogo de Servicios',
                  description: 'Muestra tus trabajos y recibe pedidos de cotización por WhatsApp.',
                  templateId: 'catalog',
                  isSelected: _selectedTemplateId == 'catalog',
                  onTap: (id) {
                    _speak("Catálogo. Muestra lo que haces y deja que te contacten para cotizar.");
                    setState(() => _selectedTemplateId = id);
                  },
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isLoading ? null : _confirmAndNavigate,
                child: _isLoading 
                  ? SizedBox(
                      height: 24, width: 24, 
                      child: CircularProgressIndicator(color: theme.colorScheme.onPrimary, strokeWidth: 2)
                    )
                  : const Text("Continuar"),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _TemplateOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String templateId;
  final bool isSelected;
  final Function(String) onTap;

  const _TemplateOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.templateId,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final borderColor = isSelected ? colorScheme.primary : theme.dividerColor;
    final bgColor = isSelected ? colorScheme.primary.withValues(alpha: 0.08) : theme.cardTheme.color;

    return Card(
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: isSelected ? 2 : 1),
      ),
      color: bgColor,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onTap(templateId),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : theme.scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon, 
                  size: 30, 
                  color: isSelected ? colorScheme.onPrimary : colorScheme.primary
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title, 
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                      )
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description, 
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8)
                      )
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: colorScheme.primary, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}