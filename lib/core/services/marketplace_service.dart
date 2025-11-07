import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/models/category_model.dart';
import 'package:proveedor_servicly_app/core/models/country_model.dart';

/// Un servicio para obtener los datos del marketplace desde las colecciones públicas.
class MarketplaceService {
  final FirebaseFirestore _db;

  MarketplaceService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // --- CORRECCIÓN 1 ---
  // Apunta a 'catalogs' para los perfiles de proveedores
  CollectionReference<Map<String, dynamic>> get _publicProfilesCollection => _db.collection('catalogs');
  
  // --- CORRECCIÓN 2 ---
  // Apunta a 'main_categories' para los filtros de rubro
  CollectionReference<Map<String, dynamic>> get _mainCategoriesCollection => _db.collection('main_categories');
  
  CollectionReference<Map<String, dynamic>> get _countriesCollection => _db.collection('countries');

  /// Obtiene la lista de categorías principales para los filtros del marketplace.
  Stream<List<CategoryModel>> getMainCategories() {
    // Esto ahora leerá de 'main_categories'
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
    String? profileType,
  }) {
    // Esto ahora leerá de 'catalogs'
    Query<Map<String, dynamic>> query = _publicProfilesCollection;

    // NOTA: Para que estos filtros funcionen, el documento en 'catalogs'
    // debe tener los campos 'country', 'mainCategory' y 'profileType'.

    if (countryCode != null && countryCode.isNotEmpty) {
      query = query.where('country', isEqualTo: countryCode);
    }
    if (categoryName != null && categoryName.isNotEmpty) {
      // Asegúrate de que tus perfiles en 'catalogs' tengan este campo
      query = query.where('mainCategory', isEqualTo: categoryName);
    }
    
    if (profileType != null && profileType.isNotEmpty) {
      // Asegúrate de que tus perfiles en 'catalogs' tengan este campo
      query = query.where('profileType', isEqualTo: profileType);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ProviderProfileModel.fromFirestore(doc)).toList();
    });
  }
}