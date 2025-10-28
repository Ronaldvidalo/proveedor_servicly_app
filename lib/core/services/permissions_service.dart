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

  /// ¿Puede mostrar el módulo de Portafolio (Galería)?
  /// Solo disponible para planes de pago (o fundador).
  bool get canUsePortfolioModule {
    return planType == _planOptimiza || 
           planType == _planExpande || 
           planType == _planFundador;
  }
  
  /// ¿Puede mostrar el módulo de Reseñas de Clientes?
  /// Disponible para todos, pero lo definimos aquí por si cambia.
  bool get canUseReviewsModule {
    return true; 
  }

  // --- LÍMITES DE LA TIENDA/CATÁLOGO ---
  // Aquí implementamos tu idea de límites

  /// Límite de categorías de servicios/productos.
  int get maxCategories {
    switch (planType) {
      case _planConecta:
        return 5; // Límite para Plan Conecta (Free)
      case _planOptimiza:
        return 15; // Límite para Plan Optimiza
      case _planExpande:
      case _planFundador:
        return 999; // Ilimitado
      default:
        return 5;
    }
  }

  /// Límite de productos/servicios en total.
  int get maxProducts {
     switch (planType) {
      case _planConecta:
        return 50; // Límite para Plan Conecta (Free)
      case _planOptimiza:
        return 200; // Límite para Plan Optimiza
      case _planExpande:
      case _planFundador:
        return 9999; // Ilimitado
      default:
        return 50;
    }
  }

  /// Método de ayuda para verificar si se puede añadir un nuevo producto.
  bool canAddProduct(int currentProductCount) {
    return currentProductCount < maxProducts;
  }
  
  /// Método de ayuda para verificar si se puede añadir una nueva categoría.
  bool canAddCategory(int currentCategoryCount) {
    return currentCategoryCount < maxCategories;
  }
  /// ¿Puede usar el módulo de Promociones?
  /// (Ej: Disponible desde Optimiza)
  bool get canUsePromotionsModule {
    return planType == _planOptimiza ||
           planType == _planExpande ||
           planType == _planFundador;
  }

  /// ¿Puede usar el módulo de Gift Cards?
  /// (Ej: Solo para Expande/Fundador)
  bool get canUseGiftCardModule {
    return planType == _planExpande ||
           planType == _planFundador;
  }
}