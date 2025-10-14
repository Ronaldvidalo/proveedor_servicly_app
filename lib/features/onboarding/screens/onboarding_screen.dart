// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 14/10/2025
// Style: Cyber Glow
// This screen was refactored to align with the "Cyber Glow" design philosophy,
// featuring a dynamic PageView, custom-styled indicators, a prominent
// FloatingActionButton, and a skip option for an improved user experience.
// ---------------------------------

import 'package:flutter/material.dart';

/// Modelo simple para contener los datos de cada página del onboarding.
class OnboardingPageModel {
  /// La ruta del archivo de imagen o ilustración.
  final IconData icon; // Usaremos IconData que representa el concepto.
  
  /// El título principal de la página.
  final String title;

  /// La descripción detallada que explica el beneficio.
  final String description;

  OnboardingPageModel({
    required this.icon,
    required this.title,
    required this.description,
  });
}

/// Una pantalla que guía al nuevo usuario a través de las características
/// principales de la aplicación, con un estilo visual "Cyber Glow".
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  // UI Polish: El contenido de las páginas se mantiene, el cambio es visual.
  final List<OnboardingPageModel> _pages = [
    OnboardingPageModel(
      icon: Icons.folder_special_rounded,
      title: 'Organiza tu Negocio',
      description:
          'Centraliza clientes, presupuestos y agenda en un solo lugar. Di adiós al cuaderno y al caos.',
    ),
    OnboardingPageModel(
      icon: Icons.bar_chart_rounded,
      title: 'Controla tus Finanzas',
      description:
          'Registra ingresos y gastos fácilmente. Observa el crecimiento de tu trabajo sin complicaciones.',
    ),
    OnboardingPageModel(
      icon: Icons.shield_moon_rounded, // Icono más temático.
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

  /// Navega a la siguiente página o, si es la última, ejecuta el callback onFinished.
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

    // --- Definición del Tema "Cyber Glow" ---
    const primaryColor = Color(0xFF00BFFF); // Azul eléctrico brillante
    const backgroundColor = Color(0xFF1A1A2E); // Azul oscuro casi negro
    const surfaceColor = Color(0xFF2D2D5A); // Superficie ligeramente más clara
    const textColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // --- Botón de Saltar ---
            // UX Improvement: Permitir al usuario saltar el onboarding es una
            // práctica recomendada para no forzar la interacción.
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: widget.onFinished,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)
                ),
                child: const Text('Saltar'),
              ),
            ),

            // --- Contenido deslizable (PageView) ---
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
                  // UI Polish: Se inyectan los colores del tema al widget de la página.
                  return _OnboardingPageWidget(
                    icon: page.icon,
                    title: page.title,
                    description: page.description,
                    primaryColor: primaryColor,
                    surfaceColor: surfaceColor,
                    textColor: textColor,
                  );
                },
              ),
            ),

            // --- Controles Inferiores (Indicadores y Botón) ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // --- Indicadores de Página ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _buildDot(index: index, primaryColor: primaryColor, surfaceColor: surfaceColor),
                    ),
                  ),

                  // --- Botón de Acción ---
                  // UI Polish: Botón flotante para una apariencia más dinámica.
                  FloatingActionButton(
                    onPressed: _goToNextPage,
                    backgroundColor: primaryColor,
                    elevation: 5,
                    child: Icon(
                      isLastPage ? Icons.check_rounded : Icons.arrow_forward_ios_rounded,
                      color: Colors.black, // Color corregido para contraste
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

  /// Widget auxiliar para construir un punto indicador con el estilo "Cyber Glow".
  Widget _buildDot({required int index, required Color primaryColor, required Color surfaceColor}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(right: 8),
      height: 10,
      width: _currentPageIndex == index ? 30 : 10,
      decoration: BoxDecoration(
        color: _currentPageIndex == index ? primaryColor : surfaceColor,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

/// Widget privado que renderiza el contenido de una única página de onboarding.
class _OnboardingPageWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color primaryColor;
  final Color surfaceColor;
  final Color textColor;

  const _OnboardingPageWidget({
    required this.icon,
    required this.title,
    required this.description,
    required this.primaryColor,
    required this.surfaceColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // UI Polish: El icono ahora tiene un contenedor con efecto "glow" para
          // integrarse con el diseño de la pantalla de autenticación.
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: surfaceColor,
              boxShadow: [
                BoxShadow(
                  // CORRECCIÓN: Se usa '.withAlpha()' en lugar de '.withOpacity()'.
                  color: primaryColor.withAlpha(77), // 0.3 opacity
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 100,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 64),
          Text(
            title,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white70,
              height: 1.5, // Mejora la legibilidad del párrafo.
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

