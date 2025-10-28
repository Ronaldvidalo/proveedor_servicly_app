import 'package:proveedor_servicly_app/core/models/user_model.dart';

// Constantes para los nombres de planes. Evita "strings mágicos".
const String _planConecta = 'conecta'; // Free
const String _planOptimiza = 'optimiza'; // Standard
const String _planExpande = 'expande'; // Premium
const String _planFundador = 'fundador'; // Founder (Premium)

/// Servicio que centraliza la lógica de negocio y los permisos
/// basados en el plan de suscripción del usuario.
class PermissionsService {
  final UserModel _user;

  PermissionsService(this._user);

  /// El tipo de plan actual del usuario.
  String get planType => _user.planType ?? _planConecta; // Default 'conecta' (free)

  // --- PERMISOS DE MÓDULOS DE CATÁLOGO ---

  /// ¿Puede usar el módulo de Video de Bienvenida?
  /// Solo disponible para planes de pago (o fundador).
  bool get canUseWelcomeVideo {
    return planType == _planOptimiza || 
           planType == _planExpande || 
           planType == _planFundador;
  }

  /// ¿Puede MOSTRAR el módulo de Portafolio (Galería)?
  /// CORRECCIÓN: Todos los planes pueden mostrarlo. Los límites se aplican al AÑADIR.
  bool get canUsePortfolioModule {
    return true; 
  }
  
  /// ¿Puede MOSTRAR el módulo de Promociones?
  /// CORRECCIÓN: Todos los planes pueden mostrarlo (o al menos el "conecta").
  bool get canUsePromotionsModule {
     // Decidamos: ¿El plan "conecta" puede gestionar promociones?
     // Por ahora, sigamos tu mockup: requiere Optimiza.
     // Si "conecta" SÍ puede, cambia esto a 'return true;'
     return planType == _planOptimiza || 
           planType == _planExpande || 
           planType == _planFundador;
  }

  /// ¿Puede MOSTRAR el módulo de Gift Cards?
  /// (Esto sí parece solo para planes altos)
  bool get canUseGiftCardModule {
    return planType == _planExpande || 
           planType == _planFundador;
  }

  /// ¿Puede mostrar el módulo de Reseñas de Clientes?
  /// Disponible para todos.
  bool get canUseReviewsModule {
    return true; 
  }

  // --- LÍMITES DE LA TIENDA/CATÁLOGO ---

  /// Límite de categorías de PRODUCTOS (Servicios).
  int get maxProductCategories {
    switch (planType) {
      case _planConecta:
        return 5;
      case _planOptimiza:
        return 15;
      case _planExpande:
      case _planFundador:
        return 999; // Ilimitado
      default:
        return 5;
    }
  }
  
  /// Límite de PRODUCTOS (Servicios) en total.
  int get maxProducts {
     switch (planType) {
      case _planConecta:
        return 50;
      case _planOptimiza:
        return 200;
      case _planExpande:
      case _planFundador:
        return 9999; // Ilimitado
      default:
        return 50;
    }
  }

  // --- LÍMITES DEL PORTAFOLIO (Tu nueva lógica) ---

  /// Límite de categorías de PORTAFOLIO (Carpetas).
  int get maxPortfolioCategories {
     switch (planType) {
      case _planConecta:
        return 5; // Límite para Plan Conecta (Free)
      case _planOptimiza:
        return 20;
      case _planExpande:
      case _planFundador:
        return 999; // Ilimitado
      default:
        return 5;
    }
  }

  /// Límite de ÍTEMS (fotos/videos) del portafolio en total.
  int get maxPortfolioItems {
     switch (planType) {
      case _planConecta:
        return 25; // Ej: 5 carpetas * 5 ítems = 25
      case _planOptimiza:
        return 100;
      case _planExpande:
      case _planFundador:
        return 9999; // Ilimitado
      default:
        return 25;
    }
  }
  
  // --- MÉTODOS DE AYUDA (CHECKS) ---

  bool canAddProduct(int currentProductCount) {
    return currentProductCount < maxProducts;
  }
  
  bool canAddProductCategory(int currentCategoryCount) {
    return currentCategoryCount < maxProductCategories;
  }

  bool canAddPortfolioCategory(int currentCategoryCount) {
    return currentCategoryCount < maxPortfolioCategories;
  }
  
  bool canAddPortfolioItem(int currentItemCount) {
    return currentItemCount < maxPortfolioItems;
  }

  // Límite de 1 minuto por video (requerirá lógica en la app, no aquí)
  Duration get maxVideoDuration {
     switch (planType) {
      case _planConecta:
        return const Duration(minutes: 1);
      case _planOptimiza:
      case _planExpande:
      case _planFundador:
        return const Duration(minutes: 5); // O sin límite
      default:
        return const Duration(minutes: 1);
    }
  }
}