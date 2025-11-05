import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart';
import 'package:proveedor_servicly_app/features/crm/data/models/cliente_model.dart';
import 'package:proveedor_servicly_app/features/crm/core/crm_enums.dart';

// Este ViewModel maneja la lógica y el estado de la pestaña "Leads y Seguimiento"
class LeadListViewModel extends ChangeNotifier {
  final CrmRepository _repository;

  // Simulación: Determinar si el usuario es Pro (debería venir de un servicio de Auth/Config)
  final bool _isProUser = true; 

  String _searchTerm = '';

  LeadListViewModel(this._repository);

  bool get isProUser => _isProUser;

  // Define los estados de Lead disponibles para el pipeline de ventas (Solo Pro)
  List<CrmEstado> get availableLeadPipelineStates {
    // Si no es Pro, solo puede convertir a Cliente Activo (mediante el botón Convertir)
    if (!_isProUser) return []; 
    
    return [
      CrmEstado.leadNuevo,
      CrmEstado.contactado,
      CrmEstado.cotizado,
      CrmEstado.clienteActivo, // Opción final para conversión manual
    ];
  }

  // Stream que obtiene la lista filtrada de Leads desde el Repositorio
  Stream<List<Cliente>> get filteredLeadsStream {
    return _repository.getLeadsStream(searchTerm: _searchTerm, isPro: _isProUser);
  }

  void setSearchTerm(String term) {
    if (_searchTerm != term) {
      _searchTerm = term;
      notifyListeners();
    }
  }

  // --- Lógica de Conversión y Actualización de Pipeline ---

  // Método llamado desde la UI para cambiar el estado de un Lead
  Future<void> updateLeadStatus(String leadId, CrmEstado newStatus, BuildContext context) async {
    try {
      if (newStatus == CrmEstado.clienteActivo) {
        // Usar la lógica de conversión existente si el destino es CLIENTE_ACTIVO
        await _repository.convertLeadToClient(leadId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 ¡Lead convertido a Cliente Activo exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Mover el Lead a un nuevo estado del pipeline (Solo Pro)
        await _repository.updateLeadStatus(leadId, newStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lead movido a ${getLeadStatusLabel(newStatus)}'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar el estado del Lead: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // El antiguo método de conversión ahora simplemente llama a updateLeadStatus
  Future<void> convertLeadToClient(String leadId, BuildContext context) async {
    await updateLeadStatus(leadId, CrmEstado.clienteActivo, context);
  }


  // --- Utilidades para la UI de Leads ---

  // Obtiene el color asociado al estado del Lead
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

  // Obtiene la etiqueta del estado (Human-readable label)
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
  
  // Obtiene la inicial para el avatar
  String getLeadStatusInitial(CrmEstado estado) {
     return getLeadStatusLabel(estado)[0];
  }
}