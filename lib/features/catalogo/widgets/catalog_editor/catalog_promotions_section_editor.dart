import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';

class CatalogPromotionsSectionEditor extends StatelessWidget {
  final ProviderProfileModel profile;

  const CatalogPromotionsSectionEditor({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Ofertas y Promociones", 
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => _showPromoEditor(context),
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: const Text("Editar Promo"),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF00B2B2)),
                ),
              ],
            ),
          ),
          
          // TARJETA DE PROMOCIÓN INTERACTIVA
          GestureDetector(
            onTap: () => _showPromoEditor(context),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    profile.brandColor.withValues(alpha: 0.8),
                    profile.brandColor.withValues(alpha: 0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.percent, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.promoTitle ?? "Configurar Oferta",
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          profile.promoSubtitle ?? "Toca aquí para definir los días de descuento",
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_right, color: Colors.white38),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPromoEditor(BuildContext context) {
    final titleController = TextEditingController(text: profile.promoTitle);
    final subtitleController = TextEditingController(text: profile.promoSubtitle);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24, right: 24, top: 24
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Editar Promoción", 
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Título (Ej: 20% OFF en Coloración)",
                labelStyle: TextStyle(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: subtitleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Subtítulo (Ej: Válido Martes y Miércoles)",
                labelStyle: TextStyle(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00B2B2)),
                onPressed: () async {
                  // Usamos profile.id que ahora ya está definido en el modelo
                  await context.read<FirestoreService>().updateCatalogField(profile.id, {
                    'promoTitle': titleController.text.trim(),
                    'promoSubtitle': subtitleController.text.trim(),
                  });
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("GUARDAR PROMOCIÓN", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}