// lib/features/onboarding/screens/onboarding_screen.dart

import 'package:flutter/material.dart';

// El import de auth_screen.dart ya no es necesario aquí.

/// Modelo simple para contener los datos de cada página del onboarding.
class OnboardingPageModel {
  /// La ruta del archivo de imagen o ilustración.
  final IconData icon; // Usaremos IconData como placeholder para imágenes.
  
  /// El título principal de la página.
  final String title;

  /// La descripción detallada que explica el beneficio.
  final String description;

  // CORRECCIÓN: Se eliminó 'onFinished' de este modelo. No pertenece aquí.
  OnboardingPageModel({
    required this.icon,
    required this.title,
    required this.description,
  });
}

/// Una pantalla que guía al nuevo usuario a través de las características
/// principales de la aplicación.
class OnboardingScreen extends StatefulWidget {
  // CORRECCIÓN: 'onFinished' es una propiedad del widget de la pantalla.
  final VoidCallback onFinished;

  /// Constructor para OnboardingScreen que requiere la función de callback.
  // CORRECCIÓN: Se eliminó el constructor duplicado, dejando solo este.
  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  /// Controlador para manejar el estado del PageView (página actual, etc.).
  final PageController _pageController = PageController();

  /// El índice de la página que se está mostrando actualmente.
  int _currentPageIndex = 0;

  /// Contenido para cada una de las páginas del onboarding.
  final List<OnboardingPageModel> _pages = [
    OnboardingPageModel(
      icon: Icons.folder_special_outlined,
      title: 'Organiza tu Negocio',
      description:
          'Centraliza clientes, presupuestos y agenda en un solo lugar. Di adiós al cuaderno y al caos.',
    ),
    OnboardingPageModel(
      icon: Icons.bar_chart_outlined,
      title: 'Controla tus Finanzas',
      description:
          'Registra ingresos y gastos fácilmente. Observa el crecimiento de tu trabajo sin complicaciones.',
    ),
    OnboardingPageModel(
      icon: Icons.gpp_good_outlined,
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
      // CORRECCIÓN: Ahora 'widget.onFinished()' es válido porque OnboardingScreen tiene esta propiedad.
      widget.onFinished();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = _currentPageIndex == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
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
                    return _OnboardingPageWidget(
                      icon: page.icon,
                      title: page.title,
                      description: page.description,
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // --- Indicadores de Página ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => _buildDot(index: index),
                ),
              ),

              const SizedBox(height: 48),

              // --- Botón de Acción ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _goToNextPage,
                  child: Text(isLastPage ? 'Comenzar' : 'Siguiente'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget auxiliar para construir un punto indicador.
  Widget _buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPageIndex == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPageIndex == index
            ? Theme.of(context).primaryColor
            : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Widget privado que renderiza el contenido de una única página de onboarding.
class _OnboardingPageWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPageWidget({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 150,
          color: Theme.of(context).primaryColor.withAlpha(204),
        ),
        const SizedBox(height: 48),
        Text(
          title,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          description,
          style: textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}