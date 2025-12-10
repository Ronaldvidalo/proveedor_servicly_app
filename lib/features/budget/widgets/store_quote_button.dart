// --- UX/UI Enhancement Comment ---
// Widget: StoreQuoteButton
// Ubicación: lib/features/public_profile/screens/widgets/store_quote_button.dart
// Responsabilidad: Botón estandarizado para solicitar cotizaciones.
// Flujo: 
// 1. Cliente Público -> Navega al formulario estructurado (ClientQuoteRequestScreen).
// 2. Admin/Override -> Ejecuta acción personalizada (si se provee).

import 'package:flutter/material.dart';

// --- IMPORT DE LA PANTALLA DEL FORMULARIO ---
// Asegúrate de que esta ruta coincida con donde guardaste el archivo del paso anterior.
// Si lo guardaste en 'lib/features/public_profile/screens/client_quote_request_screen.dart', usa esta:
import 'package:proveedor_servicly_app/features/budget/screens/client_quote_request_screen.dart';
// Si lo guardaste en budget, ajusta la ruta.

class StoreQuoteButton extends StatelessWidget {
  final String providerId;
  final String providerName; // <-- Dato necesario para el título del formulario
  final Color brandColor;
  final String? message;
  final bool isFullWidth;
  final VoidCallback? onPressedOverride; 

  const StoreQuoteButton({
    super.key,
    required this.providerId,
    this.providerName = 'Proveedor', // Valor por defecto seguro
    required this.brandColor,
    this.message,
    this.isFullWidth = true,
    this.onPressedOverride,
  });

  @override
  Widget build(BuildContext context) {
    // -----------------------------------------------------------
    // CASO 1: ACCIÓN PERSONALIZADA (Admin / Preview)
    // -----------------------------------------------------------
    if (onPressedOverride != null) {
      return SizedBox(
        width: isFullWidth ? double.infinity : null,
        child: ElevatedButton.icon(
          onPressed: onPressedOverride,
          icon: const Icon(Icons.edit_note, size: 20),
          label: const Text(
            "Crear Cotización (Admin)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: brandColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            shadowColor: brandColor.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    // -----------------------------------------------------------
    // CASO 2: FLUJO CLIENTE -> FORMULARIO DE SOLICITUD
    // -----------------------------------------------------------
    // Aquí es donde cambiamos la lógica. Ya no abrimos WhatsApp directo.
    // Abrimos la pantalla de ClientQuoteRequestScreen.
    
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: () {
          // Navegación al formulario de solicitud
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClientQuoteRequestScreen(
                providerId: providerId,
                providerName: providerName,
              ),
            ),
          );
        },
        // Usamos un icono que sugiera "Llenar formulario"
        icon: const Icon(Icons.assignment_add, size: 20), 
        label: const Text(
          "Solicitar Cotización",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: brandColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: brandColor.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}