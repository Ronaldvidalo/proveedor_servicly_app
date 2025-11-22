import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- Módulo CRM (Ajustamos las rutas según la estructura de carpetas) ---
import 'package:proveedor_servicly_app/features/crm/presentation/widget/lead_capture_icon.dart'; // Necesario para ContactAction enum
import 'package:proveedor_servicly_app/features/crm/presentation/widget/lead_capture_button.dart'; // Widget compacto de icono
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart'; 


/// Widget reutilizable que muestra una fila de íconos de contacto (CTA)
/// que activan la captura de Leads de intención activa (FREE).
/// 
/// Utiliza los campos 'whatsapp', 'phone' y 'contactEmail' del ProviderProfileModel.
class ContactActionRow extends StatelessWidget {
  /// Color principal, generalmente el color de marca del proveedor.
  final Color brandColor;

  /// Estilo del icono (FilledButton.icon vs OutlinedButton.icon)
  final bool useOutlineStyle;
  
  const ContactActionRow({
    super.key,
    required this.brandColor,
    this.useOutlineStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    // Leemos el perfil del proveedor
    final profile = context.watch<ProviderProfileModel>(); 
    final providerId = profile.providerId;

    final List<Widget> actionButtons = [];
    
    // 1. WhatsApp
    if (profile.whatsapp != null && profile.whatsapp!.isNotEmpty) {
      actionButtons.add(
        LeadCaptureIcon(
          actionType: ContactAction.whatsapp,
          contactValue: profile.whatsapp!,
          providerId: providerId,
          brandColor: brandColor,
          useOutlineStyle: useOutlineStyle,
        )
      );
    }
    
    // 2. Teléfono
    if (profile.phone != null && profile.phone!.isNotEmpty) {
      actionButtons.add(
        LeadCaptureIcon(
          actionType: ContactAction.phone,
          contactValue: profile.phone!,
          providerId: providerId,
          brandColor: brandColor,
          useOutlineStyle: useOutlineStyle,
        )
      );
    }
    
    // 3. Email
    if (profile.contactEmail.isNotEmpty) {
      actionButtons.add(
        LeadCaptureIcon(
          actionType: ContactAction.email,
          contactValue: profile.contactEmail,
          providerId: providerId,
          brandColor: brandColor,
          useOutlineStyle: useOutlineStyle,
        )
      );
    }
    
    // 4. Cotización (Siempre activa si hay un email o es relevante)
    actionButtons.add(
      LeadCaptureIcon(
        actionType: ContactAction.quote,
        contactValue: profile.contactEmail.isNotEmpty ? profile.contactEmail : profile.phone ?? 'N/A', 
        providerId: providerId,
        brandColor: brandColor,
        useOutlineStyle: useOutlineStyle,
      )
    );

    // Si la lista de botones no está vacía, mostramos los botones con separadores.
    if (actionButtons.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Usamos .expand para añadir SizedBox entre botones de forma eficiente
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      // Los separadores se añaden entre cada botón
      children: actionButtons.expand((button) => [button, const SizedBox(width: 12)]).toList().sublist(0, actionButtons.length * 2 - 1),
    );
  }
}