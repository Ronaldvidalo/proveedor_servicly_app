import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para el Clipboard
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';

class ShareProfileButton extends StatelessWidget {
  final ProviderProfileModel profile;
  final Color brandColor;
  final bool isIconOnly;

  const ShareProfileButton({
    super.key,
    required this.profile,
    required this.brandColor,
    this.isIconOnly = true,
  });

  // --- LÓGICA REUTILIZABLE PRO ---
  static Future<void> share(BuildContext context, ProviderProfileModel profile) async {
    // 1. Link simulado (o real si tienes web)
    final String profileLink = "https://servicly.app/profile/${profile.providerId}";
    
    // 2. Mensaje Atractivo
    final String message = 
        "¡Hola! Echa un vistazo a mi perfil profesional en Servicly 🚀\n\n"
        "*${profile.businessName}*\n"
        "${profile.welcomeMessage}\n\n"
        "📍 ${profile.address ?? 'Servicio Profesional'}\n\n"
        "📲 Contáctame o pide tu cotización aquí: $profileLink";

    // 3. TRUCO PRO: Copiar al Portapapeles (Para Instagram/Facebook)
    await Clipboard.setData(ClipboardData(text: message));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Enlace copiado! Pégalo en tu historia o post.'), 
          duration: Duration(seconds: 2), 
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
        )
      );
    }

    // 4. Descargar Logo y Compartir
    String imageUrl = profile.logoUrl;

    if (imageUrl.isNotEmpty) {
      try {
        // Feedback visual
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preparando imagen de perfil...'), 
            duration: Duration(milliseconds: 800), 
            backgroundColor: Colors.black54,
            behavior: SnackBarBehavior.floating,
          )
        );

        final uri = Uri.parse(imageUrl);
        final response = await http.get(uri);
        final bytes = response.bodyBytes;
        final temp = await getTemporaryDirectory();
        final path = '${temp.path}/profile_share.jpg';
        File(path).writeAsBytesSync(bytes);

        // Compartir Archivo + Texto
        await Share.shareXFiles(
          [XFile(path)],
          text: message,
          subject: "Te comparto mi perfil: ${profile.businessName}",
        );
      } catch (e) {
        debugPrint("Error compartiendo logo: $e");
        Share.share(message, subject: "Mira este perfil: ${profile.businessName}");
      }
    } else {
      // Si no hay logo, solo texto
      Share.share(message, subject: "Mira este perfil: ${profile.businessName}");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isIconOnly) {
      return IconButton(
        onPressed: () => share(context, profile),
        icon: const Icon(Icons.share_rounded),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(8),
        ),
        tooltip: 'Compartir Perfil',
      );
    }

    return OutlinedButton.icon(
      onPressed: () => share(context, profile),
      style: OutlinedButton.styleFrom(
        foregroundColor: brandColor,
        side: BorderSide(color: brandColor.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.share_rounded, size: 20),
      label: const Text("Compartir"),
    );
  }
}