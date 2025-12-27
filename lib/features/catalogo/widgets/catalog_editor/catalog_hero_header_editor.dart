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

  // --- LÓGICA DE SUBIDA DE IMÁGENES (Igual que antes) ---
  Future<void> _changeImage(bool isLogo) async {
    final picker = ImagePicker();
    final storage = context.read<StorageService>();
    final firestore = context.read<FirestoreService>();
    // ... (Resto de la lógica de _changeImage permanece igual)
     final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final String folder = isLogo ? 'logos' : 'covers';
      final String fileName = '${widget.user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String path = 'catalogs/${widget.user.uid}/$folder/$fileName';

      final String downloadUrl = await storage.uploadFileWithProgress(
        File(pickedFile.path),
        path,
        (progress) => debugPrint("Progreso: $progress"),
      );

      final Map<String, dynamic> updateData = isLogo 
          ? {'logoUrl': downloadUrl} 
          : {'coverImageUrl': downloadUrl};

      await firestore.updateCatalogField(widget.user.uid, updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isLogo ? "Logo actualizado" : "Portada actualizada")),
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
    // ✅ Usamos los datos reales del perfil pasado al widget
    final profile = widget.profile;
    // Ajustamos la altura para que quepa todo cómodamente
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
            // 1. Fondo de Portada (Cover) con indicador de cámara grande
            _buildCoverBackground(profile),

            // 2. Gradiente oscuro para legibilidad
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent, Colors.black],
                  stops: [0.0, 0.3, 0.95],
                ),
              ),
            ),

            // 3. Sección Superior: Identidad (Logo, Nombre y Lápiz de edición)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: _buildHeaderContent(profile),
            ),

            // 4. Sección Inferior: Información, Rating y CTA
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRatingHeader(profile),
                  const SizedBox(height: 12),
                  
                  // Dirección (Muestra dato real o texto de configurar)
                  _buildEditableInfoRow(
                    Icons.location_on_outlined,
                    (profile.address?.isNotEmpty ?? false) 
                        ? profile.address! 
                        : "Configurar ubicación técnica",
                    onTap: () => _navigateToBrandSettings(context),
                  ),
                  
                  // Horario (Muestra dato real o texto de configurar)
                  _buildEditableInfoRow(
                    Icons.access_time_rounded,
                    (profile.openingHours?.isNotEmpty ?? false) 
                        ? profile.openingHours! 
                        : "Configurar horario",
                    onTap: () => _navigateToBrandSettings(context),
                  ),
                  const SizedBox(height: 20),

                  // Botón de Acción Principal (CTA)
                  _buildBookingCTA(profile),

                  // Indicador de carga si se está subiendo una foto
                  if (_isUploading)
                    const Padding(
                      padding: EdgeInsets.only(top: 12.0),
                      child: LinearProgressIndicator(color: Color(0xFF00B2B2), backgroundColor: Colors.white10),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS COMPONENTES ---

  // 1. Fondo de Portada con icono de cámara grande si está vacío
  Widget _buildCoverBackground(ProviderProfileModel profile) {
    bool hasCover = profile.coverImageUrl != null && profile.coverImageUrl!.isNotEmpty;
    return GestureDetector(
      onTap: () => _changeImage(false), // Cambiar Portada
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasCover)
            Image.network(profile.coverImageUrl!, fit: BoxFit.cover)
          else
            Container(color: profile.brandColor.withOpacity(0.2)), // Fondo sutil si no hay imagen
          
          // Icono de cámara grande centrado (estilo image_1.png)
          Center(
            child: Icon(
              Icons.add_a_photo_outlined, 
              color: Colors.white.withOpacity(hasCover ? 0.5 : 0.8), 
              size: 48
            ),
          ),
        ],
      ),
    );
  }

  // 2. Contenido Superior: Logo + Nombre con indicador de edición
  Widget _buildHeaderContent(ProviderProfileModel profile) {
    return Row(
      children: [
        // Avatar con lápiz
        GestureDetector(
          onTap: () => _changeImage(true), // Cambiar Logo
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white12,
                // ✅ Muestra el logo real si existe
                backgroundImage: profile.logoUrl.isNotEmpty ? NetworkImage(profile.logoUrl) : null,
                // Muestra icono por defecto si no hay logo
                child: profile.logoUrl.isEmpty ? const Icon(Icons.business, color: Colors.white) : null,
              ),
              // ✅ Pequeño indicador de lápiz sobre el avatar
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
        
        // Nombre y enlace de edición
        Expanded(
          child: GestureDetector(
            onTap: () => _navigateToBrandSettings(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Muestra el nombre real del negocio
                Text(
                  profile.businessName,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                // ✅ Enlace visual "Editar Identidad" con icono pequeño
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
        // Botón de configuración rápida
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          onPressed: () => _navigateToBrandSettings(context),
        ),
      ],
    );
  }

  // 3. Filas de información (Dirección/Horario) con icono
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
            // Flecha sutil para indicar navegación
            const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }

  // 4. Header de Rating (Visual por ahora, usa datos reales del perfil)
  Widget _buildRatingHeader(ProviderProfileModel profile) {
    return Row(
      children: [
        Text((profile.averageRating ?? 5.0).toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
        const SizedBox(width: 8),
        Row(children: List.generate(5, (i) => Icon(Icons.star, color: i < (profile.averageRating ?? 5).round() ? Colors.amber : Colors.grey, size: 18))),
        const SizedBox(width: 8),
        Text("(${profile.reviewCount ?? 0} Reviews)", style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }

  // 5. Botón CTA (Mismo que antes)
  Widget _buildBookingCTA(ProviderProfileModel profile) {
     final bool isAgenda = profile.bookingActionType == 'agenda';
    final String buttonLabel = isAgenda ? "Agendar Cita" : "Pedir Presupuesto";

    return GestureDetector(
      onTap: () => _showBookingEditor(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF00B2B2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00B2B2).withOpacity(0.3),
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
   // --- SELECTOR DE DOS OPCIONES (SIN TEXTO) ---
  void _showBookingEditor(BuildContext context) {
    String tempSelection = widget.profile.bookingActionType ?? 'presupuesto';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Función del Botón Principal", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              
              // OPCIÓN A: AGENDA
              _buildSimpleOption(
                label: "Vincular con mi Agenda",
                icon: Icons.calendar_today_rounded,
                isSelected: tempSelection == 'agenda',
                onTap: () => setModalState(() => tempSelection = 'agenda'),
              ),
              
              const SizedBox(height: 12),
              
              // OPCIÓN B: PRESUPUESTO
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
                    // EL SISTEMA DECIDE EL TEXTO AQUÍ, TÚ NO ESCRIBES NADA
                    final String autoText = (tempSelection == 'agenda') ? "Agendar Cita" : "Pedir Presupuesto";
                    
                    await context.read<FirestoreService>().updateCatalogField(widget.profile.id, {
                      'bookingActionType': tempSelection,
                      'bookingButtonText': autoText,
                    });
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("CONFIRMAR SELECCIÓN"),
                ),
              ),
              const SizedBox(height: 20),
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
          color: isSelected ? const Color(0xFF00B2B2).withOpacity(0.15) : Colors.white.withOpacity(0.05),
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


  void _navigateToBrandSettings(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => BrandSettingsScreen(user: widget.user, brandProfile: widget.profile)));
  }
}