import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart';

enum ContactAction { whatsapp, phone, email, website, quote }

class LeadCaptureButton extends StatelessWidget {
  final ContactAction actionType;
  final String contactValue;
  final String providerId;
  final Color brandColor;
  final String? label;
  final String? message;
  final bool isOutline;
  final VoidCallback? onPressedOverride;

  const LeadCaptureButton({
    super.key,
    required this.actionType,
    required this.contactValue,
    required this.providerId,
    required this.brandColor,
    this.label,
    this.message,
    this.isOutline = false,
    this.onPressedOverride,
  });

  Future<void> _handlePress(BuildContext context) async {
    // 1. Ejecutar override si existe (ej: cerrar diálogo)
    if (onPressedOverride != null) {
      onPressedOverride!();
    }

    final currentUser = context.read<UserModel?>();
    final crmRepo = context.read<CrmRepository>();

    Uri? launchUri;
    String source = '';

    // Lógica de URLs
    switch (actionType) {
      case ContactAction.whatsapp:
        source = 'whatsapp';
        String cleanNum = contactValue.replaceAll(RegExp(r'[^\d]'), '');
        if (!cleanNum.startsWith('+')) cleanNum = '+$cleanNum';
        String urlStr = "https://wa.me/$cleanNum";
        if (message != null) urlStr += "?text=${Uri.encodeComponent(message!)}";
        launchUri = Uri.parse(urlStr);
        break;
      case ContactAction.phone:
        source = 'telefono';
        launchUri = Uri.parse("tel:$contactValue");
        break;
      case ContactAction.email:
        source = 'email';
        launchUri = Uri.parse("mailto:$contactValue");
        break;
      case ContactAction.website:
        source = 'sitio_web';
        String url = contactValue;
        if (!url.startsWith('http')) url = 'https://$url';
        launchUri = Uri.parse(url);
        break;
      case ContactAction.quote:
        source = 'solicitud_presupuesto';
        break;
    }

    // 2. Capturar Lead con datos enriquecidos (Foto y Ubicación)
    try {
      // Intentamos obtener datos extras si el usuario está logueado
      String? photoUrl;
      String? location;

      if (currentUser != null) {
        // Priorizamos el logo del perfil público, si no, la foto de auth
        photoUrl = currentUser.personalization['logoUrl'] as String?;
        
        // Intentamos obtener país o dirección
        location = currentUser.personalization['country'] as String? ?? 
                   currentUser.personalization['address'] as String?;
      }

      await crmRepo.captureLeadFromPublicProfile(
        providerId: providerId,
        source: source,
        email: currentUser?.email,
        nombreCompleto: currentUser?.displayName,
        telefono: null, // Se podría sacar del perfil si existiera
        // --- NUEVOS CAMPOS ---
        photoUrl: photoUrl,
        location: location,
        // ---------------------
      );
    } catch (e) {
      debugPrint("Error capturando lead: $e");
    }

    // 3. Lanzar acción
    if (launchUri != null) {
      try {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    } else if (actionType == ContactAction.quote && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Solicitud registrada.'), backgroundColor: Colors.green)
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getIcon();
    final text = label ?? _getDefaultLabel();

    if (isOutline) {
      return OutlinedButton.icon(
        onPressed: () => _handlePress(context),
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: brandColor, 
          side: BorderSide(color: brandColor),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      return FilledButton.icon(
        onPressed: () => _handlePress(context),
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: FilledButton.styleFrom(
          backgroundColor: brandColor,
          foregroundColor: ThemeData.estimateBrightnessForColor(brandColor) == Brightness.dark 
              ? Colors.white : Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  IconData _getIcon() {
    switch (actionType) {
      case ContactAction.whatsapp: return Icons.chat_bubble;
      case ContactAction.phone: return Icons.phone;
      case ContactAction.email: return Icons.email;
      case ContactAction.website: return Icons.language;
      case ContactAction.quote: return Icons.request_quote;
    }
  }

  String _getDefaultLabel() {
    switch (actionType) {
      case ContactAction.whatsapp: return 'WhatsApp';
      case ContactAction.phone: return 'Llamar';
      case ContactAction.email: return 'Email';
      case ContactAction.website: return 'Web';
      case ContactAction.quote: return 'Cotizar';
    }
  }
}