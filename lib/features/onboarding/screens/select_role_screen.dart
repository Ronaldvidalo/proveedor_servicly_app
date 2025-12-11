// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 14/10/2025
// Style: Cyber Glow (Adaptive Light/Dark)
// QA FIX 26/11/2025:
// 1. Refactorización completa para eliminar colores hardcoded.
// 2. Adaptación a Modo Claro/Oscuro usando ThemeService.
// 3. INTEGRACIÓN IA SERVI (10/12/2025): Voz y Avatar añadidos.
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart'; // Control de estado de audio

// --- Imports de Servicios ---
import '../../../core/services/firestore_service.dart';

// --- IMPORTS DE LA IA (SERVI) ---
import 'package:proveedor_servicly_app/ai/services/voice_service.dart';
import 'package:proveedor_servicly_app/ai/widgets/servi_avatar.dart';

/// Pantalla donde el nuevo usuario elige su rol principal en la plataforma.
class SelectRoleScreen extends StatefulWidget {
  const SelectRoleScreen({super.key});

  @override
  State<SelectRoleScreen> createState() => _SelectRoleScreenState();
}

class _SelectRoleScreenState extends State<SelectRoleScreen> {
  String? _loadingRole;

  // --- VARIABLES DE IA (SERVI) ---
  final ServiVoiceService _voiceService = ServiVoiceService();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    
    // 1. Escuchar cuando Servi habla para animar el avatar
    _voiceService.player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isSpeaking = state == PlayerState.playing);
      }
    });

    // 2. Bienvenida de la IA (Con delay para que la UI cargue primero)
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _speak("¿Cuál es tu misión hoy? Selecciona 'Soy Proveedor' si vas a trabajar, o 'Busco un Servicio' si quieres contratar a un experto.");
      }
    });
  }

  Future<void> _speak(String text) async {
    await _voiceService.speak(text);
  }

  @override
  void dispose() {
    _voiceService.dispose(); // Importante liberar recursos
    super.dispose();
  }

  Future<void> _selectRole(String role) async {
    if (_loadingRole != null) return;

    setState(() => _loadingRole = role);

    final firestoreService = context.read<FirestoreService>();
    final user = context.read<User?>();

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Sesión de usuario no válida.')),
        );
      }
      setState(() => _loadingRole = null);
      return;
    }

    try {
      // Feedback auditivo sutil antes de guardar
      if (role == 'provider') {
        _speak("Entendido. Vamos a configurar tu negocio.");
      } else {
        _speak("Perfecto. Vamos a buscar a los mejores profesionales.");
      }

      await firestoreService.updateUser(user.uid, {'role': role});
      // AuthWrapper maneja la navegación automáticamente al detectar el cambio en Firestore
    } catch (e) {
      if (mounted) {
        _speak("Ups, hubo un problema al guardar tu selección.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el rol: $e')),
        );
        setState(() => _loadingRole = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // QA FIX: Usar tema del contexto
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // 1. Fondo dinámico (Gris claro / Azul Oscuro)
      backgroundColor: theme.scaffoldBackgroundColor,
      
      // 2. AppBar Transparente para alojar al Avatar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Sin botón de atrás
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0),
            child: Center(
              // --- AQUÍ ESTÁ SERVI VIGILANDO ---
              child: ServiAvatar(
                isSpeaking: _isSpeaking,
                size: 45,
                onTap: () => _speak("Toca la tarjeta que mejor describa lo que quieres hacer hoy."),
              ),
            ),
          )
        ],
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '¿Cómo usarás la App?',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    // QA FIX: Color texto dinámico
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Elige tu rol principal para personalizar tu experiencia.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    // QA FIX: Color secundario dinámico
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Wrap(
                  spacing: 24.0,
                  runSpacing: 24.0,
                  alignment: WrapAlignment.center,
                  children: [
                    _RoleCard(
                      icon: Icons.store_mall_directory_outlined,
                      title: 'Soy Proveedor',
                      subtitle: 'Quiero gestionar mi negocio, clientes y finanzas.',
                      onTap: () => _selectRole('provider'),
                      isLoading: _loadingRole == 'provider',
                    ),
                    _RoleCard(
                      icon: Icons.person_search_outlined,
                      title: 'Busco un Servicio',
                      subtitle: 'Quiero encontrar y contratar profesionales.',
                      onTap: () => _selectRole('client'),
                      isLoading: _loadingRole == 'client',
                    ),
                    _RoleCard(
                      icon: Icons.sync_alt_rounded,
                      title: 'Ambas Opciones',
                      subtitle: 'Quiero gestionar mi negocio y también contratar servicios.',
                      onTap: () => _selectRole('both'),
                      isLoading: _loadingRole == 'both',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Un widget reutilizable y estilizado para mostrar una tarjeta de selección de rol.
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLoading;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    // QA FIX: Obtener colores del tema
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // El color primario define el borde/icono (Azul Neón por defecto)
    final primaryColor = colorScheme.primary;
    
    // Color de superficie de tarjeta (Blanco en Light / Azul superficie en Dark)
    final surfaceColor = theme.cardTheme.color;

    return SizedBox(
      width: 280,
      child: Material(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        elevation: 5,
        // QA FIX: Sombra sutil adaptada al modo
        shadowColor: theme.shadowColor.withValues(alpha: 0.1), 
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: primaryColor.withValues(alpha: 0.2),
          highlightColor: primaryColor.withValues(alpha: 0.1),
          child: Container(
            // QA FIX: Añadimos un borde sutil para mejor definición en modo claro
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isLoading
                      ? SizedBox(
                          key: const ValueKey('loader'),
                          height: 48,
                          width: 48,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          ),
                        )
                      : Icon(icon, key: const ValueKey('icon'), size: 48, color: primaryColor),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    // QA FIX: Texto dinámico
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    // QA FIX: Texto secundario dinámico
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}