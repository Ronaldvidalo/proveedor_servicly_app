// features/settings/widgets/payment_methods_section.dart

import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/features/settings/screens/manage_payment_methods_screen.dart';

// Definimos un nuevo widget reutilizable para la tarjeta de sección
// que contiene la opción de métodos de pago.
class PaymentMethodsSection extends StatelessWidget {
  final UserModel user;

  // Aceptamos una función para construir la tarjeta de sección genérica
  // que ya tienes definida en _BrandSettingsScreenState.
  // Esto mantiene la consistencia visual.
  final Widget Function({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) buildSectionCard;

  const PaymentMethodsSection({
    super.key,
    required this.user,
    required this.buildSectionCard,
  });

  // Colores de la pantalla BrandSettingsScreen
  static const Color backgroundColor = Color(0xFF1A1A2E);
  static const Color accentColor = Color(0xFF00BFFF);

  @override
  Widget build(BuildContext context) {
    return buildSectionCard(
      title: 'Métodos de Pago P2P',
      subtitle: 'Gestiona las cuentas donde recibirás tus pagos (CBU, Alias, Wallets).',
      children: [
        // La opción de navegación principal
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          tileColor: backgroundColor,
          leading: const Icon(Icons.account_balance_wallet_outlined, color: accentColor),
          title: const Text(
            'Gestionar mis métodos de pago',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ManagePaymentMethodsScreen(user: user),
            ));
          },
        ),
      ],
    );
  }
}