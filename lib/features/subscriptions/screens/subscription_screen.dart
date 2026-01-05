import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_paypal/flutter_paypal.dart';
import 'package:url_launcher/url_launcher.dart'; 

import '../../../../config/payment_config.dart';
import 'package:proveedor_servicly_app/features/subscriptions/models/subscription_plan_model.dart';
import 'package:proveedor_servicly_app/features/subscriptions/services/subscription_service.dart';
import '../widgets/glow_card.dart';
import '../widgets/success_payment_dialog.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String _selectedPlanId = 'plan_pro';
  bool _isLoading = false;

  void _handlePlanSelection(String planId) {
    setState(() => _selectedPlanId = planId);
  }

  // --- LÓGICA PRINCIPAL DE PAGO (WEB ONLY) ---
  void _proceedToCheckout() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Inicia sesión primero.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Doble verificación: Si un usuario móvil llega aquí, no debe ejecutar PayPal
    if (!kIsWeb) {
      return; 
    }

    final selectedPlan = SubscriptionPlan.availablePlans.firstWhere(
      (p) => p.id == _selectedPlanId,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => UsePaypal(
            sandboxMode: PaymentConfig.isSandbox,
            clientId: PaymentConfig.clientId,
            secretKey: PaymentConfig.secretKey,
            returnURL: PaymentConfig.returnUrl,
            cancelURL: PaymentConfig.cancelUrl,
            transactions: [
              {
                "amount": {
                  "total": selectedPlan.price.toString(),
                  "currency": "USD",
                  "details": {
                    "subtotal": selectedPlan.price.toString(),
                    "shipping": "0",
                    "shipping_discount": "0"
                  }
                },
                "description": "Suscripción ${selectedPlan.title} - Servicly",
                "item_list": {
                  "items": [
                    {
                      "name": "Plan ${selectedPlan.title}",
                      "quantity": 1,
                      "price": selectedPlan.price.toString(),
                      "currency": "USD"
                    }
                  ],
                }
              }
            ],
            note: "Servicly Premium Plan",
            
            // --- PAGO EXITOSO ---
            onSuccess: (Map params) async {
              // 1. Cerrar WebView inmediatamente
              if (mounted) Navigator.of(context).pop(); 

              setState(() => _isLoading = true);
              try {
                // 2. Actualizar Backend
                await SubscriptionService().upgradeUserPlan(
                  userId: user.uid,
                  planId: selectedPlan.id,
                  amountPaid: selectedPlan.price,
                );

                if (!mounted) return;
                setState(() => _isLoading = false);

                // 3. Diálogo de Éxito
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => SuccessPaymentDialog(
                    planName: selectedPlan.title,
                    onContinue: () {
                      Navigator.of(context).pop(); // Cierra Diálogo
                      Navigator.of(context).pop(); // Cierra Screen
                    },
                  ),
                );
              } catch (e) {
                if (mounted) setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            },

            // --- ERROR ---
            onError: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Error en PayPal")),
              );
              if (mounted) Navigator.of(context).pop();
            },

            // --- CANCELADO ---
            onCancel: (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Pago cancelado")),
              );
            }
        ),
      ),
    );
  }

  // --- FUNCIÓN PARA ABRIR LA WEB DESDE EL MÓVIL ---
  Future<void> _launchWebPortal() async {
    // CAMBIA ESTO POR TU URL REAL
    final Uri url = Uri.parse('https://servicly.app/login'); 
    
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir el navegador')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir enlace: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ESTRATEGIA HÍBRIDA:
    // Si NO es web (es Android/iOS), mostramos la UI "Reader" sin precios.
    if (!kIsWeb) {
      return _buildMobileReadOnlyUI(context);
    }

    // --- INTERFAZ WEB (TIENDA COMPLETA) ---
    final plans = SubscriptionPlan.availablePlans;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Elige tu Potencial"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildHeader(context),
            const SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 800) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: plans.map((plan) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: _buildPlanItem(plan, theme),
                          ),
                        )).toList(),
                      );
                    } else {
                      return Column(
                        children: plans.map((plan) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _buildPlanItem(plan, theme),
                        )).toList(),
                      );
                    }
                  },
                ),
              ),
            ),
            // Botón de pago REAL (Solo visible en Web)
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  // --- UI MÓVIL (SEGURA PARA GOOGLE PLAY - SIN PRECIOS) ---
  Widget _buildMobileReadOnlyUI(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text("Tu Cuenta"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.stars_rounded, size: 80, color: theme.primaryColor),
            const SizedBox(height: 24),
            
            Text(
              "Nivel Profesional",
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            const Text(
              "Desbloquea herramientas profesionales como Inteligencia Artificial y Gestión Multi-tienda.\n\nLa administración de planes se realiza de forma segura en nuestro portal web.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 30),
            
            // BOTÓN QUE ABRE EL NAVEGADOR EXTERNO
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _launchWebPortal, // <--- Acción del Link
                icon: const Icon(Icons.open_in_browser),
                label: const Text("IR A SERVICLY.APP"),
                style: FilledButton.styleFrom(
                  // Estilo secundario para no parecer un botón de compra agresivo
                  backgroundColor: theme.cardColor, 
                  foregroundColor: theme.primaryColor,
                  side: BorderSide(color: theme.primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Se abrirá en tu navegador predeterminado",
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES (WEB) ---

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          "SERVICLY PREMIUM",
          style: TextStyle(
            color: theme.primaryColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Actualiza tu plan",
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildPlanItem(SubscriptionPlan plan, ThemeData theme) {
    final isSelected = _selectedPlanId == plan.id;
    final isDark = theme.brightness == Brightness.dark;

    return GlowCard(
      isSelected: isSelected,
      isRecommended: plan.isRecommended,
      onTap: () => _handlePlanSelection(plan.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.title.toUpperCase(),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          // EN WEB SÍ MOSTRAMOS PRECIOS
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "\$${plan.price}",
                style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 4),
              Text(plan.period, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          Text(plan.description),
          const SizedBox(height: 20),
          ...plan.features.map((f) => Row(
            children: [
              Icon(Icons.check, size: 16, color: theme.primaryColor),
              const SizedBox(width: 8),
              Expanded(child: Text(f)),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: FilledButton(
          onPressed: _isLoading ? null : _proceedToCheckout,
          child: _isLoading 
            ? const SizedBox(
                width: 24, 
                height: 24, 
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
              ) 
            : const Text("CONTINUAR AL PAGO"),
        ),
      ),
    );
  }
}