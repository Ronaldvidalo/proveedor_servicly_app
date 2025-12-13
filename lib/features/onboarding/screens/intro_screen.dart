// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 19/10/2025
// Style: Cyber Glow (Adaptive Light/Dark)
// QA FIX 11/12/2025: Ajuste de Guion (Presentación IA + Tono Argentino)
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; // Control de audio

// --- IMPORTS DE LA IA ---
import 'package:proveedor_servicly_app/ai/services/voice_service.dart';
import 'package:proveedor_servicly_app/ai/widgets/servi_avatar.dart';

/// Modelo simple para contener los datos de cada página de la introducción.
class IntroPageModel {
  final IconData icon;
  final String title;
  final String description;
  final String voiceScript; // Guion de voz para cada página

  IntroPageModel({
    required this.icon,
    required this.title,
    required this.description,
    required this.voiceScript,
  });
}

/// Una pantalla que guía al nuevo usuario a través de las características
/// principales de la aplicación, con un estilo visual "Cyber Glow".
class IntroScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const IntroScreen({super.key, required this.onFinished});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  // --- IA SERVI ---
  final ServiVoiceService _voiceService = ServiVoiceService();
  bool _isSpeaking = false;

  // --- DEFINICIÓN DE PÁGINAS (GUION NATURAL MEJORADO) ---
  final List<IntroPageModel> _pages = [
    IntroPageModel(
      icon: Icons.folder_special_rounded,
      title: 'Organizá tu Negocio',
      description: 'Centralizá clientes, presupuestos y agenda en un solo lugar. Chau al cuaderno y al caos.',
      // CAMBIO AQUÍ: Presentación clara como IA de Servicly
      voiceScript: "Hola, soy Servi, la inteligencia artificial de Servicly. Estoy acá para ayudarte a mejorar tu negocio. Vamos a organizar todo para que te olvides del caos y los papeles sueltos.",
    ),
    IntroPageModel(
      icon: Icons.bar_chart_rounded,
      title: 'Controlá tus Finanzas',
      description: 'Registrá ingresos y gastos fácilmente. Mirá cómo crece tu trabajo sin complicaciones.',
      voiceScript: "Tomá el control de tus números. Mirá cómo crecen tus ingresos día a día y decidí mejor.",
    ),
    IntroPageModel(
      icon: Icons.shield_moon_rounded,
      title: 'Profesionalizá tu Servicio',
      description: 'Generá contratos y presupuestos digitales claros. Que tus clientes te tomen en serio.',
      voiceScript: "Proyectá confianza total. Con presupuestos digitales y contratos claros, vas a quedar como un profesional de primera.",
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    // 1. Escuchar a Servi
    _voiceService.player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isSpeaking = state == PlayerState.playing);
    });

    // 2. Iniciar la narración de la primera página
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _speak(_pages[0].voiceScript);
    });
  }

  Future<void> _speak(String text) async {
    await _voiceService.speak(text);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _voiceService.dispose(); // Liberar recursos
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPageIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // Mensaje de despedida antes de salir
      _speak("¡Dale, arrancamos! Tu éxito empieza ahora.");
      // Pequeña pausa para el efecto
      Future.delayed(const Duration(milliseconds: 1500), widget.onFinished);
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPageIndex = index;
    });
    // Narrar la nueva página
    _speak(_pages[index].voiceScript);
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = _currentPageIndex == _pages.length - 1;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER CON AVATAR Y BOTÓN SALTAR ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Avatar de Servi narrando
                  ServiAvatar(
                    isSpeaking: _isSpeaking,
                    size: 40,
                    onTap: () => _speak(_pages[_currentPageIndex].voiceScript), // Repetir al tocar
                  ),
                  
                  TextButton(
                    onPressed: widget.onFinished,
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    child: const Text('Saltar'),
                  ),
                ],
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _IntroPageWidget(
                    icon: page.icon,
                    title: page.title,
                    description: page.description,
                  );
                },
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _buildDot(
                        index: index, 
                        activeColor: colorScheme.primary, 
                        inactiveColor: theme.dividerColor
                      ),
                    ),
                  ),
                  FloatingActionButton(
                    onPressed: _goToNextPage,
                    backgroundColor: colorScheme.primary,
                    elevation: 5,
                    child: Icon(
                      isLastPage ? Icons.check_rounded : Icons.arrow_forward_ios_rounded,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot({required int index, required Color activeColor, required Color inactiveColor}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(right: 8),
      height: 10,
      width: _currentPageIndex == index ? 30 : 10,
      decoration: BoxDecoration(
        color: _currentPageIndex == index ? activeColor : inactiveColor,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

/// Widget privado que renderiza el contenido de una única página de introducción.
class _IntroPageWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _IntroPageWidget({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.cardTheme.color,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 100,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 64),
          Text(
            title,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}