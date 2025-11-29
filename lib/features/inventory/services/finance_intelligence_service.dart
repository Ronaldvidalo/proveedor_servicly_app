import 'package:flutter/foundation.dart';
import 'package:proveedor_servicly_app/ai/services/gemini_service.dart';
import 'package:proveedor_servicly_app/features/finance/data/repositories/finance_repository.dart'; // Asumido
import 'package:proveedor_servicly_app/features/finance/data/models/transaction_model.dart'; // Asumido

class FinanceIntelligenceService {
  final GeminiService _geminiService;
  final FinanceRepository _financeRepo;
  final String _userId;

  FinanceIntelligenceService(this._geminiService, this._financeRepo, this._userId);

  /// Procesa una lista de transacciones crudas y clasifica su categoría usando SERVI.
  Future<List<TransactionModel>> classifyTransactions(List<TransactionModel> transactions) async {
    if (_userId.isEmpty) return transactions;
    
    // 1. Obtener la lista de categorías contables del usuario para dar contexto a la IA.
    final userCategories = await _financeRepo.getUserExpenseCategories(_userId);
    
    if (userCategories.isEmpty) {
        debugPrint('No se encontraron categorías contables del usuario. Se saltará la clasificación IA.');
        return transactions;
    }

    // 2. Procesar y clasificar cada transacción en paralelo (Future.wait)
    final classifiedFutures = transactions.map((tx) async {
      final description = tx.description;
      
      // La IA clasifica la transacción.
      final suggestedCategory = await _geminiService.classifyTransaction(
        description,
        userCategories,
      );
      
      // Creamos una copia de la transacción con la categoría sugerida.
      return tx.copyWith(
        category: suggestedCategory,
        // Puedes añadir un campo como isAIAssigned: true
      );
    }).toList();
    
    return await Future.wait(classifiedFutures);
  }
}