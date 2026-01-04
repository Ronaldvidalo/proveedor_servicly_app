import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart'; // <--- Importamos el correcto

class DashboardContext extends ChangeNotifier {
  // Si es null, estamos viendo el "Resumen Global"
  ProviderProfileModel? _selectedProfile;

  ProviderProfileModel? get selectedProfile => _selectedProfile;
  
  bool get isGlobalView => _selectedProfile == null;

  void selectProfile(ProviderProfileModel profile) {
    _selectedProfile = profile;
    notifyListeners();
  }

  void selectGlobal() {
    _selectedProfile = null;
    notifyListeners();
  }
}