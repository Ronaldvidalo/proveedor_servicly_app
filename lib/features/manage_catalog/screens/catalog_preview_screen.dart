import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/presentation/templates/catalog_layout.dart';

/// Muestra el CatalogLayout usando un ProviderProfileModel temporal
/// construido en memoria para previsualización.
class CatalogPreviewScreen extends StatelessWidget {
  final ProviderProfileModel previewProfile;

  const CatalogPreviewScreen({
    super.key,
    required this.previewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vista Previa'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // El cuerpo es simplemente el CatalogLayout, al que le pasamos
      // el perfil temporal que construimos.
      body: CatalogLayout(
        providerId: previewProfile.providerId,
        profile: previewProfile,
      ),
    );
  }
}