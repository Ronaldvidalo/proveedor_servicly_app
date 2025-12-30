import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

// --- Modelos ---
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';

// --- Servicios ---
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/ai/services/voice_service.dart'; 

// --- Widgets del Editor ---
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog_editor/catalog_hero_header_editor.dart';
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog_editor/catalog_portfolio_section_editor.dart';
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog_editor/catalog_services_section_editor.dart';
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog_editor/catalog_trust_signals_editor.dart';
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog_editor/catalog_gift_card_section_editor.dart';
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog_editor/catalog_promotions_section_editor.dart';

// --- Widgets de Visualización ---
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog/catalog_reviews_section.dart';

// --- IA & Coach ---
import 'package:proveedor_servicly_app/ai/widgets/servi_coach_widget.dart';

class CatalogEditorScreen extends StatefulWidget {
  final String providerId;
  const CatalogEditorScreen({super.key, required this.providerId});

  @override
  State<CatalogEditorScreen> createState() => _CatalogEditorScreenState();
}

class _CatalogEditorScreenState extends State<CatalogEditorScreen> {
  // --- Keys para el Tour ---
  final GlobalKey _keyReviews = GlobalKey();
  final GlobalKey _keyFab = GlobalKey();

  // --- Estado de Servi ---
  final ServiVoiceService _voiceService = ServiVoiceService(); 
  String _serviMessage = "¡Hola! 👋 Bienvenido al Editor. Aquí podrás diseñar tu perfil profesional.";
  bool _isTourActive = false;
  
  // 🔊 ESTADO DE VOZ: Por defecto SIEMPRE habla (False = No silenciado)
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndStartTour();
        // Saludo inicial (Solo si no está muteado, aunque por defecto no lo está)
        Future.delayed(const Duration(milliseconds: 500), () {
           if(mounted && !_isTourActive) _speak(_serviMessage);
        });
    });
  }

  @override
  void dispose() {
    _voiceService.dispose(); 
    super.dispose();
  }

  // --- CONTROL DE VOZ ---
  void _speak(String text) {
    if (_isMuted) return; // 🛑 Si le ordenamos silencio, no habla.
    
    _voiceService.stop(); 
    _voiceService.speak(text);
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    // Feedback inmediato
    if (_isMuted) {
      _voiceService.stop(); // Calla inmediatamente
    } else {
      _speak("Audio activado. Te seguiré guiando."); // Confirma que volvió
    }
  }

  Future<void> _checkAndStartTour() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenTour = prefs.getBool('has_seen_catalog_editor_tour') ?? false;

    if (!hasSeenTour) {
      _startTour();
      await prefs.setBool('has_seen_catalog_editor_tour', true);
    }
  }

  void _startTour() {
    setState(() => _isTourActive = true);
    // Si estaba muteado, lo desmuteamos para el tour porque es importante
    if (_isMuted) {
       setState(() => _isMuted = false);
       _speak("Activando audio para el tutorial.");
    }
    ShowCaseWidget.of(context).startShowCase([_keyReviews, _keyFab]);
  }

  void _onShowcaseStepStart(int? index, GlobalKey key) {
    String newMessage = "";
    
    if (key == _keyReviews) {
      newMessage = "🎛️ Módulos Inteligentes: Puedes activar o desactivar secciones, como las Reseñas, con un solo toque.";
    } else if (key == _keyFab) {
      newMessage = "💾 Vista Finalizada: Cuando termines de editar, toca aquí para guardar y ver cómo lo verán tus clientes.";
    }

    setState(() => _serviMessage = newMessage);
    _speak(newMessage); 
  }

  void _onShowcaseComplete(int? index, GlobalKey key) {
    setState(() {
      _isTourActive = false;
      _serviMessage = "¡Excelente! 🚀 Todo listo para editar. Si necesitas ayuda, toca mi avatar.";
    });
    _speak(_serviMessage); 
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    final currentUser = context.read<UserModel?>();

    if (currentUser == null) return const Scaffold(body: Center(child: Text("Error de sesión")));

    return ShowCaseWidget(
      onStart: (index, key) => _onShowcaseStepStart(index, key),
      onComplete: (index, key) => _onShowcaseComplete(index, key),
      blurValue: 1,
      builder: (context) {
        return StreamBuilder<ProviderProfileModel?>(
          stream: firestoreService.getCatalogStream(widget.providerId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(backgroundColor: Color(0xFF1A1A2E), body: Center(child: CircularProgressIndicator(color: Color(0xFF00B2B2))));
            }

            final profile = snapshot.data;
            if (profile == null) return const Scaffold(body: Center(child: Text("No se encontró la configuración del catálogo")));

            return Scaffold(
              backgroundColor: const Color(0xFF0D0D1A),
              appBar: AppBar(
                backgroundColor: const Color(0xFF0D0D1A),
                elevation: 0,
                actions: [
                  // 🔇 BOTÓN DE ORDEN DE SILENCIO
                  IconButton(
                    icon: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up, 
                      color: _isMuted ? Colors.redAccent : Colors.greenAccent
                    ),
                    onPressed: _toggleMute,
                    tooltip: _isMuted ? "Activar Voz" : "Silenciar Servi",
                  ),
                  // 🎓 BOTÓN DE REPETIR TOUR
                  IconButton(
                    icon: const Icon(Icons.help_outline, color: Colors.white54),
                    onPressed: _startTour, 
                    tooltip: "Ver Tutorial",
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: Stack(
                children: [
                  // CAPA 1: CONTENIDO DEL EDITOR
                  CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      CatalogHeroHeaderEditor(profile: profile, user: currentUser),
                      CatalogPromotionsSectionEditor(providerId: widget.providerId),
                      CatalogTrustSignalsEditor(profile: profile),
                      CatalogPortfolioSectionEditor(providerId: widget.providerId, brandColor: profile.brandColor),
                      CatalogServicesSectionEditor(providerId: widget.providerId, brandColor: profile.brandColor),
                      CatalogGiftCardSectionEditor(providerId: widget.providerId),

                      // 7. Reseñas con Toggle
                      _buildModuleToggle(
                        context,
                        key: _keyReviews,
                        title: "Opiniones de Clientes",
                        subtitle: "Mostrar testimonios reales en tu perfil",
                        isEnabled: profile.showReviewsModule,
                        onChanged: (val) => _updateModuleVisibility('showReviewsModule', val),
                      ),
                      
                      if (profile.showReviewsModule) CatalogReviewsSection(profile: profile),

                      const SliverToBoxAdapter(child: SizedBox(height: 150)),
                    ],
                  ),

                  // CAPA 2: SERVI COACH (Flotando)
                  Positioned(
                    bottom: 100,
                    right: 20,
                    child: ServiCoachWidget(
                      title: _isTourActive ? "GUÍA DE EDITOR" : "ASISTENTE DE DISEÑO",
                      message: _serviMessage,
                      autoPlay: !_isMuted, // 🛑 El widget visual también respeta el silencio (no anima la boca si está mudo)
                      duration: _isTourActive ? const Duration(seconds: 10) : const Duration(seconds: 6),
                    ),
                  ),
                ],
              ),
              
              floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
              floatingActionButton: Showcase(
                key: _keyFab,
                title: 'Guardar y Previsualizar',
                description: 'Toca aquí para ver tu catálogo final.',
                targetShapeBorder: const StadiumBorder(),
                child: FloatingActionButton.extended(
                  backgroundColor: const Color(0xFF00B2B2),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: const Text("VISTA FINALIZADA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            );
          },
        );
      }
    );
  }

  Future<void> _updateModuleVisibility(String field, bool value) async {
    await context.read<FirestoreService>().updateCatalogField(widget.providerId, {field: value});
  }

  Widget _buildModuleToggle(BuildContext context, {required String title, required String subtitle, required bool isEnabled, required Function(bool) onChanged, GlobalKey? key}) {
    Widget content = Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isEnabled ? const Color(0xFF00B2B2).withValues(alpha: 0.3) : Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11))])),
          Switch(value: isEnabled, activeColor: const Color(0xFF00B2B2), onChanged: onChanged),
        ],
      ),
    );

    if (key != null) {
      content = Showcase(
        key: key,
        title: 'Control de Módulos',
        description: 'Activa o desactiva secciones según tu estrategia.',
        child: content,
      );
    }

    return SliverToBoxAdapter(child: content);
  }
}