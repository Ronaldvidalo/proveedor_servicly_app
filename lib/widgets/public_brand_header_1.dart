import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/widgets/follow_button.dart';

// Widgets de CRM y UI
// Asegúrate de que LeadCaptureIcon exista o usa el widget que acabamos de crear si quieres reemplazar los iconos pequeños también
import 'package:proveedor_servicly_app/features/crm/presentation/widget/lead_capture_icon.dart'; 
// IMPORTANTE: Importamos el botón que acabamos de crear
import 'package:proveedor_servicly_app/features/crm/presentation/widget/lead_capture_button.dart';
import 'package:proveedor_servicly_app/widgets/info_chip.dart'; // Para IconsKE

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
    // Usamos el tema directamente si está disponible, o constantes como fallback
    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surface; // Antes Color(0xFF2D2D5A)
    final accentColor = theme.colorScheme.primary;  // Antes Color(0xFF00BFFF)

    // =========================================================
    // 1. CONSTRUCCIÓN DE LA LISTA DE ICONOS (SOLO SI EXISTEN DATOS)
    // =========================================================
    final List<Widget> activeIcons = [];

    // A. Iconos de Contacto (Capturan Leads)
    if (profile.whatsapp != null && profile.whatsapp!.isNotEmpty) {
      activeIcons.add(_buildCrmIcon(ContactAction.whatsapp, profile.whatsapp!, profile.providerId, accentColor));
    }
    if (profile.phone != null && profile.phone!.isNotEmpty) {
      activeIcons.add(_buildCrmIcon(ContactAction.phone, profile.phone!, profile.providerId, accentColor));
    }
    if (profile.contactEmail.isNotEmpty) {
      activeIcons.add(_buildCrmIcon(ContactAction.email, profile.contactEmail, profile.providerId, accentColor));
    }
    if (profile.website != null && profile.website!.isNotEmpty) {
      // Nota: ContactAction.website no estaba en el enum original que me pasaste, 
      // asumo que lo manejas como un link externo o debes agregarlo al enum.
      // Por ahora lo dejo comentado para evitar errores si no existe en tu enum.
      // activeIcons.add(_buildCrmIcon(ContactAction.website, profile.website!, profile.providerId, accentColor));
    }

    // B. Iconos Sociales
    if (profile.instagram != null && profile.instagram!.isNotEmpty) {
      activeIcons.add(_SocialIcon(
        icon: IconsKE.instagram, 
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
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(100), blurRadius: 15, offset: const Offset(0, 8)),
        ],
        border: Border.all(color: accentColor.withAlpha(50)),
      ),
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
                BoxShadow(color: accentColor.withAlpha(80), blurRadius: 20, spreadRadius: 2)
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
              color: Colors.white,
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
                Icon(Icons.location_on, size: 14, color: accentColor.withAlpha(200)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    profile.address!,
                    style: TextStyle(color: accentColor.withAlpha(200), fontSize: 13, fontWeight: FontWeight.w500),
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
              // 1. Botón "Seguir" (Secundario)
              // Mantenemos tu FollowButton existente, pero le damos menos espacio (flex 1)
              // si queremos que el de Cotizar destaque más, o los dejamos iguales.
              Expanded(
                child: FollowButton(
                  providerId: profile.providerId,
                  clientId: clientId,
                  // Si tu FollowButton soporta estilo, idealmente que sea 'Outlined'
                ),
              ),
              
              const SizedBox(width: 12), // Espacio reducido para que quepan mejor
              
              // 2. Botón "Solicitar Presupuesto" (PRIMARIO)
              // Reemplaza al antiguo botón de "Mensaje"
              Expanded(
                flex: 1, // Opcional: pon '2' si quieres que sea el doble de grande
                child: LeadCaptureButton(
                  actionType: ContactAction.quote, // Acción: Presupuesto
                  contactValue: '', // No necesita valor externo, es interno
                  providerId: profile.providerId,
                  label: 'Cotizar', // Texto corto y potente
                  brandColor: accentColor,
                  isOutline: false, // FALSE = Relleno con Glow (Destacado)
                  message: 'Hola, me gustaría solicitar una cotización.',
                ),
              ),
            ],
          ),
          
          // --- FILA DE ICONOS DESLIZABLE (HORIZONTAL SCROLL) ---
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
    );
  }

  // Helper para crear iconos CRM consistentes
  Widget _buildCrmIcon(ContactAction type, String value, String pId, Color color) {
    // Asegúrate de que LeadCaptureIcon esté importado correctamente
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
        side: BorderSide(color: brandColor.withAlpha(100), width: 1),
        padding: const EdgeInsets.all(10),
        minimumSize: const Size.square(48),
      ),
    );
  }
}