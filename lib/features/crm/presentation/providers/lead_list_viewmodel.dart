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
  // Nota: En una aplicación real, se usaría Provider/Riverpod para obtener el estado de la suscripción.
  final bool _isProUser = true; 

  String _searchTerm = '';

  LeadListViewModel(this._repository);

  bool get isProUser => _isProUser;

  // Stream que obtiene la lista filtrada de Leads desde el Repositorio
  Stream<List<Cliente>> get filteredLeadsStream {
    // Llama al método del repositorio que ya implementamos
    return _repository.getLeadsStream(searchTerm: _searchTerm, isPro: _isProUser);
  }

  void setSearchTerm(String term) {
    if (_searchTerm != term) {
      _searchTerm = term;
      // Notificar a los widgets (Consumers) para que reconstruyan el StreamBuilder
      notifyListeners();
    }
  }

  // --- Lógica de Conversión ---

  // Método llamado desde la UI para convertir un Lead en Cliente
  Future<void> convertLeadToClient(String leadId, BuildContext context) async {
    try {
      // 1. Llamar al repositorio para actualizar el estado en Firestore
      await _repository.convertLeadToClient(leadId);

      // 2. Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 ¡Lead convertido a Cliente Activo exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      // 3. Manejar errores
      // En producción, aquí se usaría un logger y no solo print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al convertir Lead: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- Utilidades para la UI de Leads (Distinción Pro) ---

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

  // Obtiene la etiqueta del estado
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