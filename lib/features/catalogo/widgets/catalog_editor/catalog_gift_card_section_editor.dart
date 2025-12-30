import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proveedor_servicly_app/features/promotion/models/promotion_model.dart';
import 'package:proveedor_servicly_app/features/promotion/widgets/gift_card_widget.dart';
import 'package:proveedor_servicly_app/features/promotion/screens/marketing_center_screen.dart';

class CatalogGiftCardSectionEditor extends StatelessWidget {
  final String providerId;

  const CatalogGiftCardSectionEditor({super.key, required this.providerId});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          StreamBuilder<List<PromotionModel>>(
            stream: FirebaseFirestore.instance
                .collection('promotions') // ✅ Colección raíz
                .where('providerId', isEqualTo: providerId)
                .where('type', isEqualTo: 'GIFT_CARD')
                .where('isActive', isEqualTo: true)
                .snapshots()
                .map((snap) => snap.docs.map((doc) => PromotionModel.fromFirestore(doc)).toList()),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState(context);
              }

              return SizedBox(
                height: 160,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) => GiftCardWidget(promo: snapshot.data![index]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 10, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Tarjetas de Regalo", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00B2B2)),
            onPressed: () => _nav(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return GestureDetector(
      onTap: () => _nav(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 30),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: const Column(
          children: [
            Icon(Icons.card_giftcard_rounded, color: Colors.white24, size: 40),
            SizedBox(height: 8),
            Text("Configurar Módulo de Gift Cards", style: TextStyle(color: Colors.white38)),
            Text("Toca para configurar", style: TextStyle(color: Color(0xFF00B2B2), fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _nav(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketingCenterScreen(initialTabIndex: 1)));
  }
}