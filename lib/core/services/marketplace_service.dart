import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/models/category_model.dart';
import 'package:proveedor_servicly_app/core/models/country_model.dart';

/// Un servicio para obtener los datos del marketplace desde las colecciones públicas.
class MarketplaceService {
  final FirebaseFirestore _db;

  MarketplaceService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // --- CORRECCIÓN 1: Apuntar a la colección NUEVA y CORRECTA ---
  CollectionReference<Map<String, dynamic>> get _publicProfilesCollection => _db.collection('brandProfiles');
  
  CollectionReference<Map<String, dynamic>> get _mainCategoriesCollection => _db.collection('main_categories');
  
  CollectionReference<Map<String, dynamic>> get _countriesCollection => _db.collection('countries');

  /// Obtiene la lista de categorías principales para los filtros del marketplace.
  Stream<List<CategoryModel>> getMainCategories() {
    return _mainCategoriesCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
    });
  }
  
  /// Obtiene la lista de países disponibles para los filtros.
  Stream<List<CountryModel>> getCountries() {
    return _countriesCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => CountryModel.fromFirestore(doc)).toList();
    });
  }
  
  /// Obtiene un stream con la lista de perfiles públicos de proveedores.
  Stream<List<ProviderProfileModel>> getProviders({
    String? categoryName, 
    String? countryCode,
    String? profileType, // Esto trae 'store', 'catalog', etc.
  }) {
    Query<Map<String, dynamic>> query = _publicProfilesCollection;

    debugPrint("🛒 Marketplace: Iniciando consulta a 'brandProfiles'...");

    // 1. Filtro por País
    if (countryCode != null && countryCode.isNotEmpty) {
      query = query.where('country', isEqualTo: countryCode);
    }

    // 2. Filtro por Categoría
    if (categoryName != null && categoryName.isNotEmpty) {
      // En tu captura de pantalla veo que el campo se llama 'mainCategory'
      query = query.where('mainCategory', isEqualTo: categoryName);
    }
    
    // 3. Filtro por Tipo de Perfil (CORREGIDO)
    if (profileType != null && profileType.isNotEmpty && profileType != 'all') {
      // En tu captura el campo es 'publicProfileTemplate', NO 'profileType'
      debugPrint("🛒 Filtrando por template: $profileType");
      query = query.where('publicProfileTemplate', isEqualTo: profileType);
    }
    
    return query.snapshots().map((snapshot) {
      debugPrint("✅ Marketplace: Se encontraron ${snapshot.docs.length} perfiles.");
      
      return snapshot.docs.map((doc) {
        try {
          // Intentamos convertir el documento al modelo
          return ProviderProfileModel.fromFirestore(doc);
        } catch (e) {
          debugPrint("❌ Error al leer perfil ${doc.id}: $e");
          return null;
        }
      })
      .where((p) => p != null) // Filtramos los que fallaron
      .cast<ProviderProfileModel>() // Aseguramos el tipo
      .toList();
    });
  }
}