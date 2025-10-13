import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/services/provider_service.dart';
import 'package:proveedor_servicly_app/core/models/public_profile_view_model.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/presentation/templates/tienda_layout.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/presentation/templates/cv_layout.dart';


/// La "mini-app" pública de un proveedor, visible para sus clientes.
///
/// Actúa como un director: obtiene los datos del perfil y decide qué plantilla/layout mostrar.
class PublicProfileScreen extends StatelessWidget {
  /// The unique ID of the provider whose profile will be displayed.
  final String providerId;

  /// Creates an instance of [PublicProfileScreen].
  ///
  /// The [providerId] is required to fetch the correct profile.
  const PublicProfileScreen({super.key, required this.providerId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PublicProfileViewModel(
        providerService: context.read<ProviderService>(),
      )..fetchProfile(providerId),
      child: Consumer<PublicProfileViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (viewModel.hasError || viewModel.profile == null) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(child: Text(viewModel.error ?? 'No se pudo encontrar el perfil del proveedor.')),
            );
          }

          final profile = viewModel.profile!;

          // --- EL CAMALEÓN: Elige qué layout construir ---
          // Ahora el 'profile' tiene el campo 'publicProfileTemplate' y los errores desaparecerán.
          switch (profile.publicProfileTemplate) {
            case 'tienda':
              return TiendaLayout(providerId: providerId, profile: profile);
            
            case 'cv':
              return CvLayout(profile: profile);
            
            // Un layout por defecto si la plantilla no se reconoce o es nula.
            default:
              return CvLayout(profile: profile);
          }
        },
      ),
    );
  }
}

