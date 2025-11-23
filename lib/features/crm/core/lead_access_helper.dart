import 'package:cloud_firestore/cloud_firestore.dart';

class LeadAccessHelper {
  
  /// Determina si el usuario tiene permiso para ver los datos de contacto de este lead.
  static bool canAccessLead(String planType, String leadSource) {
    // 1. PLAN MAX: Ve TODO (Vistas de producto, Carritos abandonados, Contactos directos)
    if (planType == 'max') return true;

    // 2. PLAN PRO: Ve Contactos directos + Carritos abandonados
    if (planType == 'pro') {
      if (leadSource.contains('cart')) return true; // Carrito
      if (_isDirectContact(leadSource)) return true; // Contacto directo
      
      // No ve 'view_product' (vistas sin acción)
      return false; 
    }

    // 3. PLAN FREE: Solo ve Contactos directos (Alta intención)
    if (planType == 'free') {
      return _isDirectContact(leadSource);
    }

    // Por defecto, bloqueado
    return false;
  }

  /// Define qué fuentes se consideran "Contacto Directo" (Intención genuina)
  static bool _isDirectContact(String source) {
    final s = source.toLowerCase();
    return s.contains('whatsapp') || 
           s.contains('telefono') || 
           s.contains('phone') || 
           s.contains('email') || 
           s.contains('mail') || 
           s.contains('presupuesto') || 
           s.contains('quote');
    // Nota: 'view_product' y 'cart' NO son contactos directos.
  }

  /// Obtiene la duración máxima de retención de leads según el plan (en días)
  static int getRetentionDays(String planType) {
    switch (planType) {
      case 'max': return 7;
      case 'pro': return 5;
      case 'free': default: return 2;
    }
  }
  
  /// Verifica si el lead ha expirado según el plan
  static bool isLeadExpired(String planType, Timestamp createdAt) {
    final daysLimit = getRetentionDays(planType);
    final deadline = DateTime.now().subtract(Duration(days: daysLimit));
    return createdAt.toDate().isBefore(deadline);
  }
}