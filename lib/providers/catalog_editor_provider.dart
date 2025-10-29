import 'package:flutter/foundation.dart'; // Importado para debugPrint
import 'package:flutter/material.dart';
import 'dart:io'; // Para File
import 'package:image_picker/image_picker.dart'; // Para seleccionar imágenes/videos

// Modelos y Servicios
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/core/services/storage_service.dart'; // Para subir/borrar archivos
import 'package:proveedor_servicly_app/core/models/portfolio_category_model.dart'; // Modelo de categoría
import 'package:proveedor_servicly_app/core/models/portfolio_item_model.dart'; // Modelo de ítem
import 'package:proveedor_servicly_app/core/services/permissions_service.dart'; // Para límites del plan

class CatalogEditorProvider with ChangeNotifier {
  // --- SERVICIOS INYECTADOS ---
  final FirestoreService _firestoreService;
  final StorageService _storageService;
  final PermissionsService _permissionsService;
  final ImagePicker _imagePicker = ImagePicker(); // Instancia de ImagePicker

  // --- ESTADO GENERAL ---
  late ProviderProfileModel _profileModelDraft;
  bool _isDirty = false;
  bool _isSaving = false;

  // --- ESTADO DEL PORTAFOLIO ---
  List<PortfolioCategoryModel> _localCategories = [];
  String? _selectedCategoryId;
  bool _isLoadingCategories = true;
  bool _isUploadingItem = false;
  double _uploadProgress = 0.0;
  String? _uploadingItemId; // Para identificar qué item se está subiendo

  // --- Constructor Actualizado ---
  CatalogEditorProvider({
    required ProviderProfileModel initialProfile,
    required FirestoreService firestoreService,
    required StorageService storageService,
    required PermissionsService permissionsService,
  }) : _firestoreService = firestoreService,
       _storageService = storageService,
       _permissionsService = permissionsService
  {
    _profileModelDraft = initialProfile.copyWith();
    // Podríamos iniciar la carga de categorías aquí si fuera necesario
    // loadInitialCategories(userId); // Necesitaríamos el userId aquí
  }

  // --- Getters Públicos (Generales) ---
  ProviderProfileModel get profile => _profileModelDraft;
  bool get isDirty => _isDirty;
  bool get isSaving => _isSaving;

  // --- Getters Públicos (Portafolio) ---
  List<PortfolioCategoryModel> get localCategories => _localCategories;
  String? get selectedCategoryId => _selectedCategoryId;
  bool get isLoadingCategories => _isLoadingCategories;
  bool get isUploadingItem => _isUploadingItem;
  double get uploadProgress => _uploadProgress;
  String? get uploadingItemId => _uploadingItemId;


  // --- Métodos de Mutación (Generales y Módulos Simples) ---

  /// Actualiza el texto de bienvenida en el borrador.
  void updateWelcomeText(String newText) {
    if (_profileModelDraft.welcomeMessage == newText) return;
    _profileModelDraft = _profileModelDraft.copyWith(welcomeMessage: newText);
    _markAsDirty();
  }

  /// Actualiza la visibilidad de un módulo (ej. desde el BottomSheet).
  void setModuleVisibility({required String moduleKey, required bool isVisible}) {
    // (Ejemplo para portafolio)
    if (moduleKey == 'showPortfolioModule') {
      if (_profileModelDraft.showPortfolioModule == isVisible) return;
      _profileModelDraft = _profileModelDraft.copyWith(showPortfolioModule: isVisible);
    }
    // (Ejemplo para bienvenida)
    else if (moduleKey == 'showWelcomeModule') {
       if (_profileModelDraft.showWelcomeModule == isVisible) return;
       _profileModelDraft = _profileModelDraft.copyWith(showWelcomeModule: isVisible);
    }
    // (Ejemplo para contacto - asumiendo que se añade a copyWith)
    // else if (moduleKey == 'showContactModule') {
    //    if (_profileModelDraft.showContactModule == isVisible) return;
    //    _profileModelDraft = _profileModelDraft.copyWith(showContactModule: isVisible);
    // }
    // (Ejemplo para reseñas)
    else if (moduleKey == 'showReviewsModule') {
       if (_profileModelDraft.showReviewsModule == isVisible) return;
       _profileModelDraft = _profileModelDraft.copyWith(showReviewsModule: isVisible);
    }
    // (Ejemplo para promos)
    else if (moduleKey == 'showPromotionsModule') {
       if (_profileModelDraft.showPromotionsModule == isVisible) return;
       _profileModelDraft = _profileModelDraft.copyWith(showPromotionsModule: isVisible);
    }
    // (Ejemplo para gift cards)
    else if (moduleKey == 'showGiftCardModule') {
       if (_profileModelDraft.showGiftCardModule == isVisible) return;
       _profileModelDraft = _profileModelDraft.copyWith(showGiftCardModule: isVisible);
    }
    else {
      debugPrint("Aviso: Clave de módulo desconocida en setModuleVisibility: $moduleKey");
      return; // Key desconocida o sin cambios
    }

    _markAsDirty();
  }

  /// Actualiza el slogan en el borrador.
  void updateSlogan(String? newSlogan) {
    if (_profileModelDraft.slogan == newSlogan) return;
    _profileModelDraft = _profileModelDraft.copyWith(slogan: newSlogan);
    _markAsDirty();
  }

  /// Actualiza el horario en el borrador.
  void updateOpeningHours(String? newHours) {
    if (_profileModelDraft.openingHours == newHours) return;
    _profileModelDraft = _profileModelDraft.copyWith(openingHours: newHours);
    _markAsDirty();
  }

  /// Actualiza el teléfono en el borrador.
  void updatePhone(String? newPhone) {
    if (_profileModelDraft.phone == newPhone) return;
    _profileModelDraft = _profileModelDraft.copyWith(phone: newPhone);
    _markAsDirty();
  }

  /// Actualiza el WhatsApp en el borrador.
  void updateWhatsapp(String? newWhatsapp) {
    if (_profileModelDraft.whatsapp == newWhatsapp) return;
    _profileModelDraft = _profileModelDraft.copyWith(whatsapp: newWhatsapp);
    _markAsDirty();
  }

  /// Actualiza el email de contacto en el borrador.
  void updateContactEmail(String newEmail) {
    // Asumimos que el email no puede ser null basado en el modelo
    if (_profileModelDraft.contactEmail == newEmail) return;
    _profileModelDraft = _profileModelDraft.copyWith(contactEmail: newEmail);
    _markAsDirty();
  }


  // --- Métodos de Mutación (Portafolio) ---

  /// Carga inicial de categorías desde Firestore y actualiza la lista local.
  Future<void> loadInitialCategories(String userId) async {
    _isLoadingCategories = true;
    notifyListeners();
    try {
      _localCategories = await _firestoreService.getPortfolioCategoriesStream(userId).first;
    } catch (e) {
      debugPrint("Error cargando categorías iniciales: $e");
      _localCategories = [];
    } finally {
      _isLoadingCategories = false;
      if (_localCategories.isNotEmpty) {
        if (_selectedCategoryId == null || !_localCategories.any((cat) => cat.id == _selectedCategoryId)) {
          _selectedCategoryId = _localCategories.first.id;
        }
      } else {
        _selectedCategoryId = null;
      }
      notifyListeners();
    }
  }

  /// Selecciona una categoría para mostrar sus ítems.
  void selectCategory(String? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  /// Añade una nueva categoría de portafolio.
  Future<bool> addPortfolioCategory(String userId, String name) async {
    if (!_permissionsService.canAddPortfolioCategory(_localCategories.length)) {
      debugPrint("Límite de categorías de portafolio alcanzado.");
      return false;
    }
    try {
      await _firestoreService.addPortfolioCategory(userId, name);
      await loadInitialCategories(userId); 
      if (_localCategories.isNotEmpty) {
         _selectedCategoryId = _localCategories.last.id;
         notifyListeners(); 
      }
      return true;
    } catch (e) {
      debugPrint("Error al añadir categoría de portafolio: $e");
      return false;
    }
  }

  /// Actualiza el nombre de una categoría.
  Future<void> updatePortfolioCategoryName(String userId, String categoryId, String newName) async {
    try {
      await _firestoreService.updatePortfolioCategory(userId, categoryId, newName);
      // --- WORKAROUND ---
      // No actualizamos localmente porque falta copyWith en PortfolioCategoryModel.
      // Recargamos todo para ver el cambio.
      await loadInitialCategories(userId); 
      // final index = _localCategories.indexWhere((cat) => cat.id == categoryId);
      // if (index != -1) {
      //   // ¡ESTA LÍNEA FALLA SI NO HAY copyWith!
      //   _localCategories[index] = _localCategories[index].copyWith(name: newName); 
      //   notifyListeners();
      // }
    } catch (e) {
      debugPrint("Error al actualizar nombre de categoría de portafolio: $e");
    }
  }

  /// Elimina una categoría (y sus ítems/archivos asociados).
  Future<void> deletePortfolioCategory(String userId, String categoryId) async {
    try {
      final itemsToDelete = await _firestoreService.getPortfolioItemsStream(userId, categoryId).first;
      List<Future<void>> deleteFutures = [];
      for (var item in itemsToDelete) {
        deleteFutures.add(_firestoreService.deletePortfolioItem(userId, item.id));
        if (item.url.isNotEmpty) {
           deleteFutures.add(_storageService.deleteFileByUrl(item.url));
        }
      }
      await Future.wait(deleteFutures);
      await _firestoreService.deletePortfolioCategory(userId, categoryId);

      _localCategories.removeWhere((cat) => cat.id == categoryId);
      if (_selectedCategoryId == categoryId) {
        _selectedCategoryId = _localCategories.isNotEmpty ? _localCategories.first.id : null;
      }
      notifyListeners();

    } catch (e) {
      debugPrint("Error al eliminar categoría de portafolio y sus ítems: $e");
    }
  }

  /// Reordena las categorías en la UI y guarda el nuevo orden en Firestore.
  Future<void> reorderPortfolioCategories(String userId, int oldIndex, int newIndex) async {
    final item = _localCategories.removeAt(oldIndex);
    final int insertIndex = (newIndex > oldIndex) ? newIndex - 1 : newIndex;
    _localCategories.insert(insertIndex, item);
    notifyListeners(); // Actualiza UI inmediatamente

    final Map<String, int> newOrderMap = {};
    for (int i = 0; i < _localCategories.length; i++) {
      newOrderMap[_localCategories[i].id] = i;
    }

    try {
      await _firestoreService.updatePortfolioCategoriesOrder(userId, newOrderMap);
    } catch (e) {
      debugPrint("Error al reordenar categorías de portafolio en Firestore: $e");
    }
  }

  /// Añade un nuevo ítem (foto o video) al portafolio en la categoría seleccionada.
  Future<void> addPortfolioItem(String userId, PortfolioItemType type) async {
     // TODO: Implementar chequeo de límite total de items (_permissionsService.canAddPortfolioItem)
    // if (!_permissionsService.canAddPortfolioItem(await getTotalItemCount(userId))) {
    //    debugPrint("Límite de ítems del portafolio alcanzado.");
    //    return; // Mostrar SnackBar de límite
    // }

    final XFile? pickedFile = type == PortfolioItemType.image
        ? await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80) 
        : await _imagePicker.pickVideo(source: ImageSource.gallery, maxDuration: _permissionsService.maxVideoDuration); 

    if (pickedFile == null || _selectedCategoryId == null) {
      debugPrint("Añadir ítem cancelado: No se seleccionó archivo o categoría.");
      return;
    }

    _isUploadingItem = true;
    _uploadProgress = 0.0;
    _uploadingItemId = DateTime.now().millisecondsSinceEpoch.toString();
    notifyListeners();

    try {
      final file = File(pickedFile.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
      final storagePath = 'users/$userId/portfolio/$_selectedCategoryId/$fileName';

      final downloadUrl = await _storageService.uploadFileWithProgress(
        file,
        storagePath,
        (progress) {
          if (_isUploadingItem) { 
             _uploadProgress = progress;
             notifyListeners();
          }
        },
      );

      if (_isUploadingItem) {
          await _firestoreService.addPortfolioItem(
            userId: userId,
            categoryId: _selectedCategoryId!,
            type: type,
            url: downloadUrl,
          );
      }

    } catch (e) {
      debugPrint("Error al añadir ítem de portafolio: $e");
    } finally {
      // Usamos 'mounted' getter aquí por seguridad
      if (mounted) { 
        _isUploadingItem = false;
        _uploadProgress = 0.0;
        _uploadingItemId = null;
        notifyListeners();
      }
    }
  }

  /// Elimina un ítem del portafolio (Firestore y Storage).
  Future<void> deletePortfolioItem(String userId, PortfolioItemModel item) async {
    try {
      await _firestoreService.deletePortfolioItem(userId, item.id);
      if (item.url.isNotEmpty) {
        await _storageService.deleteFileByUrl(item.url);
      }
    } catch (e) {
      debugPrint("Error al eliminar ítem de portafolio: $e");
    }
  }


  // --- Lógica de Estado y Guardado (General) ---

  /// Marca el estado como "sucio" y notifica a los listeners.
  void _markAsDirty() {
    if (!_isDirty) {
      _isDirty = true;
    }
    // Solo notifica si aún está montado
    if (mounted) {
       notifyListeners(); 
    }
  }

  /// Guarda todos los cambios del borrador (_profileModelDraft) en Firestore.
  Future<bool> saveChangesToFirestore({required String providerId}) async {
    if (!_isDirty) {
       debugPrint("Guardar cambios: No hay cambios pendientes.");
       return true; 
    }

    _isSaving = true;
     if (mounted) notifyListeners(); // Notifica antes del await

    try {
      await _firestoreService.updateUser(
        providerId,
        {
          'personalization': _profileModelDraft.toMap()
        }
      );

      _isDirty = false; 
      _isSaving = false;
       if (mounted) notifyListeners(); // Notifica después del await si está montado
      debugPrint("Guardar cambios: Éxito.");
      return true;

    } catch (e) {
      debugPrint("Error al guardar cambios generales: $e");
      _isSaving = false;
       if (mounted) notifyListeners(); // Notifica error si está montado
      return false; 
    }
  }

   // --- Helper para verificar si el widget está montado ---
   bool _mounted = true; 

   @override
   void dispose() {
     _mounted = false; // Marcar como no montado al hacer dispose
     super.dispose();
   }

   // Getter para verificar si está montado 
   bool get mounted => _mounted;

} // Fin de la clase CatalogEditorProvider