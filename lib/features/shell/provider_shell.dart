/// lib/features/shell/provider_shell.dart
library;

import 'package:flutter/material.dart';
import '../dashboard/screens/dashboard_screen.dart';
// --- CORRECCIÓN: AÑADIR ESTA LÍNEA DE IMPORT ---
import '../settings/screens/settings_screen.dart'; 

/// El "Shell" o contenedor principal para la interfaz del Proveedor.
/// Gestiona la navegación de las "páginas matrices" de la app.
class ProviderShell extends StatefulWidget {
  const ProviderShell({super.key});

  @override
  State<ProviderShell> createState() => _ProviderShellState();
}

class _ProviderShellState extends State<ProviderShell> {
  int _selectedIndex = 0;

  // La lista de pantallas ahora refleja las páginas matrices.
  static final List<Widget> _screens = <Widget>[
    const DashboardScreen(), // 0: Inicio (Dashboard con módulos dinámicos)
    const _PlaceholderScreen(title: 'Oportunidades'), // 1: Marketplace a futuro
    const SettingsScreen(),  // 2: La nueva pantalla de Configuración
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double mobileBreakpoint = 640;
        if (constraints.maxWidth < mobileBreakpoint) {
          return _buildMobileLayout();
        } else {
          return _buildWebLayout();
        }
      },
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      body: _screens.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb_outline), activeIcon: Icon(Icons.lightbulb), label: 'Oportunidades'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Configuración'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildWebLayout() {
    return Scaffold(
      body: Row(
        children: <Widget>[
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            labelType: NavigationRailLabelType.all,
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Inicio')),
              NavigationRailDestination(icon: Icon(Icons.lightbulb_outline), selectedIcon: Icon(Icons.lightbulb), label: Text('Oportunidades')),
              NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Configuración')),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _screens.elementAt(_selectedIndex),
          ),
        ],
      ),
    );
  }
}

/// Widget de placeholder para las pantallas que aún no hemos construido.
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Text(
              'Próximamente: $title',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: const Text(
                'Estamos construyendo esta sección para traerte nuevas oportunidades de negocio.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}