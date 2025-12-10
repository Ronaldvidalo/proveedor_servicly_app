// --- UX/UI Enhancement Comment ---
// Widget: PublicBrandHeader1
// Ubicación: lib/features/public_profile/screens/widgets/public_brand_header_1.dart
// Responsabilidad: Encabezado del perfil público con logo, nombre y botones de acción.
// Corrección: Se añade el parámetro 'providerName' a StoreQuoteButton y se manejan imports correctamente.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/widgets/follow_button.dart';
import 'package:proveedor_servicly_app/features/crm/presentation/widget/lead_capture_icon.dart';

// Importamos el widget donde está definido ContactAction que usa LeadCaptureIcon
// Si LeadCaptureIcon usa un enum interno o de otro archivo, asegúrate de importar ESE archivo.
// Asumiendo que LeadCaptureIcon y LeadCaptureButton comparten el mismo enum:
import 'package:proveedor_servicly_app/features/crm/presentation/widget/lead_capture_button.dart' show ContactAction; 

// --- IMPORTS DE WIDGETS ---
import 'package:proveedor_servicly_app/features/public_profile/screens/widgets/share_profile_button.dart';
import 'package:proveedor_servicly_app/features/budget/widgets/store_quote_button.dart'; 

class PublicBrandHeader1 extends StatelessWidget {
  final ProviderProfileModel profile;
  final Function(String) onLaunchUrl;
  final String? clientId;

  const PublicBrandHeader1({
    super.key,
    required this.profile,
    required this.onLaunchUrl,
    this.clientId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surface; 
    final accentColor = theme.colorScheme.primary; 

    // =========================================================
    // 1. CONSTRUCCIÓN DE LA LISTA DE ICONOS (CRM)
    // =========================================================
    final List<Widget> activeIcons = [];

    // A. Iconos de Contacto
    if (profile.whatsapp != null && profile.whatsapp!.isNotEmpty) {
      activeIcons.add(_buildCrmIcon(ContactAction.whatsapp, profile.whatsapp!, profile.providerId, accentColor));
    }
    if (profile.phone != null && profile.phone!.isNotEmpty) {
      activeIcons.add(_buildCrmIcon(ContactAction.phone, profile.phone!, profile.providerId, accentColor));
    }
    if (profile.contactEmail.isNotEmpty) {
      activeIcons.add(_buildCrmIcon(ContactAction.email, profile.contactEmail, profile.providerId, accentColor));
    }

    // B. Iconos Sociales
    if (profile.instagram != null && profile.instagram!.isNotEmpty) {
      activeIcons.add(_SocialIcon(
        icon: Icons.camera_alt, // Reemplazo seguro si no tienes IconsKE
        url: 'https://instagram.com/${profile.instagram}',
        brandColor: accentColor,
      ));
    }
    if (profile.facebook != null && profile.facebook!.isNotEmpty) {
      activeIcons.add(_SocialIcon(
        icon: Icons.facebook,
        url: 'https://facebook.com/${profile.facebook}',
        brandColor: accentColor,
      ));
    }
    if (profile.tiktok != null && profile.tiktok!.isNotEmpty) {
      activeIcons.add(_SocialIcon(
        icon: Icons.music_note,
        url: 'https://tiktok.com/${profile.tiktok}',
        brandColor: accentColor,
      ));
    }
    // =========================================================

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Stack(
        children: [
          // BOTÓN DE COMPARTIR
          Positioned(
            top: 12,
            right: 12,
            child: ShareProfileButton(
              profile: profile,
              brandColor: accentColor,
              isIconOnly: true, 
            ),
          ),

          // CONTENIDO PRINCIPAL
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Column(
              children: [
                // --- LOGO ---
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor, width: 3),
                    boxShadow: [
                      BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2)
                    ],
                    image: profile.logoUrl.isNotEmpty
                        ? DecorationImage(image: NetworkImage(profile.logoUrl), fit: BoxFit.cover)
                        : null,
                    color: const Color(0xFF1A1A2E),
                  ),
                  child: profile.logoUrl.isEmpty
                      ? const Icon(Icons.store, size: 50, color: Colors.white24)
                      : null,
                ),
                const SizedBox(height: 16),
                
                // --- NOMBRE ---
                Text(
                  profile.businessName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white, // O theme.colorScheme.onSurface
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                
                // --- ESLOGAN ---
                if (profile.welcomeMessage.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    profile.welcomeMessage,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                ],

                // --- UBICACIÓN ---
                if (profile.address != null && profile.address!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, size: 14, color: accentColor.withValues(alpha: 0.8)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          profile.address!,
                          style: TextStyle(color: accentColor.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // --- BOTONES DE ACCIÓN PRINCIPAL (CTA) ---
                Row(
                  children: [
                    // 1. Botón "Seguir"
                    Expanded(
                      child: FollowButton(
                        providerId: profile.providerId,
                        clientId: clientId,
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // 2. Botón "Cotizar" (NUEVO WIDGET INTEGRADO)
                    Expanded(
                      flex: 1, 
                      child: StoreQuoteButton(
                        providerId: profile.providerId,
                        // CORRECCIÓN: Se agrega providerName requerido
                        providerName: profile.businessName, 
                        brandColor: accentColor,
                        // No pasamos onPressedOverride, usa el flujo "Cliente -> Formulario"
                      ),
                    ),
                  ],
                ),
                
                // --- FILA DE ICONOS CRM ---
                if (activeIcons.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 16),
                  
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: activeIcons.map((icon) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: icon,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper para crear iconos CRM consistentes
  Widget _buildCrmIcon(ContactAction type, String value, String pId, Color color) {
    return LeadCaptureIcon(
      actionType: type,
      contactValue: value,
      providerId: pId,
      brandColor: color,
      useOutlineStyle: true,
    );
  }
}

/// Widget local para replicar el estilo de LeadCaptureIcon en redes sociales
class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final String url;
  final Color brandColor;

  const _SocialIcon({
    required this.icon,
    required this.url,
    required this.brandColor,
  });

  Future<void> _launch() async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 24),
      onPressed: _launch,
      style: IconButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: brandColor,
        side: BorderSide(color: brandColor.withValues(alpha: 0.4), width: 1),
        padding: const EdgeInsets.all(10),
        minimumSize: const Size.square(48),
      ),
    );
  }
}