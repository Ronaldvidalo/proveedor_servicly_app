import 'package:flutter/material.dart';
import '../../../../../core/models/provider_profile_model.dart';

/// Un widget que renderiza el layout de perfil público estilo "CV Simple".
class CvLayout extends StatelessWidget {
  final ProviderProfileModel profile;

  const CvLayout({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    // Obtenemos los datos directamente del modelo fuertemente tipado.
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
                      // Maneja errores de red de forma elegante.
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
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Widgets auxiliares movidos aquí ---

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

