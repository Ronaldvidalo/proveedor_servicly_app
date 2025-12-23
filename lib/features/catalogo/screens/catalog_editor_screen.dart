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
import '../widgets/catalog_editor_layout.dart'; 


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
           // ✅ CORRECCIÓN: Eliminado operador ?? [] ya que activeModules no es nullable
           activeModules: widget.user.activeModules, 
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
    // QA FIX: Obtener tema
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_initialProfileFuture == null) {
       // Fondo dinámico
       return Scaffold(
         backgroundColor: theme.scaffoldBackgroundColor, 
         body: Center(child: CircularProgressIndicator(color: colorScheme.primary))
       );
    }

    return FutureBuilder<ProviderProfileModel?>(
      future: _initialProfileFuture!,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor, 
            appBar: null, 
            body: Center(child: CircularProgressIndicator(color: colorScheme.primary))
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              title: const Text('Error al Cargar Perfil'), 
              backgroundColor: theme.scaffoldBackgroundColor,
              foregroundColor: colorScheme.onSurface,
              elevation: 0,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                      Text(
                      'No se pudo cargar la configuración del catálogo.\n${snapshot.error != null ? "Error: ${snapshot.error}" : ""}',
                      textAlign: TextAlign.center,
                      // Texto de error visible en ambos modos
                      style: TextStyle(color: colorScheme.error),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                       icon: Icon(Icons.refresh, color: colorScheme.onPrimary),
                       label: Text("Intentar de Nuevo", style: TextStyle(color: colorScheme.onPrimary)),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: colorScheme.primary,
                       ),
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
          child: CatalogEditorLayout( 
            userId: widget.user.uid,
          ),
        );
      },
    );
  }
}