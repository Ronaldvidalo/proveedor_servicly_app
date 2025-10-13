import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// --- CORRECCIÓN: Se ajustan las rutas para que coincidan con la estructura del proyecto ---
import '../../../core/models/provider_profile_model.dart';
import '../../../core/services/provider_service.dart';
import 'package:proveedor_servicly_app/core/services/provider_service.dart';
import 'package:proveedor_servicly_app/core/models/public_profile_view_model.dart';


/// La "mini-app" pública de un proveedor, visible para sus clientes.
///
/// Construye su UI dinámicamente basada en la configuración de personalización
/// del proveedor, utilizando un ViewModel para gestionar el estado.
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
          switch (profile.publicProfileFormat) {
            case 'portfolio':
              // TODO: Construir el layout de Portafolio/Catálogo
              return _buildCvLayout(context, profile); // Placeholder
            case 'store':
              // TODO: Construir el layout de Tienda
              return _buildCvLayout(context, profile); // Placeholder
            case 'cv':
            default:
              return _buildCvLayout(context, profile);
          }
        },
      ),
    );
  }

  /// Construye el layout de perfil público estilo "CV Simple".
  Widget _buildCvLayout(BuildContext context, ProviderProfileModel profile) {
    // We now get all data directly from the strongly-typed model.
    final brandColor = profile.brandColor;
    final businessName = profile.businessName;
    final logoUrl = profile.logoUrl;
    final welcomeMessage = profile.welcomeMessage;
    final contactEmail = profile.contactEmail;
    final address = profile.address;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: brandColor,
            foregroundColor: ThemeData.estimateBrightnessForColor(brandColor) == Brightness.dark
                ? Colors.white
                : Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                businessName,
                style: const TextStyle(shadows: [Shadow(color: Colors.black38, blurRadius: 4)]),
              ),
              centerTitle: true,
              background: logoUrl.isNotEmpty
                  ? Image.network(
                      logoUrl,
                      fit: BoxFit.cover,
                      // Handle potential network errors gracefully
                      errorBuilder: (context, error, stackTrace) => Container(color: brandColor.withOpacity(0.5)),
                    )
                  : Container(color: brandColor.withOpacity(0.5)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                _SectionTitle(title: 'Sobre Nosotros'),
                const SizedBox(height: 8),
                Text(welcomeMessage, style: Theme.of(context).textTheme.bodyLarge),
                const Divider(height: 48),

                _SectionTitle(title: 'Información de Contacto'),
                const SizedBox(height: 16),
                if (contactEmail.isNotEmpty)
                  _ContactInfoTile(
                    icon: Icons.email_outlined,
                    text: contactEmail,
                  ),
                if (address != null && address.isNotEmpty)
                  _ContactInfoTile(
                    icon: Icons.location_on_outlined,
                    text: address,
                  ),
                // TODO: Añadir más campos de contacto como teléfono, redes sociales, etc.
                const Divider(height: 48),

                _buildModulesSection(context, profile),
              ]),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Builds the list of active modules. (Re-integrated from previous version)
  Widget _buildModulesSection(BuildContext context, ProviderProfileModel profile) {
    if (profile.activeModules.isEmpty) {
      return const SizedBox.shrink(); // Don't show anything if no modules are active
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Nuestros Servicios'),
        const SizedBox(height: 16),
        ...profile.activeModules.map((moduleName) {
          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 12.0),
            child: ListTile(
              leading: Icon(Icons.extension, color: profile.brandColor),
              title: Text(moduleName),
              subtitle: const Text('Funcionalidad próximamente disponible.'),
            ),
          );
        }).toList(),
      ],
    );
  }
}

// --- Widgets auxiliares para el layout ---
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _ContactInfoTile extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContactInfoTile({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

