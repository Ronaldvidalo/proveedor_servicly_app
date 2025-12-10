// --- UX/UI Enhancement Comment ---
// Servicio: PdfGeneratorService
// Ubicación: lib/features/budget/services/pdf_generator_service.dart
// Responsabilidad: Maquetar y generar el byte array (Uint8List) del PDF.

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import 'package:proveedor_servicly_app/features/budget/models/quote_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';

class PdfGeneratorService {
  
  /// Genera el PDF y devuelve los bytes
  Future<Uint8List> generateQuotePdf(Quote quote, UserModel provider) async {
    final pdf = pw.Document();

    final profileImage = await _resolveProfileImage(provider.logoUrl);
    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    final currencyFormat = NumberFormat.simpleCurrency(name: quote.currency);
    final dateFormat = DateFormat('dd MMM yyyy');

    final PdfColor primaryColor = PdfColors.blue900; 
    final PdfColor accentColor = PdfColors.grey200;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(40),
          theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        ),
        header: (context) => _buildHeader(quote, provider, profileImage, primaryColor, dateFormat),
        build: (context) => [
          pw.SizedBox(height: 20),
          _buildClientSection(quote),
          pw.SizedBox(height: 30),
          _buildItemsTable(quote, primaryColor, accentColor, currencyFormat),
          pw.SizedBox(height: 20),
          _buildTotalsSection(quote, currencyFormat),
          pw.SizedBox(height: 40),
          _buildTermsSection(quote),
        ],
        footer: (context) => _buildFooter(provider),
      ),
    );

    return pdf.save();
  }

  // --- WIDGETS INTERNOS DEL PDF ---

  pw.Widget _buildHeader(Quote quote, UserModel provider, pw.ImageProvider? logo, PdfColor color, DateFormat dateFormat) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                if (logo != null)
                  pw.Container(
                    width: 60,
                    height: 60,
                    margin: const pw.EdgeInsets.only(right: 15),
                    child: pw.Image(logo),
                  ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(provider.businessName ?? 'Nombre de tu Negocio', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: color)),
                    pw.Text(provider.email ?? '', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text("COTIZACIÓN", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: color)),
                pw.Text("#${quote.number}", style: const pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 5),
                pw.Text("Fecha: ${dateFormat.format(quote.createdAt)}", style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Divider(color: color, thickness: 1),
      ],
    );
  }

  pw.Widget _buildClientSection(Quote quote) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5))),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("PREPARADO PARA:", style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(quote.clientName.isEmpty ? 'Cliente General' : quote.clientName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _buildItemsTable(Quote quote, PdfColor headerColor, PdfColor rowColor, NumberFormat format) {
    return pw.TableHelper.fromTextArray(
      headers: ['DESCRIPCIÓN', 'CANT.', 'PRECIO', 'TOTAL'],
      data: quote.items.map((item) => [
        item.name,
        item.quantity.toString(),
        format.format(item.unitPrice),
        format.format(item.total),
      ]).toList(),
      headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
      headerDecoration: pw.BoxDecoration(color: headerColor),
      cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.center, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
    );
  }

  pw.Widget _buildTotalsSection(Quote quote, NumberFormat format) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text("TOTAL: ${format.format(quote.total)}", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _buildTermsSection(Quote quote) {
    return pw.Text("Gracias por su confianza.", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700));
  }

  pw.Widget _buildFooter(UserModel provider) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300))),
      child: pw.Center(child: pw.Text("Generado por Servicly App", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500))),
    );
  }

  Future<pw.ImageProvider?> _resolveProfileImage(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return pw.MemoryImage(response.bodyBytes);
    } catch (e) { return null; }
    return null;
  }
}