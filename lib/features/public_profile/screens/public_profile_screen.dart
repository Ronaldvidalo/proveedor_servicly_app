import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- IMPORTS DE MODELOS Y SERVICIOS ---
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';

// --- IMPORTS DE TUS PLANTILLAS REALES ---
import 'package:proveedor_servicly_app/features/public_profile/screens/presentation/templates/tienda_layout.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/presentation/templates/cv_layout.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/presentation/templates/catalog_layout.dart';

class PublicProfileScreen extends StatefulWidget {
  final String providerId; 

  const PublicProfileScreen({super.key, required this.providerId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  late Future<ProviderProfileModel?> _profileFuture;

  @override
  void initState() {
    super.initState();
    // 1. Buscamos los datos en la nueva colección 'brandProfiles'
    _profileFuture = context.read<FirestoreService>().getProviderPublicProfile(widget.providerId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProviderProfileModel?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        // A. ESTADO DE CARGA
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // B. ESTADO DE ERROR
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Error")),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.broken_image_outlined, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("No se encontró el perfil de la tienda."),
                  ElevatedButton(
                    onPressed: () => setState(() {
                       _profileFuture = context.read<FirestoreService>().getProviderPublicProfile(widget.providerId);
                    }),
                    child: const Text("Reintentar")
                  )
                ],
              ),
            ),
          );
        }

        // C. DATOS OBTENIDOS EXITOSAMENTE
        final profile = snapshot.data!;
        
        // Limpiamos el string para evitar errores por espacios o mayúsculas
        final String templateId = (profile.publicProfileTemplate ?? 'cv').trim().toLowerCase();
        
        debugPrint("🚀 ABRIENDO PLANTILLA EXTERNA: '$templateId'");

        // --- EL SWITCH DESTRUIDOR DE DUDAS ---
        // Aquí enviamos los datos a TUS archivos originales.
        switch (templateId) {
          case 'store':
            // Pasamos el providerId y el perfil completo a tu archivo tienda_layout.dart
            return TiendaLayout(providerId: widget.providerId, profile: profile);
            
          case 'catalog':
            return CatalogLayout(providerId: widget.providerId, profile: profile);
            
          case 'cv':
          default:
            // Nota: Verifica si tu CvLayout recibe providerId o solo profile
            return CvLayout(profile: profile);
        }
      },
    );
  }
}