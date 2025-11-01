import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Modelos y Servicios necesarios
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/core/services/storage_service.dart';
import 'package:proveedor_servicly_app/core/services/permissions_service.dart';
// Provider
import 'package:proveedor_servicly_app/providers/catalog_editor_provider.dart';
// Widgets
import '../widgets/catalog_editor_layout.dart'; // ¡Nuestro layout principal!


class CatalogEditorScreen extends StatefulWidget {
  final UserModel user;

  const CatalogEditorScreen({super.key, required this.user});

  @override
  State<CatalogEditorScreen> createState() => _CatalogEditorScreenState();
}

class _CatalogEditorScreenState extends State<CatalogEditorScreen> {
  Future<ProviderProfileModel?>? _initialProfileFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (mounted) {
         setState(() {
            _initialProfileFuture = _loadInitialProfile();
         });
       }
    });
  }

  /// Carga el ProviderProfileModel inicial
  Future<ProviderProfileModel?> _loadInitialProfile() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    try {
      var profile = await firestoreService.getCatalogData(widget.user.uid);
      if (!mounted) return null;

      if (profile == null) {
         if(mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Creando nuevo perfil de catálogo...'), backgroundColor: Colors.green),
          );
        }
         profile = ProviderProfileModel(
            providerId: widget.user.uid,
            businessName: widget.user.displayName ?? 'Nuevo Negocio',
            logoUrl: '', 
            brandColor: Colors.deepPurple, 
            activeModules: widget.user.activeModules ?? [], 
            profileType: 'catalog',
            contactEmail: widget.user.email ?? '', 
            welcomeMessage: '¡Bienvenido a mi negocio!', 
             showWelcomeModule: true, welcomeModuleType: 'text',
             showPortfolioModule: true, showReviewsModule: true,
             showPromotionsModule: false, showGiftCardModule: false,
             showBookingModule: true, showQuotesModule: false,
         );
         await firestoreService.setCatalogData(widget.user.uid, profile.toMap());
      }
      return profile; 
    } catch (e) {
      debugPrint("Error crítico al cargar/crear ProviderProfile: $e");
      if (!mounted) return null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fatal al cargar perfil: $e.'), backgroundColor: Colors.red),
        );
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialProfileFuture == null) {
       return const Scaffold(backgroundColor: Color(0xFF1A1A2E), body: Center(child: CircularProgressIndicator()));
    }

    return FutureBuilder<ProviderProfileModel?>(
      future: _initialProfileFuture!,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: Color(0xFF1A1A2E), appBar: null, body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF1A1A2E),
            appBar: AppBar(title: const Text('Error al Cargar Perfil'), backgroundColor: Colors.grey[900]),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Text(
                      'No se pudo cargar la configuración del catálogo.\n${snapshot.error != null ? "Error: ${snapshot.error}" : ""}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.orangeAccent),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                       icon: const Icon(Icons.refresh),
                       label: const Text("Intentar de Nuevo"),
                       onPressed: () => setState(() => _initialProfileFuture = _loadInitialProfile()),
                    )
                  ],
                ),
              ),
            ),
          );
        }

        final initialProfile = snapshot.data!;
        final firestoreService = context.read<FirestoreService>();
        final storageService = context.read<StorageService>();
        final permissionsService = context.read<PermissionsService>();

        // --- ¡CAMBIO CLAVE! ---
        // El ChangeNotifierProvider envuelve el layout.
        // Ya no hay Scaffold ni AppBar aquí.
        return ChangeNotifierProvider<CatalogEditorProvider>(
          create: (_) => CatalogEditorProvider(
            initialProfile: initialProfile,
            firestoreService: firestoreService,
            storageService: storageService,
            permissionsService: permissionsService,
          ),
          child: CatalogEditorLayout( // <- El layout es ahora el widget raíz
            userId: widget.user.uid,
          ),
        );
      },
    );
  }
}