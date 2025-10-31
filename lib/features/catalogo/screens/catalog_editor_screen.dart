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

// --- ¡RUTAS CORREGIDAS! ---
import '../widgets/catalog_editor_layout.dart'; // El layout principal
import 'package:proveedor_servicly_app/features/catalogo/modules/module_settings_sheet.dart';


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

        return ChangeNotifierProvider<CatalogEditorProvider>(
          create: (_) => CatalogEditorProvider(
            initialProfile: initialProfile,
            firestoreService: firestoreService,
            storageService: storageService,
            permissionsService: permissionsService,
          ),
          child: Builder(
            builder: (context) {
              // El provider se lee/escucha dentro del layout, no aquí.

              return Scaffold(
                // ¡LA APPBAR ESTÁ AQUÍ AHORA! (Ver _buildSliverHeader en el layout)
                // (O la dejamos comentada si _buildSliverHeader la maneja)
                /*
                appBar: AppBar(
                  title: const Text("Editar Catálogo"),
                  backgroundColor: Colors.grey[900], 
                  elevation: 1.0, 
                  actions: [
                    Consumer<CatalogEditorProvider>(
                      builder: (ctx, provider, child) {
                        // ... Botón Guardar ...
                      },
                    )
                  ],
                ),
                */
                
                backgroundColor: const Color(0xFF1A1A2E), 
                body: CatalogEditorLayout(
                  // --- ¡CORRECCIÓN! ---
                  // Le pasamos el userId al layout
                  userId: widget.user.uid,
                ),

                // --- ¡CORRECCIÓN! ---
                // El FAB pertenece a la pantalla (Scaffold)
                floatingActionButton: FloatingActionButton(
                  tooltip: "Configurar módulos",
                  onPressed: () {
                    // Llamamos al método definido aquí
                    _showModuleSettings(context);
                  },
                  child: const Icon(Icons.layers_outlined),
                ),
              );
            }
          ),
        );
      },
    );
  }

  // --- ¡MÉTODO CORREGIDO! ---
  // El método vive en el State de la pantalla
  void _showModuleSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[850], 
      shape: const RoundedRectangleBorder(
         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        // Usamos context.read porque el context del builder
        // está por encima del ChangeNotifierProvider
        return ChangeNotifierProvider.value(
          value: context.read<CatalogEditorProvider>(),
          child: const ModuleSettingsSheet(),
        );
      },
    );
  }
}