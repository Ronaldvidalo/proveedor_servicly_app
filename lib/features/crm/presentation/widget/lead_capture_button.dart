import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// --- Importaciones del Módulo CRM ---
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart';

/// Define los tipos de acción que puede realizar el botón.
enum ContactAction { whatsapp, phone, email, quote }

/// Widget reutilizable para botones de acción que capturan Leads.
///
/// Este widget encapsula la lógica de:
/// 1. Capturar el Lead en Firestore (usando CrmRepository).
/// 2. Lanzar la aplicación externa (WhatsApp, Teléfono, etc.).
class LeadCaptureButton extends StatelessWidget {
  /// El tipo de acción a realizar (Define el ícono y el esquema de URL).
  final ContactAction actionType;

  /// El valor del contacto (Número de teléfono, Email, o URL).
  final String contactValue;

  /// ID del proveedor, necesario para el CrmRepository.
  final String providerId;

  /// El texto visible del botón.
  final String label;

  /// Color de marca del proveedor (para estilizar el botón).
  final Color brandColor;

  /// Mensaje opcional para WhatsApp o Email.
  final String? message;

  /// Determina si se deben usar botones Outlined o Filled (para diálogos).
  final bool isOutline;

  const LeadCaptureButton({
    super.key,
    required this.actionType,
    required this.contactValue,
    required this.providerId,
    required this.label,
    required this.brandColor,
    this.message,
    this.isOutline = false, // Nuevo parámetro para el estilo
  });

  @override
  Widget build(BuildContext context) {
    // Definir el estilo base del botón
    final foregroundColor = ThemeData.estimateBrightnessForColor(brandColor) == Brightness.dark
        ? Colors.white
        : Colors.black;

    final buttonStyle = isOutline
        ? OutlinedButton.styleFrom(
            foregroundColor: brandColor,
            side: BorderSide(color: brandColor, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          )
        : FilledButton.styleFrom(
            backgroundColor: brandColor,
            foregroundColor: foregroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          );

    final button = isOutline
        ? OutlinedButton.icon(
            style: buttonStyle,
            icon: Icon(_getIconData(actionType)),
            label: Text(label),
            onPressed: () => handleAction(context), // Usar el método público
          )
        : FilledButton.icon(
            style: buttonStyle,
            icon: Icon(_getIconData(actionType)),
            label: Text(label),
            onPressed: () => handleAction(context), // Usar el método público
          );

    // Envolver en SizedBox para que ocupe todo el ancho si es un botón primario
    return SizedBox(width: double.infinity, child: button);
  }

  /// Lógica para manejar la acción de captura y lanzamiento.
  /// Se hace público para ser llamado desde otros widgets (e.g., LeadCaptureIcon).
  Future<void> handleAction(BuildContext context) async {
    final crmRepository = context.read<CrmRepository>();
    Uri? launchUri;
    String source;

    // 1. Determinar la URL y el origen (source) del Lead
    final cleanValue = contactValue.trim();

    switch (actionType) {
      case ContactAction.whatsapp:
        final cleanNumber = cleanValue.replaceAll(RegExp(r'[^\d]'), '');
        final formattedNumber = cleanNumber.startsWith('+') ? cleanNumber : '+$cleanNumber'; 
        final encodedMessage = Uri.encodeComponent(message ?? 'Hola, me gustaría más información.');
        launchUri = Uri.parse('https://wa.me/$formattedNumber?text=$encodedMessage');
        source = 'public_whatsapp';
        break;
      case ContactAction.phone:
        launchUri = Uri(scheme: 'tel', path: cleanValue);
        source = 'public_telefono';
        break;
      case ContactAction.email:
        launchUri = Uri(scheme: 'mailto', path: cleanValue, queryParameters: {'subject': label, 'body': message});
        source = 'public_email';
        break;
      case ContactAction.quote:
        // Caso especial: Solicitud de Presupuesto (asumimos que abre un modal o envía un email interno)
        launchUri = null; // No lanza app externa
        source = 'public_solicitud_presupuesto';
        break;
    }

    // 2. Capturar el Lead en Firestore
    try {
      if (launchUri != null || actionType == ContactAction.quote) {
        await crmRepository.captureLeadFromPublicProfile(
          email: actionType == ContactAction.email || actionType == ContactAction.quote ? cleanValue : null,
          nombreCompleto: 'Visitante CTA', 
          source: source,
          providerId: providerId,
          telefono: actionType == ContactAction.phone || actionType == ContactAction.whatsapp ? cleanValue : null,
        );
      }
    } catch (e) {
      debugPrint("Error crítico al capturar Lead: $e");
    }

    // 3. Lanzar la URL (si aplica)
    if (launchUri != null) {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir la aplicación externa.')));
      }
    } else if (actionType == ContactAction.quote && context.mounted) {
        // Mensaje de feedback para Solicitud de Presupuesto (sin URL externa)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Su solicitud ha sido registrada. ¡El proveedor le contactará pronto!'), backgroundColor: Colors.green),
        );
    }
  }

  // Define el IconData basado en el tipo de acción
  IconData _getIconData(ContactAction actionType) {
    switch (actionType) {
      case ContactAction.whatsapp:
        return Icons.chat_bubble_outline;
      case ContactAction.phone:
        return Icons.phone_outlined;
      case ContactAction.email:
        return Icons.email_outlined;
      case ContactAction.quote:
        return Icons.request_quote_outlined;
    }
  }
}