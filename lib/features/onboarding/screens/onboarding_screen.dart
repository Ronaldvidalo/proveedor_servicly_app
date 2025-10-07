// lib/features/onboarding/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import '../../auth/widgets/auth_wrapper.dart';
import '../../auth/screens/auth_screen.dart';

// Aún no existen, pero preparamos la navegación futura.
// import '../../auth/screens/auth_screen.dart'; 

/// Modelo simple para contener los datos de cada página del onboarding.
class OnboardingPageModel {
  /// La ruta del archivo de imagen o ilustración.
  final IconData icon; // Usaremos IconData como placeholder para imágenes.
  
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
/// principales de la aplicación.
class OnboardingScreen extends StatefulWidget {
  /// Constructor para OnboardingScreen.
  const OnboardingScreen({super.key});

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
      // CORRECCIÓN: Ícono corregido a uno existente.
      icon: Icons.folder_special_outlined,
      title: 'Organiza tu Negocio',
      description: 'Centraliza clientes, presupuestos y agenda en un solo lugar. Di adiós al cuaderno y al caos.',
    ),
    OnboardingPageModel(
      icon: Icons.bar_chart_outlined,
      title: 'Controla tus Finanzas',
      description: 'Registra ingresos y gastos fácilmente. Observa el crecimiento de tu trabajo sin complicaciones.',
    ),
    OnboardingPageModel(
      // CORRECCIÓN: Ícono corregido a uno existente.
      icon: Icons.gpp_good_outlined, 
      title: 'Profesionaliza tu Servicio',
      description: 'Genera contratos y recordatorios de pago automáticos para cobrar a tiempo y sin estrés.',
    ),
  ];
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Navega a la siguiente página o, si es la última, a la pantalla de autenticación.
  void _goToNextPage() {
  if (_currentPageIndex < _pages.length - 1) {
    // ...código para ir a la siguiente página...
  } else {
    // Navegamos a la pantalla de Autenticación.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
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
        // En un proyecto real, reemplazarías este Icon por una imagen o ilustración.
        // Ejemplo: Image.asset('assets/images/onboarding_1.svg', height: 250);
        Icon(
          icon,
          size: 150,
          // CORRECCIÓN: Se reemplaza 'withOpacity' (obsoleto) por 'withAlpha'.
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