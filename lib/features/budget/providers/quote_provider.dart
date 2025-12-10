// --- UX/UI Enhancement Comment ---
// Provider: QuoteProvider
// Responsabilidad: Gestionar el estado de las cotizaciones y la lógica de negocio del editor.
// Ubicación: lib/features/budget/providers/quote_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/features/budget/models/quote_model.dart';
import 'package:proveedor_servicly_app/features/budget/models/quote_item_model.dart';
import 'package:proveedor_servicly_app/features/budget/repositories/quote_repository.dart';

class QuoteProvider extends ChangeNotifier {
  final QuoteRepository _repository;
  final String _userId;

  // --- ESTADO DE LA LISTA ---
  List<Quote> _quotes = [];
  List<Quote> get quotes => _quotes;
  
  bool _isLoading = true;
  bool get isLoading => _isLoading;
  
  StreamSubscription? _quotesSubscription;

  // --- ESTADO DEL EDITOR (Cotización actual en edición) ---
  Quote? _currentQuote;
  Quote? get currentQuote => _currentQuote;

  QuoteProvider({
    required QuoteRepository repository, 
    required String userId
  }) : _repository = repository,
       _userId = userId {
    _initStream();
  }

  // 1. INICIALIZAR STREAM (Escucha tiempo real)
  void _initStream() {
    _isLoading = true;
    notifyListeners();

    _quotesSubscription = _repository.getQuotesStream(_userId).listen(
      (quotesData) {
        _quotes = quotesData;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        print("Error escuchando cotizaciones: $error");
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // 2. GESTIÓN DEL EDITOR
  
  // Iniciar una nueva cotización limpia
  void startNewQuote(UserModel? currentUser) {
    // Generamos un folio temporal (luego se puede mejorar con lógica de secuencias)
    final tempNumber = 'COT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    
    _currentQuote = Quote(
      id: '', // Vacío indica que es nueva
      number: tempNumber,
      clientId: '', 
      clientName: '',
      createdAt: DateTime.now(),
      status: 'draft',
      items: [],
      currency: 'USD', // Configurable según perfil
      taxRate: 0.0,    // Configurable
    );
    notifyListeners();
  }

  // Cargar una cotización existente para editar
  void editQuote(Quote quote) {
    _currentQuote = quote;
    notifyListeners();
  }

  // Agregar un ítem al editor (Desde el Selector de Inventario)
  void addItemToCurrent(QuoteItem item) {
    if (_currentQuote == null) return;
    
    final updatedItems = List<QuoteItem>.from(_currentQuote!.items)..add(item);
    _recalculateCurrent(items: updatedItems);
  }

  // Eliminar un ítem
  void removeItemFromCurrent(String itemId) {
    if (_currentQuote == null) return;

    final updatedItems = _currentQuote!.items.where((i) => i.id != itemId).toList();
    _recalculateCurrent(items: updatedItems);
  }

  // Actualizar cantidad o precio de un ítem
  void updateItemInCurrent(String itemId, {double? quantity, double? price}) {
    if (_currentQuote == null) return;

    final updatedItems = _currentQuote!.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(
          quantity: quantity ?? item.quantity,
          unitPrice: price ?? item.unitPrice,
        );
      }
      return item;
    }).toList();

    _recalculateCurrent(items: updatedItems);
  }

  // Actualizar datos del cliente
  void updateClientInfo(String name, String email) {
    if (_currentQuote == null) return;
    // Nota: Podrías agregar email al modelo Quote si lo necesitas
    _currentQuote = _currentQuote!.copyWith(clientName: name);
    notifyListeners();
  }

  // Recálculo interno de totales
  void _recalculateCurrent({List<QuoteItem>? items}) {
    if (_currentQuote == null) return;
    
    final finalItems = items ?? _currentQuote!.items;
    
    // Suma de subtotales
    double subtotal = 0.0;
    for (var item in finalItems) {
      subtotal += item.total;
    }

    // Cálculo de impuestos
    double taxAmount = subtotal * (_currentQuote!.taxRate / 100);
    double total = subtotal + taxAmount;

    _currentQuote = _currentQuote!.copyWith(
      items: finalItems,
      total: total,
    );
    notifyListeners();
  }

  // 3. GUARDAR EN FIREBASE
  Future<void> saveCurrentQuote() async {
    if (_currentQuote == null) return;
    
    try {
      await _repository.saveQuote(_userId, _currentQuote!);
      // Opcional: Limpiar currentQuote o navegar atrás
    } catch (e) {
      print("Error guardando cotización: $e");
      rethrow;
    }
  }
  
  // 4. ELIMINAR
  Future<void> deleteQuote(String quoteId) async {
    try {
      await _repository.deleteQuote(_userId, quoteId);
    } catch (e) {
       print("Error eliminando: $e");
    }
  }

  @override
  void dispose() {
    _quotesSubscription?.cancel();
    super.dispose();
  }
  Future<void> updateQuoteStatus(String quoteId, String newStatus) async {
    try {
      await _repository.updateStatus(_userId, quoteId, newStatus);
      // No necesitamos recargar manualmente, el Stream escuchará el cambio
      // y actualizará la UI automáticamente.
    } catch (e) {
      print("Error actualizando estado: $e");
      rethrow;
    }
  }
}