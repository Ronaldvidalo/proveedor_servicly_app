/// lib/features/shell/provider_shell.dart
library;

import 'package:flutter/material.dart';
import '../home/screens/home_screen.dart'; // Nuestra pantalla de dashboard existente

/// El "Shell" o contenedor principal para la interfaz del Proveedor.
///
/// Gestiona la navegación principal (BottomNav en móvil, NavigationRail en web)
/// y muestra la pantalla correspondiente a la sección seleccionada.
class ProviderShell extends StatefulWidget {
  const ProviderShell({super.key});

  @override
  State<ProviderShell> createState() => _ProviderShellState();
}

class _ProviderShellState extends State<ProviderShell> {
  // El índice de la pestaña actualmente seleccionada.
  int _selectedIndex = 0;

  // Lista de las pantallas principales que corresponden a cada pestaña.
  static final List<Widget> _screens = <Widget>[
    // TODO: Renombrar HomeScreen a DashboardScreen para mayor claridad
    const HomeScreen(), // 0: Inicio (Dashboard)
    const _PlaceholderScreen(title: 'Agenda'),     // 1: Agenda
    const _PlaceholderScreen(title: 'Clientes'),   // 2: Clientes
    const _PlaceholderScreen(title: 'Finanzas'),   // 3: Finanzas
    const _PlaceholderScreen(title: 'Oportunidades'), // 4: Oportunidades
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder es el widget clave para la responsividad.
    // Nos da el ancho de la pantalla y nos permite construir diferentes UIs.
    return LayoutBuilder(
      builder: (context, constraints) {
        // Breakpoint para cambiar de móvil a web/escritorio.
        const double mobileBreakpoint = 640;

        if (constraints.maxWidth < mobileBreakpoint) {
          // --- VISTA MÓVIL ---
          return _buildMobileLayout();
        } else {
          // --- VISTA WEB / ESCRITORIO ---
          return _buildWebLayout();
        }
      },
    );
  }

  /// Construye la interfaz para pantallas angostas (móvil).
  Widget _buildMobileLayout() {
    return Scaffold(
      body: _screens.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Mantiene el fondo y muestra todos los labels
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Agenda'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), activeIcon: Icon(Icons.people_alt), label: 'Clientes'),
          BottomNavigationBarItem(icon: Icon(Icons.assessment_outlined), activeIcon: Icon(Icons.assessment), label: 'Finanzas'),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb_outline), activeIcon: Icon(Icons.lightbulb), label: 'Oportunidades'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  /// Construye la interfaz para pantallas anchas (web/escritorio).
  Widget _buildWebLayout() {
    return Scaffold(
      body: Row(
        children: <Widget>[
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            labelType: NavigationRailLabelType.all, // Muestra siempre los labels
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Inicio')),
              NavigationRailDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: Text('Agenda')),
              NavigationRailDestination(icon: Icon(Icons.people_alt_outlined), selectedIcon: Icon(Icons.people_alt), label: Text('Clientes')),
              NavigationRailDestination(icon: Icon(Icons.assessment_outlined), selectedIcon: Icon(Icons.assessment), label: Text('Finanzas')),
              NavigationRailDestination(icon: Icon(Icons.lightbulb_outline), selectedIcon: Icon(Icons.lightbulb), label: Text('Oportunidades')),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // El contenido principal ocupa el resto del espacio.
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
        child: Text(
          'Pantalla de $title',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}