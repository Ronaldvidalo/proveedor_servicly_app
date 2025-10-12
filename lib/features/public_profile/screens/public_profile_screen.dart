/// lib/features/public_profile/screens/public_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';

/// La "mini-app" pública de un proveedor, visible para sus clientes.
/// Construye su UI dinámicamente basada en la configuración de personalización
/// del proveedor.
class PublicProfileScreen extends StatefulWidget {
  final String providerId;
  const PublicProfileScreen({super.key, required this.providerId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  late Future<UserModel?> _providerFuture;

  @override
  void initState() {
    super.initState();
    // Al iniciar la pantalla, llamamos al servicio para obtener los datos del proveedor.
    _providerFuture = context.read<FirestoreService>().getUser(widget.providerId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _providerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('No se pudo encontrar el perfil del proveedor.')),
          );
        }

        final provider = snapshot.data!;
        final format = provider.personalization['publicProfileFormat'] as String? ?? 'cv';

        // --- EL CAMALEÓN: Elige qué layout construir ---
        switch (format) {
          case 'portfolio':
            // TODO: Construir el layout de Portafolio/Catálogo
            return _buildCvLayout(provider); // Placeholder
          case 'store':
            // TODO: Construir el layout de Tienda
            return _buildCvLayout(provider); // Placeholder
          case 'cv':
          default:
            return _buildCvLayout(provider);
        }
      },
    );
  }

  /// Construye el layout de perfil público estilo "CV Simple".
  Widget _buildCvLayout(UserModel provider) {
    final personalization = provider.personalization;
    final brandColor = _colorFromHex(personalization['primaryColor'] as String?) ?? Theme.of(context).primaryColor;
    final businessName = personalization['businessName'] as String? ?? 'Proveedor de Servicios';
    final logoUrl = personalization['logoUrl'] as String?;
    final welcomeMessage = personalization['welcomeMessage'] as String? ?? 'Servicios profesionales a tu disposición.';
    final contactEmail = personalization['contactEmail'] as String? ?? provider.email;
    final address = personalization['address'] as String?;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: brandColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                businessName, 
                style: const TextStyle(shadows: [Shadow(color: Colors.black38, blurRadius: 4)])
              ),
              background: logoUrl != null
                  ? Image.network(logoUrl, fit: BoxFit.cover)
                  : Container(color: brandColor.withOpacity(0.5)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                _SectionTitle(title: 'Sobre Mí'),
                const SizedBox(height: 8),
                Text(welcomeMessage, style: Theme.of(context).textTheme.bodyLarge),
                const Divider(height: 48),

                _SectionTitle(title: 'Información de Contacto'),
                const SizedBox(height: 16),
                if (contactEmail != null)
                  _ContactInfoTile(
                    icon: Icons.email_outlined,
                    text: contactEmail,
                  ),
                if (address != null)
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

  /// Función de utilidad para convertir un color Hex a un objeto Color.
  Color? _colorFromHex(String? hexColor) {
    if (hexColor == null) return null;
    final hexCode = hexColor.replaceAll('#', '');
    if (hexCode.length == 6) {
      return Color(int.parse('FF$hexCode', radix: 16));
    }
    return null;
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
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}