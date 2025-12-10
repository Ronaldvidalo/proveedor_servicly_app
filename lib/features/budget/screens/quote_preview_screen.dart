// --- UX/UI Enhancement Comment ---
// Pantalla: QuotePreviewScreen
// Ubicación: lib/features/budget/screens/quote_preview_screen.dart
// Responsabilidad: Mostrar la vista previa del PDF generado usando 'printing'.
// Nota: Este archivo SOLO maneja la UI. La lógica está en services/pdf_generator_service.dart

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

// --- IMPORTS DE MODELOS ---
import 'package:proveedor_servicly_app/features/budget/models/quote_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';

// --- IMPORT DEL SERVICIO DE PDF ---
// Asegúrate de que este archivo exista en la carpeta 'services'
import 'package:proveedor_servicly_app/features/budget/services/pdf_generator_service.dart';

class QuotePreviewScreen extends StatelessWidget {
  final Quote quote;
  final UserModel user;

  const QuotePreviewScreen({
    super.key, 
    required this.quote,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Instanciamos el servicio que contiene la lógica de generación
    final pdfService = PdfGeneratorService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vista Previa PDF"),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: PdfPreview(
        // 1. GENERACIÓN: Llamamos al servicio para crear los bytes del PDF
        build: (format) => pdfService.generateQuotePdf(quote, user),
        
        // 2. CONFIGURACIÓN: Opciones de la UI de Printing
        canChangeOrientation: false,
        canDebug: false, // Ocultar opciones de debug en producción
        
        // Nombre del archivo al compartir/descargar
        pdfFileName: 'Cotizacion_${quote.number}.pdf',
        
        // Widget de carga mientras se genera el documento
        loadingWidget: const Center(child: CircularProgressIndicator()),
        
        // Personalización de acciones (opcional)
        // actions: [ ... ], 
      ),
    );
  }
}