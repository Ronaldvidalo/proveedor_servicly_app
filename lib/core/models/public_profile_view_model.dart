import 'package:flutter/foundation.dart';
import '../../../../core/models/provider_profile_model.dart';
import '../../../../core/services/provider_service.dart';

/// Documentation for `PublicProfileViewModel`.
///
/// This ViewModel manages the state for the [PublicProfileScreen]. It fetches
/// the provider's profile data using [ProviderService] and notifies its listeners
/// about state changes (loading, success, error).
class PublicProfileViewModel extends ChangeNotifier {
  final ProviderService _providerService;

  /// Creates an instance of [PublicProfileViewModel].
  ///
  /// Requires a [ProviderService] to fetch profile data.
  PublicProfileViewModel({required ProviderService providerService})
      : _providerService = providerService;

  /// The provider's profile data. Null if not yet fetched or if an error occurred.
  ProviderProfileModel? _profile;
  ProviderProfileModel? get profile => _profile;

  /// Represents the loading state of the profile fetching operation.
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Holds an error message if the fetching operation fails.
  String? _error;
  String? get error => _error;
  bool get hasError => _error != null;

  /// Fetches the profile for the given [providerId].
  ///
  /// Manages the state flow:
  /// 1. Sets loading to true.
  /// 2. Calls the [ProviderService] to get the data.
  /// 3. On success, updates the [profile].
  /// 4. On failure or if no profile is found, sets an [error] message.
  /// 5. Sets loading to false and notifies listeners.
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
