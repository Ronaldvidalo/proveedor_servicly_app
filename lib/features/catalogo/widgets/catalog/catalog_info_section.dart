import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';

class CatalogInfoSection extends StatelessWidget {
  final ProviderProfileModel profile;
  final Function(Uri url, String source) onContactTap;

  const CatalogInfoSection({
    super.key, 
    required this.profile, 
    required this.onContactTap
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            // Fondo ligeramente más claro que el scaffold para dar profundidad
            color: const Color(0xFF2D2D5A).withAlpha(150),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Información',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 20),
              
              // --- Ubicación y Horario con iconos minimalistas ---
              _buildInfoRow(
                Icons.location_on_outlined, 
                profile.address ?? "Ubicación a consultar"
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.access_time_outlined, 
                profile.openingHours ?? "Consultar horario"
              ),
              
              const SizedBox(height: 24),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 20),

              // --- Botones de Acción de Contacto ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (profile.phone != null)
                    _ContactCircleBtn(
                      icon: Icons.phone_outlined, 
                      label: "Llamar",
                      color: Colors.blueAccent,
                      onTap: () => onContactTap(Uri.parse("tel:${profile.phone}"), "tel"),
                    ),
                  if (profile.whatsapp != null)
                    _ContactCircleBtn(
                      icon: Icons.chat_bubble_outline_rounded, 
                      label: "WhatsApp",
                      color: const Color(0xFF25D366),
                      onTap: () {
                        final cleanNumber = profile.whatsapp!.replaceAll(RegExp(r'[^\d]'), '');
                        onContactTap(Uri.parse("https://wa.me/$cleanNumber"), "whatsapp");
                      },
                    ),
                  if (profile.contactEmail.isNotEmpty)
                    _ContactCircleBtn(
                      icon: Icons.email_outlined, 
                      label: "Email",
                      color: Colors.purpleAccent,
                      onTap: () => onContactTap(Uri.parse("mailto:${profile.contactEmail}"), "email"),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.white38),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text, 
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400)
          )
        ),
      ],
    );
  }
}

class _ContactCircleBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ContactCircleBtn({
    required this.icon, 
    required this.label, 
    required this.color, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(60)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500)
          ),
        ],
      ),
    );
  }
}