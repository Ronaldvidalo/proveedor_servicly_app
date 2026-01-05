// lib/features/subscriptions/domain/models/subscription_plan.dart

enum PlanType { free, pro, corporate }

class SubscriptionPlan {
  final String id;
  final PlanType type;
  final String title;
  final String description;
  final double price;
  final String period; // '/mes', '/año'
  final List<String> features;
  final bool isRecommended;

  const SubscriptionPlan({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.price,
    required this.period,
    required this.features,
    this.isRecommended = false,
  });

  // Datos Mock para la UI (simulando respuesta de backend/config remota)
  static List<SubscriptionPlan> get availablePlans => [
        const SubscriptionPlan(
          id: 'plan_free',
          type: PlanType.free,
          title: 'Starter',
          description: 'Para probar la experiencia.',
          price: 0,
          period: '/siempre',
          features: ['Acceso básico', 'Publicidad incluida', 'Soporte estándar'],
        ),
        const SubscriptionPlan(
          id: 'plan_pro',
          type: PlanType.pro,
          title: 'Profesional',
          description: 'Potencia tu carrera individual.',
          price: 19.99,
          period: '/mes',
          features: [
            'Sin publicidad',
            'Soporte prioritario 24/7',
            'Insignia "Glover Pro"',
            'Acceso a estadísticas'
          ],
          isRecommended: true, // Este tendrá el Glow pulsante
        ),
        const SubscriptionPlan(
          id: 'plan_corp',
          type: PlanType.corporate,
          title: 'Corporativo',
          description: 'Escala tu negocio.',
          price: 29.99,
          period: '/mes',
          features: [
            'Todo lo de PRO',
            'Gestión de equipos',
            'API dedicada',
            'Facturación empresarial'
          ],
        ),
      ];
}