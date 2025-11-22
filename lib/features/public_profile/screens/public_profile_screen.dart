import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Servicios
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/core/services/analytics_service.dart';
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart';
// Modelos
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
// Plantillas
import 'package:proveedor_servicly_app/features/public_profile/screens/presentation/templates/tienda_layout.dart';
// (Añade aquí tus otras plantillas si las tienes listas, como CatalogLayout)

/// Esta pantalla actúa como un "Router" inteligente.
/// 1. Escucha los cambios en el perfil de marca (brandProfiles).
/// 2. Decide qué plantilla mostrar (Tienda, Catálogo, etc.).
/// 3. Inyecta los servicios necesarios para la vista pública.
class PublicProfileScreen extends StatelessWidget {
  final String providerId;

  const PublicProfileScreen({super.key, required this.providerId});

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    const accentColor = Color(0xFF00BFFF);
    const backgroundColor = Color(0xFF1A1A2E);

    // Inyectamos CRM y Analytics aquí para que estén disponibles en toda la rama pública
    return MultiProvider(
      providers: [
        Provider(create: (_) => CrmRepository()),
        Provider(create: (_) => AnalyticsService()),
      ],
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: StreamBuilder<ProviderProfileModel?>(
          // --- CORRECCIÓN CLAVE: Apuntamos a 'brandProfiles' ---
          stream: firestoreService.getBrandProfile(providerId), 
          builder: (context, snapshot) {
            
            // 1. Estado de Carga
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: accentColor),
              );
            }

            // 2. Estado de Error o Perfil No Encontrado
            if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
              // Si falla, imprimimos el error en consola para depurar
              debugPrint("Error cargando perfil: ${snapshot.error}");
              
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_off_outlined, size: 80, color: Colors.white24),
                      const SizedBox(height: 24),
                      const Text(
                        'Perfil no disponible',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No se pudo encontrar la información pública de este proveedor.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white60),
                      ),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Volver'),
                        style: FilledButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.black),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              );
            }

            // 3. ¡Perfil Encontrado! -> Seleccionar Plantilla
            final profile = snapshot.data!;
            
            // Aquí decidimos qué diseño mostrar según la configuración del usuario
            switch (profile.profileType) {
              case 'store':
                return TiendaLayout(
                  providerId: providerId,
                  profile: profile,
                );
              
              case 'catalog':
                // TODO: Si tienes CatalogLayout listo, úsalo aquí.
                // return CatalogLayout(providerId: providerId, profile: profile);
                return _PlaceholderTemplate(name: 'Catálogo', profile: profile);
                
              case 'cv':
                // return CvLayout(profile: profile);
                return _PlaceholderTemplate(name: 'CV Profesional', profile: profile);
                
              default:
                // Por defecto, mostramos la Tienda si no reconocemos el tipo
                return TiendaLayout(
                  providerId: providerId,
                  profile: profile,
                );
            }
          },
        ),
      ),
    );
  }
}

/// Layout temporal para plantillas en desarrollo
class _PlaceholderTemplate extends StatelessWidget {
  final String name;
  final ProviderProfileModel profile;

  const _PlaceholderTemplate({required this.name, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text(profile.businessName),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 60, color: Colors.white24),
            const SizedBox(height: 16),
            Text('Plantilla "$name"', style: const TextStyle(color: Colors.white, fontSize: 20)),
            const Text('En construcción', style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}