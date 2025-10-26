import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/models/category_model.dart';
import 'package:proveedor_servicly_app/core/models/country_model.dart'; // Se asume que crearás este modelo

/// Un servicio para obtener los datos del marketplace desde las colecciones públicas.
class MarketplaceService {
  final FirebaseFirestore _db;

  MarketplaceService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _publicProfilesCollection => _db.collection('public_profiles');
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
  ///
  /// Permite filtrar por tipo de perfil, categoría y/o país.
  Stream<List<ProviderProfileModel>> getProviders({
    String? categoryName, 
    String? countryCode,
    String? profileType, // <-- PARÁMETRO AÑADIDO
  }) {
    Query<Map<String, dynamic>> query = _publicProfilesCollection;

    // NOTA: Para que estos filtros funcionen, el documento en 'public_profiles'
    // debe tener los campos 'country', 'mainCategory' y 'profileType'.

    if (countryCode != null && countryCode.isNotEmpty) {
      query = query.where('country', isEqualTo: countryCode);
    }
    if (categoryName != null && categoryName.isNotEmpty) {
      query = query.where('mainCategory', isEqualTo: categoryName);
    }
    
    // --- LÓGICA AÑADIDA ---
    // Si se proporciona un 'profileType' (y no es 'all', que vendrá como null),
    // filtramos la consulta por ese tipo.
    if (profileType != null && profileType.isNotEmpty) {
      query = query.where('profileType', isEqualTo: profileType);
    }
    // --- FIN DE LA LÓGICA ---
    
    // NOTA TÉCNICA: Esta consulta compuesta (con múltiples 'where')
    // requerirá un índice en Firestore. La primera vez que se ejecute,
    // Firebase dará un error en la consola con un enlace para
    // crear el índice automáticamente.
    // (Ej: un índice para [profileType, mainCategory])

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ProviderProfileModel.fromFirestore(doc)).toList();
    });
  }
}