import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:proveedor_servicly_app/core/models/portfolio_item_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';

class PortfolioItemDetailView extends StatefulWidget {
  final PortfolioItemModel item;
  final String providerId;
  final String currentViewerId;
  final String profileType; 
  final String businessName;

  const PortfolioItemDetailView({
    super.key,
    required this.item,
    required this.providerId,
    required this.currentViewerId,
    required this.profileType,
    required this.businessName,
  });

  @override
  State<PortfolioItemDetailView> createState() => _PortfolioItemDetailViewState();
}

class _PortfolioItemDetailViewState extends State<PortfolioItemDetailView> {
  late bool _isLiked;
  late int _currentLikeCount;
  bool _isProcessingLike = false;
  
  // ✅ MEJORA TIKTOK: Estado para expandir/colapsar el texto
  bool _isTextExpanded = false;

  @override
  void initState() {
    super.initState();
    // Inicialización de estados sociales basado en el modelo
    _isLiked = widget.item.isLikedBy(widget.currentViewerId);
    _currentLikeCount = widget.item.likeCount;
    
    // Registro técnico de visita al abrir la imagen
    _incrementView();
  }

  Future<void> _incrementView() async {
    try {
      await context.read<FirestoreService>().incrementPortfolioItemView(
        widget.providerId, 
        widget.item.id
      );
    } catch (e) {
      debugPrint("Error al registrar métrica de vista: $e");
    }
  }

  String _getContactLabel() {
    switch (widget.profileType.toLowerCase()) {
      case 'ingeniero':
      case 'inspector':
        return "Pedir Presupuesto";
      case 'peluqueria':
      case 'estetica':
        return "Quiero este look";
      case 'plomero':
      case 'tecnico':
        return "Consultar Precio";
      case 'veterinaria':
        return "Agendar Cita";
      default:
        return "Pedir Información";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Visualizador de Imagen con Zoom Interactivo
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Hero(
                tag: 'portfolio_item_${widget.item.id}',
                child: Image.network(
                  widget.item.url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white24)
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image_outlined, 
                    color: Colors.white24, 
                    size: 50
                  ),
                ),
              ),
            ),
          ),

          // ✅ CAPA DE TEXTO ESTILO TIKTOK (Bottom Left Overlay)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.9),
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lógica de texto expandible
                  if (widget.item.caption != null && widget.item.caption!.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() => _isTextExpanded = !_isTextExpanded),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: Text(
                              widget.item.caption!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.3,
                                letterSpacing: 0.2,
                              ),
                              maxLines: _isTextExpanded ? null : 2,
                              overflow: _isTextExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.item.caption!.length > 80) // Solo mostrar si el texto es largo
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _isTextExpanded ? "Ver menos" : "Ver más...",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 24),

                  // Barra de Herramientas de Interacción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Likes y Compartir a la izquierda
                      Row(
                        children: [
                          _buildActionCircle(
                            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                            label: _currentLikeCount.toString(),
                            color: _isLiked ? Colors.redAccent : Colors.white,
                            onTap: _handleLikeToggle,
                            isLoading: _isProcessingLike,
                          ),
                          const SizedBox(width: 16),
                          _buildActionCircle(
                            icon: Icons.share_outlined,
                            label: "Compartir",
                            onTap: _handleShare,
                          ),
                        ],
                      ),

                      // Botón Dinámico de Contacto a la derecha (Lead Generator)
                      ElevatedButton.icon(
                        onPressed: _handleContactAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B2B2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                        label: Text(_getContactLabel(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para iconos circulares tipo TikTok
  Widget _buildActionCircle({
    required IconData icon, 
    required String label, 
    required VoidCallback onTap,
    Color color = Colors.white,
    bool isLoading = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: isLoading ? null : onTap,
          icon: isLoading 
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24))
            : Icon(icon, color: color, size: 28),
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
        ),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  Future<void> _handleLikeToggle() async {
    if (_isProcessingLike) return;

    setState(() {
      _isProcessingLike = true;
      _isLiked = !_isLiked;
      _currentLikeCount += _isLiked ? 1 : -1;
    });

    try {
      final firestore = context.read<FirestoreService>();
      await firestore.togglePortfolioItemLike(
        providerId: widget.providerId,
        itemId: widget.item.id,
        userId: widget.currentViewerId,
        isLiking: _isLiked,
      );
      
      if (!mounted) return;

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLiked = !_isLiked;
        _currentLikeCount += _isLiked ? 1 : -1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al procesar el 'Me gusta'"))
      );
    } finally {
      if (mounted) setState(() => _isProcessingLike = false);
    }
  }

  Future<void> _handleContactAction() async {
    final String itemInfo = widget.item.caption ?? "este trabajo del portafolio";
    final String message = Uri.encodeComponent(
      "Hola ${widget.businessName}, vi esta foto en tu portafolio y me interesa saber más:\n\n"
      "Ref: $itemInfo\n"
      "Foto: ${widget.item.url}"
    );
    
    final Uri whatsappUri = Uri.parse("https://wa.me/5491122334455?text=$message");

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir la aplicación de mensajes"))
      );
    }
  }

  void _handleShare() {
    debugPrint("Compartiendo URL: ${widget.item.url}");
  }

  void _showTechnicalDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Información Técnica", 
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 20),
            _buildInfoRow(Icons.visibility_outlined, "Vistas", "${widget.item.viewCount}"),
            _buildInfoRow(Icons.fingerprint, "ID Documento", widget.item.id),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 20),
          const SizedBox(width: 12),
          Text("$label: ", style: const TextStyle(color: Colors.white38)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}