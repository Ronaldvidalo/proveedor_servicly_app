import 'dart:async';
import 'package:flutter/material.dart';
// --- IMPORT NECESARIO PARA EL ERROR ---
import 'package:provider/provider.dart' as provider;
import 'package:proveedor_servicly_app/core/models/user_model.dart';

// --- IMPORTS DE LOS WIDGETS (TARJETAS) ---
// Asegúrate de que estos archivos existan en tu proyecto
import 'package:proveedor_servicly_app/features/dashboard/widgets/dashboard_cards/daily_sales_card.dart';
import 'package:proveedor_servicly_app/features/dashboard/widgets/dashboard_cards/FinancialHealthCard.dart';
import 'package:proveedor_servicly_app/features/dashboard/widgets/dashboard_cards/inventory_alert_card.dart';
import 'package:proveedor_servicly_app/features/dashboard/widgets/dashboard_cards/next_appointment_card.dart';

// --- IMPORTS DE LAS PANTALLAS (PARA NAVEGACIÓN) ---
import 'package:proveedor_servicly_app/features/sales/screens/sales_history_screen.dart';
import 'package:proveedor_servicly_app/features/finance/presentation/screens/advanced_finance_screen.dart';
import 'package:proveedor_servicly_app/features/inventory/screens/inventory_screen.dart';
import 'package:proveedor_servicly_app/features/agenda/presentation/screens/agenda_screen.dart'; 

class DashboardSummaryCards extends StatefulWidget {
  const DashboardSummaryCards({super.key});

  @override
  State<DashboardSummaryCards> createState() => _DashboardSummaryCardsState();
}

class _DashboardSummaryCardsState extends State<DashboardSummaryCards> {
  final PageController _pageController = PageController(viewportFraction: 0.5);
  int _currentPage = 0;
  Timer? _timer;

  // Lista de widgets para iterar
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // CORRECCIÓN: Eliminamos 'const' porque los hijos no son constantes
    _pages = [
      // 1. Ventas
      GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesHistoryScreen())),
        child: Center(child: const DailySalesCard()), // const aquí si el constructor del widget lo permite
      ),
      // 2. Finanzas
      GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdvancedFinanceScreen())),
        child: Center(child: const FinancialHealthCard()),
      ),
      // 3. Inventario
      GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen())),
        child: Center(child: const InventoryAlertCard()),
      ),
      // 4. Agenda
      GestureDetector(
        onTap: () {
           // Obtenemos el usuario usando el alias 'provider' que definimos arriba
           final user = provider.Provider.of<UserModel?>(context, listen: false);
           if (user != null) {
             Navigator.push(context, MaterialPageRoute(builder: (_) => AgendaScreen(user: user)));
           } else {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text("Error: Usuario no identificado"))
             );
           }
        },
        child: Center(child: const NextAppointmentCard()),
      ),
    ];
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < _pages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    _timer?.cancel();
    _startAutoScroll();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                  }
                  return Transform.scale(
                    scale: Curves.easeOut.transform(value),
                    child: child,
                  );
                },
                child: _pages[index],
              );
            },
          ),
        ),
        
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _pages.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: _currentPage == index ? 20 : 6,
              decoration: BoxDecoration(
                color: _currentPage == index 
                    ? const Color(0xFF00BFFF) 
                    : Colors.white.withOpacity(0.2), // ignore: deprecated_member_use
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}