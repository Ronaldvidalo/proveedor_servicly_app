import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proveedor_servicly_app/features/promotion/models/promotion_model.dart';
import 'package:proveedor_servicly_app/features/promotion/widgets/gift_card_widget.dart';

class CatalogGiftCardSection extends StatefulWidget {
  final String providerId;

  const CatalogGiftCardSection({super.key, required this.providerId});

  @override
  State<CatalogGiftCardSection> createState() => _CatalogGiftCardSectionState();
}

class _CatalogGiftCardSectionState extends State<CatalogGiftCardSection> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9, initialPage: 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// Inicia la animación de rotación automática si hay múltiples tarjetas
  void _startAutoPlay(int totalItems) {
    if (_timer != null) return; // Evitar múltiples timers
    if (totalItems <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _currentPage++;
        if (_currentPage >= totalItems) {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PromotionModel>>(
      // Consulta técnica a la colección raíz
      stream: FirebaseFirestore.instance
          .collection('promotions')
          .where('providerId', isEqualTo: widget.providerId)
          .where('type', isEqualTo: 'GIFT_CARD')
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => PromotionModel.fromFirestore(doc))
              .where((p) => p.isAvailableToday) // Filtro de vigencia
              .toList()),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final giftCards = snapshot.data!;
        
        // Iniciamos el motor de animación una vez recibidos los datos
        WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoPlay(giftCards.length));

        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Text(
                    "Regalá Experiencias",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Carrusel de Gift Cards
                SizedBox(
                  height: 170,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: giftCards.length,
                    onPageChanged: (index) => _currentPage = index,
                    itemBuilder: (context, index) {
                      final promo = giftCards[index];
                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          // Efecto técnico de escala al rotar
                          double value = 1.0;
                          if (_pageController.position.haveDimensions) {
                            value = (_pageController.page! - index).abs();
                            value = (1 - (value * 0.1)).clamp(0.0, 1.0);
                          }
                          return Center(
                            child: SizedBox(
                              height: Curves.easeOut.transform(value) * 170,
                              width: Curves.easeOut.transform(value) * 400,
                              child: child,
                            ),
                          );
                        },
                        child: GiftCardWidget(promo: promo), // ✅ Reutilizamos tu widget estético
                      );
                    },
                  ),
                ),

                // Indicador de páginas (Dots) si hay más de una
                if (giftCards.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        giftCards.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 4,
                          width: _currentPage == index ? 20 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index 
                                ? const Color(0xFF00E5FF) 
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}