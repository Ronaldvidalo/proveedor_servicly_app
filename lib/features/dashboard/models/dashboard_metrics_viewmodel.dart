import 'package:flutter/foundation.dart';
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart'; // Importar el repositorio
import 'dart:async';

/// ViewModel que gestiona y expone las métricas principales del Dashboard (ej: Conteo de Leads, Visitas).
class DashboardMetricsViewModel extends ChangeNotifier {
  final CrmRepository _crmRepository;
  
  // --- Métrica de Leads ---
  int _leadCount = 0;
  StreamSubscription<int>? _leadSubscription;

  // --- Métrica de Visitas (Placeholder para futura implementación) ---
  int _visitCount = 0; 
  
  // --- GETTERS PÚBLICOS ---
  int get leadCount => _leadCount;
  int get visitCount => _visitCount; // Retorna el valor actual (0 hasta implementar el Stream)

  DashboardMetricsViewModel(this._crmRepository) {
    _loadLeadCount();
    // _loadVisitCount(); // Iniciar stream de visitas cuando esté disponible
  }

  /// Inicializa la suscripción al stream de conteo de Leads.
  void _loadLeadCount() {
    _leadSubscription?.cancel();
    
    // Usamos el Stream del CrmRepository para obtener el conteo en tiempo real
    _leadSubscription = _crmRepository.getLeadCountStream().listen((count) {
      if (_leadCount != count) {
        _leadCount = count;
        notifyListeners(); // Notifica al DashboardMetricsCard del cambio
      }
    }, onError: (error) {
      if (kDebugMode) {
        print('Error al cargar stream de conteo de Leads: $error');
      }
    });
  }
  
  // Función placeholder para la métrica de Visitas (Si se basa en un Stream futuro)
  /*
  void _loadVisitCount() {
      // Ejemplo: si el repositorio tiene un Stream para visitas por semana
      // _visitSubscription = _crmRepository.getVisitCountStream().listen((count) {
      //     _visitCount = count;
      //     notifyListeners();
      // });
  }
  */

  @override
  void dispose() {
    _leadSubscription?.cancel();
    super.dispose();
  }
}