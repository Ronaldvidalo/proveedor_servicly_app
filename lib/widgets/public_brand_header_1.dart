import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/widgets/contact_icon_button.dart';
import 'package:proveedor_servicly_app/widgets/info_chip.dart'; // Para el helper IconsKE
import 'package:proveedor_servicly_app/widgets/follow_button.dart'; // <-- ¡NUEVA IMPORTACIÓN!

/// PLANTILLA 1: El Header Público Principal (Estilo Tarjeta de Presentación)
class PublicBrandHeader1 extends StatelessWidget {
  final ProviderProfileModel profile;
  final Function(String) onLaunchUrl;
  
  // --- CAMPOS MODIFICADOS ---
  // Ya no recibimos 'isFollowing' ni 'onFollowTap'
  // Recibimos el ID del cliente que está viendo.
  final String? clientId;

  const PublicBrandHeader1({
    super.key,
    required this.profile,
    required this.onLaunchUrl,
    this.clientId, // <-- AÑADIDO
  });

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Color(0xFF2D2D5A);
    const accentColor = Color(0xFF00BFFF);

    // (La lógica de 'contactIcons' no cambia...)
    final List<Widget> contactIcons = [];
    if (profile.phone != null && profile.phone!.isNotEmpty) {
      contactIcons.add(ContactIconButton(icon: Icons.phone, tooltip: 'Llamar', onTap: () => onLaunchUrl('tel:${profile.phone}')));
    }
    if (profile.whatsapp != null && profile.whatsapp!.isNotEmpty) {
      contactIcons.add(ContactIconButton(icon: Icons.message, tooltip: 'WhatsApp', onTap: () => onLaunchUrl('https://wa.me/${profile.whatsapp}')));
    }
    if (profile.website != null && profile.website!.isNotEmpty) {
      contactIcons.add(ContactIconButton(icon: Icons.language, tooltip: 'Web', onTap: () => onLaunchUrl(profile.website!)));
    }
    if (profile.instagram != null && profile.instagram!.isNotEmpty) {
      contactIcons.add(ContactIconButton(icon: IconsKE.instagram, tooltip: 'Instagram', onTap: () => onLaunchUrl('https://instagram.com/${profile.instagram}')));
    }
    if (profile.facebook != null && profile.facebook!.isNotEmpty) {
      contactIcons.add(ContactIconButton(icon: Icons.facebook, tooltip: 'Facebook', onTap: () => onLaunchUrl('https://facebook.com/${profile.facebook}')));
    }
    if (profile.tiktok != null && profile.tiktok!.isNotEmpty) {
      contactIcons.add(ContactIconButton(icon: Icons.music_note, tooltip: 'TikTok', onTap: () => onLaunchUrl('https://tiktok.com/${profile.tiktok}')));
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(24.0),
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
          // ... (Logo, Nombre, Eslogan, Dirección no cambian) ...
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
          if (profile.welcomeMessage.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              profile.welcomeMessage,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
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

          // --- 3. Botones de Acción (¡MODIFICADO!) ---
          Row(
            children: [
              Expanded(
                // ¡Usamos el nuevo widget!
                child: FollowButton(
                  providerId: profile.providerId,
                  clientId: clientId,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.message_outlined, size: 18),
                  label: const Text('Mensaje'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: accentColor.withAlpha(100)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    // TODO: Implementar navegación al Chat
                  },
                ),
              ),
            ],
          ),

          // --- 4. Barra de Iconos de Contacto (Sin cambios) ---
          if (contactIcons.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: contactIcons,
            ),
          ],
        ],
      ),
    );
  }
}