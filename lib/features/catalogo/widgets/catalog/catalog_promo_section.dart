import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:proveedor_servicly_app/features/promotion/models/promotion_model.dart';

class CatalogPromotionsSectionV2 extends StatefulWidget {
  // ✅ PASO CRÍTICO: Definir el campo en la clase
  final String providerId;

  // ✅ PASO CRÍTICO: Definir el parámetro 'required' en el constructor
  const CatalogPromotionsSectionV2({
    super.key, 
    required this.providerId, 
  });

  @override
  State<CatalogPromotionsSectionV2> createState() => _CatalogPromotionsSectionStateV2();
}

class _CatalogPromotionsSectionStateV2 extends State<CatalogPromotionsSectionV2> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay(int totalItems) {
    if (_timer != null || totalItems <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        _currentPage++;
        if (_currentPage >= totalItems) _currentPage = 0;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOutQuart,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PromotionModel>>(
      stream: FirebaseFirestore.instance
          .collection('promotions')
          .where('providerId', isEqualTo: widget.providerId) // Usa widget.providerId
          .where('type', isEqualTo: 'DISCOUNT')
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => PromotionModel.fromFirestore(doc))
              .where((p) => p.isAvailableToday)
              .toList()),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final promos = snapshot.data!;
        WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoPlay(promos.length));

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text(
                  "Ofertas Especiales",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: 105,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: promos.length,
                  onPageChanged: (index) => _currentPage = index,
                  itemBuilder: (context, index) => _buildPromoCard(promos[index]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPromoCard(PromotionModel promo) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00B2B2).withValues(alpha: 0.9), 
            const Color(0xFF008080).withValues(alpha: 0.7)
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF00B2B2).withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: const Icon(Icons.flash_on, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${promo.discountPercentage.toStringAsFixed(0)}% OFF: ${promo.title}",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "\$${NumberFormat("#,##0").format(promo.promoPrice)} • Aprovechá hoy",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white54),
        ],
      ),
    );
  }
}