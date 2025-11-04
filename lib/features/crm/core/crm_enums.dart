// crm_enums.dart
// Define los estados posibles del contacto en el embudo CRM.
enum CrmEstado {
  // Estados para la funcionalidad Free y Pro
  lead, 
  clienteActivo,

  // Estados solo para la funcionalidad Pro (Flujo de Ventas Detallado)
  leadNuevo, // Nuevo contacto capturado (ej. desde el perfil público)
  contactado, // Se ha iniciado la comunicación
  cotizado, // Se ha enviado un presupuesto/cotización
  clienteInactivo, // Cliente anterior sin actividad reciente
}
