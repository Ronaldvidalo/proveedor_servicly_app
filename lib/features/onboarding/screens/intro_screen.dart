// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 19/10/2025
// Style: Cyber Glow (Adaptive Light/Dark)
// QA FIX 26/11/2025:
// 1. Refactorización completa para eliminar colores hardcoded.
// 2. Adaptación automática a Modo Claro/Oscuro usando Theme.of(context).
// 3. Actualización de métodos deprecados (.withValues).
// ---------------------------------

import 'package:flutter/material.dart';

/// Modelo simple para contener los datos de cada página de la introducción.
class IntroPageModel {
  final IconData icon;
  final String title;
  final String description;

  IntroPageModel({
    required this.icon,
    required this.title,
    required this.description,
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

  final List<IntroPageModel> _pages = [
    IntroPageModel(
      icon: Icons.folder_special_rounded,
      title: 'Organiza tu Negocio',
      description:
          'Centraliza clientes, presupuestos y agenda en un solo lugar. Di adiós al cuaderno y al caos.',
    ),
    IntroPageModel(
      icon: Icons.bar_chart_rounded,
      title: 'Controla tus Finanzas',
      description:
          'Registra ingresos y gastos fácilmente. Observa el crecimiento de tu trabajo sin complicaciones.',
    ),
    IntroPageModel(
      icon: Icons.shield_moon_rounded,
      title: 'Profesionaliza tu Servicio',
      description:
          'Genera contratos y recordatorios de pago automáticos para cobrar a tiempo y sin estrés.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPageIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onFinished();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = _currentPageIndex == _pages.length - 1;
    
    // QA FIX: Obtenemos el tema del contexto para colores dinámicos
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // 1. Fondo dinámico (Gris claro / Azul Oscuro)
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: widget.onFinished,
                style: TextButton.styleFrom(
                  // QA FIX: Texto visible en ambos modos (Gris oscuro / Gris claro)
                  foregroundColor: colorScheme.onSurface.withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)
                ),
                child: const Text('Saltar'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPageIndex = index;
                  });
                },
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
                        // QA FIX: Color inactivo sutil pero visible
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
                      // QA FIX: Texto sobre botón primario (generalmente negro para neón, o blanco)
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
    // QA FIX: Accedemos al tema dentro del widget hijo
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
              // QA FIX: Color de superficie dinámico (Blanco / Azul Superficie)
              color: theme.cardTheme.color,
              boxShadow: [
                BoxShadow(
                  // QA FIX: Sombra neón dinámica con .withValues
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 100,
              // QA FIX: El icono usa el color primario (Azul Neón / Rosa Neón, etc.)
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 64),
          Text(
            title,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              // QA FIX: Color de texto principal dinámico
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: textTheme.titleMedium?.copyWith(
              // QA FIX: Color secundario (grisáceo) dinámico
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