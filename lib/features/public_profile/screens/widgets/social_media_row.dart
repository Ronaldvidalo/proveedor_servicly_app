import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
// Asumimos que tiene un paquete de iconos para marcas, como font_awesome
// Si no lo tiene, usamos íconos de Material Design como placeholder.

/// Widget reutilizable que muestra una fila de íconos de Redes Sociales
/// que usan los datos del ProviderProfileModel para navegar a las URL.
class SocialMediaRow extends StatelessWidget {
  final Color brandColor;

  const SocialMediaRow({super.key, required this.brandColor});

  // Función para construir cada IconButton de Red Social
  Widget _buildSocialIcon(
      BuildContext context, IconData icon, String? url, String tooltip) {
    if (url == null || url.isEmpty) {
      return const SizedBox.shrink();
    }

    // Aseguramos que la URL tenga un protocolo para url_launcher
    String launchableUrl = url;
    if (!url.startsWith('http')) {
      launchableUrl = 'https://$url';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: IconButton(
        icon: Icon(icon, color: brandColor, size: 30),
        tooltip: tooltip,
        onPressed: () async {
          final uri = Uri.tryParse(launchableUrl);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri);
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('No se pudo abrir el enlace: $launchableUrl')),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProviderProfileModel>();

    // ✅ CORRECCIÓN: Se eliminó la variable 'surfaceColor' no utilizada.

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 1. Facebook
        _buildSocialIcon(
          context,
          Icons.facebook, // Placeholder de Material
          profile.facebook,
          'Facebook',
        ),
        // 2. Instagram
        _buildSocialIcon(
          context,
          Icons.camera_alt_outlined, // Placeholder de Material
          profile.instagram,
          'Instagram',
        ),
        // 3. TikTok
        _buildSocialIcon(
          context,
          Icons.tiktok_sharp, // Asumimos un ícono similar
          profile.tiktok,
          'TikTok',
        ),
        // 4. Website
        _buildSocialIcon(
          context,
          Icons.language_outlined,
          profile.website,
          'Sitio Web',
        ),
      ],
    );
  }
}