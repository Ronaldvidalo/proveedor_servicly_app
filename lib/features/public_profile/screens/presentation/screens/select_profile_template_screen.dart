import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart'; // Control de audio

// --- Modelos y Servicios ---
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';

// --- Navegación ---
import 'package:proveedor_servicly_app/features/settings/screens/brand_settings_screen.dart';

// --- IA Servi ---
import 'package:proveedor_servicly_app/ai/services/voice_service.dart';
import 'package:proveedor_servicly_app/ai/widgets/servi_avatar.dart';

/// Una pantalla donde los usuarios eligen una plantilla para su perfil público.
class SelectProfileTemplateScreen extends StatefulWidget {
  /// El modelo del usuario actual.
  final UserModel user;

  const SelectProfileTemplateScreen({super.key, required this.user});

  @override
  State<SelectProfileTemplateScreen> createState() => _SelectProfileTemplateScreenState();
}

class _SelectProfileTemplateScreenState extends State<SelectProfileTemplateScreen> {
  // --- VARIABLES DE IA Y ESTADO ---
  final ServiVoiceService _voiceService = ServiVoiceService();
  bool _isSpeaking = false;
  String? _selectedTemplateId; // Para saber cuál está seleccionada
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // 1. Listener para animar al avatar cuando habla
    _voiceService.player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isSpeaking = state == PlayerState.playing);
      }
    });

    // 2. EXPLICACIÓN INICIAL DE LA IA (La diferencia clave)
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _speak("Último paso. ¿Qué formato prefieres? Elige 'Tienda' si vendes productos con carrito de compras, o 'Catálogo' si ofreces servicios y prefieres cotizaciones por WhatsApp.");
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

  /// Guarda la selección y navega a la configuración de marca
  Future<void> _confirmAndNavigate() async {
    if (_selectedTemplateId == null) {
      _speak("Por favor, selecciona una opción para continuar.");
      return;
    }

    setState(() => _isLoading = true);
    
    // Opcional: Guardar la selección en Firestore antes de avanzar
    final firestore = context.read<FirestoreService>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      try {
        await firestore.updateUser(uid, {
          'profileTemplate': _selectedTemplateId,
          'publicProfileCreated': true, // Marcamos el hito
        });
      } catch (e) {
        debugPrint("Error guardando template: $e");
      }
    }

    if (!mounted) return;

    // Feedback final
    await _speak("¡Excelente elección! Ahora personalicemos tu marca.");
    
    // Pequeña pausa para que se escuche el feedback
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BrandSettingsScreen(
          user: widget.user,
          // initialTemplateId: _selectedTemplateId, // Si tu BrandSettings lo soporta
        ),
      ),
    );
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
        automaticallyImplyLeading: false, // Quitamos botón atrás para obligar flujo
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
                
                // OPCIÓN 1: PERFIL PROFESIONAL
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

                // OPCIÓN 2: TIENDA (STORE)
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

                // OPCIÓN 3: CATÁLOGO
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
          
          // BOTÓN DE CONFIRMACIÓN
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

/// Widget para una tarjeta de opción de plantilla con estado de selección.
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