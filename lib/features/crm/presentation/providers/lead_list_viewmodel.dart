// --- INICIO DE ARCHIVO: lead_list_viewmodel.dart ---

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart';
import 'package:proveedor_servicly_app/features/crm/data/models/cliente_model.dart';
import 'package:proveedor_servicly_app/features/crm/core/crm_enums.dart';

/// ViewModel que gestiona la lógica y el estado de la pestaña "Leads y Seguimiento" (Pipeline de Ventas).
class LeadListViewModel extends ChangeNotifier {
  final CrmRepository _crmRepository;

  // --- CORRECCIÓN: Inicializar en false y actualizar vía init() ---
  bool _isProUser = false; 
  String _searchTerm = '';

  StreamSubscription<List<Cliente>>? _clientesSubscription;
  StreamSubscription<Map<String, dynamic>>? _configSubscription; 
  
  int _leadCount = 0; 
  final int leadLimit = 100;

  LeadListViewModel(this._crmRepository) {
    // Ya no cargamos aquí, esperamos al init()
    // _loadClientesStream(isPro: _isProUser);
    // _loadUserConfigStream(); 
  }

  // --- MÉTODO DE INICIALIZACIÓN (NUEVO) ---
  void init(bool isPro) {
    _isProUser = isPro;
    _loadClientesStream(isPro: _isProUser);
    _loadUserConfigStream();
    notifyListeners();
  }
  
  // --- GETTERS PÚBLICOS ---

  bool get isProUser => _isProUser;
  int get leadCount => _leadCount;
  
  List<CrmEstado> get availableLeadPipelineStates {
    // --- CORRECCIÓN: Devolver estados básicos si no es Pro ---
    if (!_isProUser) {
      return [
        CrmEstado.leadNuevo,
        CrmEstado.lead,
      ]; 
    }
    
    return [
      CrmEstado.leadNuevo,
      CrmEstado.contactado,
      CrmEstado.cotizado,
      CrmEstado.clienteActivo, 
    ];
  }

  Stream<List<Cliente>> get filteredLeadsStream {
    return _crmRepository.getLeadsStream(searchTerm: _searchTerm, isPro: _isProUser)
        .map((leads) {
          return leads.where((cliente) {
            if (_searchTerm.isEmpty) return true;
            final term = _searchTerm.toLowerCase();
            return cliente.nombreCompleto.toLowerCase().contains(term) ||
                   cliente.email.toLowerCase().contains(term) ||
                   cliente.telefono.contains(term);
          }).toList();
        });
  }


  // --- MÉTODOS DE LÓGICA Y ACTUALIZACIÓN ---
  
  void _loadUserConfigStream() {
    _configSubscription?.cancel();
    _configSubscription = _crmRepository.getUserConfigStream().listen(
      (config) {
        final newCount = (config['clienteCount'] as int?) ?? 0;
        if (newCount != _leadCount) {
            _leadCount = newCount;
            notifyListeners();
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('Error al cargar stream de configuración/conteo: $error');
        }
      },
    );
  }


  void _loadClientesStream({bool isPro = false}) {
    _clientesSubscription?.cancel();
    
    _clientesSubscription = _crmRepository.getLeadsStream(isPro: isPro).listen(
      (leads) {
        notifyListeners();
      },
      onError: (error) {
        if (kDebugMode) {
          print('Error al cargar stream de Leads: $error');
        }
      },
    );
  }
  
  void setSearchTerm(String term) {
    if (_searchTerm != term) {
      _searchTerm = term;
      notifyListeners(); 
    }
  }

  /// Función auxiliar para ejecutar el Future y manejar el feedback de UI.
  void _executeFuture(Future<void> future, CrmEstado newStatus, BuildContext context) {
      if (!context.mounted) return;

      future.then((_) {
        if (context.mounted) {
          final message = newStatus == CrmEstado.clienteActivo 
              ? '🎉 ¡Lead convertido a Cliente Activo exitosamente!'
              : 'Lead movido a ${getLeadStatusLabel(newStatus)}';
          
          final color = newStatus == CrmEstado.clienteActivo ? Colors.green : Colors.blue;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: color),
          );
        }
      }).catchError((e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar el estado del Lead: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
  }

  /// Método llamado desde la UI para cambiar el estado de un Lead o convertirlo.
  void updateLeadStatus(String leadId, CrmEstado newStatus, BuildContext context) {
    if (!context.mounted) return;
    
    final updateFuture = (newStatus == CrmEstado.clienteActivo) 
        ? _crmRepository.convertLeadToClient(leadId) 
        : _crmRepository.updateLeadStatus(leadId, newStatus); 
    
    _executeFuture(updateFuture, newStatus, context);
  }
  
  void convertLeadToClient(String leadId, BuildContext context) {
    if (!context.mounted) return;
    updateLeadStatus(leadId, CrmEstado.clienteActivo, context);
  }


  // --- Utilidades para la UI de Leads ---

  Color getLeadStatusColor(CrmEstado estado) {
    switch (estado) {
      case CrmEstado.leadNuevo:
        return Colors.blue.shade700;
      case CrmEstado.contactado:
        return Colors.orange.shade700;
      case CrmEstado.cotizado:
        return Colors.purple.shade700;
      case CrmEstado.lead:
      case CrmEstado.clienteInactivo:
      case CrmEstado.clienteActivo:
        return Colors.grey.shade500;
    }
  }

  String getLeadStatusLabel(CrmEstado estado) {
    switch (estado) {
      case CrmEstado.leadNuevo:
        return 'Nuevo';
      case CrmEstado.contactado:
        return 'Contactado';
      case CrmEstado.cotizado:
        return 'Cotizado';
      case CrmEstado.lead:
        return 'Lead (Básico)';
      case CrmEstado.clienteActivo:
        return 'Cliente Activo';
      case CrmEstado.clienteInactivo:
        return 'Cliente Inactivo';
    }
  }
  
  String getLeadStatusInitial(CrmEstado estado) {
      return getLeadStatusLabel(estado)[0];
  }
  
  @override
  void dispose() {
    _clientesSubscription?.cancel();
    _configSubscription?.cancel(); 
    super.dispose();
  }
}

// --- FIN DE ARCHIVO: lead_list_viewmodel.dart ---