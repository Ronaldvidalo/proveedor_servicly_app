import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:geolocator/geolocator.dart';
import 'package:proveedor_servicly_app/core/services/location_service.dart';

// 1. Proveedor del servicio (Inyección de dependencias)
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

// 2. Notificador de Estado (Lógica de negocio)
class UserLocationNotifier extends StateNotifier<AsyncValue<Position?>> {
  final LocationService _locationService;

  UserLocationNotifier(this._locationService) : super(const AsyncValue.data(null));

  Future<void> captureUserLocation() async {
    // Emitimos estado de carga
    state = const AsyncValue.loading();
    try {
      // Llamamos al servicio
      final position = await _locationService.determinePosition();
      // Emitimos estado de éxito con los datos
      state = AsyncValue.data(position);
      
      if (kDebugMode) {
        print("Ubicación capturada: ${position.latitude}, ${position.longitude}");
      }
    } catch (e, stack) {
      // Emitimos estado de error
      state = AsyncValue.error(e, stack);
    }
  }
}

// 3. El Provider que usarás en la Pantalla (UI)
final userLocationProvider = StateNotifierProvider<UserLocationNotifier, AsyncValue<Position?>>((ref) {
  final service = ref.watch(locationServiceProvider);
  return UserLocationNotifier(service);
});