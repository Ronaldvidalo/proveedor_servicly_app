// /lib/features/crm/presentation/providers/recommendations_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'package:proveedor_servicly_app/ai/services/gemini_service.dart';
import 'package:proveedor_servicly_app/features/crm/data/models/cliente_model.dart';
import 'package:proveedor_servicly_app/features/inventory/data/inventory_repository.dart'; 
import 'package:proveedor_servicly_app/core/models/product_model.dart'; // Catálogo completo

class RecommendationsViewModel extends ChangeNotifier {
    final GeminiService _geminiService;
    final InventoryRepository _inventoryRepo;
    final Cliente _client;
    
    List<ProductModel> _allProducts = []; // Catálogo completo
    List<String> _recommendations = []; // Nombres sugeridos por IA
    bool _isLoading = false;

    RecommendationsViewModel(this._geminiService, this._inventoryRepo, this._client) {
        _loadRecommendations();
    }

    // --- GETTERS ---
    bool get isLoading => _isLoading;
    List<String> get recommendations => _recommendations;
    
    // Obtener objetos completos de productos (opcional, si necesita más datos que solo el nombre)
    List<ProductModel> get recommendedProducts {
      if (_recommendations.isEmpty || _allProducts.isEmpty) return [];
      
      // Filtra el catálogo por los nombres sugeridos por la IA
      return _allProducts
          .where((p) => _recommendations.contains(p.name))
          .toList();
    }

    // --- LÓGICA ---
    
    Future<void> _loadRecommendations() async {
        if (_isLoading) return;
        _isLoading = true;
        notifyListeners();

        try {
            // 1. Obtener el catálogo completo para dar contexto a la IA y para mapeo posterior
            final productModelsStream = _inventoryRepo.getProductsStream();
            final allProducts = await productModelsStream.first; // Toma el primer snapshot
            _allProducts = allProducts;
            
            // 2. Preparar el contexto de la IA
            final allProductNames = allProducts.map((p) => p.name).toList();
            
            // Asumimos que el historial del cliente se obtiene de otra fuente, 
            // pero para este MVP lo simularemos con una etiqueta o campo del cliente.
            // NOTA: En un sistema real, se usaría un SalesRepository.
            final clientHistorySimulated = _client.etiquetas.where((tag) => tag.startsWith('bought_')).toList();
            
            // 3. Llamar a SERVI para la predicción
            final suggestedNames = await _geminiService.predictClientRecommendations(
                _client.id, 
                allProductNames, 
                clientHistorySimulated
            );
            
            _recommendations = suggestedNames;

        } catch (e) {
            debugPrint('Error loading recommendations: $e');
            _recommendations = ['Error al cargar sugerencias.'];
        } finally {
            _isLoading = false;
            notifyListeners();
        }
    }
}
