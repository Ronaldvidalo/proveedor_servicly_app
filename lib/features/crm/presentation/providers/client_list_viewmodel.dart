import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
// Importaciones de paquete asumidas:
import 'package:proveedor_servicly_app/features/crm/data/models/cliente_model.dart';
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart';

// Un ChangeNotifier que maneja la lógica de la pestaña Clientes (contactos pagados)
class ClientListViewModel extends ChangeNotifier {
  final CrmRepository _repository;
  // Estado para el término de búsqueda
  String _searchTerm = '';
  // Estado para la configuración del usuario (plan y límite)
  Map<String, dynamic> _userConfig = {};
  
  // StreamController para manejar la lista de clientes desde el repositorio y aplicar filtros
  // Utilizamos BehaviorSubject para tener el último valor emitido disponible.
  final _clientesSubject = BehaviorSubject<List<Cliente>>();

  // Suscripciones a los streams de Firestore
  StreamSubscription? _clientesSubscription;
  StreamSubscription? _configSubscription;

  ClientListViewModel(this._repository) {
    // Inicialización del ViewModel. Se llama al construir la instancia.
    _startSubscriptions();
  }
  
  // Inicializa los streams
  void _startSubscriptions() {
    // 1. Suscripción a la lista de clientes activos (en tiempo real)
    _clientesSubscription = _repository.getClientesActivos().listen((clientes) {
      _clientesSubject.add(clientes);
      _applySearchAndLimit();
    });

    // 2. Suscripción a la configuración del usuario (para plan y límite)
    _configSubscription = _repository.getUserConfigStream().listen((config) {
      _userConfig = config;
      // Re-evaluar la lista si cambia el plan o el contador de límites
      _applySearchAndLimit();
      notifyListeners(); 
    });
  }

  // --- GETTERS PÚBLICOS ---
  
  // Expone el stream de clientes después de aplicar filtros y límite
  Stream<List<Cliente>> get filteredClientesStream => _clientesSubject.stream.map((clientes) {
    return _applySearchAndLimit(clientes);
  });
  
  // Bandera que indica si el usuario tiene plan Pro
  bool get isProUser => (_userConfig['plan'] as String? ?? 'free') == 'pro';
  
  // Contador actual de clientes/leads (usado para el límite Free)
  int get clienteCount => (_userConfig['clienteCount'] as int? ?? 0);
  
  // Límite estricto para la versión Free (100 contactos combinados)
  int get freeLimit => 100;
  
  // Calcula el porcentaje de límite usado (0.0 a 1.0)
  double get limitPercentage => isProUser ? 0.0 : (clienteCount / freeLimit).clamp(0.0, 1.0);
  
  String get searchTerm => _searchTerm;

  // --- LÓGICA DE FILTRADO Y LÍMITES ---
  
  // Aplica la búsqueda y el límite Free a la lista de clientes
  List<Cliente> _applySearchAndLimit([List<Cliente>? sourceList]) {
    final clientes = sourceList ?? _clientesSubject.valueOrNull ?? [];
    
    // 1. Aplicar Búsqueda (filtrado en memoria ya que Firestore no soporta búsquedas parciales eficientes)
    List<Cliente> filtered = clientes.where((c) {
      if (_searchTerm.isEmpty) return true;
      final term = _searchTerm.toLowerCase();
      // Búsqueda por nombre, email o teléfono
      return c.nombreCompleto.toLowerCase().contains(term) ||
             c.email.toLowerCase().contains(term) ||
             c.telefono.contains(term);
    }).toList();

    // 2. Aplicar Límite Free (solo si el usuario no es Pro)
    if (!isProUser && filtered.length > freeLimit) {
      // Retorna solo la parte de la lista que está dentro del límite
      return filtered.sublist(0, freeLimit);
    }

    return filtered;
  }

  // Método público para actualizar el término de búsqueda
  void setSearchTerm(String term) {
    _searchTerm = term;
    // Dispara la re-evaluación del stream
    _clientesSubject.add(_clientesSubject.valueOrNull ?? []); 
    // Notifica a los listeners de la UI que el término de búsqueda ha cambiado
    notifyListeners(); 
  }
  
  // Método de limpieza obligatorio para ChangeNotifier/Streams
  @override
  void dispose() {
    _clientesSubscription?.cancel();
    _configSubscription?.cancel();
    _clientesSubject.close();
    super.dispose();
  }
}
