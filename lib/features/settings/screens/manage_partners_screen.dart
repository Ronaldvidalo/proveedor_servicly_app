import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/core/services/storage_service.dart';

/// Una pantalla reutilizable dedicada para añadir, editar y eliminar
/// los logos de los partners (marcas) del proveedor.
class ManagePartnersScreen extends StatefulWidget {
  final UserModel user;
  final ProviderProfileModel profile;

  const ManagePartnersScreen({
    super.key,
    required this.user,
    required this.profile,
  });

  @override
  State<ManagePartnersScreen> createState() => _ManagePartnersScreenState();
}

class _ManagePartnersScreenState extends State<ManagePartnersScreen> {
  // Mantiene una copia local de la lista para la UI
  late List<Map<String, dynamic>> _partners;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Clonamos la lista inicial para poder modificarla
    _partners = List<Map<String, dynamic>>.from(widget.profile.partners);
  }

  /// Guarda la lista de partners actualizada en Firestore
  Future<void> _savePartnersToFirestore() async {
    setState(() => _isLoading = true);
    
    // CORRECCIÓN (use_build_context_synchronously): Guardar el contexto antes del 'await'
    final firestoreService = context.read<FirestoreService>();
    final messenger = ScaffoldMessenger.of(context);
    final bool isMounted = mounted; 

    try {
      // Usamos 'copyWith' en el perfil existente y 'toMap' para preparar los datos
      final updatedProfile = widget.profile.copyWith(partners: _partners);
      // El método 'toMap()' convierte todo al mapa 'personalization'
      final personalizationData = updatedProfile.toMap();
      
      // CORRECCIÓN: Reconstruir el mapa 'brandData' completo
      // para usarlo con 'setBrandProfile'
      final Map<String, dynamic> brandData = {
        'providerId': updatedProfile.providerId,
        'publicProfileTemplate': updatedProfile.profileType,
        'activeModules': updatedProfile.activeModules,
        'personalization': personalizationData, // <-- Aquí van los partners
      };

      // CORRECCIÓN (undefined_method): Usar 'setBrandProfile' en lugar de 'updateBrandProfile'
      await firestoreService.setBrandProfile(
        widget.user.uid,
        brandData, // Pasamos el mapa completo
      );
      
      // CORRECCIÓN: Comprobar 'mounted' antes de usar el ScaffoldMessenger
      if (!isMounted) return; 
      messenger.showSnackBar(const SnackBar(
        content: Text('Lista de partners guardada.'),
        backgroundColor: Colors.green,
      ));

    } catch (e) {
      if (!isMounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text('Error al guardar: $e'),
        backgroundColor: Colors.redAccent,
      ));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Muestra el diálogo para añadir o editar un partner
  Future<void> _showAddEditPartnerDialog({Map<String, dynamic>? partnerToEdit}) async {
    final nameController = TextEditingController(text: partnerToEdit?['name'] ?? '');
    XFile? selectedImage;
    String? existingImageUrl = partnerToEdit?['logoUrl'];
    bool isUploading = false;
    final GlobalKey<State> dialogKey = GlobalKey<State>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        // CORRECCIÓN (use_build_context_synchronously): Guardar el navigator y storage antes de cualquier await
        final storageService = dialogContext.read<StorageService>();
        final navigator = Navigator.of(dialogContext);
        final messenger = ScaffoldMessenger.of(dialogContext); // Guardamos messenger también

        return StatefulBuilder(
          key: dialogKey,
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2D2D5A),
              title: Text(
                partnerToEdit == null ? 'Añadir Partner' : 'Editar Partner',
                style: const TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- Selector de Imagen ---
                  GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                      if (image != null) {
                        setDialogState(() {
                          selectedImage = image;
                          existingImageUrl = null; // Borramos la imagen vieja si se selecciona una nueva
                        });
                      }
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        // CORRECCIÓN (deprecated_member_use): .withOpacity() a .withAlpha()
                        color: Colors.black.withAlpha(51), // 0.2
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white54, width: 1),
                      ),
                      child: (selectedImage != null)
                          ? Image.file(File(selectedImage!.path), fit: BoxFit.cover)
                          // CORRECCIÓN (unchecked_use_of_nullable_value):
                          : (existingImageUrl?.isNotEmpty ?? false) // Usamos '?.isNotEmpty ?? false'
                              ? Image.network(existingImageUrl!, fit: BoxFit.cover)
                              : const Icon(Icons.add_a_photo, color: Colors.white70, size: 40),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // --- Campo de Nombre ---
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nombre del Partner (ej: "Marca X")',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF1A1A2E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  if (isUploading)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: CircularProgressIndicator(color: Color(0xFF00BFFF)),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => navigator.pop(),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFFF),
                      foregroundColor: Colors.black),
                  onPressed: isUploading ? null : () async {
                    if (nameController.text.isEmpty) {
                       messenger.showSnackBar(const SnackBar(
                        content: Text('Por favor, ingresa un nombre para el partner.'),
                        backgroundColor: Colors.orange,
                      ));
                      return;
                    }
                    
                    setDialogState(() => isUploading = true);
                    String finalLogoUrl = existingImageUrl ?? '';

                    // 1. Si se seleccionó una nueva imagen, subirla
                    if (selectedImage != null) {
                      final String storagePath = 'partners/${widget.user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
                      
                      try {
                        // CORRECCIÓN (unnecessary_non_null_assertion):
                        final String? oldUrl = partnerToEdit?['logoUrl'] as String?;
                        if (oldUrl != null && oldUrl.isNotEmpty) {
                          await storageService.deleteFileByUrl(oldUrl);
                        }

                        // Subir la nueva
                        finalLogoUrl = await storageService.uploadFileWithProgress(
                          File(selectedImage!.path),
                          storagePath,
                          (progress) {},
                        );
                      } catch (e) {
                         debugPrint('Error al subir imagen: $e');
                         setDialogState(() => isUploading = false);
                         return; // No continuar si falla la subida
                      }
                    }
                    
                    // CORRECCIÓN (use_build_context_synchronously): Comprobar si el diálogo sigue montado
                    if (!navigator.context.mounted) return;
                    navigator.pop({
                      'name': nameController.text,
                      'logoUrl': finalLogoUrl,
                    });
                  },
                  child: Text(isUploading ? 'Subiendo...' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    // 3. Procesar el resultado del diálogo
    if (result != null) {
      setState(() {
        if (partnerToEdit != null) {
          // Estamos editando: encontrar el original y reemplazarlo
          final index = _partners.indexOf(partnerToEdit);
          _partners[index] = result;
        } else {
          // Estamos añadiendo: simplemente agregarlo
          _partners.add(result);
        }
      });
      // Guardar en Firestore
      await _savePartnersToFirestore();
    }
  }

  /// Elimina un partner de la lista y de Storage
  Future<void> _deletePartner(Map<String, dynamic> partner) async {
    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D5A),
        title: const Text('Eliminar Partner', style: TextStyle(color: Colors.white)),
        content: Text('¿Seguro que quieres eliminar a "${partner['name']}"? El logo se borrará permanentemente.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(child: const Text('Cancelar', style: TextStyle(color: Colors.white70)), onPressed: () => Navigator.of(ctx).pop(false)),
          TextButton(child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)), onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );

    if (didConfirm != true) return;

    setState(() => _isLoading = true);
    final storageService = context.read<StorageService>();
    
    // 1. Borrar de la lista local
    setState(() => _partners.remove(partner));

    // 2. Borrar logo de Storage
    try {
      if (partner['logoUrl'] != null && (partner['logoUrl'] as String).isNotEmpty) {
        await storageService.deleteFileByUrl(partner['logoUrl']);
      }
    } catch (e) {
      debugPrint('Error al borrar logo de partner: $e');
    }

    // 3. Guardar la nueva lista en Firestore
    await _savePartnersToFirestore();
    
    // CORRECCIÓN (use_build_context_synchronously):
    // El 'finally' en _savePartnersToFirestore ya quita el _isLoading
    // pero si falla, 'mounted' ya se comprueba en _savePartnersToFirestore
    // Esta comprobación extra es segura.
    if(mounted) {
      setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Gestionar Partners'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Añade las marcas con las que trabajas. Estos logos aparecerán en un carrusel en tu perfil público.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: _partners.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.handshake_outlined, size: 80, color: Colors.white24),
                            SizedBox(height: 16),
                            Text('Aún no has añadido partners.', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _partners.length,
                        itemBuilder: (context, index) {
                          final partner = _partners[index];
                          return Card(
                            color: surfaceColor,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: (partner['logoUrl'] != null && (partner['logoUrl'] as String).isNotEmpty)
                                ? Image.network(partner['logoUrl'], width: 40, height: 40, fit: BoxFit.contain)
                                : const Icon(Icons.image_not_supported, color: Colors.white38),
                              title: Text(partner['name'] ?? 'Sin Nombre', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                                    tooltip: 'Editar',
                                    onPressed: () => _showAddEditPartnerDialog(partnerToEdit: partner),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    tooltip: 'Eliminar',
                                    onPressed: () => _deletePartner(partner),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              // CORRECCIÓN (deprecated_member_use): .withOpacity() a .withAlpha()
              color: Colors.black.withAlpha(128), // 0.5
              child: const Center(child: CircularProgressIndicator(color: accentColor)),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditPartnerDialog(),
        backgroundColor: accentColor,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }
}