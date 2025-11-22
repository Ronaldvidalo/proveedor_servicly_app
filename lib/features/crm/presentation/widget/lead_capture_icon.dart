import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/features/crm/presentation/widget/lead_capture_button.dart'; // Importar el botón principal

/// Widget compacto que muestra un ícono de acción de contacto y
/// encapsula la lógica de captura de Leads llamando a LeadCaptureButton.handleAction.
class LeadCaptureIcon extends StatelessWidget {
  /// El tipo de acción a realizar.
  final ContactAction actionType;

  /// El valor del contacto (Número de teléfono, Email, o URL).
  final String contactValue;

  /// ID del proveedor, necesario para la captura de leads.
  final String providerId;

  /// El color de marca del proveedor.
  final Color brandColor;

  /// Estilo de borde (para el OutlinedButton.icon vs FilledButton.icon).
  final bool useOutlineStyle;

  const LeadCaptureIcon({
    super.key,
    required this.actionType,
    required this.contactValue,
    required this.providerId,
    required this.brandColor,
    this.useOutlineStyle = false,
  });

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

  @override
  Widget build(BuildContext context) {
    // Definir el estilo de IconButton para la apariencia visual.
    final iconButtonStyle = IconButton.styleFrom(
      backgroundColor: useOutlineStyle ? Colors.transparent : Theme.of(context).colorScheme.surface,
      foregroundColor: brandColor,
      side: useOutlineStyle ? BorderSide(color: brandColor, width: 1.5) : BorderSide.none,
      padding: const EdgeInsets.all(12),
      minimumSize: const Size.square(52), // Tamaño mínimo para un buen target táctil
    );

    // Creamos una instancia de LeadCaptureButton SÓLO para acceder a la lógica de acción.
    final leadButtonInstance = LeadCaptureButton(
      actionType: actionType,
      contactValue: contactValue,
      providerId: providerId,
      label: actionType.name, // Usar el nombre de la acción como etiqueta interna
      brandColor: brandColor,
      isOutline: useOutlineStyle,
    );

    return IconButton(
      icon: Icon(_getIconData(actionType), size: 28),
      onPressed: () => leadButtonInstance.handleAction(context),
      style: iconButtonStyle,
    );
  }
}