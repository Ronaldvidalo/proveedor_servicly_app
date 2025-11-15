import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/features/settings/screens/brand_settings_screen.dart';
import 'package:proveedor_servicly_app/widgets/info_chip.dart';

/// Encabezado de Marca (REUTILIZABLE)
class BrandHeaderCard extends StatefulWidget {
  final UserModel user;
  final Function(ProviderProfileModel) onShowContacts;
  final Function(String) onLaunchUrl;

  const BrandHeaderCard({
    super.key,
    required this.user,
    required this.onShowContacts,
    required this.onLaunchUrl,
  });

  @override
  State<BrandHeaderCard> createState() => _BrandHeaderCardState();
}

class _BrandHeaderCardState extends State<BrandHeaderCard> {
  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    const surfaceColor = Color(0xFF2D2D5A);
    const accentColor = Color(0xFF00BFFF);

    return StreamBuilder<ProviderProfileModel?>(
      stream: firestoreService.getBrandProfile(widget.user.uid),
      builder: (context, snapshot) {
        // 1. Estado de Carga (Retorna Widget normal, NO Sliver)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 140,
            child: Center(child: CircularProgressIndicator(color: accentColor)),
          );
        }

        // 2. Estado Vacío/Error (Retorna Widget normal, NO Sliver)
        if (!snapshot.hasData || snapshot.data == null) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => BrandSettingsScreen(
                      user: widget.user, brandProfile: null),
                ));
              },
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                    color: accentColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: accentColor.withAlpha(80))),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.edit_outlined, color: accentColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Completa tu perfil de marca para más visibilidad',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final brandProfile = snapshot.data!;

        final bool hasContactInfo =
            (brandProfile.phone != null && brandProfile.phone!.isNotEmpty) ||
                (brandProfile.whatsapp != null &&
                    brandProfile.whatsapp!.isNotEmpty) ||
                (brandProfile.contactEmail.isNotEmpty) ||
                (brandProfile.website != null &&
                    brandProfile.website!.isNotEmpty) ||
                (brandProfile.instagram != null &&
                    brandProfile.instagram!.isNotEmpty) ||
                (brandProfile.facebook != null &&
                    brandProfile.facebook!.isNotEmpty) ||
                (brandProfile.tiktok != null &&
                    brandProfile.tiktok!.isNotEmpty);

        // 3. Contenido Principal (Retorna Container, NO Sliver)
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withAlpha(100)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF1A1A2E),
                    backgroundImage: brandProfile.logoUrl.isNotEmpty
                        ? NetworkImage(brandProfile.logoUrl)
                        : null,
                    child: brandProfile.logoUrl.isEmpty
                        ? const Icon(Icons.business_rounded,
                            size: 24, color: accentColor)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          brandProfile.businessName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (brandProfile.welcomeMessage.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            brandProfile.welcomeMessage,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (hasContactInfo)
                    IconButton(
                      icon: const Icon(Icons.info_outline_rounded,
                          color: accentColor, size: 24),
                      tooltip: 'Ver Información de Contacto',
                      onPressed: () => widget.onShowContacts(brandProfile),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: accentColor, size: 24),
                    tooltip: 'Editar Perfil de Marca',
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => BrandSettingsScreen(
                          user: widget.user,
                          brandProfile: brandProfile,
                        ),
                      ));
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}