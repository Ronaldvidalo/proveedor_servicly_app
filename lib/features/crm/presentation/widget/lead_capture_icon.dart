import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// Modelos y Servicios
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart';
import 'package:proveedor_servicly_app/features/crm/presentation/widget/lead_capture_button.dart'; // Para el Enum ContactAction

/// Widget compacto que muestra un ícono de acción de contacto.
/// Maneja su propia lógica de captura de leads para ser independiente.
class LeadCaptureIcon extends StatelessWidget {
  final ContactAction actionType;
  final String contactValue;
  final String providerId;
  final Color brandColor;
  final bool useOutlineStyle;

  const LeadCaptureIcon({
    super.key,
    required this.actionType,
    required this.contactValue,
    required this.providerId,
    required this.brandColor,
    this.useOutlineStyle = false,
  });

  // --- LÓGICA DE CAPTURA Y LANZAMIENTO ---
  Future<void> _handleAction(BuildContext context) async {
    final currentUser = context.read<UserModel?>();
    final crmRepo = context.read<CrmRepository>();
    
    Uri? launchUri;
    String source = '';
    final cleanValue = contactValue.trim();

    // 1. Configurar URL y Fuente
    switch (actionType) {
      case ContactAction.whatsapp:
        source = 'public_whatsapp';
        String cleanNum = cleanValue.replaceAll(RegExp(r'[^\d]'), '');
        if (!cleanNum.startsWith('+')) cleanNum = '+$cleanNum';
        // Mensaje genérico para el ícono
        String urlStr = "https://wa.me/$cleanNum";
        launchUri = Uri.parse(urlStr);
        break;
      case ContactAction.phone:
        source = 'public_telefono';
        launchUri = Uri.parse("tel:$cleanValue");
        break;
      case ContactAction.email:
        source = 'public_email';
        launchUri = Uri.parse("mailto:$cleanValue");
        break;
      case ContactAction.website: // --- ¡NUEVO CASO AÑADIDO! ---
        source = 'public_sitio_web';
        String url = cleanValue;
        if (!url.startsWith('http')) url = 'https://$url';
        launchUri = Uri.parse(url);
        break;
      case ContactAction.quote:
        source = 'public_solicitud_presupuesto';
        break;
    }

    // 2. Capturar Lead (Fire & Forget)
    try {
      crmRepo.captureLeadFromPublicProfile(
        providerId: providerId,
        source: source,
        email: currentUser?.email,
        nombreCompleto: currentUser?.displayName ?? 'Visitante Anónimo',
        telefono: null,
      );
    } catch (e) {
      debugPrint("Error capturando lead en icono: $e");
    }

    // 3. Lanzar Acción
    if (launchUri != null) {
      try {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('No se pudo abrir: $contactValue')),
          );
        }
      }
    } else if (actionType == ContactAction.quote && context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud de presupuesto registrada.'), backgroundColor: Colors.green),
       );
    }
  }

  IconData _getIconData(ContactAction actionType) {
    switch (actionType) {
      case ContactAction.whatsapp: return Icons.chat_bubble_outline;
      case ContactAction.phone: return Icons.phone_outlined;
      case ContactAction.email: return Icons.email_outlined;
      case ContactAction.website: return Icons.language_outlined; // --- ¡NUEVO CASO! ---
      case ContactAction.quote: return Icons.request_quote_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Estilo Visual
    final iconButtonStyle = IconButton.styleFrom(
      backgroundColor: useOutlineStyle ? Colors.transparent : Theme.of(context).colorScheme.surface,
      foregroundColor: brandColor,
      side: useOutlineStyle ? BorderSide(color: brandColor, width: 1.5) : BorderSide.none,
      padding: const EdgeInsets.all(12),
      minimumSize: const Size.square(52),
    );

    return IconButton(
      icon: Icon(_getIconData(actionType), size: 28),
      onPressed: () => _handleAction(context), // Llamamos a la lógica local
      style: iconButtonStyle,
    );
  }
}