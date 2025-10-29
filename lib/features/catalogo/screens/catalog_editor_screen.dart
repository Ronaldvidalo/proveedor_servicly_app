import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/services/provider_service.dart';
import 'package:provider/provider.dart';
// debugPrint está en material.dart

// Modelos y Servicios necesarios
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/core/services/product_service.dart';
import 'package:proveedor_servicly_app/core/services/storage_service.dart';
import 'package:proveedor_servicly_app/core/services/permissions_service.dart';

// Provider (Importación de Paquete)
import 'package:proveedor_servicly_app/providers/catalog_editor_provider.dart';

// Widgets Modulares y Configuración (Importaciones de Paquete - ¡Verifica estas rutas!)
import 'package:proveedor_servicly_app/widgets/modules/welcome_module_widget.dart';
import 'package:proveedor_servicly_app/widgets/modules/module_config.dart';
import 'package:proveedor_servicly_app/features/modules/screens/contact_module_widget.dart';
import 'package:proveedor_servicly_app/widgets/modules/portfolio_module_widget.dart';

// BottomSheet (Importación de Paquete - ¡Verifica esta ruta!)
import 'package:proveedor_servicly_app/features/modules/screens/module_settings_sheet.dart';


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

  /// Carga el ProviderProfileModel inicial usando ProviderService.
  Future<ProviderProfileModel?> _loadInitialProfile() async {
    // Es seguro usar context aquí
    final providerService = Provider.of<ProviderService>(context, listen: false);

    try {
      final profile = await providerService.getProviderProfile(widget.user.uid);

      if (!mounted) return null; // Salir si se desmonta durante la carga

      if (profile == null) {
        // Solo muestra un mensaje si falla la carga, devuelve null
         if(mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontró perfil existente. Puedes crear uno aquí.'), backgroundColor: Colors.orange),
          );
        }
        // --- SIMPLIFICADO: Devolvemos null si no se carga ---
        // Necesitaríamos un ProviderProfileModel.empty() o similar si quisiéramos crear uno nuevo aquí
         return ProviderProfileModel( // Creamos uno mínimo solo para que no falle el FutureBuilder si retorna null del catch
            providerId: widget.user.uid,
            businessName: widget.user.displayName ?? 'Nuevo Negocio', // Fallback
            logoUrl: '',
            brandColor: Colors.deepPurple,
            activeModules: widget.user.activeModules ?? [],
            profileType: 'catalog',
            contactEmail: widget.user.email ?? '', // Fallback
            welcomeMessage: '',
             showWelcomeModule: true, welcomeModuleType: 'text',
             showPortfolioModule: true, showReviewsModule: true,
             showPromotionsModule: false, showGiftCardModule: false,
         );
      }
      return profile; // Devuelve el perfil cargado
    } catch (e) {
      debugPrint("Error crítico al cargar ProviderProfile: $e");

      if (!mounted) return null; // Salir si se desmonta durante el error

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fatal al cargar perfil: $e.'), backgroundColor: Colors.red),
        );
      }
      // --- SIMPLIFICADO: Devolvemos null en caso de error ---
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialProfileFuture == null) {
       return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return FutureBuilder<ProviderProfileModel?>(
      future: _initialProfileFuture!,
      builder: (context, snapshot) {
        // --- Estado de Carga ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            appBar: null,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // --- Estado de Error O PERFIL NULO ---
        // Ahora manejamos explícitamente si snapshot.data es null
        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error al Cargar Perfil')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column( // Usamos Column para añadir un botón
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Text(
                      'No se pudo cargar la configuración del catálogo o no existe un perfil.\n${snapshot.error != null ? "Error: ${snapshot.error}" : ""}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.orangeAccent),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                       icon: const Icon(Icons.refresh),
                       label: const Text("Intentar de Nuevo"),
                       onPressed: () {
                          // Reinicia el future para reintentar la carga
                          setState(() {
                             _initialProfileFuture = _loadInitialProfile();
                          });
                       },
                    )
                  ],
                ),
              ),
            ),
          );
        }

        // --- Datos Cargados: Construimos el Editor ---
        final initialProfile = snapshot.data!; // Sabemos que no es null aquí
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
              final editorProvider = context.read<CatalogEditorProvider>();

              return Scaffold(
                appBar: AppBar(
                  title: const Text("Editar Catálogo"),
                  backgroundColor: Colors.grey[900],
                  elevation: 4.0,
                  actions: [
                    Consumer<CatalogEditorProvider>(
                      builder: (ctx, provider, child) {
                        if (provider.isSaving) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
                          );
                        }
                        return TextButton(
                          onPressed: provider.isDirty
                              ? () async {
                                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                                  // final navigator = Navigator.of(context);

                                  final success = await provider.saveChangesToFirestore(providerId: widget.user.uid);

                                  if (!mounted) return;

                                  if (success) {
                                    scaffoldMessenger.showSnackBar(
                                      const SnackBar(content: Text('Cambios guardados con éxito!'), backgroundColor: Colors.green),
                                    );
                                    // navigator.pop();
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
                body: ListView(
                  padding: const EdgeInsets.all(12.0),
                  children: [
                    _buildSectionCard(
                      child: WelcomeModuleWidget(
                        config: WelcomeModuleEditConfig(
                          editorProvider: editorProvider,
                        ),
                      ),
                    ),
                    _buildSectionCard(
                       child: ContactModuleWidget(
                          // Usando importación de paquete explícita
                          config: ContactModuleEditConfig(editorProvider: editorProvider),
                       ),
                    ),
                     _buildSectionCard(
                       child: PortfolioModuleWidget(
                          config: PortfolioModuleEditConfig(
                            editorProvider: editorProvider,
                            userId: widget.user.uid
                          ),
                       ),
                     ),
                    const SizedBox(height: 80),
                  ],
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
      backgroundColor: Colors.grey[850],
      shape: const RoundedRectangleBorder(
         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: context.read<CatalogEditorProvider>(),
          child: const ModuleSettingsSheet(), // Usando importación de paquete
        );
      },
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Card(
      elevation: 3.0,
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
} // Fin de _CatalogEditorScreenState