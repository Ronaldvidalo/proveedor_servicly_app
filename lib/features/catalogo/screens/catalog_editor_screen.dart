import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Modelos y Servicios necesarios
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/core/services/provider_service.dart';
import 'package:proveedor_servicly_app/core/services/storage_service.dart';
import 'package:proveedor_servicly_app/core/services/permissions_service.dart';
// Provider
import 'package:proveedor_servicly_app/providers/catalog_editor_provider.dart';
// --- NUESTROS WIDGETS DE EDICIÓN ---
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
    final providerService = Provider.of<ProviderService>(context, listen: false);

    try {
      final profile = await providerService.getProviderProfile(widget.user.uid);
      if (!mounted) return null;

      if (profile == null) {
         if(mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontró perfil existente. Puedes crear uno aquí.'), backgroundColor: Colors.orange),
          );
        }
         return ProviderProfileModel(
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
         );
      }
      return profile; 
    } catch (e) {
      debugPrint("Error crítico al cargar ProviderProfile: $e");
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
              // Obtenemos el provider para pasarlo al layout
              final editorProvider = context.read<CatalogEditorProvider>();

              return Scaffold(
                appBar: AppBar(
                  title: const Text("Editar Catálogo"),
                  backgroundColor: Colors.grey[900], // Fondo oscuro
                  elevation: 1.0, 
                  actions: [
                    Consumer<CatalogEditorProvider>(
                      builder: (ctx, provider, child) {
                        if (provider.isSaving) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: SizedBox(
                                width: 24, height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
                          );
                        }
                        return TextButton(
                          onPressed: provider.isDirty
                              ? () async {
                                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                                  final success = await provider.saveChangesToFirestore(providerId: widget.user.uid);
                                  if (!mounted) return;
                                  if (success) {
                                    scaffoldMessenger.showSnackBar(
                                      const SnackBar(content: Text('Cambios guardados con éxito!'), backgroundColor: Colors.green),
                                    );
                                  } else {
                                     scaffoldMessenger.showSnackBar(
                                      const SnackBar(content: Text('Error al guardar los cambios.'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              : null,
                          child: Text(
                            "Guardar",
                            style: TextStyle(
                              color: provider.isDirty ? Colors.white : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        );
                      },
                    )
                  ],
                ),
                
                // --- ¡CUERPO SIMPLIFICADO! ---
                // Usamos nuestro nuevo layout de edición
                backgroundColor: const Color(0xFF1A1A2E), // Fondo oscuro
                body: CatalogEditorLayout(
                  provider: editorProvider,
                  userId: widget.user.uid,
                ),

                floatingActionButton: FloatingActionButton(
                  tooltip: "Configurar módulos",
                  onPressed: () {
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

  void _showModuleSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[850], // Color oscuro
      shape: const RoundedRectangleBorder(
         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: context.read<CatalogEditorProvider>(),
          child: const ModuleSettingsSheet(),
        );
      },
    );
  }
}