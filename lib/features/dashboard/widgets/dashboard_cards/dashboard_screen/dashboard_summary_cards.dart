import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_pkg; 
import 'package:proveedor_servicly_app/core/models/user_model.dart';

// IMPORTS DE TARJETAS Y PANTALLAS
import 'package:proveedor_servicly_app/features/dashboard/widgets/dashboard_cards/daily_sales_card.dart';
import 'package:proveedor_servicly_app/features/dashboard/widgets/dashboard_cards/FinancialHealthCard.dart';
import 'package:proveedor_servicly_app/features/dashboard/widgets/dashboard_cards/inventory_alert_card.dart';
import 'package:proveedor_servicly_app/features/dashboard/widgets/dashboard_cards/next_appointment_card.dart';
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
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;
  Timer? _timer;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pages = [
      _buildNavWrapper(child: const DailySalesCard(), destination: const SalesHistoryScreen()),
      _buildNavWrapper(child: const FinancialHealthCard(), destination: const AdvancedFinanceScreen()),
      _buildNavWrapper(child: const InventoryAlertCard(), destination: const InventoryScreen()),
      _buildNavWrapper(
        onTap: () {
            final user = provider_pkg.Provider.of<UserModel?>(context, listen: false);
            if (user != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AgendaScreen(user: user)));
            }
        },
        child: const NextAppointmentCard(),
      ),
    ];
  }

  Widget _buildNavWrapper({required Widget child, Widget? destination, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () {
        if (destination != null) Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        // 🛡️ SOLUCIÓN OVERFLOW: Clip evita que sombras o transformaciones salgan del área
        clipBehavior: Clip.none, 
        // ⚠️ IMPORTANTE: No ponemos width fijo aquí, dejamos que el PageView controle.
        child: child,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_pageController.hasClients) {
        if (_currentPage < _pages.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutQuint,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 180, 
          child: PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) {
                if(mounted) setState(() => _currentPage = index);
            },
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 0.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                  } else {
                     value = (_currentPage - index).toDouble();
                  }
                  
                  double delta = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                  final double scale = Curves.easeOutCubic.transform(delta);
                  final double opacity = Curves.easeIn.transform(delta);

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..scale(scale, scale),
                    child: Opacity(
                      // 🛡️ SOLUCIÓN: Clamp estricto para evitar valores negativos
                      opacity: opacity.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: _pages[index],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // INDICADORES (DOTS)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_pages.length, (index) {
             return AnimatedContainer(
               // 🛡️ SOLUCIÓN CRÍTICA: Cambiado easeOutBack por easeOut.
               // easeOutBack causaba el error de "Negative Blur Radius".
               duration: const Duration(milliseconds: 400),
               curve: Curves.easeOut, 
               margin: const EdgeInsets.symmetric(horizontal: 4),
               height: 6,
               width: _currentPage == index ? 24 : 8,
               decoration: BoxDecoration(
                 color: _currentPage == index ? colorScheme.primary : theme.dividerColor,
                 borderRadius: BorderRadius.circular(10),
                 boxShadow: _currentPage == index ? [
                   BoxShadow(
                     color: colorScheme.primary.withValues(alpha: 0.3),
                     blurRadius: 4,
                     offset: const Offset(0, 2),
                   )
                 ] : [],
               ),
             );
          }),
        )
      ],
    );
  }
}