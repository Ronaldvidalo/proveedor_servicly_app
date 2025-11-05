import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/services/provider_service.dart';
import 'package:proveedor_servicly_app/core/models/public_profile_view_model.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/presentation/templates/tienda_layout.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/presentation/templates/cv_layout.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/presentation/templates/catalog_layout.dart';
// Módulo CRM
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart';


/// La "mini-app" pública de un proveedor, visible para sus clientes.
/// Ahora actúa como el inyector del CrmRepository para la captura de Leads.
class PublicProfileScreen extends StatelessWidget {
  final String providerId;

  const PublicProfileScreen({super.key, required this.providerId});

  @override
  Widget build(BuildContext context) {
    // Inyectamos el Repositorio y el ViewModel para que las plantillas puedan acceder al CRM
    return MultiProvider(
      providers: [
        // 1. Inyectar el ViewModel de Perfil
        ChangeNotifierProvider(
          create: (context) => PublicProfileViewModel(
            providerService: context.read<ProviderService>(),
          )..fetchProfile(providerId),
        ),
        // 2. Inyectar el Repositorio CRM (esencial para la captura de leads)
        // Ya que el Dashboard no inyecta este Provider, lo hacemos aquí.
        Provider(create: (_) => CrmRepository()), 
      ],
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

          // --- CORRECCIÓN CLAVE: Usamos 'profile.profileType' en lugar de 'profile.publicProfileTemplate' ---
          switch (profile.profileType) { 
            case 'catalog':
              return CatalogLayout(providerId: providerId, profile: profile);
            
            case 'store':
              return TiendaLayout(providerId: providerId, profile: profile);
            
            case 'cv':
              return CvLayout(profile: profile);
            
            default:
              return CvLayout(profile: profile);
          }
        },
      ),
    );
  }
}