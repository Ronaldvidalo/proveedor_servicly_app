import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proveedor_servicly_app/features/promotion/models/promotion_model.dart';
import 'package:proveedor_servicly_app/features/promotion/screens/marketing_center_screen.dart';

class CatalogPromotionsSectionEditor extends StatelessWidget {
  final String providerId;

  const CatalogPromotionsSectionEditor({super.key, required this.providerId});

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
                .where('type', isEqualTo: 'DISCOUNT')
                .where('isActive', isEqualTo: true)
                .snapshots()
                .map((snap) => snap.docs.map((doc) => PromotionModel.fromFirestore(doc)).toList()),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState(context);
              }

              return SizedBox(
                height: 100,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) => _buildPromoCard(snapshot.data![index]),
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
      padding: const EdgeInsets.fromLTRB(20, 24, 10, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Promociones", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00B2B2)),
            onPressed: () => _nav(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(PromotionModel promo) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF00B2B2).withValues(alpha: 0.8), const Color(0xFF008080).withValues(alpha: 0.4)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars, color: Colors.white, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("${promo.discountPercentage.toStringAsFixed(0)}% OFF: ${promo.title}", 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(promo.description ?? "Válido hoy", 
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
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
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.percent_rounded, color: Colors.white24, size: 40),
              Text("No hay ofertas activas", style: TextStyle(color: Colors.white38)),
              Text("Toca para configurar", style: TextStyle(color: Color(0xFF00B2B2), fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  void _nav(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketingCenterScreen(initialTabIndex: 0)));
  }
}