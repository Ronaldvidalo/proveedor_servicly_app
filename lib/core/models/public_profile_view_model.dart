import 'package:flutter/foundation.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/services/provider_service.dart';

/// Gestiona el estado de la [PublicProfileScreen].
///
/// Obtiene los datos del perfil del proveedor utilizando [ProviderService] y
/// notifica a sus listeners sobre los cambios de estado (cargando, éxito, error).
class PublicProfileViewModel extends ChangeNotifier {
  final ProviderService _providerService;

  /// Crea una instancia de [PublicProfileViewModel].
  ///
  /// Requiere un [ProviderService] para obtener los datos del perfil.
  PublicProfileViewModel({required ProviderService providerService})
      : _providerService = providerService;

  /// Los datos del perfil del proveedor. Es nulo si aún no se han obtenido o si ocurrió un error.
  ProviderProfileModel? _profile;
  ProviderProfileModel? get profile => _profile;

  /// Representa el estado de carga de la operación de obtención del perfil.
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Contiene un mensaje de error si la operación de obtención falla.
  String? _error;
  String? get error => _error;
  bool get hasError => _error != null;

  /// Obtiene el perfil para un [providerId] dado.
  ///
  /// Gestiona el flujo de estado:
  /// 1. Establece el estado de carga a verdadero.
  /// 2. Llama al [ProviderService] para obtener los datos.
  /// 3. Si tiene éxito, actualiza el [profile].
  /// 4. Si falla o no se encuentra el perfil, establece un mensaje de [error].
  /// 5. Establece el estado de carga a falso y notifica a los listeners.
  Future<void> fetchProfile(String providerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _providerService.getProviderProfile(providerId);

      if (_profile == null) {
        _error = 'No se pudo encontrar el perfil del proveedor.';
      }
    } catch (e) {
      _error = 'Ocurrió un error al cargar el perfil. Intente nuevamente.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

