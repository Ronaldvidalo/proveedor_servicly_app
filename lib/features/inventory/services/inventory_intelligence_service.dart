// /lib/features/inventory/services/inventory_intelligence_service.dart

import 'package:proveedor_servicly_app/core/models/product_model.dart'; 
import 'package:proveedor_servicly_app/features/agenda/data/repositories/agenda_repository.dart'; 
import 'package:proveedor_servicly_app/features/agenda/data/models/agenda_event_model.dart'; 

class InventoryIntelligenceService {
  final AgendaRepository _agendaRepo;
  final String _userId;

  InventoryIntelligenceService(this._agendaRepo, this._userId);

  /// Analiza un producto y crea un evento/recordatorio en la agenda si es necesario.
  Future<void> monitorAndSuggestTasks(ProductModel product) async {
    if (_userId.isEmpty) return;
    
    // Asumimos que su ProductModel tiene estos campos. Usamos 0/null como fallback.
    final currentQuantity = product.quantity ?? 0;
    // ✅ CORRECCIÓN: Eliminado '?? 5' ya que minStock no es nullable
    final minStock = product.minStock; 
    
    // --- LÓGICA 1: Tarea de Caducidad ---
    if (product.expiryDate != null) {
      final expirationDate = product.expiryDate!.toDate();
      final daysUntilExpiry = expirationDate.difference(DateTime.now()).inDays;

      // Sugerir tarea de revisión 7 días antes de la caducidad
      if (daysUntilExpiry <= 7 && daysUntilExpiry > 0) {
        final reviewDate = expirationDate.subtract(const Duration(days: 7));
        
        final event = AgendaEvent(
          title: '🚨 Revisar caducidad: ${product.name}',
          description: 'El producto ${product.name} caduca en $daysUntilExpiry días. Revisa si se puede vender con descuento o si debe ser desechado.',
          startTime: reviewDate,
          endTime: reviewDate.add(const Duration(minutes: 30)), // Bloqueo de 30 minutos
          eventType: EventType.personalReminder, 
          providerId: _userId, 
          isAllDay: false,
        );

        await _agendaRepo.addEvent(event);
      }
    }
    
    // --- LÓGICA 2: Tarea de Reposición por Stock Crítico ---
    if (currentQuantity <= minStock) {
       final event = AgendaEvent(
          title: '📦 Reponer Stock Crítico: ${product.name}',
          description: 'El stock ($currentQuantity) de ${product.name} está en o por debajo del nivel mínimo ($minStock). ¡Es hora de realizar un pedido!',
          startTime: DateTime.now().add(const Duration(hours: 1)), // Sugerencia de tarea inmediata
          endTime: DateTime.now().add(const Duration(hours: 1, minutes: 30)),
          eventType: EventType.personalReminder,
          providerId: _userId,
          isAllDay: false,
        );

        await _agendaRepo.addEvent(event);
    }
  }
}