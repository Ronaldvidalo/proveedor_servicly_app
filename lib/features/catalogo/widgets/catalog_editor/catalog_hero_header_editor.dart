import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// Modelos y Servicios
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/core/services/storage_service.dart';
import 'package:proveedor_servicly_app/features/settings/screens/brand_settings_screen.dart';

// ✅ Importamos el widget de Rating
import 'package:proveedor_servicly_app/features/reviews/widgets/provider_rating_badge.dart';

class CatalogHeroHeaderEditor extends StatefulWidget {
  final ProviderProfileModel profile;
  final UserModel user;

  const CatalogHeroHeaderEditor({
    super.key,
    required this.profile,
    required this.user,
  });

  @override
  State<CatalogHeroHeaderEditor> createState() => _CatalogHeroHeaderEditorState();
}

class _CatalogHeroHeaderEditorState extends State<CatalogHeroHeaderEditor> {
  bool _isUploading = false;

  // --- LÓGICA DE SUBIDA DE IMÁGENES ---
  Future<void> _changeImage(bool isLogo) async {
    final picker = ImagePicker();
    final storage = context.read<StorageService>();
    final firestore = context.read<FirestoreService>();
    
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final String folder = isLogo ? 'logos' : 'covers';
      final String fileName = '${widget.user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String path = 'brandProfiles/${widget.user.uid}/$folder/$fileName';

      final String downloadUrl = await storage.uploadFileWithProgress(
        File(pickedFile.path),
        path,
        (progress) => debugPrint("Progreso subida: $progress"),
      );

      final Map<String, dynamic> updateData = isLogo 
          ? {'logoUrl': downloadUrl} 
          : {'coverImageUrl': downloadUrl};

      await firestore.setBrandProfile(widget.user.uid, updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isLogo ? "Logo actualizado" : "Portada de fondo actualizada"),
            backgroundColor: const Color(0xFF00B2B2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error subiendo imagen: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return StreamBuilder<ProviderProfileModel?>(
      stream: firestoreService.getBrandProfile(widget.user.uid),
      builder: (context, snapshot) {
        final profile = snapshot.data ?? widget.profile;
        const double headerHeight = 480.0; 

        return SliverAppBar(
          expandedHeight: headerHeight,
          pinned: true,
          stretch: true,
          backgroundColor: const Color(0xFF1A1A2E),
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // 1. CAPA BASE: Fondo de Portada (Interactiva)
                _buildCoverBackground(profile),

                // 2. CAPA DECORATIVA: Gradiente (IgnorePointer permite que el toque pase)
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black54, Colors.transparent, Colors.black],
                        stops: [0.0, 0.3, 0.95],
                      ),
                    ),
                  ),
                ),

                // 3. CAPA SUPERIOR: Logo y Nombre
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  right: 16,
                  child: _buildHeaderContent(profile),
                ),

                // 4. CAPA INFERIOR: Información y CTA
                Positioned(
                  bottom: 24,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ WIDGET REUTILIZABLE DE RATING
                      ProviderRatingBadge(
                        profile: profile,
                        starSize: 20,
                        // Forzamos texto blanco y grande porque estamos sobre fondo oscuro
                        textStyle: const TextStyle(
                          color: Colors.white, 
                          fontSize: 24, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildEditableInfoRow(
                        Icons.location_on_outlined,
                        (profile.address?.isNotEmpty ?? false) 
                            ? profile.address! 
                            : "Añadir ubicación técnica",
                        onTap: () => _navigateToBrandSettings(context, profile),
                      ),
                      
                      _buildEditableInfoRow(
                        Icons.access_time_rounded,
                        (profile.openingHours?.isNotEmpty ?? false) 
                            ? profile.openingHours! 
                            : "Configurar horario",
                        onTap: () => _navigateToBrandSettings(context, profile),
                      ),
                      const SizedBox(height: 20),

                      _buildBookingCTA(profile),

                      if (_isUploading)
                        const Padding(
                          padding: EdgeInsets.only(top: 12.0),
                          child: LinearProgressIndicator(
                            color: Color(0xFF00B2B2), 
                            backgroundColor: Colors.white10
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- COMPONENTES DEL HEADER ---

  Widget _buildCoverBackground(ProviderProfileModel profile) {
    bool hasCover = profile.coverImageUrl != null && profile.coverImageUrl!.isNotEmpty;
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // ✅ Asegura que toda el área sea táctil
      onTap: () => _changeImage(false), 
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasCover)
            Image.network(profile.coverImageUrl!, fit: BoxFit.cover)
          else
            Container(color: profile.brandColor.withValues(alpha: 0.2)), 
          
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_a_photo_outlined, 
                  color: Colors.white.withValues(alpha: hasCover ? 0.5 : 0.8), 
                  size: 48
                ),
                if (!hasCover)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      "CAMBIAR IMAGEN DE FONDO", 
                      style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderContent(ProviderProfileModel profile) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _changeImage(true), 
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white10,
                backgroundImage: profile.logoUrl.isNotEmpty ? NetworkImage(profile.logoUrl) : null,
                child: profile.logoUrl.isEmpty ? const Icon(Icons.business, color: Colors.white) : null,
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF00B2B2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 10, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        
        Expanded(
          child: GestureDetector(
            onTap: () => _navigateToBrandSettings(context, profile),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.businessName.isEmpty ? "Nuevo Negocio" : profile.businessName,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const Row(
                  children: [
                      Text("Editar Identidad", style: TextStyle(color: Color(0xFF00B2B2), fontSize: 12)),
                      SizedBox(width: 4),
                      Icon(Icons.edit_note, color: Color(0xFF00B2B2), size: 14),
                  ],
                )
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          onPressed: () => _navigateToBrandSettings(context, profile),
        ),
      ],
    );
  }

  Widget _buildEditableInfoRow(IconData icon, String text, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }

  // _buildRatingHeader Eliminado porque ahora usamos ProviderRatingBadge

  Widget _buildBookingCTA(ProviderProfileModel profile) {
    final bool isAgenda = profile.bookingActionType == 'agenda';
    final String buttonLabel = isAgenda ? "Agendar Cita" : "Pedir Presupuesto";

    return GestureDetector(
      onTap: () => _showBookingEditor(context, profile),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF00B2B2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00B2B2).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              buttonLabel.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.1),
            ),
            const Positioned(
              right: 16,
              child: Icon(Icons.swap_horiz, color: Colors.white70, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingEditor(BuildContext context, ProviderProfileModel profile) {
    String tempSelection = profile.bookingActionType ?? 'presupuesto';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Función del Botón Principal", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              
              _buildSimpleOption(
                label: "Vincular con mi Agenda",
                icon: Icons.calendar_today_rounded,
                isSelected: tempSelection == 'agenda',
                onTap: () => setModalState(() => tempSelection = 'agenda'),
              ),
              
              const SizedBox(height: 12),
              
              _buildSimpleOption(
                label: "Pedir Presupuesto / Cotización",
                icon: Icons.description_outlined,
                isSelected: tempSelection == 'presupuesto',
                onTap: () => setModalState(() => tempSelection = 'presupuesto'),
              ),

              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00B2B2)),
                  onPressed: () async {
                    final String autoText = (tempSelection == 'agenda') ? "Agendar Cita" : "Pedir Presupuesto";
                    
                    await context.read<FirestoreService>().setBrandProfile(widget.user.uid, {
                      'bookingActionType': tempSelection,
                      'bookingButtonText': autoText,
                    });
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("CONFIRMAR SELECCIÓN"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleOption({required String label, required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00B2B2).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF00B2B2) : Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF00B2B2) : Colors.white38),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF00B2B2), size: 20),
          ],
        ),
      ),
    );
  }

  void _navigateToBrandSettings(BuildContext context, ProviderProfileModel profile) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => BrandSettingsScreen(user: widget.user, brandProfile: profile)));
  }
}