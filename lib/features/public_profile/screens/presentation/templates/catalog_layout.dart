import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// Modelos
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart'; 

// Widgets Reutilizables
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog_hero_header.dart';
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog_promotions_section.dart'; 
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog_trust_signals.dart';
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog_portfolio_section.dart';
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog_services_section.dart';
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog_gift_card_section.dart'; 
import 'package:proveedor_servicly_app/features/catalogo/widgets/catalog_reviews_section.dart';
import 'package:proveedor_servicly_app/features/catalogo/widgets/floating_appointment_bar.dart';

// Repositorios y Pantallas
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart';
import 'package:proveedor_servicly_app/features/booking/screens/booking_screen.dart';

class CatalogLayout extends StatefulWidget {
  const CatalogLayout({
    super.key,
    required this.providerId,
    required this.profile,
  });

  final String providerId;
  final ProviderProfileModel profile;

  @override
  State<CatalogLayout> createState() => _CatalogLayoutState();
}

class _CatalogLayoutState extends State<CatalogLayout> {
  // Estado local para seguimiento
  bool _isFollowing = false;
  
  // --- GESTIÓN DEL BORRADOR DE SERVICIOS ---
  final List<ProductModel> _selectedServices = [];

  // Función para añadir o quitar servicios del borrador
  void _toggleService(ProductModel service) {
    setState(() {
      // Usamos el ID para asegurar una comparación precisa en Firebase
      if (_selectedServices.any((s) => s.id == service.id)) {
        _selectedServices.removeWhere((s) => s.id == service.id);
      } else {
        _selectedServices.add(service);
      }
    });
  }

  // Muestra el Modal con el resumen tipo "Recibo" antes de agendar
  void _showAppointmentDraft() {
    final double total = _selectedServices.fold(0, (sum, item) => sum + item.price);
    final Color brandColor = widget.profile.brandColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Resumen de Cita",
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Borrador de presupuesto técnico", 
                  style: TextStyle(color: Colors.white38, fontSize: 13)
                ),
                const Divider(color: Colors.white10, height: 32),
                
                // Lista de servicios en el recibo/borrador
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: _selectedServices.length,
                    itemBuilder: (context, index) {
                      final item = _selectedServices[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item.name, 
                          style: const TextStyle(color: Colors.white, fontSize: 15)
                        ),
                        trailing: Text(
                          "\$${item.price.toStringAsFixed(2)}", 
                          style: const TextStyle(color: Colors.white70)
                        ),
                      );
                    },
                  ),
                ),

                const Divider(color: Colors.white10),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "TOTAL ESTIMADO", 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                      Text(
                        "\$${total.toStringAsFixed(2)}", 
                        style: TextStyle(
                          color: brandColor, 
                          fontSize: 20, 
                          fontWeight: FontWeight.bold
                        )
                      ),
                    ],
                  ),
                ),
                
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00B2B2)
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Cerramos el modal
                      // Navegamos a la pantalla de reserva enviando el ID del proveedor
                      Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (_) => BookingScreen(providerId: widget.providerId)
                        )
                      );
                    },
                    child: const Text(
                      "CONFIRMAR Y AGENDAR", 
                      style: TextStyle(fontWeight: FontWeight.bold)
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

  // Captura de leads para el CRM antes de abrir apps externas
  Future<void> _handleContact(Uri url, String source) async {
    try {
      final crmRepository = context.read<CrmRepository>();
      await crmRepository.captureLeadFromPublicProfile(
        email: null, 
        nombreCompleto: 'Visitante Catálogo', 
        source: source,
        providerId: widget.providerId,
      );
    } catch (e) {
      debugPrint("Error al capturar Lead: $e");
    }
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _toggleFollow() {
    setState(() => _isFollowing = !_isFollowing);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFollowing 
              ? 'Siguiendo a ${widget.profile.businessName}' 
              : 'Dejaste de seguir'
        ),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Header con identidad y botones de contacto
          CatalogHeroHeader(
            profile: profile,
            isEditor: false,
            isFollowing: _isFollowing,
            onFollowTap: _toggleFollow,
            onContactTap: _handleContact,
          ),

          // 2. Sección de Promociones
          const CatalogPromotionsSection(),

          // 3. Sellos de confianza/calidad
          const CatalogTrustSignals(),

          // 4. Portafolio Visual
          if (profile.showPortfolioModule)
            CatalogPortfolioSection(
              providerId: widget.providerId,
              brandColor: profile.brandColor,
            ),
          
          // 5. SECCIÓN DE SERVICIOS (Conexión activa con el borrador)
          CatalogServicesSection(
            providerId: widget.providerId,
            brandColor: profile.brandColor,
            onServiceTap: _toggleService,        // Activamos la función de selección
            selectedServices: _selectedServices, // Pasamos el estado de selección
          ),

          // 6. Módulo de Gift Cards
          const CatalogGiftCardSection(),

          // 7. Módulo de Reseñas de Firebase
          if (profile.showReviewsModule)
            CatalogReviewsSection(profile: profile),

          // Espacio para evitar que el FAB tape el último contenido
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      
      // --- BARRA FLOTANTE DE RESUMEN (Aparece al seleccionar servicios) ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _selectedServices.isNotEmpty 
        ? FloatingAppointmentBar(
            count: _selectedServices.length,
            total: _selectedServices.fold(0, (sum, item) => sum + item.price),
            onTap: _showAppointmentDraft, // Abre el recibo/borrador
          )
        : null,
    );
  }
}