// --- UX/UI Enhancement Comment ---
// Provider: QuoteProvider
// Responsabilidad: Gestionar el estado de las cotizaciones.
// Ubicación: lib/features/budget/providers/quote_provider.dart
// Actualización: 
// 1. Soporte para 'validUntil' y 'notes'.
// 2. Métodos para actualizar fecha y notas desde el editor.
// ---------------------------------

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

  // 1. INICIALIZAR STREAM
  void _initStream() {
    if (_userId.isEmpty) {
      _isLoading = false;
      _quotes = []; 
      return; 
    }

    _isLoading = true;
    
    _quotesSubscription = _repository.getQuotesStream(_userId).listen(
      (quotesData) {
        _quotes = quotesData;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Error escuchando cotizaciones: $error");
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // 2. GESTIÓN DEL EDITOR
  
  // Iniciar una nueva cotización limpia
  void startNewQuote(UserModel? currentUser) {
    final tempNumber = 'COT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final now = DateTime.now();
    
    _currentQuote = Quote(
      id: '', 
      number: tempNumber,
      clientId: '', 
      clientName: '',
      createdAt: now,
      // Default: Validez de 30 días
      validUntil: now.add(const Duration(days: 30)),
      status: 'draft',
      items: [],
      currency: 'USD',
      taxRate: 0.0,
      notes: '', // Notas vacías al inicio
    );
    notifyListeners();
  }

  // Cargar una cotización existente para editar
  void editQuote(Quote quote) {
    _currentQuote = quote;
    notifyListeners();
  }

  // Agregar un ítem
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
    _currentQuote = _currentQuote!.copyWith(clientName: name);
    // notifyListeners(); // Opcional: si el input es controlado, a veces no es necesario notificar a cada tecla
  }

  // --- NUEVO: Actualizar Fecha de Vencimiento ---
  void updateExpirationDate(DateTime date) {
    if (_currentQuote == null) return;
    _currentQuote = _currentQuote!.copyWith(validUntil: date);
    notifyListeners();
  }

  // --- NUEVO: Actualizar Notas ---
  // Este método debe llamarse antes de guardar o al cambiar el texto
  void updateNotes(String content) {
    if (_currentQuote == null) return;
    _currentQuote = _currentQuote!.copyWith(notes: content);
    // No notificamos listeners a cada caracter para evitar reconstruir toda la UI,
    // pero actualizamos el modelo interno para el guardado.
  }

  // Recálculo interno de totales
  void _recalculateCurrent({List<QuoteItem>? items}) {
    if (_currentQuote == null) return;
    
    final finalItems = items ?? _currentQuote!.items;
    
    double subtotal = 0.0;
    for (var item in finalItems) {
      subtotal += item.total;
    }

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
      // Nos aseguramos de que todos los datos estén sincronizados
      await _repository.saveQuote(_userId, _currentQuote!);
    } catch (e) {
      debugPrint("Error guardando cotización: $e");
      rethrow;
    }
  }
  
  // 4. ELIMINAR
  Future<void> deleteQuote(String quoteId) async {
    try {
      await _repository.deleteQuote(_userId, quoteId);
    } catch (e) {
       debugPrint("Error eliminando: $e");
    }
  }

  // 5. ACTUALIZAR ESTADO
  Future<void> updateQuoteStatus(String quoteId, String newStatus) async {
    try {
      await _repository.updateStatus(_userId, quoteId, newStatus);
      
      // Si estamos editando la misma que cambiamos de estado, actualizamos la local
      if (_currentQuote != null && _currentQuote!.id == quoteId) {
        _currentQuote = _currentQuote!.copyWith(status: newStatus);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error actualizando estado: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    _quotesSubscription?.cancel();
    super.dispose();
  }
}